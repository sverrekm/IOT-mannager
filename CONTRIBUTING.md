# Bidra til IoT Manager

Takk for at du vil bidra til IoT Manager! Dette dokumentet forklarer hvordan du kan bidra.

## Hvordan bidra

### Rapporter bugs

Hvis du finner en feil:

1. Sjekk om feilen allerede er rapportert i [Issues](https://github.com/sverrekm/IOT-mannager/issues)
2. Hvis ikke, opprett en ny issue med:
   - Tydelig tittel
   - Beskrivelse av problemet
   - Steg for å reprodusere
   - Forventet vs faktisk oppførsel
   - System info (Raspberry Pi modell, OS versjon, etc.)
   - Logger hvis relevant

### Foreslå forbedringer

Har du en idé til forbedring?

1. Opprett en issue med tag `enhancement`
2. Beskriv hva du vil forbedre og hvorfor
3. Diskuter løsningen før du begynner å kode

### Pull Requests

1. Fork repositoryet
2. Opprett en branch: `git checkout -b feature/ny-funksjon`
3. Gjør dine endringer
4. Test endringene grundig på Raspberry Pi
5. Commit: `git commit -m "Legg til ny funksjon"`
6. Push: `git push origin feature/ny-funksjon`
7. Opprett Pull Request

### Kode stil

- Bruk 4 spaces for innrykk i bash scripts
- Bruk 2 spaces for YAML filer
- Kommenter kompleks logikk
- Følg eksisterende kode stil
- Test på Raspberry Pi før PR

### Testing

Før du sender inn PR, test:

1. Installasjon på ren Raspberry Pi
2. Alle valg av tjenester
3. Start/stopp/restart funksjoner
4. Backup og restore
5. Sjekk at dokumentasjon er oppdatert

### Dokumentasjon

Hvis du legger til ny funksjonalitet:

1. Oppdater README.md
2. Oppdater QUICKSTART.md hvis relevant
3. Legg til i TROUBLESHOOTING.md hvis aktuelt
4. Kommenter koden

## Utviklingsmiljø

### Lokal testing

```bash
# Klon repo
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager

# Test install script
./install.sh

# Test andre scripts
./scripts/manage.sh status
./scripts/backup.sh
```

### Teste på Raspberry Pi

Anbefalt å teste på:
- Raspberry Pi 5 (primær)
- Raspberry Pi 4 (sekundær)
- Raspberry Pi OS 64-bit

### Verktøy

- ShellCheck for bash linting: `sudo apt-get install shellcheck`
- yamllint for YAML validering: `pip install yamllint`

## Commit meldinger

Følg konvensjonelle commit meldinger:

- `feat: Legg til ny tjeneste`
- `fix: Rett opp Zigbee adapter bug`
- `docs: Oppdater README`
- `refactor: Reorganiser backup script`
- `test: Legg til test for MQTT`
- `chore: Oppdater .gitignore`

## Spørsmål?

Usikker på noe? Opprett en issue med spørsmålet ditt!

## Lisens

Ved å bidra aksepterer du at dine bidrag lisenseres under MIT License.

## Anerkjennelser

Bidragsytere vil bli listet i README.md
