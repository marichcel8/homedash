import Foundation
import HomeKit

/// Verdichteter Heim-Status für die Übersicht oben im Dashboard
/// (ähnlich den Status-Pills der Apple-Home-App).
///
/// Reine Lese-Aggregation über die zwischengespeicherten Characteristic-
/// Werte – es werden keine Reads oder Writes ausgelöst.
struct SensorSummary: Equatable {
    var temperatureRange: ClosedRange<Double>?
    var averageHumidity: Double?

    var hasMotionSensors = false
    var motionDetectedCount = 0

    var hasContactSensors = false
    var openCount = 0

    var hasLocks = false
    var unlockedCount = 0

    var alertCount = 0
    var offlineCount = 0

    var isEmpty: Bool {
        temperatureRange == nil && averageHumidity == nil
        && !hasMotionSensors && !hasContactSensors && !hasLocks
        && alertCount == 0 && offlineCount == 0
    }

    init(accessories: [HMAccessory]) {
        var temperatures: [Double] = []
        var humidities: [Double] = []

        for accessory in accessories {
            if !accessory.isReachable { offlineCount += 1 }

            for service in accessory.services {
                switch service.serviceType {
                case HMServiceTypeTemperatureSensor,
                     HMServiceTypeThermostat,
                     HMServiceTypeHeaterCooler:
                    if let t = service.number(HMCharacteristicTypeCurrentTemperature) {
                        temperatures.append(t.doubleValue)
                    }

                case HMServiceTypeHumiditySensor:
                    if let h = service.number(HMCharacteristicTypeCurrentRelativeHumidity) {
                        humidities.append(h.doubleValue)
                    }

                case HMServiceTypeMotionSensor:
                    hasMotionSensors = true
                    if service.number(HMCharacteristicTypeMotionDetected)?.boolValue == true {
                        motionDetectedCount += 1
                    }

                case HMServiceTypeOccupancySensor:
                    hasMotionSensors = true
                    if service.number(HMCharacteristicTypeOccupancyDetected)?.intValue == 1 {
                        motionDetectedCount += 1
                    }

                case HMServiceTypeContactSensor:
                    hasContactSensors = true
                    // 0 = Kontakt erkannt (zu), 1 = kein Kontakt (offen)
                    if service.number(HMCharacteristicTypeContactState)?.intValue == 1 {
                        openCount += 1
                    }

                case HMServiceTypeGarageDoorOpener:
                    hasContactSensors = true
                    if let state = service.number(HMCharacteristicTypeCurrentDoorState)?.intValue,
                       state != HMCharacteristicValueDoorState.closed.rawValue {
                        openCount += 1
                    }

                case HMServiceTypeLockMechanism:
                    hasLocks = true
                    if service.number(HMCharacteristicTypeCurrentLockMechanismState)?.intValue
                        == HMCharacteristicValueLockMechanismState.unsecured.rawValue {
                        unlockedCount += 1
                    }

                case HMServiceTypeLeakSensor:
                    if service.number(HMCharacteristicTypeLeakDetected)?.intValue == 1 { alertCount += 1 }
                case HMServiceTypeSmokeSensor:
                    if service.number(HMCharacteristicTypeSmokeDetected)?.intValue == 1 { alertCount += 1 }
                case HMServiceTypeCarbonMonoxideSensor:
                    if service.number(HMCharacteristicTypeCarbonMonoxideDetected)?.intValue == 1 { alertCount += 1 }
                case HMServiceTypeCarbonDioxideSensor:
                    if service.number(HMCharacteristicTypeCarbonDioxideDetected)?.intValue == 1 { alertCount += 1 }

                default:
                    break
                }
            }
        }

        if let lo = temperatures.min(), let hi = temperatures.max() {
            temperatureRange = lo...hi
        }
        if !humidities.isEmpty {
            averageHumidity = humidities.reduce(0, +) / Double(humidities.count)
        }
    }
}

private extension HMService {
    /// Characteristic-Werte kommen als NSNumber; Bool/Int/Double über
    /// NSNumber zu lesen ist robuster als `as? Bool` / `as? Int`.
    func number(_ type: String) -> NSNumber? {
        characteristic(type)?.value as? NSNumber
    }
}
