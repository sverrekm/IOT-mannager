#!/bin/bash

# Quick fix for Docker permission issue
# Kjør dette scriptet etter install.sh hvis du får permission denied

echo "=== Docker Permission Fix ==="
echo

# Metode 1: Aktiver docker gruppe i current session
echo "Aktiverer Docker gruppe i denne sesjonen..."
newgrp docker <<EOF
cd ~/iot-manager
docker compose up -d
echo
echo "✓ Tjenester startet!"
docker compose ps
EOF
