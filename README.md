# IoT Manager Server for Raspberry Pi 5

Automatisk installasjonsskript for å sette opp en komplett IoT server på Raspberry Pi 5 med Docker og Docker Compose.

## Innhold

- [Home Assistant](https://www.home-assistant.io/) - Smart home platform
- [Mosquitto](https://mosquitto.org/) - MQTT broker
- [Node-RED](https://nodered.org/) - Flow-basert automatisering
- [Zigbee2MQTT](https://www.zigbee2mqtt.io/) - Zigbee til MQTT bridge
- [Portainer](https://www.portainer.io/) (valgfri) - Docker administrasjon

## Systemkrav

- Raspberry Pi 5 (anbefalt) eller Raspberry Pi 4
- Raspberry Pi OS (64-bit anbefalt)
- Minimum 10GB ledig diskplass
- Internettforbindelse
- SSH tilgang til Pi'en
- (Valgfri) Zigbee USB adapter (for Zigbee2MQTT)

## Rask installasjon

### Installere via SSH

Koble til Raspberry Pi via SSH og kjør:

```bash
# Klon repositoriet
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager

# Gjør skriptet kjørbart
chmod +x install.sh

# Kjør installasjonen
./install.sh
```

### Alternativ: Last ned direkte

```bash
# Last ned install.sh direkte
curl -O https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh

# Gjør det kjørbart
chmod +x install.sh

# Kjør installasjon
./install.sh
```

## Installasjonsforløp

Skriptet vil:

1. Sjekke systemkrav
2. Installere Docker og Docker Compose (hvis ikke allerede installert)
3. La deg velge hvilke tjenester du vil installere
4. Opprette nødvendig mappestruktur
5. Generere docker-compose.yml basert på dine valg
6. Opprette konfigurasjonsfiler
7. Starte alle valgte tjenester

## Tjenester og porter

Etter installasjon vil tjenestene være tilgjengelige på følgende adresser:

| Tjeneste | URL | Port | Beskrivelse |
|----------|-----|------|-------------|
| Home Assistant | `http://<PI_IP>:8123` | 8123 | Smart home dashboard |
| MQTT Broker | `mqtt://<PI_IP>:1883` | 1883 | MQTT protokoll |
| MQTT WebSocket | `ws://<PI_IP>:9001` | 9001 | MQTT over WebSocket |
| Node-RED | `http://<PI_IP>:1880` | 1880 | Automatisering |
| Zigbee2MQTT | `http://<PI_IP>:8080` | 8080 | Zigbee admin |
| Portainer | `https://<PI_IP>:9443` | 9443 | Docker admin |

Erstatt `<PI_IP>` med din Raspberry Pi's IP-adresse.

## Første gangs oppsett

### Home Assistant

1. Åpne `http://<PI_IP>:8123`
2. Følg installasjonsveiviseren
3. Opprett admin bruker
4. Konfigurer lokasjon og enheter

### MQTT Broker

MQTT broker er som standard satt opp med anonym tilgang for enkelt oppsett.

**For produksjon - legg til autentisering:**

```bash
# Legg til MQTT bruker
cd ~/iot-manager
chmod +x scripts/add-mqtt-user.sh
./scripts/add-mqtt-user.sh

# Følg instruksjonene for å aktivere autentisering
```

### Node-RED

1. Åpne `http://<PI_IP>:1880`
2. Installer MQTT nodes (vanligvis inkludert)
3. Konfigurer MQTT broker tilkobling:
   - Server: `mosquitto` (hvis i samme Docker nettverk) eller `<PI_IP>`
   - Port: `1883`

### Zigbee2MQTT

**Viktig:** Før du starter Zigbee2MQTT, må du konfigurere riktig USB port.

1. Finn din Zigbee adapter port:
```bash
ls -l /dev/ttyUSB* /dev/ttyACM*
```

2. Rediger konfigurasjonsfilen:
```bash
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml
```

3. Endre `port:` til riktig enhet (f.eks. `/dev/ttyUSB0`)

4. Restart Zigbee2MQTT:
```bash
cd ~/iot-manager
docker compose restart zigbee2mqtt
```

5. Åpne `http://<PI_IP>:8080` for å administrere Zigbee enheter

## Administrasjon

### Nyttige kommandoer

Alle kommandoer kjøres fra `~/iot-manager` mappen:

```bash
cd ~/iot-manager

# Se status
docker compose ps

# Se logger
docker compose logs -f

# Se logger for spesifikk tjeneste
docker compose logs -f homeassistant

# Restart alle tjenester
docker compose restart

# Restart spesifikk tjeneste
docker compose restart mosquitto

# Stopp alle tjenester
docker compose stop

# Start alle tjenester
docker compose start

# Stopp og fjern containere
docker compose down

# Start på nytt (opprett containere)
docker compose up -d

# Oppdater alle images
docker compose pull
docker compose up -d
```

### Bruke administrasjonsskriptet

For enklere administrasjon, bruk `manage.sh`:

```bash
cd ~/iot-manager
chmod +x scripts/manage.sh

# Bruk scriptet
./scripts/manage.sh status    # Se status
./scripts/manage.sh restart   # Restart alle
./scripts/manage.sh logs      # Se logger
./scripts/manage.sh update    # Oppdater images
```

## Backup og gjenoppretting

### Ta backup

```bash
cd ~/iot-manager
chmod +x scripts/backup.sh
./scripts/backup.sh
```

Backups lagres i `~/iot-manager-backups/` og inkluderer:
- Alle konfigurasjonsfiler
- Home Assistant konfigurasjon
- Node-RED flows
- Zigbee2MQTT nettverk konfigurasjon
- MQTT brukere og ACL

### Gjenopprett fra backup

```bash
# Stopp tjenester
cd ~/iot-manager
docker compose down

# Pakk ut backup
tar -xzf ~/iot-manager-backups/iot-manager-backup-YYYYMMDD_HHMMSS.tar.gz -C ~/

# Start tjenester
cd ~/iot-manager
docker compose up -d
```

## Zigbee adapter konfigurasjon

### Vanlige Zigbee adaptere

| Adapter | Port | Kommentar |
|---------|------|-----------|
| ConBee II | `/dev/ttyUSB0` | Populær og stabil |
| CC2531 | `/dev/ttyUSB0` | Krever flashing |
| Sonoff Zigbee 3.0 | `/dev/ttyACM0` | USB dongle |
| SLZB-06 | Nettverk | Ethernet/WiFi basert |

### Gi tilgang til USB port

```bash
# Legg bruker til dialout gruppe
sudo usermod -aG dialout $USER

# Logg ut og inn igjen for at endring skal tre i kraft
```

## Feilsøking

### Docker permission denied

```bash
# Legg bruker til docker gruppe
sudo usermod -aG docker $USER

# Logg ut og inn igjen
```

### Port allerede i bruk

Sjekk hvilken prosess som bruker porten:
```bash
sudo netstat -tulpn | grep :8123
```

### Zigbee adapter ikke funnet

```bash
# List tilgjengelige USB enheter
ls -l /dev/ttyUSB* /dev/ttyACM*

# Sjekk USB enheter
lsusb

# Se kernel meldinger
dmesg | grep tty
```

### Home Assistant starter ikke

```bash
# Sjekk logger
docker compose logs homeassistant

# Sjekk fil rettigheter
ls -la ~/iot-manager/homeassistant/

# Restart med ren konfigurasjon
docker compose stop homeassistant
mv ~/iot-manager/homeassistant/config ~/iot-manager/homeassistant/config.backup
mkdir ~/iot-manager/homeassistant/config
docker compose start homeassistant
```

## Sikkerhet

### Viktige sikkerhetstiltak

1. **Endre MQTT til autentisert tilgang**
   - Bruk `scripts/add-mqtt-user.sh`
   - Rediger `mosquitto/config/mosquitto.conf`
   - Sett `allow_anonymous false`

2. **Sikre Home Assistant**
   - Bruk sterke passord
   - Aktiver 2FA i Home Assistant
   - Ikke eksponer direkte til internett (bruk VPN)

3. **Sikre Zigbee2MQTT**
   - Sett `permit_join: false` etter oppsett
   - Bruk `auth_token` i frontend konfigurasjon

4. **Portainer**
   - Sett sterkt admin passord ved første innlogging

5. **Nettverk**
   - Bruk brannmur (ufw)
   - Kun eksponer nødvendige porter
   - Vurder å bruke VPN for ekstern tilgang

### Sett opp brannmur

```bash
# Installer ufw
sudo apt-get install ufw

# Tillat SSH
sudo ufw allow ssh

# Tillat nødvendige porter
sudo ufw allow 8123/tcp  # Home Assistant
sudo ufw allow 1880/tcp  # Node-RED
sudo ufw allow 8080/tcp  # Zigbee2MQTT
sudo ufw allow 9443/tcp  # Portainer

# Aktiver brannmur
sudo ufw enable
```

## Oppdateringer

### Oppdatere Docker images

```bash
cd ~/iot-manager
docker compose pull
docker compose up -d
```

### Oppdatere Raspberry Pi OS

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
```

## Ytterligere integrasjoner

### Koble Node-RED til Home Assistant

1. Åpne Node-RED (`http://<PI_IP>:1880`)
2. Gå til Hamburger meny → Manage palette
3. Installer `node-red-contrib-home-assistant-websocket`
4. Konfigurer Home Assistant server node med:
   - Base URL: `http://homeassistant:8123`
   - Access Token: (generer i Home Assistant under profil)

### Koble Zigbee2MQTT til Home Assistant

Zigbee2MQTT oppdages automatisk i Home Assistant når `homeassistant: true` er satt i configuration.yaml.

1. Åpne Home Assistant
2. Gå til Settings → Devices & Services
3. MQTT integrasjon skal vises automatisk
4. Zigbee enheter vises under MQTT

## Support og bidrag

- Rapporter problemer på GitHub Issues
- Bidra med forbedringer via Pull Requests
- Dokumentasjon: Se `/docs` mappen

## Lisens

MIT License - se LICENSE fil

## Anerkjennelser

Dette prosjektet bruker følgende åpen kildekode programvare:
- Home Assistant
- Eclipse Mosquitto
- Node-RED
- Zigbee2MQTT
- Portainer

## Lenker

- [Home Assistant Dokumentasjon](https://www.home-assistant.io/docs/)
- [Zigbee2MQTT Støttede enheter](https://www.zigbee2mqtt.io/supported-devices/)
- [Node-RED Dokumentasjon](https://nodered.org/docs/)
- [Mosquitto MQTT Broker](https://mosquitto.org/documentation/)
