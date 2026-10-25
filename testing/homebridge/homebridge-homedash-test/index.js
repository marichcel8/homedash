// Virtuelle Sensoren für HomeDash-UI-Tests. Werte fest, damit Tests stabil sind.
// Werte ändern: http://127.0.0.1:18581/set?name=<Name>&value=<Zahl>
const http = require('http');

const SENSORS = [
  { name: 'Test Temperatur', service: 'TemperatureSensor', char: 'CurrentTemperature', value: 21.5 },
  { name: 'Test Luftfeuchte', service: 'HumiditySensor', char: 'CurrentRelativeHumidity', value: 48 },
  { name: 'Test Bewegung', service: 'MotionSensor', char: 'MotionDetected', value: true },
  { name: 'Test Fenster', service: 'ContactSensor', char: 'ContactSensorState', value: 1 },
];

module.exports = (api) => {
  const { Service, Characteristic } = api.hap;

  class TestSensor {
    constructor(def) {
      this.name = def.name;
      this.def = def;
      this.info = new Service.AccessoryInformation()
        .setCharacteristic(Characteristic.Manufacturer, 'HomeDash Test')
        .setCharacteristic(Characteristic.Model, def.service)
        .setCharacteristic(Characteristic.SerialNumber, 'HDT-' + def.service);
      this.service = new Service[def.service](def.name);
      this.characteristic = this.service.getCharacteristic(Characteristic[def.char]);
      this.characteristic.onGet(() => this.def.value);
    }
    set(value) {
      this.def.value = value;
      this.characteristic.updateValue(value);
    }
    getServices() { return [this.info, this.service]; }
  }

  class Platform {
    constructor(log) { this.log = log; }
    accessories(callback) {
      const sensors = SENSORS.map((d) => new TestSensor(d));
      http.createServer((req, res) => {
        const url = new URL(req.url, 'http://x');
        const sensor = sensors.find((s) => s.name === url.searchParams.get('name'));
        if (url.pathname !== '/set' || !sensor) { res.writeHead(404); return res.end('unbekannt\n'); }
        const raw = url.searchParams.get('value');
        const value = typeof sensor.def.value === 'boolean' ? raw === 'true' || raw === '1' : Number(raw);
        sensor.set(value);
        this.log.info(`${sensor.name} = ${value}`);
        res.end('ok\n');
      }).listen(18581, '127.0.0.1');
      callback(sensors);
    }
  }

  api.registerPlatform('homebridge-homedash-test', 'HomeDashTestSensors', Platform);
};
