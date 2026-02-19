# Gregersen Audio System

Multi-room audio distribution system til Raspberry Pi.

## Hurtig deployment (SSH)

Kopiér og indsæt **hele** [`deploy.sh`](deploy.sh) direkte i din SSH-session på Raspberry Pi'en.  
Scriptet laver automatisk backup af eksisterende konfigurationsfiler, skriver de optimerede filer
og genstarter alle tre services.

> **Kræver root** — log ind som `root` eller sæt `sudo bash` foran scriptet.

---

## Signalvej

```
AirPlay (Apple TV / iPhone)
        │
        ▼
  Shairport-Sync
  (skriver til ALSA Loopback hw:Loopback,0,0)
        │
        ▼
  ALSA Loopback
  (CamillaDSP læser fra hw:Loopback,1,0)
        │
        ▼
  CamillaDSP
  (DSP-behandling → skriver til /tmp/snapfifo)
        │
        ▼
  Snapserver
  (streamer via Snapcast til alle klienter)
        │
        ▼
  Snapclient(s)  →  Højttalere
```

## Identificerede flaskehalse og rettelser

### 1. `queuelimit: 1` i CamillaDSP → **primær årsag til skratten/udfald**

CamillaDSP's `queuelimit` styrer, hvor mange lydchunks der må vente i køen.  
Med `queuelimit: 1` kan én enkelt kort CPU-spike forårsage en buffer-underrun og
et hørbart knald. Løsningen er at sætte den til `4`:

| Parameter | Før | Efter |
|-----------|-----|-------|
| `queuelimit` | 1 | **4** |

4 chunks à 1024 samples ved 44100 Hz ≈ **93 ms** ekstra buffer — usynlig latency,
men nok til at absorbere forbigående systembelastning.

### 2. ALSA periode-størrelse ikke justeret → **timing-mismatch**

Shairport-Sync skriver til ALSA Loopback med en ukontrolleret periode-størrelse,
mens CamillaDSP læser med `chunksize: 1024`. Når disse to størrelser ikke matcher,
opstår der periodisk timing-jitter.

**Løsning:** `period_size = 1024` tilføjet i `shairport-sync.conf`'s `alsa`-sektion
så ALSA-perioden matcher CamillaDSP's chunk nøjagtigt.

### 3. `audio_backend_latency_offset_in_seconds = 0.0` → **Apple TV sync-problemer**

AirPlay-protokollen forventer, at Shairport-Sync rapporterer den *samlede* nedstrøms
latency. Med en Snapcast-buffer på 1000 ms + CamillaDSP-behandling (~93 ms) er den
reelle nedstrøms latency ca. 350 ms udover Shairport's egen buffer. Når dette ikke
rapporteres til Apple TV, laver Apple TV forkert timing og lyd og billede kan forskyde
sig eller sessionen kan falde af.

| Parameter | Før | Efter |
|-----------|-----|-------|
| `audio_backend_latency_offset_in_seconds` | 0.0 | **-0.35** |

Negativ værdi: "fortæl kilden at spille 350 ms tidligere" for at kompensere for
nedstrømslatency. Justér værdien trinvist i skridt på 0.05 s, hvis der stadig er
sync-drift.

### 4. `allow_session_interruption` mangler → **Apple TV kan ikke genoptage**

Uden `allow_session_interruption = "yes"` afviser Shairport-Sync en ny AirPlay-session
hvis den eksisterende session er inaktiv men ikke lukket. Apple TV oplever dette som
forbindelsesfejl.

### 5. `chunk_ms = 10` i Snapcast → **unødvendig CPU-overhead**

10 ms chunks = 100 chunks/sekund per klient. 20 ms chunks halverer denne rate og
giver mere stabil streaming uden mærkbar ekstra latency.

| Parameter | Før | Efter |
|-----------|-----|-------|
| `chunk_ms` | 10 | **20** |

## Deployment

Kopiér konfigurationsfilerne til systemet og genstart services:

```bash
# Shairport-Sync
sudo cp config/shairport-sync.conf /etc/shairport-sync.conf
sudo systemctl restart shairport-sync

# CamillaDSP
sudo cp config/camilladsp/configs/default.yml /etc/camilladsp/configs/default.yml
sudo systemctl restart camilladsp

# Snapserver
sudo cp config/snapserver.conf /etc/snapserver.conf
sudo systemctl restart snapserver
```

## Latency-budget (efter rettelser)

| Komponent | Latency |
|-----------|---------|
| Shairport buffer | ~200 ms |
| CamillaDSP (queuelimit=4 × 1024/44100) | ~93 ms |
| Snapcast buffer | 1000 ms |
| **Samlet** | **~1293 ms** |

Dette er en stabil konfiguration. Ønskes lavere latency, kan Snapcast `buffer` sænkes
til 500 ms og `queuelimit` til 2, men det kræver pålidelig netværksforbindelse til
alle Snapcast-klienter.

## Konfigurationsfiler

| Fil i repo | Destination på system |
|------------|----------------------|
| `config/shairport-sync.conf` | `/etc/shairport-sync.conf` |
| `config/camilladsp/configs/default.yml` | `/etc/camilladsp/configs/default.yml` |
| `config/snapserver.conf` | `/etc/snapserver.conf` |
