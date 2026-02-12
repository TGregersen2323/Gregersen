# Gregersen Multi-Room Audio System

Et komplet multi-room audio distribution system til Raspberry Pi 5 med DietPi, der distribuerer lyd til 4 separate zoner med individuel DSP processing og EQ kontrol.

## 📋 Indholdsfortegnelse

- [Systemarkitektur](#systemarkitektur)
- [Hardware Krav](#hardware-krav)
- [Funktioner](#funktioner)
- [Installation](#installation)
  - [Server Installation](#server-installation)
  - [Client Installation](#client-installation)
- [Konfiguration](#konfiguration)
- [Brug](#brug)
- [Netværksopsætning](#netværksopsætning)
- [Troubleshooting](#troubleshooting)
- [Docker Alternative](#docker-alternative)
- [Avanceret Konfiguration](#avanceret-konfiguration)

## 🏗️ Systemarkitektur

```
┌─────────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI 5 SERVER                         │
│                                                                   │
│  ┌──────────────┐                                                │
│  │  AirPlay     │  Modtager lyd fra iPhone/iPad/Mac             │
│  │ (Shairport)  │────────────────┐                              │
│  └──────────────┘                │                              │
│                                   ↓                              │
│                         /tmp/shairport-sync-audio               │
│                                   │                              │
│         ┌────────────┬────────────┼────────────┬────────────┐   │
│         ↓            ↓            ↓            ↓            │   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │CamillaDSP│ │CamillaDSP│ │CamillaDSP│ │CamillaDSP│       │   │
│  │Front Left│ │Front Rght│ │Back Left │ │Back Right│       │   │
│  │  + EQ    │ │  + EQ    │ │  + EQ    │ │  + EQ    │       │   │
│  └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘       │   │
│        │            │            │            │            │   │
│        ↓            ↓            ↓            ↓            │   │
│  ┌──────────────────────────────────────────────────────┐  │   │
│  │            Snapcast Server                           │  │   │
│  │       (Multi-room Distribution)                      │  │   │
│  └────┬─────────┬─────────┬─────────┬───────────────────┘  │   │
└───────┼─────────┼─────────┼─────────┼──────────────────────┘   │
        │         │         │         │                          │
        ↓         ↓         ↓         ↓                          │
   ┌────────┐┌────────┐┌────────┐┌────────┐                     │
   │Client 1││Client 2││Client 3││Client 4│                     │
   │  FL    ││  FR    ││  BL    ││  BR    │                     │
   └────────┘└────────┘└────────┘└────────┘                     │
```

### Audio Pipeline

```
AirPlay → Shairport-sync → /tmp/shairport-sync-audio
    ↓
    ├→ CamillaDSP (Front Left)  → /tmp/snapfifo_front_left  → Snapserver → Client 1
    ├→ CamillaDSP (Front Right) → /tmp/snapfifo_front_right → Snapserver → Client 2
    ├→ CamillaDSP (Back Left)   → /tmp/snapfifo_back_left   → Snapserver → Client 3
    └→ CamillaDSP (Back Right)  → /tmp/snapfifo_back_right  → Snapserver → Client 4
```

### Audio Format

- **Sample rate:** 44100 Hz
- **Format:** S16LE (16-bit signed little-endian)
- **Channels:** 2 (stereo)
- **Latency:** <100ms typisk

## 💻 Hardware Krav

### Server (Raspberry Pi 5)
- Raspberry Pi 5 (4GB eller 8GB RAM anbefales)
- DietPi OS (eller anden Debian-baseret distribution)
- MicroSD kort (32GB minimum)
- Strømforsyning (officiel 27W USB-C adapter anbefales)
- Ethernet forbindelse (anbefales for bedst stabilitet)

### Clients (4x Raspberry Pi)
- Raspberry Pi 3, 4, eller 5
- Raspbian/DietPi OS
- MicroSD kort (16GB minimum per client)
- Strømforsyning
- Audio output (3.5mm jack, HDMI, eller USB DAC)
- Netværksforbindelse (WiFi eller Ethernet)

### Netværk
- Gigabit Ethernet switch (anbefales)
- Router med stabil WiFi (hvis ikke Ethernet bruges)
- Statiske IP addresser eller DHCP reservationer anbefales

## ✨ Funktioner

- **🎵 AirPlay Support:** Stream lyd fra enhver Apple enhed
- **🎚️ Individuel DSP:** 4 separate CamillaDSP instanser med fuld EQ kontrol
- **🔊 Multi-room Distribution:** Synkroniseret afspilning i op til 4 zoner
- **🌐 Web Interfaces:** 
  - Snapcast web UI til zone management
  - CamillaDSP GUI til real-time EQ justering
- **⚙️ Avanceret EQ:** 5-bands parametrisk EQ per zone
  - Low shelf (100 Hz)
  - 3x Peaking (250Hz, 1kHz, 4kHz)
  - High shelf (8kHz)
- **🔄 Auto-start:** Systemd services starter automatisk ved boot
- **📊 Real-time Monitoring:** Live audio levels og status
- **🐳 Docker Support:** Alternativ container-baseret deployment

## 🚀 Installation

### Server Installation

1. **Forbered Raspberry Pi 5**
   ```bash
   # Download og installer DietPi
   # https://dietpi.com/#download
   
   # Efter første boot, opdater systemet
   sudo dietpi-update
   ```

2. **Clone Repository**
   ```bash
   cd ~
   git clone https://github.com/TGregersen2323/Gregersen.git
   cd Gregersen
   ```

3. **Kør Installation Script**
   ```bash
   sudo chmod +x install_server.sh
   sudo ./install_server.sh
   ```

   Dette script vil:
   - Opdatere systemet
   - Installere Snapcast server
   - Installere Shairport-sync
   - Downloade og installere CamillaDSP
   - Installere CamillaDSP GUI
   - Kopiere konfigurationsfiler
   - Opsætte systemd services
   - Oprette named pipes

4. **Start Systemet**
   ```bash
   sudo chmod +x start_system.sh stop_system.sh status_system.sh setup_web.sh
   sudo ./start_system.sh
   ```

5. **Opsæt Web Interface**
   ```bash
   sudo ./setup_web.sh
   ```

6. **Aktiver Auto-start ved Boot**
   ```bash
   sudo systemctl enable audio-system
   ```

### Client Installation

**På hver af de 4 Raspberry Pi clients:**

1. **Forbered Client**
   ```bash
   # Installer Raspbian eller DietPi
   # Opdater systemet
   sudo apt-get update && sudo apt-get upgrade -y
   ```

2. **Download Installation Script**
   ```bash
   cd ~
   wget https://raw.githubusercontent.com/TGregersen2323/Gregersen/main/install_client.sh
   chmod +x install_client.sh
   ```

3. **Kør Installation**
   ```bash
   sudo ./install_client.sh
   ```

   Du vil blive spurgt om:
   - Server IP adresse
   - Zone valg (Front Left, Front Right, Back Left, Back Right)

4. **Verificer Installation**
   ```bash
   systemctl status snapclient
   ```

## ⚙️ Konfiguration

### Zone Assignment via Snapcast Web UI

1. Åbn browser og naviger til: `http://[SERVER_IP]:1780`
2. Du vil se alle 4 clients og 4 streams
3. For hver client:
   - Klik på client navnet
   - Vælg det korrekte stream (Front Left, Front Right, etc.)
   - Juster volume og latency efter behov

### EQ Justering via CamillaDSP GUI

1. Åbn browser og naviger til: `http://[SERVER_IP]:5000`
2. Vælg zone i dropdown menuen
3. Juster EQ bands:
   - Low shelf (100 Hz): Basser
   - Peak 250 Hz: Lav-mellemtone
   - Peak 1 kHz: Mellemtone/vokal
   - Peak 4 kHz: Høj-mellemtone/klarhed
   - High shelf (8 kHz): Diskant/brillians
4. Juster volume per zone
5. Se real-time audio levels

### Manuel Konfiguration

Alle konfigurationsfiler findes i `/etc/`:

- **Shairport-sync:** `/etc/shairport-sync.conf`
- **Snapserver:** `/etc/snapserver.conf`
- **CamillaDSP:** `/etc/camilladsp/camilladsp_[zone].yml`

Efter ændringer, genstart services:
```bash
sudo systemctl restart shairport-sync
sudo systemctl restart camilladsp@front_left
sudo systemctl restart snapserver
```

## 📱 Brug

### Afspil Musik via AirPlay

1. På din iPhone/iPad/Mac, åbn Control Center
2. Tryk på AirPlay ikonet
3. Vælg "Gregersen Audio System"
4. Afspil musik fra din foretrukne app

Musikken vil nu blive distribueret til alle 4 zoner med individuel DSP processing!

### Management Kommandoer

```bash
# Start systemet
sudo ./start_system.sh

# Stop systemet
sudo ./stop_system.sh

# Tjek status
./status_system.sh

# Se logs
journalctl -u audio-system -f
journalctl -u shairport-sync -f
journalctl -u snapserver -f
journalctl -u camilladsp@front_left -f
```

## 🌐 Netværksopsætning

### Anbefalet Netværkskonfiguration

1. **Statisk IP til Server**
   ```bash
   # På DietPi
   sudo dietpi-config
   # Network Options: Adapters → Ethernet → Static IP
   ```

2. **Port Forwarding (hvis nødvendigt)**
   - Snapcast Web: 1780
   - Snapcast TCP: 1704-1705
   - CamillaDSP API: 12340-12343
   - CamillaDSP GUI: 5000

3. **Firewall Regler**
   ```bash
   # Tillad Snapcast og CamillaDSP
   sudo ufw allow 1704:1705/tcp
   sudo ufw allow 1780/tcp
   sudo ufw allow 12340:12343/tcp
   sudo ufw allow 5000/tcp
   ```

### mDNS/Avahi (Automatisk Discovery)

Shairport-sync bruger Avahi til AirPlay discovery. Dette virker automatisk på de fleste netværk.

## 🔧 Troubleshooting

### Systemet Starter Ikke

```bash
# Tjek service status
sudo systemctl status audio-system
sudo systemctl status shairport-sync
sudo systemctl status snapserver

# Se detaljerede logs
journalctl -xe -u audio-system
```

### Ingen Lyd på Clients

1. **Tjek client forbindelse:**
   ```bash
   # På client
   systemctl status snapclient
   journalctl -u snapclient -n 50
   ```

2. **Verificer zone assignment:**
   - Åbn Snapcast Web UI
   - Tjek at client er forbundet til korrekt stream

3. **Test audio output:**
   ```bash
   # På client
   speaker-test -t wav -c 2
   ```

### CamillaDSP Fejler

```bash
# Tjek at pipes eksisterer
ls -la /tmp/shairport-sync-audio
ls -la /tmp/snapfifo_*

# Genopret pipes
sudo ./start_system.sh

# Se CamillaDSP logs
journalctl -u camilladsp@front_left -f
```

### AirPlay Virker Ikke

1. **Verificer Shairport-sync:**
   ```bash
   systemctl status shairport-sync
   journalctl -u shairport-sync -n 50
   ```

2. **Tjek Avahi/mDNS:**
   ```bash
   sudo systemctl status avahi-daemon
   avahi-browse -a
   ```

3. **Restart Shairport-sync:**
   ```bash
   sudo systemctl restart shairport-sync
   ```

### Høj Latency/Audio Dropouts

1. **Tjek netværk:**
   ```bash
   ping [CLIENT_IP]
   iperf3 -s  # På server
   iperf3 -c [SERVER_IP]  # På client
   ```

2. **Juster buffer størrelse:**
   - Rediger `/etc/snapserver.conf`
   - Øg buffer til 500ms eller mere

3. **Brug Ethernet i stedet for WiFi**

### Web Interfaces Ikke Tilgængelige

```bash
# Tjek at services kører
sudo systemctl status snapserver
sudo systemctl status camilladsp-gui

# Tjek firewall
sudo ufw status

# Test lokalt
curl http://localhost:1780
curl http://localhost:5000
```

## 🐳 Docker Alternative

Som alternativ til systemd services, kan systemet køres med Docker Compose:

### Forberedelse

```bash
# Installer Docker og Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt-get install docker-compose-plugin
```

### Start System med Docker

```bash
cd ~/Gregersen
sudo docker compose up -d
```

### Management

```bash
# Se status
sudo docker compose ps

# Se logs
sudo docker compose logs -f

# Stop system
sudo docker compose down

# Genstart en service
sudo docker compose restart camilladsp-front-left
```

### Fordele ved Docker

- ✅ Lettere dependency management
- ✅ Isolerede miljøer
- ✅ Nem backup og migration
- ✅ Konsistent deployment

### Ulemper ved Docker

- ❌ Mere ressource overhead
- ❌ Kompleksitet med audio devices
- ❌ Potentielle latency issues

## 🎓 Avanceret Konfiguration

### Custom EQ Profiler

Du kan lave forskellige EQ profiler til forskellige musik typer:

```bash
# Kopier eksisterende config
sudo cp /etc/camilladsp/camilladsp_front_left.yml \
       /etc/camilladsp/camilladsp_front_left_rock.yml

# Rediger nye profil
sudo nano /etc/camilladsp/camilladsp_front_left_rock.yml

# Skift profil
sudo systemctl stop camilladsp@front_left
sudo camilladsp -p 12340 /etc/camilladsp/camilladsp_front_left_rock.yml &
```

### Tilføj Flere Zoner

For at tilføje ekstra zoner:

1. Opret ny CamillaDSP config: `camilladsp_[zone_name].yml`
2. Tilføj ny pipe: `/tmp/snapfifo_[zone_name]`
3. Tilføj stream i `/etc/snapserver.conf`
4. Start ny CamillaDSP instans
5. Installer client og tilslut

### Integration med Home Assistant

```yaml
# configuration.yaml
media_player:
  - platform: snapcast
    host: [SERVER_IP]
```

### Automatisk Volume Normalisering

Rediger CamillaDSP config for at tilføje loudness normalization:

```yaml
filters:
  loudness_norm:
    type: Loudness
    parameters:
      reference_level: -18.0
      fader: -5.0
```

## 📊 Performance Tips

### Optimer for Lavest Latency

1. Brug Ethernet frem for WiFi
2. Reducer CamillaDSP chunksize til 512
3. Juster Snapserver buffer til minimum
4. Brug real-time kernel (avanceret)

### Reducer CPU Forbrug

1. Øg CamillaDSP chunksize til 2048
2. Reducer sample rate til 44100 (standard)
3. Begræns antal EQ bands

## 📝 Filstruktur

```
Gregersen/
├── README.md                          # Denne fil
├── install_server.sh                  # Server installation
├── install_client.sh                  # Client installation
├── start_system.sh                    # Start alle services
├── stop_system.sh                     # Stop alle services
├── status_system.sh                   # Vis system status
├── setup_web.sh                       # Opsæt web interface
├── docker-compose.yml                 # Docker deployment
├── config/
│   ├── shairport-sync.conf           # AirPlay konfiguration
│   ├── snapserver.conf               # Snapcast server config
│   ├── snapclient_template.conf      # Client config template
│   ├── camilladsp_front_left.yml     # DSP Front Left
│   ├── camilladsp_front_right.yml    # DSP Front Right
│   ├── camilladsp_back_left.yml      # DSP Back Left
│   └── camilladsp_back_right.yml     # DSP Back Right
└── systemd/
    ├── camilladsp@.service           # CamillaDSP template service
    └── audio-system.service          # Master system service
```

## 🤝 Bidrag

Bidrag er velkomne! Åbn en issue eller pull request på GitHub.

## 📄 Licens

MIT License - se LICENSE fil for detaljer.

## 🙏 Credits

Dette projekt bruger følgende open source software:

- [Shairport-sync](https://github.com/mikebrady/shairport-sync) - AirPlay audio receiver
- [CamillaDSP](https://github.com/HEnquist/camilladsp) - Digital Signal Processing
- [Snapcast](https://github.com/badaix/snapcast) - Multi-room audio distribution
- [pyCamillaDSP](https://github.com/HEnquist/pycamilladsp) - Web GUI for CamillaDSP

## 📞 Support

For spørgsmål eller problemer:
- Åbn en issue på GitHub
- Se Troubleshooting sektionen
- Tjek log filer for fejlmeddelelser

## 🔄 Version History

### v1.0.0 (Initial Release)
- Komplet multi-room audio system
- 4 zoner med individuel DSP
- Web interfaces til kontrol
- Automatisk startup ved boot
- Docker support
- Fuld dokumentation

---

**Lavet med ❤️ til multi-room audio entusiaster**