# Detaljert installasjonsveiledning

Denne guiden forklarer hvert steg i installasjonen av IoT Manager på Raspberry Pi 5.

## Forberedelser

### Hva du trenger:
- Raspberry Pi 5 (eller Pi 4)
- Raspberry Pi OS installert (64-bit anbefalt)
- Minimum 10GB ledig diskplass
- Internettforbindelse
- SSH tilgang til Pi'en

### Finn IP-adressen til Pi'en:

Hvis du er koblet til Pi'en via skjerm/tastatur:
```bash
hostname -I
```

Fra en annen maskin på samme nettverk:
```bash
# Windows
ping raspberrypi.local

# Mac/Linux
arp -a | grep raspberry
```

## Steg 1: Koble til via SSH

```bash
ssh admin@<PI_IP>
# eller
ssh pi@<PI_IP>

# Eksempel:
ssh admin@192.168.1.100
```

Standard passord er ofte `raspberry` (endre dette etter installasjon!)

## Steg 2: Last ned installasjonsskriptet

### Metode A: Klon hele repository (anbefalt)

```bash
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager
chmod +x install.sh
```

### Metode B: Last ned kun install.sh

```bash
curl -O https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh
chmod +x install.sh
```

## Steg 3: Kjør installasjonen

```bash
./install.sh
```

### Hva skriptet gjør:

1. **Sjekker systemkrav**
   - Verifiserer Raspberry Pi modell
   - Sjekker ledig diskplass (minimum 10GB)

2. **Installerer Docker** (hvis ikke installert)
   - Laster ned Docker installasjonsskript
   - Installerer Docker Engine
   - Legger brukeren din til `docker` gruppe

3. **Installerer Docker Compose** (hvis ikke installert)
   - Installerer docker-compose-plugin

4. **Lar deg velge tjenester**
   - Home Assistant (J/n)
   - MQTT Broker/Mosquitto (J/n)
   - Node-RED (J/n)
   - Zigbee2MQTT (J/n)
   - Portainer (j/N)

5. **Oppretter mappestruktur**
   ```
   ~/iot-manager/
   ├── docker-compose.yml
   ├── homeassistant/
   │   └── config/
   ├── mosquitto/
   │   ├── config/
   │   ├── data/
   │   └── log/
   ├── nodered/
   │   └── data/
   ├── zigbee2mqtt/
   │   └── data/
   └── portainer/
       └── data/
   ```

6. **Genererer konfigurasjonsfiler**
   - docker-compose.yml med valgte tjenester
   - Mosquitto konfigurasjon
   - Zigbee2MQTT konfigurasjon (hvis valgt)

## Steg 4: VIKTIG - Aktiver Docker tilgang

Etter at skriptet har kjørt, vil du se en melding om at du må aktivere Docker tilgang.

### Hvorfor?

Linux krever at brukere logger ut og inn igjen etter å ha blitt lagt til i en ny gruppe (docker gruppe).

### Løsning - Velg ETT alternativ:

#### Alternativ A: newgrp (raskest, anbefalt)

```bash
# Dette aktiverer docker gruppe i current session
newgrp docker
```

**Fordeler:** Raskest, ingen ny innlogging
**Ulemper:** Kun i current terminal session

#### Alternativ B: Logg ut og inn (mest ryddig)

```bash
# Logg ut
exit

# Logg inn igjen
ssh admin@192.168.1.100
```

**Fordeler:** Permanent for alle sessions
**Ulemper:** Må logge inn på nytt

#### Alternativ C: Bruk sudo (fungerer, men ikke ideelt)

```bash
# Kjør docker kommandoer med sudo
sudo docker compose up -d
```

**Fordeler:** Fungerer umiddelbart
**Ulemper:** Må bruke sudo hver gang, kan skape permission issues

## Steg 5: Start tjenestene

```bash
cd ~/iot-manager
docker compose up -d
```

### Hva skjer nå:

Docker vil laste ned alle images. **Dette tar 5-10 minutter første gang!**

```
[+] Pulling...
✔ homeassistant Pulling... (823MB)
✔ mosquitto Pulling... (12MB)
✔ nodered Pulling... (421MB)
✔ portainer Pulling... (287MB)
```

## Steg 6: Overvåk oppstarten

### Se logger i sanntid:

```bash
# Alle tjenester
docker compose logs -f

# Spesifikk tjeneste
docker compose logs -f homeassistant

# Trykk Ctrl+C for å avslutte
```

### Sjekk status:

```bash
docker compose ps
```

**Forventet output:**
```
NAME            IMAGE                                     STATUS         PORTS
homeassistant   ghcr.io/home-assistant/home-assistant    Up 2 minutes   0.0.0.0:8123->8123/tcp
mosquitto       eclipse-mosquitto:latest                  Up 2 minutes   0.0.0.0:1883->1883/tcp, 0.0.0.0:9001->9001/tcp
nodered         nodered/node-red:latest                   Up 2 minutes   0.0.0.0:1880->1880/tcp
portainer       portainer/portainer-ce:latest             Up 2 minutes   0.0.0.0:9443->9443/tcp
```

