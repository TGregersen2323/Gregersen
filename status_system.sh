#!/bin/bash
# Gregersen Audio System - System Status Script

echo "================================================"
echo "Gregersen Multi-Room Audio System - Status"
echo "================================================"
echo ""

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

# Check service status
echo "Service Status:"
echo "==============="

check_service() {
    local service=$1
    local display_name=$2
    
    if systemctl is-active --quiet $service; then
        echo "✓ $display_name: Running"
    else
        echo "✗ $display_name: Stopped"
    fi
}

check_service "shairport-sync" "Shairport-sync"
check_service "camilladsp@front_left" "CamillaDSP Front Left"
check_service "camilladsp@front_right" "CamillaDSP Front Right"
check_service "camilladsp@back_left" "CamillaDSP Back Left"
check_service "camilladsp@back_right" "CamillaDSP Back Right"
check_service "snapserver" "Snapcast Server"

echo ""
echo "Named Pipes:"
echo "============"

check_pipe() {
    local pipe=$1
    if [ -p "$pipe" ]; then
        echo "✓ $pipe exists"
    else
        echo "✗ $pipe missing"
    fi
}

check_pipe "/tmp/shairport-sync-audio"
check_pipe "/tmp/snapfifo_front_left"
check_pipe "/tmp/snapfifo_front_right"
check_pipe "/tmp/snapfifo_back_left"
check_pipe "/tmp/snapfifo_back_right"

echo ""
echo "Network Endpoints:"
echo "=================="
echo "IP Address:          $IP_ADDR"
echo "AirPlay Name:        Gregersen Audio System"
echo "Snapcast Web UI:     http://$IP_ADDR:1780"
echo "Snapcast TCP:        $IP_ADDR:1705"
echo "CamillaDSP FL API:   $IP_ADDR:12340"
echo "CamillaDSP FR API:   $IP_ADDR:12341"
echo "CamillaDSP BL API:   $IP_ADDR:12342"
echo "CamillaDSP BR API:   $IP_ADDR:12343"

echo ""
echo "Quick Commands:"
echo "==============="
echo "Start system:        sudo ./start_system.sh"
echo "Stop system:         sudo ./stop_system.sh"
echo "View logs:           journalctl -u audio-system -f"
echo "Shairport logs:      journalctl -u shairport-sync -f"
echo "Snapserver logs:     journalctl -u snapserver -f"
echo "CamillaDSP logs:     journalctl -u camilladsp@front_left -f"
echo ""
