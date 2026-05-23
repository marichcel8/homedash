# Claude Code Prompt v2: tvOS HomeKit Dashboard "HomeDash"

> Verbesserung des Original-Prompts. Ziel: vollständig App-Store-veröffentlichungsreife native tvOS-App
> im aktuellen Apple-Home-Designsprache (iOS/tvOS 18+), nicht nur MVP.

---

## Was am Original-Prompt verbessert wurde

| Bereich | Original | V2 |
|---|---|---|
| Scope | V1 MVP (nur Power-Toggle) | Vollständig: Toggle + Brightness + Color Temp + Thermostat + Lock + Szenen + Favoriten + Multi-Home |
| Design | "Dunkles UI im tvOS-Stil" | Aktuelles Apple-Home-Design (Material-Glass aus, vollflächige Akzentfarbe an, Status-Texte wie Apple, 22pt Radius, akzentfarbige Icon-Bubble) |
| Release | Build muss laufen | App-Store-reif: Layered Icon, Top Shelf, Launch Screen, Privacy Manifest, Lokalisierung DE+EN, Submission Checklist |
| Concurrency | nicht spezifiziert | Swift 6 Strict, `@MainActor` Store, `nonisolated` Delegates, `async/await` Wrapper für HMCharacteristic |
| Projekt | "erstelle Projekt mit Struktur" | Komplette `.xcodeproj` (project.pbxproj, scheme, workspace) wird generiert |
| Architektur | MVVM-light | DesignSystem-Layer + HomeStore (Source of Truth) + leichte ViewModels nur in Detail-Sheets |
| Permission | "Permission anfordern" | Korrektes Handling inkl. tvOS-Eigenheit: Permission-Dialog erscheint erst nach `HMHomeManager`-Allokation; Restricted-Status explizit behandelt |
| Tests | implizit | Smoke-Build via `xcodebuild` Teil der Auslieferung |
| Constraints | "kein Force-Unwrap" | + keine `print()` in Release, keine String-Hardcodes (Localized), Accessibility-Labels, Dark+Light Mode |

---

## Kontext (unverändert + ergänzt)

- **Gerät:** Apple TV 4K (3. Gen), tvOS 17+
- **Hub:** Dieses Apple TV ist Home Hub
- **Dev-Account:** Apple Developer (bezahlt)
- **Toolchain:** Xcode 16+ auf macOS, paired Apple TV
- **Sprachstand:** SwiftUI vertraut, HomeKit neu
- **Wichtig:** tvOS-Simulator hat **kein HomeKit** → Test nur auf echter Hardware
- **Wichtig:** Permission-Prompt erscheint auf tvOS nur, wenn die App das `HMHomeManager` zum ersten Mal instanziiert – falls verweigert, muss der User in *Settings → Apps → HomeDash → HomeKit* manuell erlauben

---

## Funktionsumfang (vollständig, nicht MVP)

### Kernfunktionen
1. **HomeKit-Permission**: Anfordern, Status sauber handhaben (`.authorized` / `.restricted` / `.determined`). Restricted-Pfad mit Anleitung "Öffne Einstellungen → Apps → HomeDash → HomeKit aktivieren".
2. **Multi-Home-Support**: Picker oben rechts, falls > 1 Haus. Default = `primaryHome`.
3. **Räume**: Eine horizontale Sektion pro Raum, Sortierung nach Apple-Reihenfolge.
4. **Geräte-Tiles im Apple-Home-Stil**:
   - Aus = Material-Glass-Hintergrund, monochromes Icon
   - An = vollflächige Akzentfarbe (typ-abhängig), helles Icon
   - 280×180 pt Minimum, 22 pt Corner Radius
   - Icon-Bubble (Symbol mit kreisförmigem Hintergrund) wie in Apple Home iOS 18
   - Statuszeile unten: "An · 80 %", "Aus", "21 °C → 22 °C", "Verschlossen"
5. **Power-Toggle** bei Klick (für Lichter/Steckdosen/Lüfter/Schalter)
6. **Detail-Sheet bei Long-Press / Play-Pause-Button**:
   - Licht: Slider Helligkeit, optional Farbtemperatur, Power
   - Thermostat: Zieltemperatur-Stepper, Mode-Picker (Heat/Cool/Auto/Off), Ist-Temp
   - Schloss: Lock/Unlock-Button, Status
   - Steckdose: nur Power
7. **Szenen-Sektion**: oben über den Raum-Sektionen, horizontal scrollbar, Klick = Szene ausführen
8. **Favoriten-Sektion**: optional, falls Accessories als Favoriten markiert (über Apple Home gesetzt). Falls keine vorhanden → Sektion ausblenden
9. **Auto-Refresh**: `HMAccessoryDelegate` triggert UI-Update via `@Observable`
10. **Empty States**: Keine Häuser / Keine Geräte / Keine Berechtigung – jeweils sauber illustriert
11. **Pull-to-Refresh-Äquivalent**: Menu-Button auf Siri Remote → Daten neu laden

