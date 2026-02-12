# Contributing to Gregersen Audio System

Tak for din interesse i at bidrage til Gregersen Audio System! 🎵

## 📋 Indhold

- [Code of Conduct](#code-of-conduct)
- [Hvordan kan jeg bidrage?](#hvordan-kan-jeg-bidrage)
- [Rapporter Bugs](#rapporter-bugs)
- [Foreslå Features](#foreslå-features)
- [Pull Requests](#pull-requests)
- [Udvikling](#udvikling)

## Code of Conduct

Dette projekt følger grundlæggende principper om respektfuld og konstruktiv kommunikation.

## Hvordan kan jeg bidrage?

### Rapporter Bugs

Bugs rapporteres via [GitHub Issues](https://github.com/TGregersen2323/Gregersen/issues).

**Før du rapporterer:**
- Tjek at buggen ikke allerede er rapporteret
- Saml relevante informationer (logs, system info, etc.)

**Hvad skal inkluderes:**
- Beskrivelse af problemet
- Trin til at reproducere
- Forventet vs. faktisk resultat
- System information (OS, hardware, versioner)
- Relevante logs

**Eksempel:**
```markdown
## Bug: Snapclient forbinder ikke til server

**Beskrivelse:**
Snapclient service starter, men kan ikke forbinde til server.

**Steps to reproduce:**
1. Installer client med install_client.sh
2. Indtast server IP: 192.168.1.100
3. Service starter men ingen lyd

**Logs:**
```
journalctl -u snapclient -n 50
[fejlmeddelelse her]
```

**System:**
- Raspberry Pi 4 Model B
- Raspbian 11 (Bullseye)
- Snapclient version 0.27.0
```

### Foreslå Features

Feature requests er velkomne! Brug [GitHub Issues](https://github.com/TGregersen2323/Gregersen/issues) med "Feature Request" label.

**Inkluder:**
- Klar beskrivelse af featuren
- Hvorfor den ville være nyttig
- Mulige implementerings idéer
- Eksempler på brug

### Pull Requests

Vi accepterer gerne pull requests!

**Proces:**
1. Fork projektet
2. Opret en feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit dine ændringer (`git commit -m 'Add some AmazingFeature'`)
4. Push til branchen (`git push origin feature/AmazingFeature`)
5. Åbn en Pull Request

**PR Guidelines:**
- Følg eksisterende kodestil
- Test dine ændringer grundigt
- Opdater dokumentation hvis relevant
- Beskriv ændringerne klart i PR beskrivelsen

## Udvikling

### Opsætning af Udviklings Miljø

```bash
# Clone repository
git clone https://github.com/TGregersen2323/Gregersen.git
cd Gregersen

# Test scripts (uden at installere)
bash -n install_server.sh

# Test YAML configs
python3 -c "import yaml; yaml.safe_load(open('config/camilladsp_front_left.yml'))"
```

### Test Framework

Før du submitter:

```bash
# Syntax check all bash scripts
for script in *.sh; do bash -n "$script"; done

# Validate YAML files
for file in config/*.yml; do python3 -c "import yaml; yaml.safe_load(open('$file'))"; done

# Check systemd service files
systemd-analyze verify systemd/*.service
```

### Kodestil

**Bash Scripts:**
- Brug `set -e` for fejlhåndtering
- Kommenter kompleks logik
- Brug meaningful variable names
- Følg [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

**YAML Configs:**
- 2 spaces indentation
- Beskrivende kommentarer
- Konsistent struktur

**Dokumentation:**
- Skriv på dansk i README og bruger-facing docs
- Tekniske kommentarer kan være på engelsk
- Hold eksempler opdaterede

### Commit Messages

Brug klare, beskrivende commit messages:

```
Add support for 8-zone configuration

- Update CamillaDSP configs for zones 5-8
- Modify snapserver.conf to handle additional streams
- Add documentation for expanded setup
```

**Format:**
- Første linje: Kort beskrivelse (max 72 tegn)
- Blank linje
- Detaljeret beskrivelse hvis nødvendigt

### Branching Strategy

- `main`: Stabil, production-ready kode
- `develop`: Udviklings branch
- `feature/*`: Nye features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Kritiske fixes til production

## Testing

### Manual Testing

Test grundigt på rigtig hardware:

**Server:**
```bash
# Installer på test Raspberry Pi
sudo ./install_server.sh

# Verificer alle services starter
sudo ./start_system.sh

# Tjek web interfaces
curl http://localhost:1780
curl http://localhost:5000
```

**Client:**
```bash
# Test client installation
sudo ./install_client.sh

# Verificer forbindelse
systemctl status snapclient
```

### Integration Testing

Test hele systemet:
1. Server installation
2. Multiple client installations
3. AirPlay streaming
4. Zone assignment
5. EQ adjustment
6. Volume control
7. System restart/recovery

## Dokumentation

### Opdater README

Hvis du tilføjer features, opdater:
- Feature liste
- Installation instruktioner
- Konfiguration eksempler
- Troubleshooting guide

### Code Comments

Kommenter:
- Kompleks logik
- Workarounds
- Platform-specifikke hacks
- Sikkerhedsmæssige overvejelser

## Release Process

1. Test grundigt
2. Opdater version numbers
3. Opdater CHANGELOG
4. Tag release i git
5. Opret GitHub release
6. Opdater dokumentation

## Spørgsmål?

Hvis du har spørgsmål om bidrag:
- Åbn en Discussion på GitHub
- Spørg i en Issue
- Kontakt maintainers

## Licens

Ved at bidrage accepterer du at dit bidrag vil blive licenseret under MIT License.

---

**Tak for dit bidrag til Gregersen Audio System!** 🙏
