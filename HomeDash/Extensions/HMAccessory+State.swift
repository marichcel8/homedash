import HomeKit
import SwiftUI

/// UI-Aggregator über den aktuellen Zustand eines HMAccessory.
extension HMAccessory {
    // MARK: - Power
    /// "An"-Zustand: PowerState (Bool) bevorzugt, fällt auf Active (Int 0/1) zurück.
    var isOn: Bool {
        if let v = firstCharacteristic(HMCharacteristicTypePowerState)?.value as? Bool { return v }
        if let v = firstCharacteristic(HMCharacteristicTypeActive)?.value as? Int { return v != 0 }
        return false
    }

    var hasTogglableSwitch: Bool {
        firstCharacteristic(HMCharacteristicTypePowerState)?.isWritable == true
        || firstCharacteristic(HMCharacteristicTypeActive)?.isWritable == true
    }

    // MARK: - Capability-Checks (für Universal-Detail-View)
    var supportsBrightness: Bool {
        firstCharacteristic(HMCharacteristicTypeBrightness)?.isWritable == true
    }

    var supportsHueSaturation: Bool {
        firstCharacteristic(HMCharacteristicTypeHue)?.isWritable == true
        && firstCharacteristic(HMCharacteristicTypeSaturation)?.isWritable == true
    }

    var supportsColorTemperature: Bool {
        firstCharacteristic(HMCharacteristicTypeColorTemperature)?.isWritable == true
    }

    var supportsRotationSpeed: Bool {
        firstCharacteristic(HMCharacteristicTypeRotationSpeed)?.isWritable == true
    }

    var supportsTargetPosition: Bool {
        firstCharacteristic(HMCharacteristicTypeTargetPosition)?.isWritable == true
    }

    var supportsTargetTemperature: Bool {
        firstCharacteristic(HMCharacteristicTypeTargetTemperature)?.isWritable == true
    }

    var supportsHeatingCoolingMode: Bool {
        firstCharacteristic(HMCharacteristicTypeTargetHeatingCooling)?.isWritable == true
    }

    var supportsLock: Bool {
        firstCharacteristic(HMCharacteristicTypeTargetLockMechanismState)?.isWritable == true
    }

    var supportsVolume: Bool {
        firstCharacteristic(HMCharacteristicTypeVolume)?.isWritable == true
    }

    var supportsTargetHumidity: Bool {
        firstCharacteristic(HMCharacteristicTypeTargetRelativeHumidity)?.isWritable == true
    }

    // MARK: - Werte-Reader
    var brightness: Int? {
        firstCharacteristic(HMCharacteristicTypeBrightness)?.value as? Int
    }

    var currentTemperature: Double? {
        firstCharacteristic(HMCharacteristicTypeCurrentTemperature)?.value as? Double
    }

    var targetTemperature: Double? {
        firstCharacteristic(HMCharacteristicTypeTargetTemperature)?.value as? Double
    }

    var heatingCoolingMode: Int? {
        firstCharacteristic(HMCharacteristicTypeTargetHeatingCooling)?.value as? Int
    }

    var currentHeatingCoolingMode: Int? {
        firstCharacteristic(HMCharacteristicTypeCurrentHeatingCooling)?.value as? Int
    }

    var lockState: Int? {
        firstCharacteristic(HMCharacteristicTypeCurrentLockMechanismState)?.value as? Int
    }

    var isLocked: Bool? {
        guard let state = lockState else { return nil }
        return state == HMCharacteristicValueLockMechanismState.secured.rawValue
    }

    var doorPosition: Int? {
        firstCharacteristic(HMCharacteristicTypeCurrentPosition)?.value as? Int
    }

    var fanRotationSpeed: Double? {
        firstCharacteristic(HMCharacteristicTypeRotationSpeed)?.value as? Double
    }

    var batteryLevel: Int? {
        firstCharacteristic(HMCharacteristicTypeBatteryLevel)?.value as? Int
    }

