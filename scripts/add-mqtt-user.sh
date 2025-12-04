#!/bin/bash

# Script for å legge til MQTT brukere med passord
# Kjør dette etter at Mosquitto er installert

set -e

MOSQUITTO_DIR="$HOME/iot-manager/mosquitto/config"
PASSWD_FILE="$MOSQUITTO_DIR/passwd"

if [ ! -d "$MOSQUITTO_DIR" ]; then
    echo "Feil: Mosquitto config mappe finnes ikke: $MOSQUITTO_DIR"
    exit 1
fi

echo "=== MQTT Brukeradministrasjon ==="
echo

read -p "Brukernavn: " USERNAME

if [ -z "$USERNAME" ]; then
    echo "Feil: Brukernavn kan ikke være tomt"
    exit 1
fi

# Sjekk om dette er første bruker
if [ -f "$PASSWD_FILE" ]; then
    echo "Legger til bruker i eksisterende passordfil..."
    docker run -it --rm -v "$MOSQUITTO_DIR:/mosquitto/config" eclipse-mosquitto mosquitto_passwd /mosquitto/config/passwd "$USERNAME"
else
    echo "Oppretter ny passordfil med første bruker..."
    docker run -it --rm -v "$MOSQUITTO_DIR:/mosquitto/config" eclipse-mosquitto mosquitto_passwd -c /mosquitto/config/passwd "$USERNAME"
    echo
    echo "VIKTIG: Husk å endre mosquitto.conf til å bruke autentisering:"
    echo "  1. Åpne: $MOSQUITTO_DIR/mosquitto.conf"
    echo "  2. Endre 'allow_anonymous true' til 'allow_anonymous false'"
    echo "  3. Uncomment 'password_file /mosquitto/config/passwd'"
    echo "  4. Restart Mosquitto: cd ~/iot-manager && docker compose restart mosquitto"
fi

echo
echo "Bruker '$USERNAME' lagt til!"
