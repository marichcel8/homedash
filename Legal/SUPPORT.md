# HomeDash – Support

HomeDash ist eine native tvOS-App, mit der du deine Apple-Home-Geräte direkt
vom Apple TV aus steuerst.

## Häufige Fragen

### Ich sehe „Zugriff auf dein Zuhause" als Dauerschleife

Apple TV verlangt die Berechtigung für Apple Home in den Systemeinstellungen.
1. Apple TV → **Einstellungen → Apps → HomeDash**
2. **Apple Home** auf „An" stellen
3. HomeDash neu öffnen

### Es erscheint „Kein Zuhause gefunden"

Apple TV muss mit derselben iCloud-ID angemeldet sein, unter der das Apple Home
auf deinem iPhone/iPad eingerichtet ist.
1. Apple TV → **Einstellungen → Benutzer und Accounts** prüfen
2. Wenn Account stimmt: in der Home-App auf iPhone/iPad sicherstellen, dass
   mindestens ein Zuhause existiert

### Mein Gerät wird angezeigt, aber Toggle macht nichts

- Apple TV muss im selben WLAN sein wie das Accessory
- In der Home-App auf dem iPhone testen, ob das Gerät dort reagiert
- Wenn nicht: Accessory ist offline (Stromversorgung / WLAN prüfen)

### Mein Lüfter / meine Steckdose wird mit falschem Symbol angezeigt

HomeKit kategorisiert Geräte über die `HMAccessoryCategory`. Manche Hersteller
setzen die Kategorie nicht korrekt, sodass z. B. ein Lüfter als „Switch"
auftaucht. HomeDash erkennt das anhand der vorhandenen Eigenschaften (z. B.
Drehzahl) und korrigiert es automatisch. Falls trotzdem ein falsches Symbol
erscheint, schick mir bitte Modell + Hersteller per Mail.

### Wo sehe ich Live-Bilder meiner Kamera?

Aktuell zeigt HomeDash für Kameras nur Symbol und Status. Live-Streams sind
für eine spätere Version geplant.

### Wie pinne ich ein Gerät als Favorit?

1. Geräte-Tile fokussieren
2. Select-Taste auf der Siri Remote **lang gedrückt halten** (~0,5 s)
3. Im Detail-Sheet oben den **⭐-Stern** anklicken

Favoriten erscheinen oben auf dem Dashboard.

### Hat die App Adaptive Lighting?

Nein. Apple stellt das API für „Adaptive Lighting" Drittanbietern nicht zur
Verfügung. Diese Funktion bleibt der Apple-Home-App auf iPhone/iPad vorbehalten.

### Wo speichert HomeDash meine Daten?

Ausschließlich lokal auf dem Apple TV (`UserDefaults` für deine Favoriten).
Keine Cloud, kein externer Server, kein Tracking. Details in der
[Datenschutzerklärung](PRIVACY.md).

## Kontakt

E-Mail: marsoen@outlook.de