    var currentHumidity: Double? {
        firstCharacteristic(HMCharacteristicTypeCurrentRelativeHumidity)?.value as? Double
    }

    var targetHumidity: Double? {
        firstCharacteristic(HMCharacteristicTypeTargetRelativeHumidity)?.value as? Double
    }

    var volume: Int? {
        firstCharacteristic(HMCharacteristicTypeVolume)?.value as? Int
    }

    // MARK: - Tile-„An"-Begriff
    /// Übergeordneter „Active"-Begriff für die Tile-Färbung.
    /// Default: jedes Gerät mit einem Schalter (PowerState/Active) ist „aktiv",
    /// wenn `isOn` true ist. Spezialfälle wie Schloss/Tür/Sensoren override.
    var isActiveForTile: Bool {
        switch kind {
        case .lock:
            return isLocked == false
        case .garage, .door:
            return (firstCharacteristic(HMCharacteristicTypeCurrentDoorState)?.value as? Int)
                != HMCharacteristicValueDoorState.closed.rawValue
        case .windowCovering, .window:
            return (doorPosition ?? 0) > 0
        case .motionSensor:
            return (firstCharacteristic(HMCharacteristicTypeMotionDetected)?.value as? Bool) == true
        case .occupancySensor:
            return (firstCharacteristic(HMCharacteristicTypeOccupancyDetected)?.value as? Bool) == true
        case .contactSensor:
            return (firstCharacteristic(HMCharacteristicTypeContactState)?.value as? Int) != 0
        case .leakSensor:
            return (firstCharacteristic(HMCharacteristicTypeLeakDetected)?.value as? Int) == 1
        case .smokeSensor:
            return (firstCharacteristic(HMCharacteristicTypeSmokeDetected)?.value as? Int) == 1
        case .carbonMonoxideSensor:
            return (firstCharacteristic(HMCharacteristicTypeCarbonMonoxideDetected)?.value as? Int) == 1
        case .carbonDioxideSensor:
            return (firstCharacteristic(HMCharacteristicTypeCarbonDioxideDetected)?.value as? Int) == 1
        case .securitySystem:
            return (firstCharacteristic(HMCharacteristicTypeCurrentSecuritySystemState)?.value as? Int) != 3
        case .thermostat:
            if let mode = currentHeatingCoolingMode { return mode != 0 }
            return false
        case .humiditySensor, .lightSensor, .temperatureSensor,
             .airQualitySensor, .camera, .bridge, .rangeExtender,
             .videoDoorbell:
            return false
        default:
            // Alle anderen Kategorien (Licht, Steckdose, Lüfter, Switch,
            // Air Purifier, Heater, AC, Humidifier, Sprinkler, Speaker,
            // TV, ShowerHead, Faucet, Valve, Other-with-switch, ...).
            // Speed wird NICHT als „aktiv" interpretiert – manche Geräte
            // behalten den Speed-Wert auch im Aus-Zustand.
            return isOn
        }
    }

    /// Akzentfarbe abhängig von Kind und Zustand.
    var accentColor: Color {
        switch kind {
        case .thermostat, .airHeater, .airConditioner:
            let mode = heatingCoolingMode ?? currentHeatingCoolingMode ?? 1
            if mode == 2 { return AccessoryPalette.cooling }
            return AccessoryPalette.heating
        case .lock:
            return isLocked == true ? AccessoryPalette.lockSecured : AccessoryPalette.lockOpen
        case .other:
            // Generisches togglebares Gerät -> blau wie Steckdose,
            // sonst neutral grau.
            return hasTogglableSwitch ? AccessoryPalette.outlet : AccessoryPalette.neutral
        default:
            return kind.accent
        }
    }

    var sfSymbol: String {
        isActiveForTile ? kind.sfSymbolOn : kind.sfSymbolOff
    }

