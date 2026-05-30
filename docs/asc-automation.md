# App Store: Archive + Upload + Submit — vollautomatisch (kein Xcode-GUI)

Der komplette Weg `Archive → Export → Upload → Submit` läuft headless über
`xcodebuild` + `xcrun altool` + die App Store Connect REST API. Der Mensch
wird nur für sehr wenige Dinge gebraucht (s. „Echte Ausnahmen").

Für HomeDash konkret umgesetzt in `scripts/asc.py` + `build/pipeline.sh`.

---

## Voraussetzungen (einmalig)

- **ASC API Key** (`.p8`) + `Key ID` + `Issuer ID`
  → ASC → Users and Access → Integrations → App Store Connect API
- `.p8` liegt unter `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8`
- Identifier (nicht-geheim) in `~/.appstoreconnect/config.json`:
  ```json
  {"key_id":"GY2QKWF54X","issuer_id":"<UUID>",
   "key_path":"/Users/marcel/.appstoreconnect/private_keys/AuthKey_GY2QKWF54X.p8"}
  ```
- Distribution-Zertifikat im Keychain (Privatschlüssel muss lokal vorhanden sein)

---

## Stolperfalle, die uns am meisten Zeit kostete

**Zwei Teams, gespaltene Zertifikate.** Dieser Account hat:
- `JRKK5F6HH6` (Personal Team) — nur Development-Cert
- `3PXX8LS2JZ` (bezahltes Team) — nur Distribution-Cert, App läuft hier

Beim **Export** mit *automatic signing* per CLI scheitert es an
`No Account for Team …` bzw. `missing Xcode-Username`, weil xcodebuild für
Automatic-Signing die in der Xcode-GUI eingeloggten Account-Credentials
braucht — die sind headless nicht da.

**Lösung:** *manual signing* + ein per API erzeugtes App-Store-Profil:

1. Provisioning-Profil per API erstellen (`scripts/asc.py make-profile`):
   sucht Distribution-Cert + Bundle-ID, erstellt `TVOS_APP_STORE`-Profil,
   lädt es herunter, installiert es nach
   `~/Library/MobileDevice/Provisioning Profiles/<uuid>.mobileprovision`.
2. Export mit `signingStyle=manual`, dem Profilnamen und **zusätzlich** den
   `-authenticationKey*`-Flags (sonst will xcodebuild trotzdem GUI-Creds).

---

## Der funktionierende Ablauf (HomeDash, tvOS)

### 1. Version + Build-Nummer setzen
In `scripts/generate_xcodeproj.py`: `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`
bumpen, `DEVELOPMENT_TEAM` muss das **bezahlte** Team sein. Dann
`python3 scripts/generate_xcodeproj.py`.

> Wichtig: `Info.plist` nutzt `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`
> — kein hartkodierter String, sonst gewinnt der String über die Build-Settings.

### 2. Archive (headless, API-Key-Auth)
```bash
xcodebuild archive \
  -project HomeDash.xcodeproj -scheme HomeDash \
  -destination 'generic/platform=tvOS' \
  -archivePath build/HomeDash.xcarchive \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_GY2QKWF54X.p8 \
  -authenticationKeyID GY2QKWF54X \
  -authenticationKeyIssuerID <ISSUER>
```

### 3. App-Store-Profil per API erzeugen
```bash
python3 scripts/asc.py make-profile
```

### 4. Export als App-Store-IPA (manual signing)
`build/ExportOptions-manual.plist`:
```xml
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>3PXX8LS2JZ</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Apple Distribution</string>
  <key>provisioningProfiles</key>
  <dict><key>de.marcel.homedash</key><string>HomeDash tvOS App Store (CLI)</string></dict>
  <key>destination</key><string>export</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
```
```bash
xcodebuild -exportArchive \
  -archivePath build/HomeDash.xcarchive \
  -exportPath build/export3 \
  -exportOptionsPlist build/ExportOptions-manual.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath … -authenticationKeyID … -authenticationKeyIssuerID …
```

### 5. Upload (altool, mit Retry)
```bash
export API_PRIVATE_KEYS_DIR=~/.appstoreconnect/private_keys
for i in 1 2 3 4 5; do
  xcrun altool --upload-app -f build/export3/HomeDash.ipa -t tvos \
    --apiKey GY2QKWF54X --apiIssuer <ISSUER> && break
  sleep 25
done
```
→ Steps 4+5 sind in `build/pipeline.sh` gebündelt (als Background-Task starten,
übersteht Verbindungsabbrüche).

### 6. Metadaten + Submit (REST API, via scripts/asc.py)
```bash
python3 scripts/asc.py status                # Übersicht
python3 scripts/asc.py prepare-version 1.0.2 # Version anlegen
python3 scripts/asc.py set-whatsnew 1.0.2    # whatsnew_{de,en}.txt
python3 scripts/asc.py attach-build 1.0.2 5  # Build binden
python3 scripts/asc.py set-compliance 5 false# Export-Compliance
python3 scripts/asc.py submit 1.0.2          # zur Prüfung einreichen
```

---

## REST-API-Auth (JWT ES256)
```python
import jwt, time   # PyJWT
tok = jwt.encode(
  {"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time())+600,
   "aud": "appstoreconnect-v1"},          # KEIN scope-Claim → sonst 400
  open(KEY_PATH).read(), algorithm="ES256", headers={"kid": KEY_ID})
# Authorization: Bearer <tok>
# Content-Type: application/json NUR bei POST/PATCH, nicht bei GET
```

Wichtige Endpunkte (`api.appstoreconnect.apple.com/v1`):
- Build↔Version: `PATCH /appStoreVersions/{id}/relationships/build`
- Texte: `PATCH /appStoreVersionLocalizations/{id}`
- Review-Notes: `PATCH /appStoreReviewDetails/{id}`
- Status: `GET /appStoreVersions/{id}` (`appStoreState`)
- Submit: `POST /reviewSubmissions` + `POST /reviewSubmissionItems`

---

## Echte Ausnahmen (gehen NICHT per API)

- **Erster IAP/Abo einer App**: muss einmalig im Web-UI auf der Versionsseite
  ausgewählt werden, bevor man submittet (`reviewSubmissionItems` kennt keine
  IAP-Relationship → HTTP 409). Ab dem zweiten IAP frei automatisierbar.
- **App-Store-Screenshots/Previews**: theoretisch per Asset-Upload-Flow
  möglich, aber das Erzeugen echter Screenshots braucht eine laufende App mit
  Daten (für HomeKit-Apps: kein Simulator-Inhalt → Gerät nötig).

---

## Fallstricke
- `altool` findet die `.p8` nur in Standardordnern → `API_PRIVATE_KEYS_DIR`.
- Direkt-Install aufs Gerät braucht **Development**-Signing
  (`xcrun devicectl device install app`); die App-Store-IPA geht dafür NICHT.
- LibreSSL/urllib3-Warnung unter System-Python ist harmlos
  (`warnings.filterwarnings("ignore")`).
