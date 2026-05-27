import Foundation
import HomeKit

extension Error {
    /// User-freundliche, lokalisierte Beschreibung eines Fehlers aus dem
    /// HomeKit-Stack. Mappt die häufigsten `HMError`-Codes auf konkrete,
    /// handlungsorientierte Texte; fällt zurück auf `localizedDescription`.
    ///
    /// Wird in `HomeStore.recordFailure(...)` aufgerufen und landet im
    /// `ErrorToast` sowie indirekt im Tile-Warning-Badge.
    ///
    /// Implementierungs-Hinweis: wir matchen ausschließlich auf den NSError-
    /// Code im `HMErrorDomain`, statt auf `HMError.Code`-Enum-Cases. Die
    /// typed Cases sind über SDK-Generationen mehrfach umbenannt worden
    /// (z. B. tvOS 26 strippt den `Operation`-Prefix anders), die rohen
    /// Integer-Codes sind dagegen seit iOS 8 stabil.
    var friendlyHomeKitDescription: String {
        let ns = self as NSError
        if ns.domain == HMErrorDomain {
            return Self.localizedHMMessage(forCode: ns.code)
        }
        return ns.localizedDescription
    }

    fileprivate static func localizedHMMessage(forCode code: Int) -> String {
        // Codes aus <HomeKit/HMError.h>; seit iOS 8 stabil.
        let key: String
        switch code {
        case 5:   key = "error.notReachable"      // AccessoryNotReachable
        case 6:   key = "error.notWritable"       // ReadOnlyCharacteristic
        case 8:   key = "error.notWritable"       // WriteOnlyCharacteristic (inverse, aber selber UX-Hinweis)
        case 10:  key = "error.timeout"           // OperationTimedOut
        case 11:  key = "error.poweredOff"        // AccessoryPoweredOff
        case 12:  key = "error.notPermitted"      // AccessDenied
        case 17:  key = "error.notPermitted"      // InsufficientPrivileges
        case 25:  key = "error.cancelled"         // OperationCancelled
        case 33:  key = "error.busy"              // AccessoryIsBusy
        case 38:  key = "error.invalidValue"     // InvalidValueInCharacteristicWriteRequest
        case 70:  key = "error.notReachable"      // accessoryNotResponding
        case 75:  key = "error.notReachable"      // legacy code für Unreachable
        default:  key = "error.generic"
        }
        return NSLocalizedString(key, comment: "")
    }
}
