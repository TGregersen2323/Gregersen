#!/bin/bash
# Gregersen Audio System - Client Installation Script
# For Raspberry Pi clients

set -e

echo "================================================"
echo "Gregersen Multi-Room Audio System - Client"
echo "Installation Script for Raspberry Pi"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Get server IP from user
read -p "Enter the IP address of the Gregersen Audio Server: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo "Error: Server IP address is required"
    exit 1
fi

# Get zone selection
echo ""
echo "Available zones:"
echo "1) Front Left"
echo "2) Front Right"
echo "3) Back Left"
echo "4) Back Right"
read -p "Select zone number (1-4): " ZONE_NUMBER

case $ZONE_NUMBER in
    1) ZONE_NAME="Front Left"; INSTANCE=1 ;;
    2) ZONE_NAME="Front Right"; INSTANCE=2 ;;
    3) ZONE_NAME="Back Left"; INSTANCE=3 ;;
    4) ZONE_NAME="Back Right"; INSTANCE=4 ;;
    *)
        echo "Error: Invalid zone number"
        exit 1
        ;;
esac

echo ""
echo "Configuration:"
echo "  Server: $SERVER_IP"
echo "  Zone: $ZONE_NAME"
echo "  Instance: $INSTANCE"
echo ""
read -p "Continue with installation? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Update system
echo "[1/3] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Snapclient
echo "[2/3] Installing Snapcast client..."
SNAPCAST_VERSION="0.27.0"

# Detect architecture
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "armhf" ]; then
    SNAPCAST_DEB="snapclient_${SNAPCAST_VERSION}-1_armhf.deb"
elif [ "$ARCH" = "arm64" ]; then
    SNAPCAST_DEB="snapclient_${SNAPCAST_VERSION}-1_arm64.deb"
else
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

cd /tmp
wget -q https://github.com/badaix/snapcast/releases/download/v${SNAPCAST_VERSION}/${SNAPCAST_DEB} || {
    echo "Error: Could not download Snapclient"
    exit 1
}

dpkg -i ${SNAPCAST_DEB} || apt-get install -f -y
rm ${SNAPCAST_DEB}

# Install audio dependencies
echo "Installing audio dependencies..."
apt-get install -y alsa-utils

# Configure Snapclient
echo "[3/3] Configuring Snapclient..."
cat > /etc/default/snapclient << EOF
# Snapclient configuration for Gregersen Audio System
# Zone: $ZONE_NAME

# Server connection
SNAPCLIENT_OPTS="--host $SERVER_IP --instance $INSTANCE"
EOF

# Enable and start service
echo "Enabling Snapclient service..."
systemctl daemon-reload
systemctl enable snapclient
systemctl restart snapclient

# Wait for service to start
sleep 2

# Check service status
if systemctl is-active --quiet snapclient; then
    echo ""
    echo "================================================"
    echo "Installation Complete!"
    echo "================================================"
    echo ""
    echo "Zone: $ZONE_NAME"
    echo "Server: $SERVER_IP"
    echo "Status: $(systemctl is-active snapclient)"
    echo ""
    echo "Next steps:"
    echo "1. Access Snapcast web UI: http://$SERVER_IP:1780"
    echo "2. Assign this client to the '$ZONE_NAME' stream"
    echo "3. Adjust volume and synchronization as needed"
    echo ""
    echo "To check client status: systemctl status snapclient"
    echo "To view client logs: journalctl -u snapclient -f"
    echo ""
else
    echo ""
    echo "Warning: Snapclient service failed to start"
    echo "Check logs with: journalctl -u snapclient -n 50"
    echo ""
    exit 1
fi
