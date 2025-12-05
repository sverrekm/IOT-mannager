# IoT Manager - Start Her!

## Du har nå alle filene klare! Her er neste steg:

### 1. Push filene til GitHub

Du har to alternativer:

#### Windows:
```cmd
# Dobbeltklikk på:
git-push.bat
```

#### Linux/Mac/Git Bash:
```bash
chmod +x git-push.sh
./git-push.sh
```

#### Manuelt (alle plattformer):
```bash
git init
git add .
git commit -m "Initial commit: IoT Manager installer for Raspberry Pi 5"
git remote add origin https://github.com/sverrekm/IOT-mannager.git
git branch -M main
git push -u origin main
```

**Viktig:** Du må ha tilgang til GitHub repositoryet `sverrekm/IOT-mannager`

### 2. Verifiser opplasting

Gå til: https://github.com/sverrekm/IOT-mannager

Sjekk at alle filene er der:
- ✓ install.sh
- ✓ README.md
- ✓ docker-compose.example.yml
- ✓ scripts/ mappe
- ✓ configs/ mappe

### 3. Installer på Raspberry Pi

SSH til din Raspberry Pi:

```bash
ssh pi@<PI_IP_ADRESSE>
```

Kjør installasjon:

```bash
# Alternativ 1: Direkte nedlasting og kjøring
curl -fsSL https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh | bash

# Alternativ 2: Klon først
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager
chmod +x install.sh
./install.sh
```

### 4. Følg installasjonsveiledningen

Skriptet vil:
1. Sjekke systemkrav
2. Installere Docker og Docker Compose
3. Legge til deg i Docker gruppe
4. La deg velge tjenester
5. Sette opp alt automatisk

### 5. VIKTIG: Fullfør installasjonen

**Etter at install.sh er ferdig, MÅ du kjøre:**

```bash
# Aktiver docker tilgang
newgrp docker

# Start tjenestene
cd ~/iot-manager
docker compose up -d
```

**Alternativt: Logg ut og inn igjen**
```bash
exit
ssh admin@<PI_IP>
cd ~/iot-manager
docker compose up -d
```

### 6. Overvåk første oppstart (5-10 minutter)

```bash
# Se at images lastes ned
docker compose logs -f

# Sjekk status (alle skal være "Up")
docker compose ps
```

### 7. Åpne tjenestene

Etter installasjon, åpne i nettleseren (erstatt `<PI_IP>` med Pi'ens IP):

- Home Assistant: http://\<PI_IP\>:8123
- Node-RED: http://\<PI_IP\>:1880
- Zigbee2MQTT: http://\<PI_IP\>:8080
- MQTT: mqtt://\<PI_IP\>:1883

## Dokumentasjon

- **README.md** - Komplett dokumentasjon
- **QUICKSTART.md** - Hurtig guide (5 min)
- **TROUBLESHOOTING.md** - Feilsøking
- **GITHUB_SETUP.md** - Detaljert GitHub oppsett
- **CONTRIBUTING.md** - Hvordan bidra

## Hjelp

Hvis du får problemer:

1. Les [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Sjekk [README.md](README.md)
3. Opprett issue på GitHub

## Lykke til! 🚀

Din IoT server vil snart være klar!

---

**Repository:** https://github.com/sverrekm/IOT-mannager

**Lisens:** MIT
