#!/bin/bash

# IoT Manager Server Uninstaller
# Fjerner alle tjenester og data (ADVARSEL: Dette sletter alt!)

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

INSTALL_DIR="$HOME/iot-manager"

echo -e "${RED}"
echo "╔════════════════════════════════════════╗"
echo "║   IoT Manager Server Uninstaller      ║"
echo "║            ADVARSEL!                  ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Dette vil fjerne:${NC}"
echo "  - Alle Docker containere"
echo "  - Alle konfigurasjonsfiler"
echo "  - Alle data (Home Assistant, Node-RED, Zigbee nettverk, etc.)"
echo "  - Docker images (valgfritt)"
echo

echo -e "${RED}ADVARSEL: Denne handlingen kan ikke angres!${NC}"
echo

read -p "Er du SIKKER på at du vil fortsette? (skriv 'JA' med store bokstaver): " CONFIRM

if [ "$CONFIRM" != "JA" ]; then
    echo "Avbryter..."
    exit 0
fi

echo

# Ta backup først?
read -p "Vil du ta en backup før sletting? (J/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    if [ -f "$INSTALL_DIR/../IOTmanager/scripts/backup.sh" ]; then
        echo "Tar backup..."
        bash "$INSTALL_DIR/../IOTmanager/scripts/backup.sh"
    elif [ -f "./scripts/backup.sh" ]; then
        echo "Tar backup..."
        bash ./scripts/backup.sh
    else
        echo -e "${YELLOW}Backup script ikke funnet, hopper over...${NC}"
    fi
fi

echo

if [ -d "$INSTALL_DIR" ]; then
    echo "Stopper alle tjenester..."
    cd "$INSTALL_DIR"

    if [ -f "docker-compose.yml" ]; then
        docker compose down
        echo -e "${GREEN}✓ Tjenester stoppet og fjernet${NC}"
    fi

    cd ..

    echo "Sletter installasjonsmappe..."
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Installasjonsmappe slettet${NC}"
else
    echo -e "${YELLOW}Installasjonsmappe finnes ikke: $INSTALL_DIR${NC}"
fi

# Fjern Docker images?
echo
read -p "Vil du også fjerne Docker images? (Dette frigjør diskplass) (j/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "Fjerner Docker images..."

    docker rmi ghcr.io/home-assistant/home-assistant:stable 2>/dev/null || true
    docker rmi eclipse-mosquitto:latest 2>/dev/null || true
    docker rmi nodered/node-red:latest 2>/dev/null || true
    docker rmi koenkk/zigbee2mqtt:latest 2>/dev/null || true
    docker rmi portainer/portainer-ce:latest 2>/dev/null || true

    echo -e "${GREEN}✓ Docker images fjernet${NC}"

    echo
    read -p "Vil du kjøre 'docker system prune' for å fjerne ubrukte images og containere? (j/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        docker system prune -f
        echo -e "${GREEN}✓ Docker system renset${NC}"
    fi
fi

# Fjern Docker helt?
echo
read -p "Vil du avinstallere Docker helt? (j/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "Avinstallerer Docker..."
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    echo -e "${GREEN}✓ Docker avinstallert${NC}"
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Avinstallasjon fullført!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo

if [ -d "$HOME/iot-manager-backups" ]; then
    echo -e "${YELLOW}Merk: Backups finnes fortsatt i: $HOME/iot-manager-backups${NC}"
    echo "Slett manuelt hvis ønsket: rm -rf $HOME/iot-manager-backups"
fi

echo
echo "For å installere på nytt, kjør install.sh igjen."
