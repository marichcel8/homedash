# Launch-Checkliste – HomeDash 1.0

Schritt-für-Schritt-Plan von „Code fertig" bis „App Store live".

Geschätzte Gesamtzeit: **3-4 Stunden Arbeit + 1-2 Wochen Wartezeit auf Apple**.

---

## Phase 0 – Vorbereitung (15 Min)

- [ ] **Bundle-ID festlegen:** Aktuell `de.marcel.homedash`. Frei wählen falls Konflikt.
- [ ] **Postanschrift in Impressum eintragen** – `Legal/IMPRINT.md` und `docs/imprint.html` editieren (`[Straße und Hausnummer eintragen]`, `[PLZ und Ort eintragen]`).
- [ ] **Apple-Developer-Account aktiv?** Check: https://developer.apple.com/account → Membership = aktiv.
- [ ] **App-Store-Connect-Zugriff?** https://appstoreconnect.apple.com → einloggen klappt.

## Phase 1 – Apple Developer Setup (15 Min)

- [ ] **App-ID anlegen:**
  https://developer.apple.com/account/resources/identifiers/list → `+` →
  App IDs → App. Bundle ID = `de.marcel.homedash`. Capabilities → **HomeKit** ankreuzen.
- [ ] **In Xcode Signing prüfen:** Target → Signing & Capabilities →
  Team = dein Team → keine roten Fehler.
- [ ] **App in App Store Connect anlegen:**
  https://appstoreconnect.apple.com → Apps → `+` → Neue App → tvOS →
  Bundle-ID auswählen (wird automatisch erkannt) → Name = HomeDash.

## Phase 2 – Hosting für Pflicht-URLs (20 Min)

- [ ] **GitHub-Repo anlegen** (public): `https://github.com/marichcel8/homedash`
- [ ] **Code pushen:**
  ```bash
  cd "/Users/marcel/TvOS Homekit anbindungsapp"
  git init && git add . && git commit -m "Initial release"
  git remote add origin https://github.com/marichcel8/homedash.git
  git push -u origin main
  ```
- [ ] **GitHub Pages aktivieren:** Repo → Settings → Pages → Source = `main` branch, Folder = `/docs` → Save.
- [ ] **Nach ~1 Min URLs testen:**
  - `https://marichcel8.github.io/homedash/`
  - `https://marichcel8.github.io/homedash/privacy.html`
  - `https://marichcel8.github.io/homedash/support.html`
  - `https://marichcel8.github.io/homedash/imprint.html`

## Phase 3 – Self-Test auf Apple TV (1-3 Tage)

- [ ] **Build & Run auf TV:** Xcode → Run-Destination = Apple TV → ⌘R.
- [ ] **Trust-Profile:** Apple TV → Einstellungen → Allgemein → VPN- und Geräteverwaltung → Profil bestätigen.
- [ ] **Apple-Home-Permission:** Apple TV → Einstellungen → Apps → HomeDash → Apple Home = An.
- [ ] **Smoke-Test:**
  - Alle Räume sichtbar?
  - Lichter togglen funktioniert?
  - Farbpicker funktioniert?
  - Thermostat stellen funktioniert?
  - Long-Press öffnet Detail?
  - Focus-Outline sauber (kein weißer Halo)?
- [ ] **Mehrtägig nutzen** und Edge-Cases sammeln.

## Phase 4 – TestFlight Closed Beta (1-2 Wochen)

- [ ] **Archive bauen:**
  ```bash
  ./scripts/archive.sh
  ```
  oder Xcode → Product → Archive.
- [ ] **Upload zu App Store Connect:** Organizer → Distribute App → App Store Connect → Upload.
- [ ] **Build erscheint** nach ~15 Min in App Store Connect → TestFlight.
- [ ] **Compliance ausfüllen:** TestFlight → Export Compliance → „No, keine Verschlüsselung" (wir nutzen nur HTTPS via System).
- [ ] **5-20 Tester einladen** über Apple-IDs (Internal Testing).
- [ ] **Feedback sammeln und fixen.**

## Phase 5 – App Store Listing fertigmachen (1-2 Stunden)

Quelle für alle Texte: `Legal/APPSTORE_LISTING.md`.

