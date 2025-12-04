# Feilsøking Guide

Vanlige problemer og løsninger for IoT Manager Server.

## Innholdsfortegnelse

- [Docker problemer](#docker-problemer)
- [Home Assistant problemer](#home-assistant-problemer)
- [MQTT problemer](#mqtt-problemer)
- [Node-RED problemer](#node-red-problemer)
- [Zigbee2MQTT problemer](#zigbee2mqtt-problemer)
- [Nettverksproblemer](#nettverksproblemer)
- [Ytelse problemer](#ytelse-problemer)

## Docker problemer

### "permission denied" ved Docker kommandoer

**Problem:** Får feilmelding om tillatelser når du kjører Docker kommandoer.

**Løsning:**
```bash
# Legg bruker til docker gruppe
sudo usermod -aG docker $USER

# Logg ut og inn igjen
exit

# Eller restart session
newgrp docker

# Test
docker ps
```

### "Cannot connect to the Docker daemon"

**Problem:** Docker daemon kjører ikke.

**Løsning:**
```bash
# Sjekk Docker status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Aktiver Docker ved oppstart
sudo systemctl enable docker
```

### Containere starter ikke

**Problem:** Containere går ned umiddelbart etter start.

**Løsning:**
```bash
# Se logger for spesifikk container
docker compose logs <container_navn>

# Eksempel:
docker compose logs homeassistant

# Sjekk om porter er i bruk
sudo netstat -tulpn | grep <port_nummer>

# Sjekk diskplass
df -h
```

## Home Assistant problemer

### Home Assistant starter ikke

**Problem:** Home Assistant container starter ikke eller crasher.

**Løsning:**
```bash
# Se logger
docker compose logs homeassistant

# Sjekk fil-rettigheter
ls -la ~/iot-manager/homeassistant/

# Hvis corrupted config, start med ren konfig
cd ~/iot-manager
docker compose stop homeassistant
mv homeassistant/config homeassistant/config.backup
mkdir homeassistant/config
docker compose start homeassistant
```

### "502 Bad Gateway" når du åpner Home Assistant

**Problem:** Nginx error eller Home Assistant ikke klar.

**Løsning:**
```bash
# Vent 2-3 minutter - første oppstart tar tid

# Sjekk at container kjører
docker compose ps

# Se logger
docker compose logs -f homeassistant

# Restart hvis nødvendig
docker compose restart homeassistant
```

### Integrasjoner forsvinner

**Problem:** Integrasjoner eller enheter forsvinner etter restart.

**Løsning:**
```bash
# Sjekk at volumes er mounted korrekt
docker inspect homeassistant | grep -A 10 Mounts

# Sjekk configuration.yaml for feil
cd ~/iot-manager/homeassistant/config
nano configuration.yaml

# Valider konfigurasjon
docker compose exec homeassistant hass --script check_config
```

## MQTT problemer

### Kan ikke koble til MQTT broker

**Problem:** Klienter kan ikke koble til Mosquitto.

**Løsning:**
```bash
# Sjekk at Mosquitto kjører
docker compose ps mosquitto

# Se logger
docker compose logs mosquitto

# Test forbindelse
mosquitto_sub -h localhost -p 1883 -t test/topic -v

# Hvis kommando ikke finnes, installer:
sudo apt-get install mosquitto-clients

# Test med Docker
docker run -it --rm --network host eclipse-mosquitto mosquitto_sub -h localhost -t test
```

### "Connection refused" på port 1883

**Problem:** Kan ikke koble til MQTT port.

**Løsning:**
```bash
# Sjekk at porten er åpen
sudo netstat -tulpn | grep 1883

# Sjekk mosquitto.conf
cat ~/iot-manager/mosquitto/config/mosquitto.conf

# Restart Mosquitto
docker compose restart mosquitto

# Sjekk brannmur
sudo ufw status
sudo ufw allow 1883/tcp
```

### Autentisering feiler

**Problem:** Kan ikke logge inn med brukernavn/passord.

**Løsning:**
```bash
# Sjekk at passordfil eksisterer
ls -la ~/iot-manager/mosquitto/config/passwd

# Legg til bruker på nytt
cd ~/iot-manager
./scripts/add-mqtt-user.sh

# Sjekk mosquitto.conf
cat mosquitto/config/mosquitto.conf
# Skal ha:
# allow_anonymous false
# password_file /mosquitto/config/passwd

# Restart
docker compose restart mosquitto
```

## Node-RED problemer

### Node-RED starter ikke

**Problem:** Node-RED container starter ikke.

**Løsning:**
```bash
# Se logger
docker compose logs nodered

# Sjekk diskplass
df -h

# Sjekk fil-rettigheter
ls -la ~/iot-manager/nodered/

# Restart med ren data (ADVARSEL: sletter flows)
docker compose stop nodered
mv ~/iot-manager/nodered/data ~/iot-manager/nodered/data.backup
mkdir ~/iot-manager/nodered/data
docker compose start nodered
```

### Kan ikke installere nodes

**Problem:** npm install feiler i Node-RED.

**Løsning:**
```bash
# Sjekk diskplass
df -h

# Gi container mer minne
# Rediger docker-compose.yml og legg til:
# deploy:
#   resources:
#     limits:
#       memory: 512M

# Restart
docker compose up -d
```

### Flows forsvinner

**Problem:** Flows blir borte etter restart.

**Løsning:**
```bash
# Sjekk at volume er mounted
docker inspect nodered | grep -A 10 Mounts

# Sjekk fil-rettigheter
ls -la ~/iot-manager/nodered/data/

# Restore fra backup
cp ~/iot-manager-backups/latest/nodered/data/flows.json ~/iot-manager/nodered/data/
docker compose restart nodered
```

## Zigbee2MQTT problemer

### Zigbee adapter ikke funnet

**Problem:** "Error: Error while opening serialport 'Error: Error: No such file or directory'"

**Løsning:**
```bash
# List tilgjengelige USB enheter
ls -l /dev/ttyUSB* /dev/ttyACM* /dev/serial/by-id/*

# Sjekk USB enheter
lsusb

# Se kernel meldinger
dmesg | grep -i usb

# Oppdater configuration.yaml med riktig port
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml

# Endre til riktig port, f.eks.:
# serial:
#   port: /dev/ttyUSB0

# Legg bruker til dialout gruppe
sudo usermod -aG dialout $USER

# Restart
docker compose restart zigbee2mqtt
```

### Enheter mister forbindelse

**Problem:** Zigbee enheter går offline regelmessig.

**Løsning:**
```bash
# Sjekk Zigbee kanal interferens med WiFi
# Rediger configuration.yaml
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml

# Endre kanal (11, 15, 20, 25 er vanligvis best)
# advanced:
#   channel: 20

# Sjekk signal styrke i Zigbee2MQTT web UI
# http://<PI_IP>:8080

# Legg til flere router enheter (plugger) for bedre mesh
```

### "Database is locked"

**Problem:** SQLite database låst.

**Løsning:**
```bash
# Stopp Zigbee2MQTT
docker compose stop zigbee2mqtt

# Vent 10 sekunder
sleep 10

# Start igjen
docker compose start zigbee2mqtt

# Hvis fortsatt problem, sjekk fil-rettigheter
ls -la ~/iot-manager/zigbee2mqtt/data/
```

## Nettverksproblemer

### Kan ikke nå tjenester fra andre enheter

**Problem:** Kan åpne tjenester på Pi'en selv, men ikke fra andre PC/mobiler.

**Løsning:**
```bash
# Sjekk brannmur
sudo ufw status

# Tillat nødvendige porter
sudo ufw allow 8123/tcp  # Home Assistant
sudo ufw allow 1880/tcp  # Node-RED
sudo ufw allow 8080/tcp  # Zigbee2MQTT
sudo ufw allow 1883/tcp  # MQTT

# Sjekk IP adresse
hostname -I

# Test fra annen enhet
ping <PI_IP>

# Sjekk at containere lytter på riktig interface
docker compose ps
```

### "Host mode networking not supported"

**Problem:** Home Assistant klager på host networking (vanligvis ikke på Raspberry Pi).

**Løsning:**
```bash
# Rediger docker-compose.yml
nano ~/iot-manager/docker-compose.yml

# For homeassistant, endre fra:
#   network_mode: host
# Til:
#   ports:
#     - "8123:8123"

# Restart
docker compose up -d
```

## Ytelse problemer

### Raspberry Pi er treg

**Problem:** Systemet reagerer sent.

**Løsning:**
```bash
# Sjekk CPU og minne
htop

# Hvis ikke installert:
sudo apt-get install htop

# Sjekk Docker stats
docker stats

# Sjekk diskplass
df -h

# Sjekk disk I/O
sudo iotop

# Vurder:
# 1. Bruke SSD i stedet for SD-kort
# 2. Øke swap
# 3. Disable unødvendige tjenester
```

### SD kort fylles opp

**Problem:** Lite diskplass igjen.

**Løsning:**
```bash
# Sjekk diskbruk
df -h

# Finn store filer
du -sh ~/iot-manager/* | sort -h

# Rydd Docker
docker system prune -a

# Begrens logger
# Rediger docker-compose.yml og legg til for hver service:
# logging:
#   driver: "json-file"
#   options:
#     max-size: "10m"
#     max-file: "3"

# Restart
docker compose up -d

# Rydd apt cache
sudo apt-get clean
sudo apt-get autoclean
```

## Generell feilsøking

### Få detaljerte logger

```bash
# Alle tjenester
docker compose logs -f

# Spesifikk tjeneste
docker compose logs -f homeassistant

# Siste 100 linjer
docker compose logs --tail=100 homeassistant

# Med tidsstempler
docker compose logs -f -t
```

### Restart alt

```bash
cd ~/iot-manager
docker compose restart
```

### Start på nytt fra scratch

```bash
# Ta backup først!
cd ~/iot-manager
./scripts/backup.sh

# Stopp og fjern alt
docker compose down

# Fjern data (ADVARSEL: Sletter alt!)
rm -rf homeassistant/ mosquitto/data/ nodered/data/ zigbee2mqtt/data/

# Start på nytt
docker compose up -d
```

### Kontakt support

Hvis problemet vedvarer:

1. Ta skjermbilder av feilmeldinger
2. Samle logger: `docker compose logs > logs.txt`
3. Opprett issue på GitHub med:
   - Problembeskrivelse
   - Hva du har prøvd
   - Logger
   - System info (Raspberry Pi modell, OS versjon)

## Nyttige kommandoer

```bash
# System info
uname -a
cat /etc/os-release

# Docker versjon
docker --version
docker compose version

# Sjekk alle kjørende containere
docker ps -a

# Sjekk Docker disk bruk
docker system df

# Sjekk nettverk
docker network ls
docker network inspect iot-manager_default

# Restart Docker daemon
sudo systemctl restart docker

# Se system logger
journalctl -u docker -f
```
