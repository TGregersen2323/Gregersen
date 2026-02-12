#!/bin/bash
# Gregersen Audio System - Stop System Script

set -e

echo "================================================"
echo "Stopping Gregersen Multi-Room Audio System"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Stop services in reverse order
echo "[1/4] Stopping Snapcast server..."
systemctl stop snapserver || true

echo "[2/4] Stopping CamillaDSP instances..."
for zone in front_left front_right back_left back_right; do
    echo "  Stopping CamillaDSP for $zone..."
    systemctl stop camilladsp@$zone || true
done

echo "[3/4] Stopping Shairport-sync..."
systemctl stop shairport-sync || true

echo "[4/4] Cleaning up..."
# Optional: Remove named pipes (commented out to preserve them)
# for pipe in /tmp/shairport-sync-audio /tmp/snapfifo_front_left /tmp/snapfifo_front_right /tmp/snapfifo_back_left /tmp/snapfifo_back_right; do
#     if [ -p "$pipe" ]; then
#         rm "$pipe"
#     fi
# done

echo ""
echo "================================================"
echo "All services stopped"
echo "================================================"
echo ""
