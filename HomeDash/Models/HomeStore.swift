import Foundation
import HomeKit
import Observation
import os

/// Zentrale Source-of-Truth für alle HomeKit-Daten der App.
@MainActor
@Observable
final class HomeStore {
    // MARK: - Public State
    private(set) var homes: [HMHome] = []
    var selectedHomeID: UUID? {
        didSet { stateRevision &+= 1 }
    }
    private(set) var authorizationStatus: HMHomeManagerAuthorizationStatus = []
    private(set) var isLoaded: Bool = false
    private(set) var lastError: String?

    /// Strukturelle Revision – nur Home-Wechsel / Add / Remove.
    private(set) var stateRevision: UInt = 0

    /// Pro-Accessory-Revision. Wird bei JEDER Wertänderung erhöht
    /// (eigener Write ODER externes Delegate-Update). Views beobachten
    /// das via `.id(store.revision(for: accessory))` und re-rendern
    /// genau dieses eine Tile – ohne ScrollView-Reset.
    private(set) var accessoryRevisions: [UUID: UInt] = [:]

    func revision(for accessory: HMAccessory) -> UInt {
        accessoryRevisions[accessory.uniqueIdentifier] ?? 0
    }

    // MARK: - Internals
    private let manager = HMHomeManager()
    private let managerDelegate = HomeManagerDelegateProxy()
    private let accessoryDelegate = AccessoryDelegateProxy()
    private let homeDelegate = HomeDelegateProxy()
    private let log = Logger(subsystem: "de.marcel.homedash", category: "HomeStore")

    init() {
        managerDelegate.owner = self
        accessoryDelegate.owner = self
        homeDelegate.owner = self
        manager.delegate = managerDelegate
        authorizationStatus = manager.authorizationStatus
        ingest(homes: manager.homes, enableNotifications: false)
    }

    // MARK: - Derived
    var currentHome: HMHome? {
        if let id = selectedHomeID, let match = homes.first(where: { $0.uniqueIdentifier == id }) {
            return match
        }
        return homes.first(where: { $0.isPrimary }) ?? homes.first
    }

    var hasAuthorization: Bool { authorizationStatus.contains(.authorized) }
    var permissionWasDenied: Bool {
        authorizationStatus.contains(.determined) && !authorizationStatus.contains(.authorized)
    }
    var isRestricted: Bool { authorizationStatus.contains(.restricted) }

    /// Bridges/Hubs ausfiltern: nur Accessories mit mindestens einem
    /// echten User-Service zeigen.
    private func isUsefulAccessory(_ accessory: HMAccessory) -> Bool {
        accessory.services.contains { service in
            service.serviceType != HMServiceTypeAccessoryInformation
            && !service.serviceType.contains("BridgeConfiguration")
        }
    }

    func accessories(in room: HMRoom) -> [HMAccessory] {
        room.accessories
            .filter(isUsefulAccessory)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func allAccessoriesInHome() -> [HMAccessory] {
        currentHome?.accessories.filter(isUsefulAccessory) ?? []
    }

    func roomsInCurrentHome() -> [HMRoom] {
        guard let home = currentHome else { return [] }
        return home.rooms.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func scenes() -> [HMActionSet] {
        guard let home = currentHome else { return [] }
        return home.actionSets.filter {
            $0.actionSetType == HMActionSetTypeUserDefined && !$0.actions.isEmpty
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Public actions
    func refresh() async {
        ingest(homes: manager.homes, enableNotifications: true)
    }

    /// Toggle: arbeitet sowohl mit PowerState (Bool) als auch mit
    /// Active (Int 0/1, z.B. bei Lüftern V2, Lufterhitzern, Sprinklern).
    func toggle(_ accessory: HMAccessory) async {
        if let char = accessory.firstCharacteristic(HMCharacteristicTypePowerState),
           char.isWritable {
            let current = (char.value as? Bool) ?? false
            await write(char, value: !current, for: accessory, label: "toggle power")
            return
        }
        if let char = accessory.firstCharacteristic(HMCharacteristicTypeActive),
           char.isWritable {
            let current = (char.value as? Int) ?? 0
            await write(char, value: current == 0 ? 1 : 0, for: accessory, label: "toggle active")
            return
        }
        log.warning("toggle: no power/active characteristic on \(accessory.name, privacy: .public)")
    }

    func setBrightness(_ accessory: HMAccessory, _ value: Int) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeBrightness) else { return }
        await write(char, value: max(0, min(100, value)), for: accessory, label: "brightness")
    }

    func setColorTemperature(_ accessory: HMAccessory, _ mired: Int) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeColorTemperature) else { return }
        // Range aus Metadata respektieren wenn vorhanden
        let clamped = clampToMetadata(mired, char: char)
        await write(char, value: clamped, for: accessory, label: "color temp")
    }

