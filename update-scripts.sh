#!/bin/bash

# Script for å oppdatere IoT Manager installasjonsscript fra git

set -e

REPO_URL="https://github.com/sverrekm/IOT-mannager.git"
TEMP_DIR="/tmp/iotmanager-update"

echo "=== IoT Manager Script Updater ==="
echo

# Sjekk om vi er i riktig mappe
if [ ! -f "install.sh" ]; then
    echo "Feil: Kjør dette scriptet fra IOTmanager mappen"
    exit 1
fi

echo "Dette vil oppdatere installasjonsscriptene fra git."
echo "Dine konfigurasjonsfiler og data påvirkes IKKE."
echo

read -p "Fortsette? (J/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]] && [[ ! -z $REPLY ]]; then
    exit 0
fi

# Klon til temp mappe
echo "Laster ned siste versjon..."
rm -rf "$TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR"

# Kopier scripts
echo "Oppdaterer scripts..."
cp "$TEMP_DIR/install.sh" ./
cp "$TEMP_DIR/uninstall.sh" ./
cp -r "$TEMP_DIR/scripts" ./
cp -r "$TEMP_DIR/configs" ./

# Gjør scripts kjørbare
chmod +x install.sh
chmod +x uninstall.sh
chmod +x scripts/*.sh

# Rens opp
rm -rf "$TEMP_DIR"

echo
echo "✓ Scripts oppdatert!"
echo
echo "MERK: Dette oppdaterer kun installasjonsscriptene."
echo "For å oppdatere Docker images, kjør:"
echo "  cd ~/iot-manager"
echo "  docker compose pull"
echo "  docker compose up -d"
