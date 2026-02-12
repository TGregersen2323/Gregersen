#!/bin/bash
# Gregersen Audio System - Start System Script

set -e

echo "================================================"
echo "Starting Gregersen Multi-Room Audio System"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Create named pipes if they don't exist
echo "[1/5] Creating named pipes..."
for pipe in /tmp/shairport-sync-audio /tmp/snapfifo_front_left /tmp/snapfifo_front_right /tmp/snapfifo_back_left /tmp/snapfifo_back_right; do
    if [ ! -p "$pipe" ]; then
        echo "  Creating pipe: $pipe"
        mkfifo "$pipe"
    fi
    chmod 666 "$pipe"
done

# Start Shairport-sync
echo "[2/5] Starting Shairport-sync (AirPlay receiver)..."
systemctl start shairport-sync
sleep 2

if ! systemctl is-active --quiet shairport-sync; then
    echo "Error: Shairport-sync failed to start"
    echo "Check logs with: journalctl -u shairport-sync -n 50"
    exit 1
fi
echo "  Shairport-sync is running"

# Start CamillaDSP instances
echo "[3/5] Starting CamillaDSP instances..."
for zone in front_left front_right back_left back_right; do
    echo "  Starting CamillaDSP for $zone..."
    systemctl start camilladsp@$zone
    sleep 1
    
    if ! systemctl is-active --quiet camilladsp@$zone; then
        echo "Warning: CamillaDSP $zone failed to start"
    fi
done
sleep 2

# Start Snapcast server
echo "[4/5] Starting Snapcast server..."
systemctl start snapserver
sleep 2

if ! systemctl is-active --quiet snapserver; then
    echo "Error: Snapserver failed to start"
    echo "Check logs with: journalctl -u snapserver -n 50"
    exit 1
fi
echo "  Snapserver is running"

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

echo "[5/5] System status check..."
echo ""
echo "================================================"
echo "Gregersen Audio System Started Successfully!"
echo "================================================"
echo ""
echo "Service Status:"
echo "  Shairport-sync:      $(systemctl is-active shairport-sync)"
echo "  CamillaDSP FL:       $(systemctl is-active camilladsp@front_left)"
echo "  CamillaDSP FR:       $(systemctl is-active camilladsp@front_right)"
echo "  CamillaDSP BL:       $(systemctl is-active camilladsp@back_left)"
echo "  CamillaDSP BR:       $(systemctl is-active camilladsp@back_right)"
echo "  Snapserver:          $(systemctl is-active snapserver)"
echo ""
echo "Network Endpoints:"
echo "  AirPlay Name:        Gregersen Audio System"
echo "  Snapcast Web UI:     http://$IP_ADDR:1780"
echo "  Snapcast TCP Port:   1705"
echo ""
echo "To start CamillaDSP GUI, run: ./setup_web.sh"
echo "To stop system: ./stop_system.sh"
echo "To check status: ./status_system.sh"
echo ""
