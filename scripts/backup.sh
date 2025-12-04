#!/bin/bash

# Backup script for IoT Manager Server
# Tar backup av alle konfigurasjonsfiler og data

set -e

INSTALL_DIR="$HOME/iot-manager"
BACKUP_DIR="$HOME/iot-manager-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="iot-manager-backup-$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo "=== IoT Manager Backup ==="
echo

# Opprett backup mappe
mkdir -p "$BACKUP_DIR"

echo "Stopper tjenester..."
cd "$INSTALL_DIR"
docker compose stop

echo "Oppretter backup: $BACKUP_NAME"

# Opprett backup
mkdir -p "$BACKUP_PATH"

# Backup Home Assistant
if [ -d "$INSTALL_DIR/homeassistant" ]; then
    echo "  - Backup Home Assistant..."
    cp -r "$INSTALL_DIR/homeassistant" "$BACKUP_PATH/"
fi

# Backup Mosquitto
if [ -d "$INSTALL_DIR/mosquitto" ]; then
    echo "  - Backup Mosquitto..."
    cp -r "$INSTALL_DIR/mosquitto" "$BACKUP_PATH/"
fi

# Backup Node-RED
if [ -d "$INSTALL_DIR/nodered" ]; then
    echo "  - Backup Node-RED..."
    cp -r "$INSTALL_DIR/nodered" "$BACKUP_PATH/"
fi

# Backup Zigbee2MQTT
if [ -d "$INSTALL_DIR/zigbee2mqtt" ]; then
    echo "  - Backup Zigbee2MQTT..."
    cp -r "$INSTALL_DIR/zigbee2mqtt" "$BACKUP_PATH/"
fi

# Backup docker-compose.yml
if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    echo "  - Backup docker-compose.yml..."
    cp "$INSTALL_DIR/docker-compose.yml" "$BACKUP_PATH/"
fi

# Opprett tar.gz arkiv
echo "Komprimerer backup..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

# Start tjenester igjen
echo "Starter tjenester..."
cd "$INSTALL_DIR"
docker compose start

echo
echo "✓ Backup fullført!"
echo "  Plassering: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "  Størrelse: $(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)"
echo

# Valgfritt: Slett gamle backups (holder 7 siste)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 7 ]; then
    echo "Sletter gamle backups (holder 7 siste)..."
    cd "$BACKUP_DIR"
    ls -t *.tar.gz | tail -n +8 | xargs rm -f
fi

echo "For å gjenopprette backup:"
echo "  1. Stopp tjenester: cd ~/iot-manager && docker compose down"
echo "  2. Pakk ut backup: tar -xzf $BACKUP_DIR/$BACKUP_NAME.tar.gz -C ~/"
echo "  3. Start tjenester: cd ~/iot-manager && docker compose up -d"
