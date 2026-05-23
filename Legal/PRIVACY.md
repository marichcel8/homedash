# Datenschutzerklärung – HomeDash

**Stand:** 23. Mai 2026
**Verantwortlich:** Marcel Sön — marsoen@outlook.de

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

Da HomeDash keine Daten erhebt oder verarbeitet, die mich erreichen, gibt es
keine personenbezogenen Daten, die ich auskunftspflichtig, korrigier- oder
löschpflichtig vorhalten könnte. Bei Fragen wende dich an marsoen@outlook.de.

## 9. Änderungen dieser Erklärung

Bei wesentlichen Änderungen wird die neue Version mit Datum oben veröffentlicht.
Die jeweils aktuelle Fassung ist immer unter der von dir verwendeten Listing-URL
abrufbar.

## 10. Kontakt

Marcel Sön
E-Mail: marsoen@outlook.de
