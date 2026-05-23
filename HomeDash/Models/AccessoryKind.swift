import HomeKit
import SwiftUI

/// Vollständige Kategorisierung aller Accessory-Typen, die HomeKit kennt.
///
/// Detection erfolgt mehrstufig:
/// 1. **`HMAccessoryCategory`** (Apples eigene, robuste Klassifizierung) zuerst
/// 2. Dann **`HMServiceType`** als Fallback (z. B. für DIY-Hardware ohne Kategorie)
/// 3. Zuletzt `.other` mit generischem Icon
enum AccessoryKind: Equatable {
    // Beleuchtung
    case light

    // Steckdose / Schalter
    case outlet
    case switchAccessory
    case programmableSwitch

    // Klima
    case fan
    case airPurifier
    case airHeater
    case airConditioner
    case airHumidifier
    case airDehumidifier
    case thermostat
    case showerHead

    // Sensoren
    case temperatureSensor
    case humiditySensor
    case lightSensor
    case motionSensor
    case occupancySensor
    case contactSensor
    case leakSensor
    case smokeSensor
    case carbonMonoxideSensor
    case carbonDioxideSensor
    case airQualitySensor
    case rangeExtender

    // Schloss / Tür / Fenster
    case lock
    case door
    case garage
    case window
    case windowCovering
    case videoDoorbell

    // Sicherheit
    case securitySystem
    case camera

    // Wasser
    case valve
    case sprinkler
    case faucet

    // Audio/Video
    case speaker
    case television

    // Sonstiges
    case bridge
    case other

    // MARK: - Detection (Category first, ServiceType second, Capability-Smart third)

    static func detect(_ accessory: HMAccessory) -> AccessoryKind {
        // 1. Apples offizielle Kategorie zuerst
        if let k = from(category: accessory.category.categoryType) {
            return refine(k, for: accessory)
        }
        // 2. Service-Typ als Fallback
        if let primary = accessory.primaryUsefulService {
            let serviceKind = from(serviceType: primary.serviceType)
            return refine(serviceKind, for: accessory)
        }
        // 3. Capability-Smart-Guess (z. B. DIY-Hardware ohne Kategorie)
        return capabilityGuess(for: accessory)
    }

    /// Korrigiert die Kategorie anhand vorhandener Characteristics:
    /// - Switch/Outlet/Other mit `RotationSpeed` ist faktisch ein Lüfter
    /// - Switch/Outlet mit `Brightness` ist faktisch ein dimmbares Licht
    /// (manche Geräte sind in HomeKit falsch kategorisiert)
    private static func refine(_ kind: AccessoryKind, for accessory: HMAccessory) -> AccessoryKind {
        let hasSpeed = accessory.firstCharacteristic(HMCharacteristicTypeRotationSpeed) != nil
        let hasBrightness = accessory.firstCharacteristic(HMCharacteristicTypeBrightness) != nil

        switch kind {
        case .switchAccessory, .outlet, .other:
            if hasSpeed { return .fan }
            if hasBrightness { return .light }
            return kind
        default:
            return kind
        }
    }

    private static func capabilityGuess(for accessory: HMAccessory) -> AccessoryKind {
        if accessory.firstCharacteristic(HMCharacteristicTypeRotationSpeed) != nil { return .fan }
        if accessory.firstCharacteristic(HMCharacteristicTypeBrightness) != nil { return .light }
        if accessory.firstCharacteristic(HMCharacteristicTypePowerState) != nil ||
           accessory.firstCharacteristic(HMCharacteristicTypeActive) != nil { return .switchAccessory }
        return .other
    }

