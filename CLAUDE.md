# HomeDash — Projektnotizen für Claude

tvOS HomeKit-Dashboard (SwiftUI), App Store live als
"HomeDash: Smart Home Dashboard" (App-ID 6772391873, Bundle de.marcel.homedash).

## ⛔ HARTE REGELN (immer befolgen)

1. **NIEMALS selbst zur App-Prüfung einreichen (Submit).**
   `python3 scripts/asc.py submit …` darf ich NICHT ausführen. Den Submit
   macht **immer der User selbst** — das ist sein letzter manueller Check,
   wo er nochmal alles prüft. Ich bereite alles bis zum Submit vor
   (Archive, Upload, attach-build, set-whatsnew, set-compliance) und sage
   dann „bereit zum Submit, mach du den finalen Klick / sag Bescheid wenn
   ich submitten soll". Erst auf ausdrückliche Aufforderung submitten.

2. **Verifizieren statt annehmen.** Bei Build/Upload/ASC-Schritten immer das
   echte Log / den echten API-State lesen, bevor ich „erfolgreich" sage.
   Lange Terminal-Ausgaben in eine Datei schreiben und per Read lesen, nicht
   aus abgeschnittener stdout raten.

## Release-Workflow (vollautomatisch, headless — siehe docs/asc-automation.md)

Version bumpen → `generate_xcodeproj.py` → Archive → `make-profile` →
Export (manual signing!) → Upload (altool) → attach-build → set-compliance
→ **STOP, User submittet**.

Pipeline-Skript: `build/pipeline.sh` (Export+Upload). ASC-Tooling:
`scripts/asc.py` (status, prepare-version, set-whatsnew, attach-build,
set-compliance, make-profile, submit).

### Signing-Besonderheit (wichtig!)
Zwei Teams, gespaltene Certs:
- `JRKK5F6HH6` (Personal) — nur Development-Cert
- `3PXX8LS2JZ` (bezahlt) — nur Distribution-Cert, **App läuft hier**

`DEVELOPMENT_TEAM` im Projekt = `JRKK5F6HH6` (so funktioniert der lokale/
Device-Build + GUI). Für den **App-Store-Export** aber manual signing mit
API-erzeugtem Profil (`make-profile`, Team 3PXX8LS2JZ) + `-authenticationKey*`-
Flags. Automatic signing per CLI scheitert sonst an „missing Xcode-Username".

## ASC-Credentials
Lokal in `~/.appstoreconnect/config.json` (chmod 600, NICHT im Repo).
Key-ID GY2QKWF54X, `.p8` in `~/.appstoreconnect/private_keys/`.
Issuer ID ist nicht-geheim. `.p8` verlässt nie die Maschine.

## Versionsstand
- 1.0.0, 1.0.1 — Ready for Sale (live)
- 1.0.2 (Build 5) — eingereicht, HMHomeDelegate-Live-Update-Fix + Error-Toast

## Konventionen
- User-facing: "Apple Home" (nicht "HomeKit"). "HomeKit" nur technisch.
- Lokalisierung DE + EN, alle Strings in Localizable.strings.
- Commit-Trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Roadmap: docs/ROADMAP.md (IAP via StoreKit 2 fest für v1.2.0 eingeplant).

## Backlog / offen
- Englische App-Store-Screenshots (Apple TV auf EN, via Xcode Devices, dann zurück)
- v1.1.0: Kamera-Streams, Sensor-Übersicht, Suche, Top-Shelf-Widget
