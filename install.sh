#!/bin/bash

# IoT Manager Server Installer for Raspberry Pi 5
# Automatisk oppsett av Home Assistant, MQTT, Node-RED og Zigbee2MQTT

set -e

# Farger for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
INSTALL_DIR="$HOME/iot-manager"

# Print formatted messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║   IoT Manager Server Installer v1.0   ║"
    echo "║      Raspberry Pi 5 Edition           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Ikke kjør dette skriptet som root. Bruk vanlig bruker med sudo rettigheter."
        exit 1
    fi
}

# Check system requirements
check_system() {
    print_info "Sjekker systemkrav..."

    # Check if running on Raspberry Pi
    if [ -f /proc/device-tree/model ]; then
        MODEL=$(cat /proc/device-tree/model)
        print_info "System: $MODEL"
    fi

    # Check available disk space (minimum 10GB)
    AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        print_warning "Du har mindre enn 10GB ledig diskplass. Dette kan være for lite."
        read -p "Vil du fortsette likevel? (j/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Jj]$ ]]; then
            exit 1
        fi
    fi
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker er allerede installert ($(docker --version))"

        # Check if user is in docker group
        if ! groups $USER | grep -q docker; then
            print_info "Legger til bruker i docker gruppe..."
            sudo usermod -aG docker $USER
            DOCKER_GROUP_ADDED=1
        fi
        return
    fi

    print_info "Installerer Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installert"
    DOCKER_GROUP_ADDED=1
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker compose &> /dev/null || command -v docker-compose &> /dev/null; then
        print_success "Docker Compose er allerede installert"
        return
    fi

    print_info "Installerer Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    print_success "Docker Compose installert"
}

# Service selection menu
select_services() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Velg tjenester å installere       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

    # Home Assistant
    read -p "Installere Home Assistant? (J/n) " -n 1 -r
    echo
    INSTALL_HOMEASSISTANT=${REPLY:-J}

    # MQTT Broker
    read -p "Installere MQTT Broker (Mosquitto)? (J/n) " -n 1 -r
    echo
    INSTALL_MQTT=${REPLY:-J}

    # Node-RED
    read -p "Installere Node-RED? (J/n) " -n 1 -r
    echo
    INSTALL_NODERED=${REPLY:-J}

    # Zigbee2MQTT
    read -p "Installere Zigbee2MQTT? (J/n) " -n 1 -r
    echo
    INSTALL_ZIGBEE=${REPLY:-J}

    # Portainer (Docker management UI)
    read -p "Installere Portainer (Docker admin UI)? (j/N) " -n 1 -r
    echo
    INSTALL_PORTAINER=${REPLY:-N}
}

# Create directory structure
create_directories() {
    print_info "Oppretter mappestruktur..."

    mkdir -p "$INSTALL_DIR"

    if [[ $INSTALL_HOMEASSISTANT =~ ^[Jj]$ ]]; then
        mkdir -p "$INSTALL_DIR/homeassistant/config"
    fi

    if [[ $INSTALL_MQTT =~ ^[Jj]$ ]]; then
        mkdir -p "$INSTALL_DIR/mosquitto/config"
        mkdir -p "$INSTALL_DIR/mosquitto/data"
        mkdir -p "$INSTALL_DIR/mosquitto/log"
    fi

    if [[ $INSTALL_NODERED =~ ^[Jj]$ ]]; then
        mkdir -p "$INSTALL_DIR/nodered/data"
    fi

    if [[ $INSTALL_ZIGBEE =~ ^[Jj]$ ]]; then
        mkdir -p "$INSTALL_DIR/zigbee2mqtt/data"
    fi

    if [[ $INSTALL_PORTAINER =~ ^[Jj]$ ]]; then
        mkdir -p "$INSTALL_DIR/portainer/data"
    fi

    print_success "Mappestruktur opprettet i $INSTALL_DIR"
}