- [ ] **App-Informationen:**
  - [ ] Subtitle, Promotional Text, Description (DE + EN)
  - [ ] Keywords
  - [ ] Support-URL: `https://marichcel8.github.io/homedash/support.html`
  - [ ] Marketing-URL: `https://marichcel8.github.io/homedash/`
  - [ ] Privacy Policy URL: `https://marichcel8.github.io/homedash/privacy.html`
  - [ ] Category: Lifestyle (primary) + Utilities (secondary)
  - [ ] Age Rating: 4+ (keine bedenklichen Inhalte)
  - [ ] Content Rights: „Does not contain third-party content"
- [ ] **App Privacy ausfüllen:** „No, we do not collect data from this app".
- [ ] **Screenshots aufnehmen** (1920×1080 oder 3840×2160, 5-10 Stück):
  - Dashboard mit Räumen
  - Detail-Sheet Licht mit Farbpicker
  - Detail-Sheet Thermostat
  - Detail-Sheet Lock
  - Favoriten + Szenen Sektion
  - (optional) Dark + Light Mode nebeneinander
  - Empty State
  ```bash
  xcrun simctl io booted screenshot screen.png
  ```
- [ ] **App-Preview-Video** (15-30 s, optional aber dringend empfohlen für HomeKit-Apps):
  - Aufnehmen mit QuickTime → Apple TV als Aufnahmequelle oder Simulator-Recording
  - Skript siehe `Legal/APPSTORE_LISTING.md` Abschnitt „App Preview Video"

## Phase 6 – Review Submission (5 Min Arbeit + 1-3 Tage Wartezeit)

- [ ] **Build für Submission auswählen** in App Store Connect.
- [ ] **Version Release:**
  - „Manuell veröffentlichen nach Approval" (sicher) **oder**
  - „Automatisch nach Approval" (schneller)
- [ ] **Review Notes:** Komplett aus `Legal/APPSTORE_REVIEW_NOTES.md` einfügen.
  Diese Notes sind für HomeKit-Apps quasi Pflicht — ohne wahrscheinlich Reject.
- [ ] **Demo-Account: leer lassen** (App braucht keinen Account).
- [ ] **Submit for Review** klicken.
- [ ] **E-Mail-Status verfolgen:** „Waiting For Review" → „In Review" → „Pending Developer Release" oder „Ready for Sale".
- [ ] Bei Reject:
  - In App Store Connect → Resolution Center → Apple-Feedback lesen
  - Fix einbauen, neuen Build hochladen, Notes ergänzen, resubmit.
  - HomeKit-Apps werden im Schnitt 1-2 mal abgelehnt, das ist normal.

## Phase 7 – Release (5 Min)

- [ ] Falls „Manuell veröffentlichen" gewählt: App Store Connect → Release.
- [ ] **Erste Stunden:** App-Listing checken, ist sie auffindbar?
- [ ] **Social-Posting** (optional): X/Twitter, Reddit r/HomeKit, MacRumors-Forum.

## Häufige Reject-Gründe vermeiden

| Reject-Grund | Wie vermieden |
|---|---|
| App ohne HomeKit-Setup zeigt nichts | Empty-State-UI funktioniert sauber; Review Notes erklären das ausführlich |
| Privacy-Policy fehlt oder nicht abrufbar | URL auf GitHub Pages funktioniert, getestet |
| Privacy-Manifest fehlt | `PrivacyInfo.xcprivacy` mit korrekten Reason-Codes vorhanden |
| App nutzt „HomeKit" im Namen oder Marketing | App heißt „HomeDash", Marketing nutzt „Apple Home" |
| App icon zu generisch | Eigenes Layered-Icon vorhanden (programmatisch generiert, sieht aber sauber aus) |
| Demo-Video fehlt | Empfohlen, beim Upload als App Preview einfügen |

---

## Quick-Status

✅ **Code-mäßig fertig** — buildet sauber, läuft auf TV
✅ **Legal-Dokumente fertig** — Privacy, Support, Impressum, Review Notes, Listing-Text
✅ **Website fertig** — `docs/` ist GitHub-Pages-ready
✅ **Markenrechtlich sauber** — Apple-Trademark-Konventionen beachtet
✅ **App-Icon, Top Shelf, Launch Image fertig** — programmatisch generiert

⏳ **Noch zu tun von dir:** Phase 0 Adress-Eintrag · Phase 1 App-ID · Phase 2 Git push + GitHub Pages · Phase 3-6 wie oben.
