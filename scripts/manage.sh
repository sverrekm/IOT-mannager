#!/bin/bash

# IoT Manager - Hurtig administrasjonsscript

INSTALL_DIR="$HOME/iot-manager"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "Feil: IoT Manager er ikke installert i $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

case "$1" in
    start)
        echo "Starter alle tjenester..."
        docker compose start
        echo "✓ Tjenester startet"
        ;;
    stop)
        echo "Stopper alle tjenester..."
        docker compose stop
        echo "✓ Tjenester stoppet"
        ;;
    restart)
        echo "Restarter alle tjenester..."
        docker compose restart
        echo "✓ Tjenester restartet"
        ;;
    down)
        echo "Stopper og fjerner alle containere..."
        docker compose down
        echo "✓ Containere fjernet"
        ;;
    up)
        echo "Starter alle tjenester (oppretter containere om nødvendig)..."
        docker compose up -d
        echo "✓ Tjenester startet"
        ;;
    logs)
        if [ -z "$2" ]; then
            docker compose logs -f
        else
            docker compose logs -f "$2"
        fi
        ;;
    status)
        docker compose ps
        ;;
    update)
        echo "Oppdaterer alle Docker images..."
        docker compose pull
        echo "Restarter tjenester med nye images..."
        docker compose up -d
        echo "✓ Oppdatering fullført"
        ;;
    *)
        echo "IoT Manager - Administrasjonsscript"
        echo
        echo "Bruk: $0 {start|stop|restart|down|up|logs|status|update}"
        echo
        echo "Kommandoer:"
        echo "  start    - Start alle stoppede tjenester"
        echo "  stop     - Stopp alle tjenester (data bevares)"
        echo "  restart  - Restart alle tjenester"
        echo "  down     - Stopp og fjern alle containere"
        echo "  up       - Start alle tjenester (opprett containere)"
        echo "  logs     - Vis logger (logs [tjeneste] for spesifikk tjeneste)"
        echo "  status   - Vis status for alle tjenester"
        echo "  update   - Oppdater alle Docker images"
        echo
        echo "Eksempler:"
        echo "  $0 logs homeassistant   # Vis Home Assistant logger"
        echo "  $0 restart              # Restart alle tjenester"
        echo "  $0 status               # Se status"
        exit 1
        ;;
esac
