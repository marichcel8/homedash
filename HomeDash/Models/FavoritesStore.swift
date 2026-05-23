import Foundation
import Observation

/// Speichert User-gepinte Favoriten lokal in UserDefaults.
/// HomeKit selbst exponiert keine API für die geräteübergreifenden
/// „Favoriten" der Apple Home-App – dort liest und schreibt ausschließlich
/// das interne (private) HomeKitUI-Framework.
@MainActor
@Observable
final class FavoritesStore {
    private let key = "homedash.favorites.v1"
    private(set) var ids: Set<UUID> = []

    init() {
        load()
    }

    func isFavorite(_ id: UUID) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: UUID) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        save()
    }

    private func load() {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return }
        ids = Set(arr.compactMap(UUID.init))
    }

    private func save() {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: key)
    }
}
