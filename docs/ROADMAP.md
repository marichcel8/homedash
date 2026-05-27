# HomeDash — Roadmap

Living document. Bumped jede Version. Geordnet nach realistischem
Auslieferungs-Zeithorizont; oben ist „nächste Iteration", unten ist
Vision-Wahnsinn.

---

## Aktueller Stand (1.0.x)

**Lese-/Schreib-Frontend für Apple Home auf tvOS** mit Tiles, Detail-Sheet,
Color-Picker, Universal-Device-Support, Lokalisierung (DE/EN), Error-Toast,
Offline-Indicator. Pure UI über bestehende HomeKit-APIs, keine externe
Network-Abhängigkeit, keine Analytics.

- **1.0.0** (released): Erste App-Store-Version
- **1.0.1** (released): Live-Updates bei Re-Pair (HMHomeDelegate teilweise),
  Error-Toast, Offline-Badge, Friendly-Error-Mapping
- **1.0.2** (in Arbeit): HMHomeDelegate-Bindings via @objc — Live-Updates
  für Home-Rename, Room-Rename, Accessory-Room-Wechsel, Szenen-Operationen

---

## v1.1.0 — „Mehr Substanz"
*Geschätzter Aufwand: 6–8 Wochen. Ziel: Features, die User von einem
„Apple Home Dashboard" auf TV erwarten und noch nicht da sind.*

| Feature | API/Begründung | Effort |
|---|---|---|
| 📹 **Kamera-Streams** | HMCameraProfile + AVPlayer. TV ist DER Bildschirm für Türklingel/Sicherheitskameras. Größtes funktionales Loch in v1.0 | 2–3 Wo |
| 🌡️ **Sensor-Übersicht** | Temperatur/Feuchtigkeit/Bewegung als eigene Sektion oben, nicht versteckt in Tiles | 1 Wo |
| 🔍 **Suche / Filter** | Siri-Remote-Tastatur → springt zum Gerät. Wichtig ab ~20 Geräten | 2–3 Tage |
| 🎯 **Top-Shelf-Widget** | Lieblings-Tiles auf tvOS-Startseite. Sehr Apple-TV-native | 1 Wo |
| 🏠 **Multi-Home Toggle in Navigation** | Statt nur Picker im Header — Switch zwischen Homes muss prominenter | 2 Tage |
| 🔧 **Auto-Reorder per Long-Press** | Eigene Tile-Reihenfolge pro Raum. Apple-Home-App kann's | 3–5 Tage |

**App-Store-Pitch**: „Live-Kamerastreams, Sensor-Übersicht und Top-Shelf-Widget"

---

## v1.2.0 — „Power User"
*Geschätzter Aufwand: 4–6 Wochen.*

| Feature | API | Effort |
|---|---|---|
| ⏰ **Automationen anzeigen/triggern** | HMTrigger-Familie (Event, Timer, Calendar, Location) | 2 Wo |
| 📊 **Sensor-History** | Lokales SQLite-Caching, Graph über Tag/Woche | 2 Wo |
| ⚡ **Energie-Monitoring** | Geräte mit HMServiceTypeOutlet + Energy-Characteristics | 1 Wo |
| 🎬 **Tile-Gruppen** | „Alle Lichter im Wohnzimmer" als eine Kachel | 1 Wo |
| 🎙️ **Shortcuts / App Intents** | „Hey Siri, HomeDash öffnen", Dashboard als Shortcut | 3 Tage |

---

## v1.3.0 — „Multi-Device"
*Geschätzter Aufwand: 2–3 Monate.*

| Feature | Effort |
|---|---|
| 📱 **iPhone-Companion-App** (gleiches Dashboard, Universal) | 6–8 Wo |
| ⌚ **Apple Watch Komplikation + Quick Actions** | 3–4 Wo |
| ☁️ **iCloud-Sync der Favoriten/Tile-Reihenfolge** | 1 Wo |

→ HomeDash wird zur Multi-Device-Suite.

---

## v2.0.0 — „Komplette Heim-Zentrale"
*Geschätzter Aufwand: 6–12 Monate. Major Re-Architektur.*

**Konzept**: Apple TV wird zum immer-sichtbaren Heim-Hub — wie Echo Show /
Google Hub, aber Apple-native und Privacy-first.

| Element | Was es ist |
|---|---|
| 🖼️ **Always-On Dashboard / Screensaver** | Wenn TV „aus" wäre, zeigt es dimmed Heim-Status als Bildschirmschoner |
| 🎨 **Custom Dashboards** | User baut Layouts: linke Hälfte Kameras, rechts Sensoren, unten Quick-Scenes |
| 🤖 **AI-Automation-Vorschläge** | „Du schaltest Licht jeden Tag um 18:00 ein. Automation erstellen?" |
| 🔌 **Plugin-System / Matter direct** | Geräte einbinden, die HomeKit (noch) nicht supportet — Matter direkt |
| 🌐 **Universal App** | tvOS + iOS + iPadOS + macOS + watchOS aus einem SwiftUI-Codebase |
| 🎙️ **Voice-First UI** | komplett ohne Remote bedienbar, alles Siri |
| 🎭 **Multi-User-Profile** | Pro HMUser eigene Tile-Auswahl/Layout |

---

## Monetarisierungs-Strategie

| Modell | Pro | Contra |
|---|---|---|
| Alles free Updates | Goodwill, Reviews bleiben gut | Keine Recurring-Revenue |
| **HomeDash Pro IAP** ($4.99 once) ab v1.1 | Realistisch, fair | Erst bei kritischer Mass sinnvoll |
| HomeDash+ Abo ($1.99/mo) ab v2.0 | Indie-Standard heute | Ärgert User die einmal gekauft haben |
| Pricing-Bump v2.0 (z. B. €2.99 → €9.99) | Reflektiert echten Mehrwert | Bestandskunden bekommen v2 gratis (Apple-Regel) |

**Empfehlung**: 1.x.0 alles kostenlos. **2.0.0 als neuer Major mit IAP**
für Pro-Features (Custom Dashboards, AI-Vorschläge, Matter-Plugin-Manager).

---

## Backlog (out-of-band Ideen, noch nicht zugeordnet)

- iCloud-Backup einzelner Custom-Dashboards (als Sharable Link)
- AirPlay-Empfänger-Integration: HomeDash zeigt auch was via AirPlay läuft
- Music-/Podcast-Sync mit aktivem Raum
- „Movie-Mode"-Quick-Action: Lichter dimmen + Rolläden runter + Sound-System an
- WatchOS-Komplikation für „aktueller Wohnzimmer-Status"
- Apple-TV-Audio-Routing über HomeKit-Lautsprecher
- Localisation: zusätzlich FR, ES, IT, JA, ZH
- TestFlight-Beta-Programm mit Power-User-Feedback-Form

---

*Pflegt: Marcel + Claude. Bei jedem Release-Tag eine Sektion aktualisieren.*