    func setHue(_ accessory: HMAccessory, _ degrees: Double) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeHue) else {
            log.warning("setHue: no characteristic")
            return
        }
        guard char.isWritable else {
            log.warning("setHue: not writable")
            return
        }
        await write(char, value: max(0.0, min(360.0, degrees)), for: accessory, label: "hue")
    }

    func setSaturation(_ accessory: HMAccessory, _ percent: Double) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeSaturation) else {
            log.warning("setSat: no characteristic")
            return
        }
        guard char.isWritable else {
            log.warning("setSat: not writable")
            return
        }
        await write(char, value: max(0.0, min(100.0, percent)), for: accessory, label: "saturation")
    }

    func setTargetTemperature(_ accessory: HMAccessory, celsius: Double) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeTargetTemperature) else { return }
        await write(char, value: celsius, for: accessory, label: "target temp")
    }

    func setHeatingCoolingMode(_ accessory: HMAccessory, mode: Int) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeTargetHeatingCooling) else { return }
        await write(char, value: mode, for: accessory, label: "heat/cool mode")
    }

    func setLock(_ accessory: HMAccessory, locked: Bool) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeTargetLockMechanismState) else { return }
        let value = locked
            ? HMCharacteristicValueLockMechanismState.secured.rawValue
            : HMCharacteristicValueLockMechanismState.unsecured.rawValue
        await write(char, value: value, for: accessory, label: "lock")
    }

    func setWindowCovering(_ accessory: HMAccessory, position: Int) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeTargetPosition) else { return }
        await write(char, value: max(0, min(100, position)), for: accessory, label: "window position")
    }

    func setFanSpeed(_ accessory: HMAccessory, percent: Double) async {
        guard let char = accessory.firstCharacteristic(HMCharacteristicTypeRotationSpeed) else { return }
        await write(char, value: max(0.0, min(100.0, percent)), for: accessory, label: "fan speed")
    }

    /// Generischer Schreibvorgang für selten genutzte Characteristics
    /// (z. B. Target-Humidity, Swing-Mode, Volume).
    func setCharacteristic(_ char: HMCharacteristic, value: Any, for accessory: HMAccessory) async {
        await write(char, value: value, for: accessory, label: char.characteristicType)
    }

    func run(_ scene: HMActionSet) async {
        guard let home = currentHome else { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            home.executeActionSet(scene) { [weak self] error in
                if let error {
                    self?.log.error("Szene: \(error.localizedDescription, privacy: .public)")
                    Task { @MainActor in self?.lastError = error.localizedDescription }
                }
                cont.resume()
            }
        }
        // Szenen ändern oft mehrere Geräte -> alle bumpen
        for acc in allAccessoriesInHome() { bumpRevision(for: acc) }
    }

    // MARK: - Internal write
    private func write(_ char: HMCharacteristic, value: Any,
                       for accessory: HMAccessory, label: String) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            char.writeValue(value) { [weak self] error in
                if let error {
                    // PII-safe Logging: technical label ist public, error message ist
                    // private (kann u.U. Accessory-Namen oder Pfade enthalten).
                    self?.log.error("\(label, privacy: .public): \(error.localizedDescription, privacy: .private)")
                    Task { @MainActor in self?.lastError = error.localizedDescription }
                }
                cont.resume()
            }
        }
        // Optimistic UI: SwiftUI re-rendert nur das eine Tile, weil
        // accessoryRevisions[uuid] sich ändert.
        bumpRevision(for: accessory)
    }

    private func bumpRevision(for accessory: HMAccessory) {
        let key = accessory.uniqueIdentifier
        accessoryRevisions[key] = (accessoryRevisions[key] ?? 0) &+ 1
    }

    private func clampToMetadata(_ v: Int, char: HMCharacteristic) -> Int {
        guard let meta = char.metadata else { return v }
        let minV = (meta.minimumValue as? NSNumber)?.intValue ?? Int.min
        let maxV = (meta.maximumValue as? NSNumber)?.intValue ?? Int.max
        return max(minV, min(maxV, v))
    }

    // MARK: - Delegate-Eingang
    fileprivate func didUpdateHomes(_ list: [HMHome]) {
        ingest(homes: list, enableNotifications: true)
    }

    fileprivate func didUpdateAuthorization(_ status: HMHomeManagerAuthorizationStatus) {
        authorizationStatus = status
        stateRevision &+= 1
    }

    fileprivate func accessoryDidUpdate(_ accessory: HMAccessory) {
        bumpRevision(for: accessory)
    }

    /// Wird vom HMHomeDelegate-Proxy aufgerufen, wenn sich INNERHALB eines
    /// Homes etwas ändert (Accessory hinzu/entfernt, umbenannt, neuer Raum…).
    /// Wir machen einen kompletten Re-Ingest mit dem aktuellen Snapshot,
    /// damit Bridges/Notifications korrekt neu angemeldet werden.
    fileprivate func homeContentChanged() {
        ingest(homes: manager.homes, enableNotifications: true)
    }

    // MARK: - Helpers
    private func ingest(homes list: [HMHome], enableNotifications: Bool) {
        homes = list.sorted { $0.name < $1.name }
        isLoaded = true
        stateRevision &+= 1
        for home in list {
            // Home-Delegate: für Add/Remove/Rename von Accessories, Räumen, Szenen
            home.delegate = homeDelegate
            for accessory in home.accessories {
                accessory.delegate = accessoryDelegate
            }
        }
        guard enableNotifications else { return }
        Task.detached(priority: .utility) { [weak self] in
            await self?.enableNotificationsForAll(list)
        }
    }

    nonisolated private func enableNotificationsForAll(_ list: [HMHome]) async {
        let important: Set<String> = [
            HMCharacteristicTypePowerState,
            HMCharacteristicTypeActive,
            HMCharacteristicTypeBrightness,
            HMCharacteristicTypeHue,
            HMCharacteristicTypeSaturation,
            HMCharacteristicTypeColorTemperature,
            HMCharacteristicTypeCurrentTemperature,
            HMCharacteristicTypeTargetTemperature,
            HMCharacteristicTypeCurrentHeatingCooling,
            HMCharacteristicTypeCurrentLockMechanismState,
            HMCharacteristicTypeCurrentDoorState,
            HMCharacteristicTypeCurrentPosition,
            HMCharacteristicTypeRotationSpeed,
            HMCharacteristicTypeMotionDetected,
            HMCharacteristicTypeOccupancyDetected,
            HMCharacteristicTypeContactState,
        ]
        for home in list {
            for accessory in home.accessories {
                for service in accessory.services {
                    for char in service.characteristics where important.contains(char.characteristicType) && char.properties.contains(HMCharacteristicPropertySupportsEventNotification) {
                        char.enableNotification(true) { _ in }
                    }
                }
            }
        }
    }
}

