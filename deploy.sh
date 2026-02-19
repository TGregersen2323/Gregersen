#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Gregersen Audio System: opdatér konfiguration på Raspberry Pi
#
# Kopiér ALT herunder (fra "#!/usr/bin/env bash" til og med den sidste linje)
# og indsæt det direkte i din SSH-session.
#
# Hvad scriptet gør:
#   1. Laver backup af eksisterende konfigurationsfiler (med tidsstempel)
#   2. Skriver de optimerede konfigurationsfiler
#   3. Genstarter shairport-sync, camilladsp og snapserver
#   4. Viser servicestatus så du kan se om alt kører
# =============================================================================

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo ""
echo "======================================================"
echo "  Gregersen Audio System – deploy.sh  ($TIMESTAMP)"
echo "======================================================"
echo ""

# ── 1. Backup ─────────────────────────────────────────────────────────────────

backup() {
    local src="$1"
    if [ -f "$src" ]; then
        cp "$src" "${src}.bak_${TIMESTAMP}"
        echo "  [backup] ${src}.bak_${TIMESTAMP}"
    fi
}

echo "▶ Laver backup af eksisterende konfigurationsfiler..."
backup /etc/shairport-sync.conf
backup /etc/camilladsp/configs/default.yml
backup /etc/snapserver.conf
echo ""

# ── 2. shairport-sync.conf ────────────────────────────────────────────────────

echo "▶ Skriver /etc/shairport-sync.conf..."
cat > /etc/shairport-sync.conf << 'SHAIRPORT_EOF'
// Shairport-Sync configuration
// AirPlay -> ALSA Loopback (hw:Loopback,0,0)

general =
{
    name = "Surround System";
    output_backend = "alsa";
    interpolation = "basic";
    ignore_volume_control = "no";
    mdns_backend = "avahi";
    // Tillader Apple TV at genoptage en ny session uden at vente på timeout
    allow_session_interruption = "yes";
    session_timeout = 20;
};

metadata =
{
    enabled = "yes";
    include_cover_art = "no";
    pipe_name = "/tmp/shairport-sync-metadata";
    pipe_timeout = 5000;
};

alsa =
{
    output_device = "hw:Loopback,0,0";
    // period_size matches CamillaDSP chunksize=1024 → eliminerer ALSA periode-mismatch
    period_size = 1024;
    // Negativ offset kompenserer for nedstrømslatency (CamillaDSP + Snapcast).
    // -0.35 passer til buffer=1000ms i Snapcast + ~93ms CamillaDSP (fratrukket Shairports egen buffer).
    // Typisk justeringsområde: -0.20 til -0.60. Justér i skridt á 0.05:
    //   lyd efter billede → mere negativ | lyd før billede → tættere på 0
    audio_backend_latency_offset_in_seconds = -0.35;
    // Lidt ekstra buffer i Shairport selv for stabilitet
    audio_backend_buffer_desired_length_in_seconds = 0.20;
};
SHAIRPORT_EOF
echo "  OK"
echo ""

# ── 3. CamillaDSP default.yml ─────────────────────────────────────────────────

echo "▶ Opretter /etc/camilladsp/configs/ hvis den mangler..."
mkdir -p /etc/camilladsp/configs

echo "▶ Skriver /etc/camilladsp/configs/default.yml..."
cat > /etc/camilladsp/configs/default.yml << 'CAMILLA_EOF'
# CamillaDSP configuration
# Capture: ALSA Loopback (hw:Loopback,1,0) <- skrevet af Shairport-Sync
# Playback: named pipe -> Snapcast

devices:
  samplerate: 44100
  chunksize: 1024
  # queuelimit=4 giver ~93ms headroom ved 44100Hz/1024 samples.
  # queuelimit=1 (originalen) medfører underrun ved kortvarig CPU-spike → skratten.
  # Højere værdier øger buffering og dermed latency; 4 er et godt kompromis.
  queuelimit: 4
  capture:
    type: Alsa
    channels: 2
    device: "hw:Loopback,1,0"
    format: S16LE
  playback:
    type: File
    channels: 2
    filename: "/tmp/snapfifo"
    format: S16LE

mixers:
  stereo:
    channels:
      in: 2
      out: 2
    mapping:
      - dest: 0
        sources:
          - channel: 0
            gain: 0
            inverted: false
      - dest: 1
        sources:
          - channel: 1
            gain: 0
            inverted: false

pipeline:
  - type: Mixer
    name: stereo
CAMILLA_EOF
echo "  OK"
echo ""

# ── 4. snapserver.conf ────────────────────────────────────────────────────────

echo "▶ Skriver /etc/snapserver.conf..."
cat > /etc/snapserver.conf << 'SNAPSERVER_EOF'
# Snapserver configuration
# Stream source: named pipe fra CamillaDSP

[http]
enabled = true
doc_root = /usr/share/snapserver/snapweb

[tcp]
enabled = true

[stream]
source = pipe:///tmp/snapfifo?name=CamillaStream&sampleformat=44100:16:2
# buffer=1000ms bevares — under ~500ms giver udfald på Wi-Fi klienter
buffer = 1000
codec = flac
# chunk_ms=20 (var 10): halverer chunk-raten (50 vs 100/sek) → lavere CPU-overhead og jitter
chunk_ms = 20
SNAPSERVER_EOF
echo "  OK"
echo ""

# ── 5. Genstart services ──────────────────────────────────────────────────────

echo "▶ Genstarter services..."
systemctl restart shairport-sync && echo "  shairport-sync  → genstartet" \
    || echo "  shairport-sync  → FEJL ved genstart (tjek: journalctl -u shairport-sync -n 30)"

systemctl restart camilladsp   && echo "  camilladsp      → genstartet" \
    || echo "  camilladsp      → FEJL ved genstart (tjek: journalctl -u camilladsp -n 30)"

systemctl restart snapserver   && echo "  snapserver      → genstartet" \
    || echo "  snapserver      → FEJL ved genstart (tjek: journalctl -u snapserver -n 30)"

echo ""

# ── 6. Statusoversigt ─────────────────────────────────────────────────────────

echo "======================================================"
echo "  Servicestatus"
echo "======================================================"
for svc in shairport-sync camilladsp snapserver; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || true)
    printf "  %-20s %s\n" "$svc" "$STATUS"
done

echo ""
echo "======================================================"
echo "  Færdig! Konfigurationsfiler opdateret."
echo ""
echo "  Backups gemt som:  <original>.bak_${TIMESTAMP}"
echo ""
echo "  Tip: Ved Apple TV sync-drift, justér i shairport-sync.conf:"
echo "    audio_backend_latency_offset_in_seconds"
echo "  (mere negativ = kompensér for mere nedstrømslatency)"
echo "======================================================"
echo ""