Alle skal vise **"Up X minutes"** - ikke "Restarting" eller "Exited"

## Steg 7: Åpne tjenestene

### Finn IP-adressen:

```bash
hostname -I
# Output: 192.168.1.100
```

### Åpne i nettleseren:

| Tjeneste | URL | Kommentar |
|----------|-----|-----------|
| Home Assistant | http://192.168.1.100:8123 | Tar 2-3 min å starte første gang |
| Node-RED | http://192.168.1.100:1880 | Klar umiddelbart |
| Zigbee2MQTT | http://192.168.1.100:8080 | Hvis installert |
| Portainer | https://192.168.1.100:9443 | Aksepter self-signed cert |

### MQTT Broker:

MQTT broker har ikke web interface, men lytter på:
- Port 1883 (MQTT)
- Port 9001 (WebSocket)

Test med:
```bash
# Installer mosquitto clients
sudo apt-get install mosquitto-clients

# Test publish
mosquitto_pub -h localhost -t test/topic -m "Hello from IoT Manager"

# Test subscribe (i annen terminal)
mosquitto_sub -h localhost -t test/topic
```

## Steg 8: Første gangs oppsett

### Home Assistant

1. Åpne http://192.168.1.100:8123
2. Vent 2-3 minutter på første oppstart
3. Klikk "Create my smart home"
4. Fyll inn:
   - Navn
   - Brukernavn
   - Passord
   - Lokasjon
5. Klikk gjennom veiviseren

### Node-RED

1. Åpne http://192.168.1.100:1880
2. Dra nodes fra venstre side
3. Koble sammen for å lage flows
4. Klikk "Deploy" for å aktivere

### Portainer

1. Åpne https://192.168.1.100:9443
2. Aksepter security warning (self-signed certificate)
3. Opprett admin passord (minimum 12 tegn)
4. Velg "Get Started"
5. Klikk "local" for å administrere Docker

### Zigbee2MQTT (hvis installert)

**VIKTIG: Må konfigureres før bruk!**

1. Finn Zigbee adapter port:
```bash
ls -l /dev/ttyUSB* /dev/ttyACM*
```

2. Rediger konfigurasjon:
```bash
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml
```

3. Endre port (eksempel):
```yaml
serial:
  port: /dev/ttyUSB0  # eller /dev/ttyACM0
```

4. Restart:
```bash
docker compose restart zigbee2mqtt
```

5. Åpne http://192.168.1.100:8080

## Vanlige problemer

### "Permission denied" når du kjører docker

**Problem:** Docker gruppe ikke aktivert

**Løsning:**
```bash
newgrp docker
# eller logg ut og inn igjen
```

### Home Assistant viser ikke noe

**Problem:** Fortsatt starter opp

**Løsning:** Vent 2-3 minutter, sjekk logger:
```bash
docker compose logs -f homeassistant
```

### Zigbee2MQTT starter ikke

**Problem:** Feil USB port eller mangler tilgang

**Løsning:**
```bash
# Sjekk USB enheter
ls -l /dev/ttyUSB* /dev/ttyACM*

# Legg til bruker i dialout gruppe
sudo usermod -aG dialout $USER

# Logg ut og inn, restart zigbee2mqtt
docker compose restart zigbee2mqtt
```

### "Port already in use"

**Problem:** Port er opptatt av annen tjeneste

**Løsning:**
```bash
# Sjekk hvem som bruker porten (eksempel port 8123)
sudo netstat -tulpn | grep 8123

# Stopp tjenesten eller endre port i docker-compose.yml
```

## Neste steg

1. ✅ Sikre MQTT med passord → [README.md](README.md#mqtt-broker)
2. ✅ Sett opp brannmur → [README.md](README.md#sikkerhet)
3. ✅ Konfigurer automatisk backup → [scripts/backup.sh](scripts/backup.sh)
4. ✅ Koble Home Assistant til MQTT
5. ✅ Legg til Zigbee enheter
6. ✅ Opprett Node-RED flows

## Nyttige kommandoer

```bash
# Gå til iot-manager mappen
cd ~/iot-manager

# Se status
docker compose ps

# Se logger
docker compose logs -f

# Restart alt
docker compose restart

# Restart spesifikk tjeneste
docker compose restart homeassistant

# Stopp alt
docker compose stop

# Start alt
docker compose start

# Stopp og fjern containere (data bevares)
docker compose down

# Oppdater images
docker compose pull
docker compose up -d
```

## Få hjelp

- [README.md](README.md) - Komplett dokumentasjon
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Feilsøking
- [GitHub Issues](https://github.com/sverrekm/IOT-mannager/issues) - Rapporter problemer

## Gratulerer!

Du har nå en fullverdig IoT server kjørende på Raspberry Pi! 🎉
