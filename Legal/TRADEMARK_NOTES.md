# Markenrechtliche Anmerkungen

Stand: Mai 2026

Diese Notiz fasst zusammen, welche Apple-Marken in HomeDash genannt werden und
welche Konventionen dabei beachtet werden, um Apples Branding-Guidelines zu
respektieren.

## Verwendete Apple-Marken

| Marke | Wo wird sie genannt | Konformität |
|---|---|---|
| **Apple Home** | App-UI, Marketing, Description | ✅ User-facing-Marke, korrekt verwendet |
| **HomeKit** | nur als technische Framework-Referenz (Code, Privacy-Manifest, Review Notes) | ✅ Apple erlaubt das im technischen Kontext |
| **Apple TV** | Description, README, Support | ✅ Plattform-Bezeichnung, korrekt |
| **Siri Remote** | Description, Support | ✅ Beschreibung der Bedienung |
| **iCloud** | Privacy Policy, Support | ✅ Account-Voraussetzung |
| **App Store** | Support, README | ✅ Distributionsweg |

## NICHT verwendete Apple-Marken / Badges

| Was | Warum nicht |
|---|---|
| „Works with Apple Home"-Badge | Erfordert separate Zertifizierung (MFi-Programm), die nur für Hardware gilt |
| Apple-Home-App-Icon (das bunte Haus) | geschütztes Asset, darf nicht als Inspiration für eigene Icons dienen |
| HomeKit-Logo | obsolet, Apple nutzt es selbst nicht mehr |

## Footer-Hinweis in App Store Listing

Am Ende der App-Description wird ein Disclaimer eingefügt:

> Apple Home, HomeKit, Apple TV, Siri Remote und iCloud sind Marken der Apple Inc.

Das ist Standard-Praxis bei jeder Drittanbieter-App, die Apple-Frameworks nutzt,
und beugt Markenrechtsbeanstandungen vor.

## Eigener Markenstatus „HomeDash"

- Name „HomeDash" ist nicht trivial markengeschützt (Stand Mai 2026, eigene
  Recherche auf [tmview.europa.eu](https://www.tmview.europa.eu) empfohlen).
- Apple verbietet in den Developer-Richtlinien, dass Drittanbieter-Apps die
  Wörter „iOS", „macOS", „watchOS", „tvOS", „HomeKit" oder „Siri" als
  vorderen Teil des App-Namens verwenden („My HomeKit App" → nicht ok).
  HomeDash ist davon nicht betroffen.

## Empfehlung vor Veröffentlichung

1. **EUIPO TMview Search** für „HomeDash" in Klassen 9 (Software) und 42
   (SaaS) durchführen — kostenlos.
2. Wenn auffallend ähnliche Marken existieren: Anwalt fragen oder Namen
   anpassen (z. B. „MarcelDash", „RoomBoard", „Lumio").
3. App-Store-Connect-Anmeldung als „HomeDash" einreichen — Apple prüft
   ebenfalls grob auf Namens-Konflikte und meldet es zurück, falls etwas
   Offensichtliches kollidiert.

## Bei Konflikt-Mail von Apple

Apple meldet sich gelegentlich mit „Your app uses terminology that may be
confused with Apple trademarks". Übliche Lösung:
- App-Description anpassen, Disclaimer-Hinweis stärker betonen
- Im Promo-Text „Apple Home" durch „your smart home" ersetzen
- Resubmit