    /// Lokalisierter Statustext für das Tile.
    func localizedStatus() -> String {
        switch kind {
        case .light:
            if isOn, let b = brightness, b > 0 {
                return String(format: NSLocalizedString("status.onWithLevel %@", comment: ""), "\(b)")
            }
            return NSLocalizedString(isOn ? "status.on" : "status.off", comment: "")

        case .outlet, .switchAccessory, .programmableSwitch,
             .speaker, .television, .valve, .sprinkler,
             .showerHead, .faucet, .airHumidifier, .airDehumidifier,
             .airPurifier, .airConditioner, .airHeater:
            // Wichtig: nur Speed zeigen, wenn das Gerät auch wirklich AN ist.
            // Viele Geräte behalten den Speed-Wert auch im Aus-Zustand.
            if isOn, let speed = fanRotationSpeed, speed > 0 {
                return String(format: NSLocalizedString("status.onWithLevel %@", comment: ""),
                              "\(Int(round(speed)))")
            }
            return NSLocalizedString(isOn ? "status.on" : "status.off", comment: "")

        case .fan:
            if isOn, let speed = fanRotationSpeed, speed > 0 {
                return String(format: NSLocalizedString("status.onWithLevel %@", comment: ""),
                              "\(Int(round(speed)))")
            }
            return NSLocalizedString(isOn ? "status.on" : "status.off", comment: "")

        case .lock:
            return NSLocalizedString(isLocked == true ? "status.locked" : "status.unlocked", comment: "")

        case .thermostat:
            let mode = currentHeatingCoolingMode ?? 0
            let temp = targetTemperature.map { Int(round($0)) } ?? Int(round(currentTemperature ?? 0))
            switch mode {
            case 1: return String(format: NSLocalizedString("status.heating %@", comment: ""), "\(temp)")
            case 2: return String(format: NSLocalizedString("status.cooling %@", comment: ""), "\(temp)")
            default: return String(format: NSLocalizedString("status.temperature %@", comment: ""), "\(Int(round(currentTemperature ?? Double(temp))))")
            }

        case .temperatureSensor:
            let t = Int(round(currentTemperature ?? 0))
            return String(format: NSLocalizedString("status.temperature %@", comment: ""), "\(t)")

        case .humiditySensor:
            if let h = currentHumidity { return "\(Int(round(h))) %" }
            return "—"

        case .garage, .door:
            let raw = firstCharacteristic(HMCharacteristicTypeCurrentDoorState)?.value as? Int ?? 1
            let state = HMCharacteristicValueDoorState(rawValue: raw)
            switch state {
            case .open: return NSLocalizedString("status.open", comment: "")
            case .closed: return NSLocalizedString("status.closed", comment: "")
            case .opening: return NSLocalizedString("status.opening", comment: "")
            case .closing: return NSLocalizedString("status.closing", comment: "")
            default: return NSLocalizedString("status.closed", comment: "")
            }

        case .windowCovering, .window:
            let pos = doorPosition ?? 0
            return "\(pos) %"

        case .motionSensor, .occupancySensor:
            return NSLocalizedString(isActiveForTile ? "status.detected" : "status.idle", comment: "")

        case .contactSensor:
            return NSLocalizedString(isActiveForTile ? "status.open" : "status.closed", comment: "")

        case .leakSensor, .smokeSensor, .carbonMonoxideSensor, .carbonDioxideSensor:
            return NSLocalizedString(isActiveForTile ? "status.detected" : "status.idle", comment: "")

        case .lightSensor:
            if let lux = firstCharacteristic(HMCharacteristicTypeCurrentLightLevel)?.value as? Double {
                return "\(Int(round(lux))) lx"
            }
            return "—"

        case .videoDoorbell:
            return ""

        case .airQualitySensor, .securitySystem, .camera,
             .bridge, .rangeExtender, .other:
            return isReachable ? "" : NSLocalizedString("status.notResponding", comment: "")
        }
    }
}
