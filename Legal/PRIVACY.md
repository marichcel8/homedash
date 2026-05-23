# Datenschutzerklärung – HomeDash

**Stand:** 23. Mai 2026
**Verantwortlicher:** Marcel Söndenaa-Defourny, Muldentalstraße 100, 04288 Leipzig, Deutschland — marsoen@outlook.de

HomeDash ist eine native tvOS-App, die deine Apple-Home-Geräte als Dashboard auf
dem Apple TV anzeigt und steuerbar macht. Diese Datenschutzerklärung beschreibt,
welche Daten die App verarbeitet.

## Kurzfassung in einem Satz

**HomeDash verarbeitet ausschließlich lokal auf deinem Apple TV. Es werden keine
Daten an mich, Apple oder Dritte gesendet, gesammelt oder verkauft.**

## 1. Welche Daten werden verarbeitet?

| Datenart | Wo | Zweck |
|---|---|---|
| Namen deiner Räume, Geräte, Szenen | nur lokal auf dem Apple TV | Anzeige im Dashboard |
| Aktueller Status der Geräte (an/aus, Helligkeit, Position, Temperatur) | nur lokal | Echtzeit-Anzeige und -Steuerung |
| Deine selbst angepinnten Favoriten | `UserDefaults` lokal auf dem Apple TV | Damit deine Favoriten-Sektion zwischen App-Starts erhalten bleibt |

## 2. Welche Daten werden NICHT verarbeitet?

- Kein Tracking, keine Analytics, keine Werbung
- Keine Crash-Reports an externe Dienste
- Keine Cloud-Synchronisation durch HomeDash
- Keine Verknüpfung mit deiner Apple-ID jenseits von Apples eigener Apple-Home-Anbindung
- Keine personenbezogenen Daten (Name, Mail, Standort)

## 3. Apple Home / HomeKit-Framework

HomeDash nutzt Apples öffentliches HomeKit-Framework, um lesend und schreibend
auf dein konfiguriertes Zuhause zuzugreifen. Die Daten kommen direkt aus deinem
iCloud-Account auf dem Apple TV. HomeDash sendet keine HomeKit-Daten nach außen,
sammelt sie nicht und gibt sie nicht an Dritte weiter.

Für die Apple-Home-Datenverarbeitung selbst gilt Apples Datenschutzerklärung:
<https://www.apple.com/legal/privacy/de-ww/>

## 4. Netzwerkverbindungen

HomeDash öffnet **keine** ausgehenden Netzwerkverbindungen. Die Kommunikation
mit deinen Apple-Home-Geräten läuft komplett über das HomeKit-Protokoll im
lokalen Netz, gesteuert vom System.

## 5. Berechtigungen

HomeDash verwendet folgende System-Berechtigung:

- **Apple Home / HomeKit-Zugriff**: zum Lesen und Steuern deiner Geräte

Du kannst die Berechtigung jederzeit auf der Apple TV entziehen:
*Einstellungen → Apps → HomeDash → Apple Home*.

## 6. Required-Reason-API-Nutzung

Die App nutzt `UserDefaults` für deine lokal gespeicherten Favoriten. Eingetragen
im `PrivacyInfo.xcprivacy`-Manifest unter dem Reason-Code **CA92.1**
(„Access info from same app, per documentation").

## 7. Speicherdauer

Lokale Favoriten bleiben gespeichert, solange du HomeDash installiert hast.
Beim Deinstallieren löscht tvOS alle App-Daten automatisch.

## 8. Deine Rechte (DSGVO)

Da HomeDash keine personenbezogenen Daten erhebt oder an mich übermittelt, gibt
es de facto keine bei mir vorgehaltenen Daten. Dir stehen aus Art. 13 ff. DSGVO
dennoch grundsätzlich die folgenden Rechte zu:

- **Auskunft** (Art. 15) — welche Daten ggf. verarbeitet werden
- **Berichtigung** (Art. 16) — unrichtige Daten korrigieren lassen
- **Löschung** (Art. 17) — „Recht auf Vergessenwerden"
- **Einschränkung der Verarbeitung** (Art. 18)
- **Datenübertragbarkeit** (Art. 20)
- **Widerspruch** gegen Verarbeitung (Art. 21)
- **Beschwerde bei einer Aufsichtsbehörde** (Art. 77) — für mich zuständig:
  Sächsischer Datenschutzbeauftragter,
  <https://www.saechsdsb.de>

Bei Fragen wende dich an marsoen@outlook.de.

## 9. Änderungen dieser Erklärung

Bei wesentlichen Änderungen wird die neue Version mit Datum oben veröffentlicht.
Die jeweils aktuelle Fassung ist immer unter der von dir verwendeten Listing-URL
abrufbar.

## 10. Kontakt

Marcel Söndenaa-Defourny
Muldentalstraße 100
04288 Leipzig (Leipzig-Liebertwolkwitz)
Deutschland
E-Mail: marsoen@outlook.de
