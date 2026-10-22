import SwiftUI
import HomeKit

/// Vollbild-Suche über alle Geräte des aktuellen Homes.
/// Nutzt die native tvOS-Suchtastatur (inkl. Diktat über die Siri Remote).
/// Treffer sind normale Tiles: Tap schaltet, Long-Press öffnet Details.
struct DeviceSearchView: View {
    @Environment(HomeStore.self) private var store
    @State private var query = ""

    private let columns = [
        GridItem(.adaptive(minimum: HomeDesign.tileSize), spacing: HomeDesign.gridSpacing)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(.vertical, showsIndicators: false) {
                    if results.isEmpty {
                        EmptyStateView(
                            symbol: "magnifyingglass",
                            title: "search.noResults.title",
                            message: "search.noResults.body"
                        )
                        .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading,
                                  spacing: HomeDesign.gridSpacing) {
                            ForEach(results, id: \.uniqueIdentifier) { accessory in
                                AccessoryTile(accessory: accessory)
                            }
                        }
                        .padding(.horizontal, HomeDesign.safeAreaH)
                        .padding(.vertical, 48)
                    }
                }
            }
            .searchable(text: $query, prompt: Text("search.prompt", bundle: .main))
        }
    }

    /// Leere Suche zeigt alle Geräte alphabetisch; sonst Treffer in
    /// Geräte- oder Raumname (diakritik- und groß/klein-unabhängig).
    private var results: [HMAccessory] {
        let all = store.allAccessoriesInHome()
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all }
        return all.filter { accessory in
            accessory.name.localizedStandardContains(needle)
            || (accessory.room?.name.localizedStandardContains(needle) ?? false)
        }
    }
}

/// Lupen-Button im Dashboard-Header.
struct SearchButton: View {
    @Environment(HomeStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites
    @FocusState private var isFocused: Bool
    @State private var showSearch = false

    var body: some View {
        Button {
            showSearch = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(HomeDesign.tileTitleFont)
                .foregroundStyle(.primary)
                .padding(16)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .focusOutlineCircle(isFocused: isFocused, lineWidth: 3)
        .accessibilityLabel(Text("search.button", bundle: .main))
        .fullScreenCover(isPresented: $showSearch) {
            DeviceSearchView()
                .environment(store)
                .environment(favorites)
        }
    }
}