### tvOS-Polish
- Vollständige Focus-Engine-Unterstützung (alle Tiles `.focusable`, scale 1.08, weicher Schatten/Glow)
- `.animation(.spring(response: 0.3))` für Focus
- Akzent-Glow im Schatten passend zur Tile-Farbe (wenn An)
- Dunkler Hintergrund: tvOS-typischer Vertikal-Gradient (nicht pures #000)

### Accessibility / i18n
- Alle UI-Strings via `String(localized:)` aus DE + EN `.strings`
- VoiceOver-Labels und -Hints auf jedem Control
- Min Contrast WCAG AA

---

## Architektur

- **Swift 6** mit Strict Concurrency
- **`@Observable` Macro**, keine `@StateObject`/`@Published`
- **`@MainActor` HomeStore** als Single Source of Truth
- **`nonisolated` Delegate-Methoden**, die Updates per `Task { @MainActor in ... }` einspielen
- **Async/await Wrapper** für `HMCharacteristic.readValue` / `writeValue`
- **DesignSystem-Layer** mit Tokens (Colors, Typography, Dimensions, Materials)
- **Keine externen Dependencies**
- **Pure SwiftUI**, kein UIKit-Bridging

## Dateistruktur (verbindlich)

```
HomeDash/
├── HomeDashApp.swift                  # @main, HomeStore in Environment, AppearancePreference
├── Info.plist
├── HomeDash.entitlements              # com.apple.developer.homekit
├── PrivacyInfo.xcprivacy              # Privacy Manifest (keine Tracking-APIs)
├── Localization/
│   ├── de.lproj/Localizable.strings
│   └── en.lproj/Localizable.strings
├── Resources/
│   └── (Launch-Assets falls nötig)
├── Models/
│   ├── HomeStore.swift                # @MainActor @Observable, HMHomeManagerDelegate
│   ├── AccessoryDelegateBridge.swift  # nonisolated NSObject-Bridge zu HMAccessoryDelegate
│   ├── AccessoryKind.swift            # enum Kind { .light, .outlet, .thermostat, .lock, ... }
│   └── HMCharacteristic+Async.swift   # async/await Wrapper
├── Extensions/
│   ├── HMAccessory+Kind.swift         # primaryService, kind, accentColor, sfSymbol
│   ├── HMAccessory+State.swift        # isOn, brightness, currentTemperature, targetTemperature, isLocked
│   └── HMService+Helpers.swift        # findCharacteristic(_:)
├── DesignSystem/
│   ├── DesignTokens.swift             # Colors, Radii, Spacing, Typography
│   ├── TileStyle.swift                # ViewModifier für Apple-Home-Tile
│   └── Materials.swift                # Custom Background-Materials
├── Views/
│   ├── ContentView.swift              # Root-Router (Loading/Permission/Restricted/Empty/Dashboard)
│   ├── PermissionView.swift           # Erklärung + Hinweis auf Settings
│   ├── HomeDashboardView.swift        # Header + Scenes + Rooms
│   ├── HomePickerView.swift           # Multi-Home-Picker
│   ├── ScenesSection.swift            # Horizontale Szenen-Reihe
│   ├── RoomSection.swift              # Horizontale Sektion pro Raum
│   ├── EmptyStateView.swift           # Keine Häuser / keine Geräte
│   ├── Tiles/
│   │   ├── AccessoryTile.swift        # Apple-Home-Style Tile
│   │   ├── SceneTile.swift            # Szenen-Tile
│   │   └── TileShell.swift            # Wiederverwendbares Tile-Container-Layout
│   └── Detail/
│       ├── AccessoryDetailSheet.swift # Router je Kind
│       ├── LightDetailView.swift
│       ├── ThermostatDetailView.swift
│       └── LockDetailView.swift
└── Assets.xcassets/
    ├── AppIcon.brandassets/           # Layered tvOS Icon (Front/Middle/Back) + App Store + Top Shelf
    ├── LaunchImage.launchimage/
    └── AccentColor.colorset/
```

---

## Implementierungsdetails (verbindlich)

### `HomeStore`
- `@MainActor @Observable final class HomeStore`
- Hält: `manager: HMHomeManager`, `homes: [HMHome]`, `currentHome: HMHome?`, `authorizationStatus`
- Implementiert `HMHomeManagerDelegate`: `homeManagerDidUpdateHomes(_:)` → `currentHome = manager.primaryHome ?? manager.homes.first`
- Beobachtet Accessory-Änderungen über `AccessoryDelegateBridge`, der `nonisolated` Delegate-Calls auf `@MainActor` weiterleitet
- Public API:
  - `func toggle(_ accessory: HMAccessory) async`
  - `func setBrightness(_ accessory: HMAccessory, _ value: Int) async`
  - `func setColorTemperature(_ accessory: HMAccessory, _ kelvin: Int) async`
  - `func setTargetTemperature(_ accessory: HMAccessory, _ celsius: Double) async`
  - `func setLock(_ accessory: HMAccessory, locked: Bool) async`
  - `func run(_ scene: HMActionSet) async`
  - `func refresh() async` (re-bind delegates, force reload)

### `AccessoryTile`
- `.focusable(true)` + `@FocusState`
- Aus: `ultraThinMaterial`, weißer 60% Text, Icon weiß 90%
- An: Akzentfarbe vollflächig, weißer Text, Icon-Bubble white 24%
- Bei Fokus: `.scaleEffect(isFocused ? 1.08 : 1)`, Schatten `radius: 24` in Akzent oder `.black.opacity(0.35)`
- Lange Tap-Geste (Play-Pause) öffnet Detail-Sheet
- Single Tap: `await store.toggle(accessory)` (nur für togglebare Kinds)

### `AccessoryKind` (enum)
```
case light, outlet, thermostat, lock, fan, sensor, switchAccessory, valve, garageDoor, other
```
Mapping: `HMServiceType` → `Kind`. Jeder Kind hat: `sfSymbol`, `accentColor`, `defaultAction`.

### Akzentfarben (Apple-Home-nah)
- Light: `Color(red: 1.00, green: 0.84, blue: 0.40)` (warmes Gelb)
- Outlet: `Color(red: 0.38, green: 0.78, blue: 0.97)` (Apple Blau)
- Thermostat (Heat): `Color(red: 1.00, green: 0.58, blue: 0.36)` (Orange)
- Thermostat (Cool): `Color(red: 0.36, green: 0.72, blue: 1.00)` (Eis-Blau)
- Lock: `Color(red: 0.31, green: 0.78, blue: 0.47)` (Apple Grün)
- Fan: `Color(red: 0.68, green: 0.85, blue: 1.00)`
- Switch: `Color(red: 0.78, green: 0.78, blue: 0.81)` (Grau)
- Other: `Color(white: 0.65)`

### SF Symbol Mapping
- light → `lightbulb.fill` (aus: `lightbulb`)
- outlet → `poweroutlet.type.f.fill`
- thermostat → `thermometer.medium`
- lock → `lock.fill` / `lock.open.fill`
- fan → `fan.fill`
- sensor → `sensor.fill`
- switch → `light.beacon.max.fill`
- valve → `drop.fill`
- garageDoor → `door.garage.closed` / `door.garage.open`
- other → `app.dashed`

---

## Was Du (Claude) erwartet wird

1. Generiere **alle Dateien** inklusive Xcode-Projekt (`.xcodeproj/project.pbxproj`, scheme, workspace) – kein "manuell anlegen".
2. **Kompilierbar**, kein Pseudo-Code, keine TODOs.
3. **Strict Concurrency clean** unter Swift 6.
4. **Kommentare auf Deutsch**, sparsam – nur wo das *Warum* nicht offensichtlich ist.
5. **README.md** mit:
   - Build/Deploy auf Apple TV (Trust-Dialog erwähnen)
   - Manuelle Schritte in Xcode (Signing Team, Bundle ID Konflikt-Resolution, evtl. Capability)
   - App-Store-Submission-Checklist
   - Troubleshooting (Permission verweigert, keine Geräte angezeigt, Simulator funktioniert nicht)
6. Wenn etwas auf tvOS unmöglich ist (Camera Stream, Accessory Setup) → ehrlich sagen, nicht workaround.
7. Am Ende: präzise Liste der **wirklich** manuellen Schritte (Signing Team, Permission im tvOS aktivieren, App Store Connect Listing).
8. Smoke-Build mit `xcodebuild -scheme HomeDash -destination 'generic/platform=tvOS' build` ausführen und Output zeigen.

## Constraints / Don'ts

- Kein HomeKit-Setup-Code (Accessories hinzufügen / pairen) – tvOS unterstützt das nicht
- Kein Force-Unwrap (`!`) außer in `IBOutlet`-Style nicht-nullable Konstanten
- Keine hardcoded User-facing Strings (alles lokalisiert)
- Keine externen Dependencies
- Kein `print()` in Release-Pfaden – wenn Logging, dann `os.Logger`
- Kein UIKit
- Build auf echter Hardware lauffähig; Simulator-Pfad zeigt "Keine HomeKit auf Simulator"-Hinweis

## Liefer-Reihenfolge (sequentiell)

1. Projektstruktur + `.xcodeproj`
2. DesignSystem-Layer
3. Models (HomeStore, Bridge, Kind, Async Wrapper)
4. Extensions
5. Views (Root → Tiles → Detail)
6. Assets (Layered Icon, Top Shelf, Launch)
7. Localization
8. Info.plist + Entitlements + Privacy Manifest
9. README
10. `xcodebuild` Smoke-Test