# Generate docker-compose.yml
generate_docker_compose() {
    print_info "Genererer docker-compose.yml..."

    cat > "$INSTALL_DIR/docker-compose.yml" << 'EOF'
services:
EOF

    # Home Assistant
    if [[ $INSTALL_HOMEASSISTANT =~ ^[Jj]$ ]]; then
        cat >> "$INSTALL_DIR/docker-compose.yml" << 'EOF'

  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - ./homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
EOF
    fi

    # MQTT Broker
    if [[ $INSTALL_MQTT =~ ^[Jj]$ ]]; then
        cat >> "$INSTALL_DIR/docker-compose.yml" << 'EOF'

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:latest
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    ports:
      - "1883:1883"
      - "9001:9001"
    restart: unless-stopped
EOF
    fi

    # Node-RED
    if [[ $INSTALL_NODERED =~ ^[Jj]$ ]]; then
        cat >> "$INSTALL_DIR/docker-compose.yml" << 'EOF'

  nodered:
    container_name: nodered
    image: nodered/node-red:latest
    volumes:
      - ./nodered/data:/data
    ports:
      - "1880:1880"
    restart: unless-stopped
    environment:
      - TZ=Europe/Oslo
EOF
    fi

    # Zigbee2MQTT
    if [[ $INSTALL_ZIGBEE =~ ^[Jj]$ ]]; then
        cat >> "$INSTALL_DIR/docker-compose.yml" << 'EOF'

  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:latest
    volumes:
      - ./zigbee2mqtt/data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      - "8080:8080"
    restart: unless-stopped
    privileged: true
    environment:
      - TZ=Europe/Oslo
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
EOF
    fi

    # Portainer
    if [[ $INSTALL_PORTAINER =~ ^[Jj]$ ]]; then
        cat >> "$INSTALL_DIR/docker-compose.yml" << 'EOF'

  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    volumes:
      - ./portainer/data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "9000:9000"
      - "9443:9443"
    restart: unless-stopped
EOF
    fi

    print_success "docker-compose.yml generert"
}

# Create Mosquitto configuration
create_mosquitto_config() {
    if [[ $INSTALL_MQTT =~ ^[Jj]$ ]]; then
        print_info "Oppretter Mosquitto konfigurasjon..."

        cat > "$INSTALL_DIR/mosquitto/config/mosquitto.conf" << 'EOF'
# Mosquitto Configuration
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_dest stdout

listener 1883
protocol mqtt

listener 9001
protocol websockets

# Tillat anonyme forbindelser (endre dette i produksjon!)
allow_anonymous true

# For å kreve autentisering, kommenter ut linjen over og bruk:
# allow_anonymous false
# password_file /mosquitto/config/passwd
EOF

        print_success "Mosquitto konfigurasjon opprettet"
        print_warning "VIKTIG: Mosquitto er satt opp med anonym tilgang. Endre dette for produksjon!"
    fi
}

# Create Zigbee2MQTT configuration
create_zigbee_config() {
    if [[ $INSTALL_ZIGBEE =~ ^[Jj]$ ]]; then
        print_info "Oppretter Zigbee2MQTT konfigurasjon..."

        cat > "$INSTALL_DIR/zigbee2mqtt/data/configuration.yaml" << 'EOF'
# Zigbee2MQTT Configuration
homeassistant: true

permit_join: false

mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883

serial:
  port: /dev/ttyUSB0

frontend:
  port: 8080

advanced:
  network_key: GENERATE
  pan_id: GENERATE
  channel: 11
EOF

        print_success "Zigbee2MQTT konfigurasjon opprettet"
        print_warning "VIKTIG: Endre 'port: /dev/ttyUSB0' til riktig Zigbee adapter port"
    fi
}

# Start services
start_services() {
    # Check if docker group was just added
    if [ "${DOCKER_GROUP_ADDED:-0}" -eq 1 ]; then
        print_warning "Docker gruppe ble akkurat lagt til. Du må logge ut og inn igjen."
        echo
        echo -e "${YELLOW}For å starte tjenestene, kjør følgende kommandoer:${NC}"
        echo
        echo -e "  ${BLUE}# Alternativ 1: Logg ut og inn igjen (anbefalt)${NC}"
        echo -e "  exit"
        echo -e "  ssh $USER@\$(hostname -I | awk '{print \$1}')"
        echo -e "  cd $INSTALL_DIR"
        echo -e "  docker compose up -d"
        echo
        echo -e "  ${BLUE}# Alternativ 2: Aktiver docker gruppe uten å logge ut${NC}"
        echo -e "  newgrp docker"
        echo -e "  cd $INSTALL_DIR"
        echo -e "  docker compose up -d"
        echo
        return
    fi

    # Try to start services if docker permissions are OK
    if docker ps &> /dev/null; then
        print_info "Starter tjenester..."
        cd "$INSTALL_DIR"
        docker compose up -d
        print_success "Alle tjenester er startet!"
    else
        print_error "Kan ikke starte Docker. Logg ut og inn igjen, deretter kjør:"
        echo -e "  cd $INSTALL_DIR"
        echo -e "  docker compose up -d"
    fi
}