    /// Mappt `HMAccessoryCategoryType*`-Konstanten auf unsere Kinds.
    /// Sensoren haben in HomeKit nur die generische Kategorie `Sensor` – die
    /// Verfeinerung läuft dann über den Service-Typ.
    private static func from(category type: String) -> AccessoryKind? {
        switch type {
        case HMAccessoryCategoryTypeLightbulb:           return .light
        case HMAccessoryCategoryTypeOutlet:              return .outlet
        case HMAccessoryCategoryTypeSwitch:              return .switchAccessory
        case HMAccessoryCategoryTypeProgrammableSwitch:  return .programmableSwitch
        case HMAccessoryCategoryTypeFan:                 return .fan
        case HMAccessoryCategoryTypeAirPurifier:         return .airPurifier
        case HMAccessoryCategoryTypeAirHeater:           return .airHeater
        case HMAccessoryCategoryTypeAirConditioner:      return .airConditioner
        case HMAccessoryCategoryTypeAirHumidifier:       return .airHumidifier
        case HMAccessoryCategoryTypeAirDehumidifier:     return .airDehumidifier
        case HMAccessoryCategoryTypeThermostat:          return .thermostat
        case HMAccessoryCategoryTypeShowerHead:          return .showerHead
        case HMAccessoryCategoryTypeFaucet:              return .faucet
        case HMAccessoryCategoryTypeSensor:              return nil  // serviceType entscheidet
        case HMAccessoryCategoryTypeRangeExtender:       return .rangeExtender
        case HMAccessoryCategoryTypeDoorLock:            return .lock
        case HMAccessoryCategoryTypeDoor:                return .door
        case HMAccessoryCategoryTypeGarageDoorOpener:    return .garage
        case HMAccessoryCategoryTypeWindow:              return .window
        case HMAccessoryCategoryTypeWindowCovering:      return .windowCovering
        case HMAccessoryCategoryTypeVideoDoorbell:       return .videoDoorbell
        case HMAccessoryCategoryTypeSecuritySystem:      return .securitySystem
        case HMAccessoryCategoryTypeIPCamera:            return .camera
        case HMAccessoryCategoryTypeSprinkler:           return .sprinkler
        case HMAccessoryCategoryTypeBridge:              return .bridge
        case HMAccessoryCategoryTypeOther:               return nil  // serviceType entscheidet
        default:                                         return nil
        }
    }

    /// Fallback: Mappt Service-Typen direkt.
    static func from(serviceType: String) -> AccessoryKind {
        switch serviceType {
        case HMServiceTypeLightbulb:                     return .light
        case HMServiceTypeOutlet:                        return .outlet
        case HMServiceTypeSwitch:                        return .switchAccessory
        case HMServiceTypeStatefulProgrammableSwitch,
             HMServiceTypeStatelessProgrammableSwitch:   return .programmableSwitch
        case HMServiceTypeFan:                           return .fan
        case HMServiceTypeAirPurifier:                   return .airPurifier
        case HMServiceTypeHeaterCooler:                  return .airHeater
        case HMServiceTypeHumidifierDehumidifier:        return .airHumidifier
        case HMServiceTypeThermostat:                    return .thermostat
        case HMServiceTypeTemperatureSensor:             return .temperatureSensor
        case HMServiceTypeHumiditySensor:                return .humiditySensor
        case HMServiceTypeLightSensor:                   return .lightSensor
        case HMServiceTypeMotionSensor:                  return .motionSensor
        case HMServiceTypeOccupancySensor:               return .occupancySensor
        case HMServiceTypeContactSensor:                 return .contactSensor
        case HMServiceTypeLeakSensor:                    return .leakSensor
        case HMServiceTypeSmokeSensor:                   return .smokeSensor
        case HMServiceTypeCarbonMonoxideSensor:          return .carbonMonoxideSensor
        case HMServiceTypeCarbonDioxideSensor:           return .carbonDioxideSensor
        case HMServiceTypeAirQualitySensor:              return .airQualitySensor
        case HMServiceTypeLockMechanism,
             HMServiceTypeLockManagement:                return .lock
        case HMServiceTypeDoor:                          return .door
        case HMServiceTypeGarageDoorOpener:              return .garage
        case HMServiceTypeWindow:                        return .window
        case HMServiceTypeWindowCovering:                return .windowCovering
        case HMServiceTypeDoorbell:                      return .videoDoorbell
        case HMServiceTypeSecuritySystem:                return .securitySystem
        case HMServiceTypeCameraRTPStreamManagement,
             HMServiceTypeCameraControl:                 return .camera
        case HMServiceTypeValve:                         return .valve
        case HMServiceTypeIrrigationSystem:              return .sprinkler
        case HMServiceTypeFaucet:                        return .faucet
        case HMServiceTypeSpeaker, HMServiceTypeMicrophone: return .speaker
        default:                                         return .other
        }
    }

    // MARK: - Tap-Verhalten

    /// Klick togglet (statt Detail zu öffnen).
    var prefersToggleOnTap: Bool {
        switch self {
        case .light, .outlet, .switchAccessory, .programmableSwitch,
             .fan, .airPurifier, .airHeater, .airConditioner,
             .airHumidifier, .airDehumidifier, .sprinkler, .valve,
             .speaker, .television, .showerHead, .faucet:
            return true
        default:
            return false
        }
    }

    /// Hat ein Detail-Sheet überhaupt etwas zu bieten?
    var supportsDetailSheet: Bool {
        switch self {
        case .light, .thermostat, .lock, .garage, .windowCovering, .window,
             .door, .fan, .airPurifier, .airHeater, .airConditioner,
             .airHumidifier, .airDehumidifier, .speaker, .showerHead,
             .sprinkler, .faucet:
            return true
        default:
            return false
        }
    }

