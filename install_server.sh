#!/bin/bash
# Gregersen Audio System - Server Installation Script
# For Raspberry Pi 5 with DietPi

set -e

echo "================================================"
echo "Gregersen Multi-Room Audio System - Server"
echo "Installation Script for Raspberry Pi 5 (DietPi)"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Update system
echo "[1/8] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "[2/8] Installing dependencies..."
apt-get install -y \
    build-essential \
    git \
    autoconf \
    automake \
    libtool \
    libpopt-dev \
    libconfig-dev \
    libasound2-dev \
    libsoxr-dev \
    libavahi-client-dev \
    libssl-dev \
    libmbedtls-dev \
    libsndfile1-dev \
    libsamplerate0-dev \
    libavformat-dev \
    libavcodec-dev \
    libavutil-dev \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    alsa-utils

# Install Snapcast Server
echo "[3/8] Installing Snapcast server..."
SNAPCAST_VERSION="0.27.0"
SNAPCAST_DEB="snapserver_${SNAPCAST_VERSION}-1_arm64.deb"

cd /tmp
wget -q https://github.com/badaix/snapcast/releases/download/v${SNAPCAST_VERSION}/${SNAPCAST_DEB} || {
    echo "Warning: Could not download Snapcast. Please install manually."
}

if [ -f "${SNAPCAST_DEB}" ]; then
    dpkg -i ${SNAPCAST_DEB} || apt-get install -f -y
    rm ${SNAPCAST_DEB}
fi

# Install Shairport-sync
echo "[4/8] Installing Shairport-sync..."
apt-get install -y shairport-sync || {
    echo "Installing Shairport-sync from source..."
    cd /tmp
    git clone https://github.com/mikebrady/shairport-sync.git
    cd shairport-sync
    autoreconf -fi
    ./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-pipe
    make
    make install
    cd ..
    rm -rf shairport-sync
}

# Install CamillaDSP
echo "[5/8] Installing CamillaDSP..."
CAMILLADSP_VERSION="2.0.3"
CAMILLADSP_URL="https://github.com/HEnquist/camilladsp/releases/download/v${CAMILLADSP_VERSION}/camilladsp-linux-aarch64.tar.gz"

cd /tmp
wget -q ${CAMILLADSP_URL} -O camilladsp.tar.gz || {
    echo "Error: Could not download CamillaDSP"
    exit 1
}

tar -xzf camilladsp.tar.gz
mv camilladsp /usr/local/bin/
chmod +x /usr/local/bin/camilladsp
rm camilladsp.tar.gz

# Verify CamillaDSP installation
/usr/local/bin/camilladsp --version

# Install CamillaDSP GUI
echo "[6/8] Installing CamillaDSP GUI (pyCamillaDSP)..."
python3 -m pip install --upgrade pip
python3 -m pip install camilladsp-plot pycamilladsp pycamilladsp-plot

# Create configuration directories
echo "[7/8] Setting up configuration directories..."
mkdir -p /etc/camilladsp
mkdir -p /etc/snapserver
mkdir -p /var/log/audio-system

# Copy configuration files
echo "[8/8] Copying configuration files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy Shairport-sync config
if [ -f "${SCRIPT_DIR}/config/shairport-sync.conf" ]; then
    cp "${SCRIPT_DIR}/config/shairport-sync.conf" /etc/shairport-sync.conf
    echo "Shairport-sync config installed."
fi

# Copy CamillaDSP configs
for zone in front_left front_right back_left back_right; do
    if [ -f "${SCRIPT_DIR}/config/camilladsp_${zone}.yml" ]; then
        cp "${SCRIPT_DIR}/config/camilladsp_${zone}.yml" /etc/camilladsp/
        echo "CamillaDSP config for ${zone} installed."
    fi
done

# Copy Snapserver config
if [ -f "${SCRIPT_DIR}/config/snapserver.conf" ]; then
    cp "${SCRIPT_DIR}/config/snapserver.conf" /etc/snapserver.conf
    echo "Snapserver config installed."
fi

# Copy systemd service files
if [ -f "${SCRIPT_DIR}/systemd/camilladsp@.service" ]; then
    cp "${SCRIPT_DIR}/systemd/camilladsp@.service" /etc/systemd/system/
    echo "CamillaDSP systemd service installed."
fi

if [ -f "${SCRIPT_DIR}/systemd/audio-system.service" ]; then
    cp "${SCRIPT_DIR}/systemd/audio-system.service" /etc/systemd/system/
    echo "Audio system service installed."
fi

# Reload systemd
systemctl daemon-reload

# Create named pipes
echo "Creating named pipes..."
for pipe in /tmp/shairport-sync-audio /tmp/snapfifo_front_left /tmp/snapfifo_front_right /tmp/snapfifo_back_left /tmp/snapfifo_back_right; do
    [ -p "$pipe" ] || mkfifo "$pipe"
    chmod 666 "$pipe"
done

echo ""
echo "================================================"
echo "Installation Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Review configuration files in /etc/"
echo "2. Start the system: sudo ./start_system.sh"
echo "3. Enable auto-start: sudo systemctl enable audio-system"
echo "4. Access Snapcast web UI: http://$(hostname -I | awk '{print $1}'):1780"
echo "5. Configure CamillaDSP: Run ./setup_web.sh"
echo ""
echo "To check system status: ./status_system.sh"
echo ""
