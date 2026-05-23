# HomeDash

> Dashboard für **Apple Home** auf dem **Apple TV** – native tvOS-App in SwiftUI.

Du bekommst alle Räume und Geräte deines Apple-Home-Setups direkt auf dem
Fernseher: Lichter dimmen/färben, Thermostate stellen, Schlösser ver-/entsperren,
Lüfter regeln, Szenen ausführen — bedient mit der Siri Remote.

## Features

- **Universelle Geräteunterstützung**: Lichter (RGB + Farbtemperatur), Steckdosen,
  Schalter, Lüfter, Luftreiniger, Heizlüfter, Klimaanlagen, Be-/Entfeuchter,
  Thermostate, Schlösser, Türen, Garagentore, Rollläden, Ventile, Sprinkler,
  Duschen, Lautsprecher, Türklingeln, alle Sensor-Typen
- **Smart-Detection** via `HMAccessoryCategory` + Capability-Guess für fehlerhaft
  kategorisierte Geräte (z. B. Lüfter, der als Switch registriert ist)
- **Universal-Detail-Sheet**: rendert dynamisch genau die Cards, die für das
  Gerät passen — keine fehlenden Controls bei seltenen Gerätetypen
- **Echte Apple-Home-Optik**: Material-Glass für inaktive Tiles, vollflächige
  Akzentfarbe für aktive, ein-Outline-Focus
- **Light- und Dark-Mode adaptiv** (folgt der tvOS-Einstellung)
- **Lokale Favoriten** mit Pin-Funktion (UserDefaults)
- **Multi-Home-Support** mit Picker
- **DE + EN** Lokalisierung
- **100 % lokal**, kein Tracking, keine Cloud, keine Network-Calls außer HomeKit

## Voraussetzungen

| Tool | Version |
|---|---|
| macOS | 14+ |
| Xcode | 16+ (getestet mit 26) |
| Apple TV | HD oder 4K, **tvOS 17 oder neuer** |
| Apple-Developer-Account | aktiv ($99/Jahr für App Store) |
| HomeKit-Setup | mindestens ein Apple Home auf iPhone/iPad konfiguriert |

## Projektstruktur

```
HomeDash/
├── HomeDashApp.swift                  # @main, Stores via Environment
├── Info.plist
├── HomeDash.entitlements              # com.apple.developer.homekit
├── PrivacyInfo.xcprivacy              # Privacy Manifest
├── Localization/{de,en}.lproj/        # Localizable.strings
├── Models/
│   ├── HomeStore.swift                # @MainActor @Observable, HMHomeManagerDelegate
│   ├── AccessoryKind.swift            # Category- + ServiceType-Detection
│   └── FavoritesStore.swift           # UserDefaults-basierte Favoriten
├── Extensions/                        # HMAccessory-Helper
├── DesignSystem/
│   ├── DesignTokens.swift             # Maße, Typo, AppBackground
│   ├── TileStyle.swift                # Apple-Home-Tile mit Outline-Focus
│   ├── FocusOutline.swift             # Universal-Focus-Modifier
│   ├── FocusableTap.swift             # tap-statt-Button (killt tvOS-Card-Halo)
│   ├── AccessoryPalette.swift         # Pro-Kategorie-Farben
│   └── TVSliderControl.swift          # tvOS-Slider-Ersatz (kein nativer auf TV)
└── Views/
    ├── ContentView.swift              # Root-Router
    ├── PermissionView.swift
    ├── HomeDashboardView.swift
    ├── HomePickerView.swift
    ├── ScenesSection.swift
    ├── FavoritesSection.swift
    ├── RoomSection.swift
    ├── EmptyStateView.swift
    ├── Tiles/                         # AccessoryTile, SceneTile
    └── Detail/
        ├── AccessoryDetailSheet.swift # Universal-Detail mit Capability-Cards
        ├── ColorPickerGrid.swift      # 16×7 Hue-/Saturation-Raster
        └── DetailCards.swift          # alle Capability-Cards (Power, Brightness, ...)

docs/                                  # GitHub Pages Landing + Privacy + Support
Legal/                                 # Markdown-Versionen aller Legal-Dokumente
scripts/                               # Build- und Asset-Generatoren
```

## Build auf dem Apple TV

### Erstmaliges Setup (5 Min)

```bash
open "HomeDash.xcodeproj"
```

1. Xcode → **Settings → Accounts** → falls noch nicht da: deine Apple-ID hinzufügen
2. Target `HomeDash` → **Signing & Capabilities** → Team auswählen
3. [developer.apple.com](https://developer.apple.com/account/resources/identifiers) → App-ID `de.marcel.homedash` mit HomeKit-Capability anlegen
4. Apple TV pairen: Window → **Devices and Simulators** → Apple TV anwählen → Pair → PIN eingeben
5. Run-Destination in der Toolbar = dein Apple TV → **⌘R**
6. Auf Apple TV: **Einstellungen → Apps → HomeDash → Apple Home** auf An

### Folgende Builds

Einfach **⌘R** in Xcode.

## Veröffentlichung im App Store

Siehe `LAUNCH.md` – Schritt-für-Schritt-Checkliste von „Code fertig" bis „App
Store live".

Kurz: Archive bauen, in App Store Connect hochladen, Listing aus
`Legal/APPSTORE_LISTING.md` reinkopieren, Review Notes aus
`Legal/APPSTORE_REVIEW_NOTES.md`, Privacy-URL + Support-URL auf GitHub-Pages
verweisen (siehe `docs/`).

```bash
./scripts/archive.sh   # baut Release-Archive für Distribution
```

## tvOS-Einschränkungen, die du kennen solltest

| Limit | Wirkung in HomeDash |
|---|---|
| Kein Apple-Home-Setup-Flow auf tvOS | Geräte werden via Home-App auf iPhone/iPad gepairt |
| Kein modaler Permission-Prompt | App leitet User in Settings → Apps → HomeDash → Apple Home |
| Kein `Slider` in SwiftUI auf tvOS | Eigener `TVSliderControl` mit ±-Buttons |
| Kein HomeKit im Simulator | Echte Apple TV ist Pflicht zum Testen |
| Live-Kamera-Streams | für v1.x noch nicht implementiert (siehe Roadmap) |
| Adaptive Lighting | privates API, nicht für Drittanbieter |

## Lizenz & Rechtliches

Quellcode ist dein eigener — keine externen Dependencies.

Apple Home, HomeKit, Apple TV, iCloud, Siri Remote sind eingetragene Marken
der Apple Inc. HomeDash ist eine unabhängige Anwendung und steht in keinerlei
Verbindung zu Apple Inc.

Datenschutz: [Legal/PRIVACY.md](Legal/PRIVACY.md) · Support:
[Legal/SUPPORT.md](Legal/SUPPORT.md) · Impressum: [Legal/IMPRINT.md](Legal/IMPRINT.md)

---

**Kontakt:** marsoen@outlook.de