# Show service URLs
show_urls() {
    LOCAL_IP=$(hostname -I | awk '{print $1}')

    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Installasjon fullført!         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

    # Only show service URLs if services are running
    if [ "${DOCKER_GROUP_ADDED:-0}" -eq 0 ] && docker ps &> /dev/null; then
        echo -e "${BLUE}Tjenester tilgjengelig på:${NC}\n"

        if [[ $INSTALL_HOMEASSISTANT =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Home Assistant:${NC}  http://$LOCAL_IP:8123"
        fi

        if [[ $INSTALL_MQTT =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}MQTT Broker:${NC}     mqtt://$LOCAL_IP:1883"
            echo -e "  ${GREEN}MQTT WebSocket:${NC}  ws://$LOCAL_IP:9001"
        fi

        if [[ $INSTALL_NODERED =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Node-RED:${NC}        http://$LOCAL_IP:1880"
        fi

        if [[ $INSTALL_ZIGBEE =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Zigbee2MQTT:${NC}     http://$LOCAL_IP:8080"
        fi

        if [[ $INSTALL_PORTAINER =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Portainer:${NC}       https://$LOCAL_IP:9443"
        fi
        echo
    else
        echo -e "${YELLOW}Tjenester vil være tilgjengelige etter oppstart:${NC}\n"

        if [[ $INSTALL_HOMEASSISTANT =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Home Assistant:${NC}  http://$LOCAL_IP:8123"
        fi

        if [[ $INSTALL_MQTT =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}MQTT Broker:${NC}     mqtt://$LOCAL_IP:1883"
            echo -e "  ${GREEN}MQTT WebSocket:${NC}  ws://$LOCAL_IP:9001"
        fi

        if [[ $INSTALL_NODERED =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Node-RED:${NC}        http://$LOCAL_IP:1880"
        fi

        if [[ $INSTALL_ZIGBEE =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Zigbee2MQTT:${NC}     http://$LOCAL_IP:8080"
        fi

        if [[ $INSTALL_PORTAINER =~ ^[Jj]$ ]]; then
            echo -e "  ${GREEN}Portainer:${NC}       https://$LOCAL_IP:9443"
        fi
        echo
    fi

    echo -e "${YELLOW}Nyttige kommandoer:${NC}"
    echo -e "  cd $INSTALL_DIR"
    echo -e "  docker compose up -d            # Start alle tjenester"
    echo -e "  docker compose logs -f          # Se logger"
    echo -e "  docker compose restart          # Restart alle tjenester"
    echo -e "  docker compose down             # Stopp alle tjenester\n"

    if [[ $INSTALL_HOMEASSISTANT =~ ^[Jj]$ ]]; then
        echo -e "${YELLOW}Første gangs oppsett:${NC}"
        echo -e "  1. Åpne Home Assistant: http://$LOCAL_IP:8123"
        echo -e "  2. Følg installasjonsveiviseren"
        echo -e "  3. Konfigurer integrasjoner (MQTT, Zigbee2MQTT, etc.)\n"
    fi
}

# Main installation flow
main() {
    show_banner
    check_root
    check_system

    print_info "Starter installasjon av IoT Manager Server..."
    echo

    # Install dependencies
    install_docker
    install_docker_compose

    # Service selection
    select_services

    # Create structure
    create_directories
    generate_docker_compose
    create_mosquitto_config
    create_zigbee_config

    # Start everything
    start_services

    # Show summary
    show_urls

    if [ "${DOCKER_GROUP_ADDED:-0}" -eq 1 ]; then
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}VIKTIG: Logg ut og inn igjen for å aktivere Docker tilgang!${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    else
        print_success "Installasjon fullført! Tjenester kjører."
    fi
}

# Run main function
main