// MARK: - Delegate-Proxies

private final class HomeManagerDelegateProxy: NSObject, HMHomeManagerDelegate {
    weak var owner: HomeStore?

    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        let snapshot = manager.homes
        Task { @MainActor [weak owner] in owner?.didUpdateHomes(snapshot) }
    }

    nonisolated func homeManager(_ manager: HMHomeManager,
                                 didUpdate status: HMHomeManagerAuthorizationStatus) {
        Task { @MainActor [weak owner] in owner?.didUpdateAuthorization(status) }
    }

    nonisolated func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        let snapshot = manager.homes
        Task { @MainActor [weak owner] in owner?.didUpdateHomes(snapshot) }
    }

    nonisolated func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        let snapshot = manager.homes
        Task { @MainActor [weak owner] in owner?.didUpdateHomes(snapshot) }
    }
}

private final class AccessoryDelegateProxy: NSObject, HMAccessoryDelegate {
    weak var owner: HomeStore?

    nonisolated func accessory(_ accessory: HMAccessory,
                               service: HMService,
                               didUpdateValueFor characteristic: HMCharacteristic) {
        Task { @MainActor [weak owner] in owner?.accessoryDidUpdate(accessory) }
    }

    nonisolated func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.accessoryDidUpdate(accessory) }
    }

    nonisolated func accessoryDidUpdateName(_ accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.accessoryDidUpdate(accessory) }
    }
}

/// Hört auf Änderungen innerhalb eines Homes (Accessories, Räume, Szenen, Namen).
/// Damit reagiert die App live auf Re-Pairing oder Add/Remove von Geräten in der
/// Home-App auf iPhone/iPad, ohne dass der User die Berechtigung neu erteilen muss.
private final class HomeDelegateProxy: NSObject, HMHomeDelegate {
    weak var owner: HomeStore?

    nonisolated func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdate name: String) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdateNameFor accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdateRoom room: HMRoom, for accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didAdd room: HMRoom) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didRemove room: HMRoom) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didAdd actionSet: HMActionSet) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didRemove actionSet: HMActionSet) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdateNameFor actionSet: HMActionSet) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUpdateActionsFor actionSet: HMActionSet) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didUnblockAccessory accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
    nonisolated func home(_ home: HMHome, didEncounterError error: Error, for accessory: HMAccessory) {
        Task { @MainActor [weak owner] in owner?.homeContentChanged() }
    }
}
