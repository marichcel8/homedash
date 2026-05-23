import HomeKit

extension HMAccessory {
    /// Vereinfachte Kategorie für UI-Mapping (Symbol, Farbe, Tap-Verhalten).
    /// Nutzt `HMAccessoryCategory` als primäre Quelle (Apples eigene Klassifizierung)
    /// und fällt auf den Service-Typ zurück, falls keine Kategorie vorhanden ist.
    var kind: AccessoryKind {
        AccessoryKind.detect(self)
    }
}
