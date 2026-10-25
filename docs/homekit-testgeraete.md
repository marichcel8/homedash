# Virtuelle HomeKit-Testgeräte

Damit Sensor-Übersicht und Kamera-Livebild auf dem Apple TV echt getestet
werden können, läuft auf dem Mac eine Homebridge-Bridge mit festen Testwerten.
Kostenlos, nur im lokalen Netz.

| Gerät | Dienst | Wert |
|---|---|---|
| Test Temperatur | TemperatureSensor | 21,5 °C |
| Test Luftfeuchte | HumiditySensor | 48 % |
| Test Bewegung | MotionSensor | Bewegung erkannt |
| Test Fenster | ContactSensor | offen |
| Test Kamera | Kamera (homebridge-camera-ffmpeg) | ffmpeg-Testbild `testsrc2`, 720p |

Die Sensoren kommen aus dem kleinen Plugin in
`testing/homebridge/homebridge-homedash-test/`. Werte lassen sich zur Laufzeit
ändern: `curl 'http://127.0.0.1:18581/set?name=Test%20Bewegung&value=0'`.

## Einrichten (einmalig)

```sh
mkdir -p ~/homebridge-test/storage ~/homebridge-test/plugins && cd ~/homebridge-test
npm init -y && npm install homebridge@2.4.0 homebridge-camera-ffmpeg@3.1.4
cp -R <repo>/testing/homebridge/homebridge-homedash-test plugins/
ln -sfn ../plugins/homebridge-homedash-test node_modules/homebridge-homedash-test
cp <repo>/testing/homebridge/config.example.json storage/config.json
# in storage/config.json eine zufällige MAC (username) und PIN eintragen
<repo>/testing/homebridge/start.sh
```

Im Log steht ein QR-Code und die PIN. In der Home-App auf dem iPhone
„Gerät hinzufügen“, Code scannen, „nicht zertifiziert“ bestätigen, alles in
einen Raum (z. B. „Test“) legen. Die Kopplung liegt danach in
`~/homebridge-test/storage/persist/`; die Bridge muss zum Testen laufen.

## Tests

`HomeDashUITests.testSensorOverviewShowsAllSensorKinds` und
`HomeDashCameraUITests` brauchen die gekoppelte Bridge, ohne sie werden sie
übersprungen.

Auf dem Apple TV bauen (Xcode ohne angemeldeten Account nutzt die lokalen
Team-Profile von 3PXX8LS2JZ):

```sh
xcodebuild test -project HomeDash.xcodeproj -scheme HomeDash \
  -destination 'id=<Apple-TV-UDID>' DEVELOPMENT_TEAM=3PXX8LS2JZ
```
