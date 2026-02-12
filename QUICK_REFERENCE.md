# Gregersen Audio System - Quick Reference

## 🚀 Quick Start

### Server Setup (One-time)
```bash
git clone https://github.com/TGregersen2323/Gregersen.git
cd Gregersen
sudo ./install_server.sh
sudo ./start_system.sh
sudo ./setup_web.sh
sudo systemctl enable audio-system
```

### Client Setup (On each Raspberry Pi)
```bash
wget https://raw.githubusercontent.com/TGregersen2323/Gregersen/main/install_client.sh
chmod +x install_client.sh
sudo ./install_client.sh
```

## 🎛️ Daily Use

### Start System
```bash
sudo ./start_system.sh
```

### Stop System
```bash
sudo ./stop_system.sh
```

### Check Status
```bash
./status_system.sh
```

## 🌐 Web Interfaces

- **Snapcast Control:** http://[SERVER_IP]:1780
- **CamillaDSP EQ:** http://[SERVER_IP]:5000

## 📱 AirPlay

1. Open Control Center on iOS/Mac
2. Select "Gregersen Audio System"
3. Play music

## 🔧 Common Commands

### View Logs
```bash
# All services
journalctl -u audio-system -f

# Specific services
journalctl -u shairport-sync -f
journalctl -u snapserver -f
journalctl -u camilladsp@front_left -f
```

### Restart Services
```bash
sudo systemctl restart audio-system
sudo systemctl restart shairport-sync
sudo systemctl restart snapserver
sudo systemctl restart camilladsp@front_left
```

### Manual Service Control
```bash
# Start individual service
sudo systemctl start shairport-sync

# Stop individual service
sudo systemctl stop snapserver

# Enable auto-start
sudo systemctl enable audio-system

# Disable auto-start
sudo systemctl disable audio-system
```

## 🐛 Troubleshooting Quick Fixes

### No Sound
```bash
# Restart everything
sudo ./stop_system.sh
sudo ./start_system.sh

# Check pipes exist
ls -la /tmp/shairport-sync-audio /tmp/snapfifo_*

# Recreate pipes if missing
sudo mkfifo /tmp/shairport-sync-audio
sudo mkfifo /tmp/snapfifo_front_left
sudo mkfifo /tmp/snapfifo_front_right
sudo mkfifo /tmp/snapfifo_back_left
sudo mkfifo /tmp/snapfifo_back_right
sudo chmod 666 /tmp/shairport-sync-audio /tmp/snapfifo_*
```

### AirPlay Not Showing
```bash
# Restart Shairport-sync
sudo systemctl restart shairport-sync

# Check Avahi
sudo systemctl status avahi-daemon
```

### Client Not Connected
```bash
# On client
sudo systemctl restart snapclient
journalctl -u snapclient -n 50
```

### Web UI Not Accessible
```bash
# Check services
sudo systemctl status snapserver
sudo systemctl status camilladsp-gui

# Restart web services
sudo systemctl restart snapserver
sudo systemctl restart camilladsp-gui
```

## 📊 Performance Tuning

### Low Latency Mode
Edit `/etc/camilladsp/camilladsp_front_left.yml`:
```yaml
devices:
  chunksize: 512  # Lower = less latency, more CPU
```

### High Efficiency Mode
Edit `/etc/camilladsp/camilladsp_front_left.yml`:
```yaml
devices:
  chunksize: 2048  # Higher = more latency, less CPU
```

## 🔒 Security Notes

- Change default passwords if added
- Use firewall for external access
- Keep system updated: `sudo apt update && sudo apt upgrade`

## 📱 Mobile Apps

### Snapcast Control
- **iOS:** Snapcast Control (App Store)
- **Android:** Snapdroid (Play Store)

### AirPlay Sources
- Apple Music
- Spotify
- YouTube Music
- Any iOS/Mac audio app

## 💾 Backup Configuration

```bash
# Backup all configs
sudo tar -czf gregersen-backup-$(date +%Y%m%d).tar.gz \
  /etc/shairport-sync.conf \
  /etc/snapserver.conf \
  /etc/camilladsp/ \
  /etc/systemd/system/camilladsp@.service \
  /etc/systemd/system/audio-system.service

# Restore
sudo tar -xzf gregersen-backup-20260212.tar.gz -C /
sudo systemctl daemon-reload
```

## 🔄 Update System

```bash
cd ~/Gregersen
git pull
sudo ./install_server.sh
sudo systemctl daemon-reload
sudo ./start_system.sh
```

## 📞 Get Help

- Check logs: `journalctl -xe`
- See full README: `less README.md`
- GitHub Issues: https://github.com/TGregersen2323/Gregersen/issues

---

**Pro Tip:** Bookmark the web interfaces on your phone for easy access!