    // MARK: - SF Symbols (on/off)

    var sfSymbolOn: String {
        switch self {
        case .light:                return "lightbulb.fill"
        case .outlet:               return "powerplug.fill"
        case .switchAccessory:      return "switch.2"
        case .programmableSwitch:   return "button.programmable"
        case .fan:                  return "fan.fill"
        case .airPurifier:          return "wind.circle.fill"
        case .airHeater:            return "heater.vertical"
        case .airConditioner:       return "snowflake"
        case .airHumidifier:        return "humidifier.fill"
        case .airDehumidifier:      return "dehumidifier.fill"
        case .thermostat:           return "thermometer.medium"
        case .showerHead:           return "shower.fill"
        case .faucet:               return "drop.fill"
        case .temperatureSensor:    return "thermometer.medium"
        case .humiditySensor:       return "humidity.fill"
        case .lightSensor:          return "sun.max.fill"
        case .motionSensor:         return "figure.walk.motion"
        case .occupancySensor:      return "person.fill.viewfinder"
        case .contactSensor:        return "door.left.hand.open"
        case .leakSensor:           return "drop.fill"
        case .smokeSensor:          return "smoke.fill"
        case .carbonMonoxideSensor: return "aqi.medium"
        case .carbonDioxideSensor:  return "aqi.high"
        case .airQualitySensor:     return "aqi.medium"
        case .rangeExtender:        return "wifi.router.fill"
        case .lock:                 return "lock.fill"
        case .door:                 return "door.left.hand.closed"
        case .garage:               return "door.garage.closed"
        case .window:               return "window.vertical.closed"
        case .windowCovering:       return "blinds.horizontal.closed"
        case .videoDoorbell:        return "bell.fill"
        case .securitySystem:       return "shield.lefthalf.filled"
        case .camera:               return "video.fill"
        case .valve:                return "drop.degreesign"
        case .sprinkler:            return "sparkles"
        case .speaker:              return "speaker.wave.2.fill"
        case .television:           return "tv.fill"
        case .bridge:               return "wifi.router"
        case .other:                return "homekit"
        }
    }

    var sfSymbolOff: String {
        switch self {
        case .light:           return "lightbulb"
        case .outlet:          return "powerplug"
        case .fan:             return "fan"
        case .airPurifier:     return "wind.circle"
        case .airHeater:       return "heater.vertical"
        case .airConditioner:  return "snowflake"
        case .airHumidifier:   return "humidifier"
        case .airDehumidifier: return "dehumidifier"
        case .lock:            return "lock.open.fill"
        case .garage:          return "door.garage.open"
        case .door:            return "door.left.hand.open"
        case .windowCovering:  return "blinds.horizontal.open"
        case .securitySystem:  return "shield"
        case .camera:          return "video.slash.fill"
        case .speaker:         return "speaker.fill"
        case .showerHead:      return "shower"
        case .faucet:          return "drop"
        case .sprinkler:       return "sparkles"
        case .videoDoorbell:   return "bell"
        default:               return sfSymbolOn
        }
    }

    // MARK: - Accent-Farben

    var accent: Color {
        switch self {
        case .light:                                  return AccessoryPalette.warmLight
        case .outlet, .switchAccessory,
             .programmableSwitch:                     return AccessoryPalette.outlet
        case .fan, .airPurifier:                      return AccessoryPalette.fan
        case .airConditioner:                         return AccessoryPalette.cooling
        case .airHeater:                              return AccessoryPalette.heating
        case .airHumidifier, .airDehumidifier:        return AccessoryPalette.cooling
        case .thermostat:                             return AccessoryPalette.heating
        case .showerHead, .faucet, .valve,
             .sprinkler:                              return AccessoryPalette.valve
        case .temperatureSensor, .humiditySensor,
             .lightSensor, .rangeExtender:            return AccessoryPalette.neutral
        case .motionSensor, .occupancySensor,
             .contactSensor:                          return AccessoryPalette.sensorActive
        case .leakSensor:                             return AccessoryPalette.valve
        case .smokeSensor, .carbonMonoxideSensor,
             .carbonDioxideSensor, .airQualitySensor: return AccessoryPalette.security
        case .lock:                                   return AccessoryPalette.lockSecured
        case .door, .garage, .windowCovering,
             .window:                                 return AccessoryPalette.garageOpen
        case .videoDoorbell:                          return AccessoryPalette.brand
        case .securitySystem:                         return AccessoryPalette.security
        case .camera:                                 return AccessoryPalette.neutral
        case .speaker, .television:                   return AccessoryPalette.speaker
        case .bridge, .other:                         return AccessoryPalette.neutral
        }
    }
}
