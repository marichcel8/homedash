import HomeKit

extension HMService {
    /// Liefert die erste Characteristic mit dem gegebenen Type, oder nil.
    func characteristic(_ type: String) -> HMCharacteristic? {
        characteristics.first { $0.characteristicType == type }
    }
}

extension HMAccessory {
    /// Hauptsächlicher Service eines Accessories. Bevorzugt den als
    /// `isPrimaryService` markierten, ignoriert `HMServiceTypeAccessoryInformation`.
    var primaryUsefulService: HMService? {
        services.first { $0.isPrimaryService && $0.serviceType != HMServiceTypeAccessoryInformation }
        ?? services.first { $0.serviceType != HMServiceTypeAccessoryInformation }
    }

    /// Erste Characteristic eines bestimmten Typs in irgendeinem Service.
    func firstCharacteristic(_ type: String) -> HMCharacteristic? {
        for s in services {
            if let c = s.characteristic(type) { return c }
        }
        return nil
    }
}

extension HMCharacteristic {
    var isWritable: Bool { properties.contains(HMCharacteristicPropertyWritable) }
    var isReadable: Bool { properties.contains(HMCharacteristicPropertyReadable) }
    var supportsEvents: Bool { properties.contains(HMCharacteristicPropertySupportsEventNotification) }
}
