import SwiftUI

@main
struct HomeDashApp: App {
    @State private var store = HomeStore()
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(favorites)
            // Kein erzwungenes ColorScheme – die App folgt dem System
            // (tvOS → Einstellungen → Allgemein → Aussehen).
        }
    }
}
