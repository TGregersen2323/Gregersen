# Advanced Configuration Examples

This directory contains example configurations for advanced use cases.

## Files

- `camilladsp_rock_profile.yml` - EQ profile optimized for rock music
- `camilladsp_classical_profile.yml` - EQ profile for classical music
- `snapserver_8zones.conf` - Extended configuration for 8 zones
- `systemd_override_example.conf` - Systemd service customization example

## Usage

### Using Different EQ Profiles

1. Copy the desired profile to `/etc/camilladsp/`
2. Stop the current instance
3. Start with new config:

```bash
sudo systemctl stop camilladsp@front_left
sudo cp examples/camilladsp_rock_profile.yml /etc/camilladsp/camilladsp_front_left.yml
sudo systemctl start camilladsp@front_left
```

### Switching Profiles Dynamically

You can use CamillaDSP's config switching feature:

```bash
# Using websocket API
curl -X POST http://localhost:12340/config/setconfigjson \
  -H "Content-Type: application/json" \
  -d @examples/camilladsp_rock_profile.yml
```

### Systemd Overrides

To customize a service without modifying the original file:

```bash
sudo systemctl edit camilladsp@front_left
# Paste content from systemd_override_example.conf
sudo systemctl daemon-reload
sudo systemctl restart camilladsp@front_left
```

## Creating Your Own Profiles

1. Start with an existing profile
2. Adjust EQ bands to your preference
3. Test thoroughly
4. Save with a descriptive name

## EQ Adjustment Tips

### Rock Music
- Boost bass (80-100 Hz): +3 to +6 dB
- Cut muddy frequencies (250-400 Hz): -2 to -3 dB
- Boost presence (2-4 kHz): +2 to +4 dB
- Slight high boost (8-10 kHz): +1 to +2 dB

### Classical Music
- Natural, minimal EQ
- Slight bass roll-off below 40 Hz: -3 dB
- Preserve midrange clarity
- Smooth high frequency: +1 dB above 10 kHz

### Electronic/EDM
- Deep bass boost (40-80 Hz): +6 to +9 dB
- Cut low-mids (200-400 Hz): -2 to -4 dB
- Boost highs (8-12 kHz): +3 to +5 dB

### Vocal/Podcast
- High-pass filter below 80 Hz
- Boost speech clarity (2-4 kHz): +3 to +5 dB
- Reduce sibilance (6-8 kHz): -2 to -3 dB

## Performance Considerations

- Lower `chunksize` = less latency, more CPU usage
- Higher `chunksize` = more latency, less CPU usage
- Recommended range: 512-2048 for Raspberry Pi
