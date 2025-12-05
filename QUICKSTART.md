# Hurtigstart Guide

## Installasjon (5 minutter)

### 1. SSH til Raspberry Pi

```bash
ssh pi@<PI_IP>
```

### 2. Last ned og kjør installer

```bash
curl -fsSL https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh | bash
```

**ELLER** klon hele repositoriet:

```bash
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager
chmod +x install.sh
./install.sh
```

### 3. Velg tjenester

Skriptet vil spørre hvilke tjenester du vil installere. Trykk `J` (Ja) eller `n` (nei) for hver:

- Home Assistant (anbefalt: J)
- MQTT Broker (anbefalt: J)
- Node-RED (anbefalt: J)
- Zigbee2MQTT (kun hvis du har Zigbee adapter: J/n)
- Portainer (valgfri: n)

### 4. Fullfør installasjonen

Etter at skriptet har kjørt, **MÅ** du aktivere Docker tilgang:

**Velg ETT alternativ:**

**A) newgrp (raskest)**
```bash
newgrp docker
cd ~/iot-manager
docker compose up -d
```

**B) Logg ut og inn**
```bash
exit
ssh admin@<PI_IP>
cd ~/iot-manager
docker compose up -d
```

**C) Bruk sudo**
```bash
cd ~/iot-manager
sudo docker compose up -d
```

### 5. Vent på første oppstart

**Første gang tar 5-10 minutter** - Docker laster ned alle images.

Se oppstarten:
```bash
docker compose logs -f
# Trykk Ctrl+C for å avslutte
```

Sjekk status:
```bash
docker compose ps
```

Alle skal vise "Up".

## Første gangs oppsett

### Home Assistant

1. Åpne: `http://<PI_IP>:8123`
2. Lag admin bruker
3. Følg setup wizard

### Zigbee2MQTT (hvis installert)

```bash
# 1. Finn Zigbee adapter port
ls -l /dev/ttyUSB* /dev/ttyACM*

# 2. Rediger konfigurasjon
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml

# 3. Endre 'port: /dev/ttyUSB0' til riktig port

# 4. Restart
cd ~/iot-manager
docker compose restart zigbee2mqtt
```

Åpne: `http://<PI_IP>:8080`

### Node-RED

1. Åpne: `http://<PI_IP>:1880`
2. Start å bygge flows!

## Daglig bruk

### Se status

```bash
cd ~/iot-manager
docker compose ps
```

### Restart alt

```bash
cd ~/iot-manager
docker compose restart
```

### Se logger

```bash
cd ~/iot-manager
docker compose logs -f
```

### Stopp alt

```bash
cd ~/iot-manager
docker compose stop
```

### Start alt

```bash
cd ~/iot-manager
docker compose start
```

## Viktige URLer

Erstatt `<PI_IP>` med din Pi's IP adresse:

| Tjeneste | URL |
|----------|-----|
| Home Assistant | http://\<PI_IP\>:8123 |
| Node-RED | http://\<PI_IP\>:1880 |
| Zigbee2MQTT | http://\<PI_IP\>:8080 |
| Portainer | https://\<PI_IP\>:9443 |

## Vanlige problemer

### Docker permission denied

```bash
sudo usermod -aG docker $USER
# Logg ut og inn igjen
```

### Tjeneste starter ikke

```bash
# Se logger
docker compose logs <tjenestenavn>

# Eksempel:
docker compose logs homeassistant
```

### Zigbee adapter ikke funnet

```bash
# List USB enheter
ls -l /dev/ttyUSB* /dev/ttyACM*

# Rediger konfigurasjon
nano ~/iot-manager/zigbee2mqtt/data/configuration.yaml

# Restart
docker compose restart zigbee2mqtt
```

## Neste steg

1. Les full dokumentasjon i [README.md](README.md)
2. Sett opp sikkerhet (MQTT autentisering, brannmur)
3. Konfigurer backups
4. Utforsk Home Assistant integrasjoner

## Hjelp

- Full dokumentasjon: [README.md](README.md)
- Problemer: Opprett issue på GitHub
- Docker kommandoer: [Docker Compose docs](https://docs.docker.com/compose/)
