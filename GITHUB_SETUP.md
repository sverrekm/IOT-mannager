# Oppsett av GitHub Repository

Denne guiden viser hvordan du laster opp IoT Manager til GitHub.

## Trinn 1: Initialiser Git Repository

I IOTmanager mappen, kjør:

```bash
git init
git add .
git commit -m "Initial commit: IoT Manager installer for Raspberry Pi 5"
```

## Trinn 2: Koble til GitHub Repository

```bash
git remote add origin https://github.com/sverrekm/IOT-mannager.git
git branch -M main
git push -u origin main
```

Hvis du får feilmelding om autentisering, må du sette opp GitHub credentials:

### Alternativ A: Personal Access Token (anbefalt)

1. Gå til GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Klikk "Generate new token (classic)"
3. Gi token et navn (f.eks. "IOT-mannager")
4. Velg scope: `repo` (full control of private repositories)
5. Klikk "Generate token"
6. Kopier token (vises kun én gang!)

Når du pusher, bruk:
- Username: `sverrekm`
- Password: `<din personal access token>`

### Alternativ B: SSH Key

```bash
# Generer SSH key (hvis du ikke har en)
ssh-keygen -t ed25519 -C "din-email@example.com"

# Kopier public key
cat ~/.ssh/id_ed25519.pub

# Legg til i GitHub Settings → SSH and GPG keys → New SSH key
```

Endre remote URL til SSH:
```bash
git remote set-url origin git@github.com:sverrekm/IOT-mannager.git
git push -u origin main
```

## Trinn 3: Verifiser opplasting

Gå til https://github.com/sverrekm/IOT-mannager og sjekk at alle filene er lastet opp.

## Fremtidige oppdateringer

Når du gjør endringer:

```bash
git add .
git commit -m "Beskrivelse av endringer"
git push
```

## Testing av installasjon

Etter opplasting til GitHub, test at installasjonen fungerer:

```bash
# På Raspberry Pi
curl -fsSL https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh | bash
```

## Viktig: .gitignore

Sjekk at `.gitignore` er konfigurert riktig slik at sensitive data ikke lastes opp:

```bash
cat .gitignore
```

Filen skal inneholde:
- `homeassistant/`
- `mosquitto/data/`
- `*.secret`
- `*.key`
- `.env`
- osv.

## Gjøre repository public eller private

### Public (anbefalt for open source)
Repository er tilgjengelig for alle. Perfekt for et open source installasjonsverktøy.

### Private
Kun du kan se repositoryet. Bra hvis du har egne tilpasninger.

Endre i GitHub: Settings → Danger Zone → Change repository visibility

## README badges (valgfritt)

Legg til badges i README.md:

```markdown
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi-red)
![Docker](https://img.shields.io/badge/docker-compose-blue)
```

## Release (valgfritt)

Når du har en stabil versjon:

1. Gå til GitHub repository
2. Klikk "Releases" → "Create a new release"
3. Tag version: `v1.0.0`
4. Release title: `v1.0.0 - Initial Release`
5. Beskrivelse: List hva som er inkludert
6. Publish release

## Ferdig!

Installasjonen er nå tilgjengelig via:

```bash
curl -fsSL https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh | bash
```

eller:

```bash
git clone https://github.com/sverrekm/IOT-mannager.git
cd IOT-mannager
chmod +x install.sh
./install.sh
```
