#!/bin/bash
# Gregersen Audio System - Web Interface Setup Script

set -e

echo "================================================"
echo "Gregersen Audio System - Web Interface Setup"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Check if pyCamillaDSP is installed
if ! python3 -c "import pycamilladsp" 2>/dev/null; then
    echo "Installing pyCamillaDSP..."
    python3 -m pip install pycamilladsp pycamilladsp-plot
fi

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

# Create systemd service for CamillaDSP GUI
echo "Creating systemd service for CamillaDSP GUI..."

cat > /etc/systemd/system/camilladsp-gui.service << 'EOF'
[Unit]
Description=CamillaDSP Web GUI
Documentation=https://github.com/HEnquist/pycamilladsp
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/camilladsp-gui
ExecStart=/usr/bin/python3 -m pycamilladsp_plot -p 5000 -a 0.0.0.0
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create working directory
mkdir -p /opt/camilladsp-gui

# Create configuration file for GUI
cat > /opt/camilladsp-gui/config.yml << EOF
# CamillaDSP GUI Configuration
# Manages all 4 zones

backends:
  front_left:
    host: 127.0.0.1
    port: 12340
    name: "Front Left"
    config_file: /etc/camilladsp/camilladsp_front_left.yml
  
  front_right:
    host: 127.0.0.1
    port: 12341
    name: "Front Right"
    config_file: /etc/camilladsp/camilladsp_front_right.yml
  
  back_left:
    host: 127.0.0.1
    port: 12342
    name: "Back Left"
    config_file: /etc/camilladsp/camilladsp_back_left.yml
  
  back_right:
    host: 127.0.0.1
    port: 12343
    name: "Back Right"
    config_file: /etc/camilladsp/camilladsp_back_right.yml
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start service
echo "Starting CamillaDSP GUI..."
systemctl enable camilladsp-gui
systemctl restart camilladsp-gui

# Wait for service to start
sleep 3

# Check service status
if systemctl is-active --quiet camilladsp-gui; then
    echo ""
    echo "================================================"
    echo "CamillaDSP Web GUI Setup Complete!"
    echo "================================================"
    echo ""
    echo "Access the GUI at: http://$IP_ADDR:5000"
    echo ""
    echo "The GUI provides:"
    echo "  • Real-time EQ adjustment for all 4 zones"
    echo "  • Volume control per zone"
    echo "  • Audio level monitoring"
    echo "  • Filter visualization"
    echo ""
    echo "Service management:"
    echo "  Status:  systemctl status camilladsp-gui"
    echo "  Stop:    sudo systemctl stop camilladsp-gui"
    echo "  Restart: sudo systemctl restart camilladsp-gui"
    echo "  Logs:    journalctl -u camilladsp-gui -f"
    echo ""
else
    echo ""
    echo "Warning: CamillaDSP GUI service failed to start"
    echo "Check logs with: journalctl -u camilladsp-gui -n 50"
    echo ""
    
    # Try to run it manually for debugging
    echo "Attempting to run GUI manually for testing..."
    echo "Access it at: http://$IP_ADDR:5000"
    echo "Press Ctrl+C to stop"
    echo ""
    python3 -m pycamilladsp_plot -p 5000 -a 0.0.0.0
fi
