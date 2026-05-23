import SwiftUI
import HomeKit

/// Zeigt vom User gepinte Geräte. Pin/Unpin geschieht über den
/// Stern-Button im Detail-Sheet jedes Geräts.
struct FavoritesSection: View {
    @Environment(HomeStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let favs = store.allAccessoriesInHome()
            .filter { favorites.isFavorite($0.uniqueIdentifier) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if favs.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(HomeDesign.sectionFont)
                        .foregroundStyle(AccessoryPalette.warmLight)
                    Text("dashboard.favorites", bundle: .main)
                        .font(HomeDesign.sectionFont)
                        .foregroundStyle(.primary)
                }
                .padding(.bottom, HomeDesign.sectionBottomPadding)
                .padding(.horizontal, HomeDesign.safeAreaH)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeDesign.gridSpacing) {
                        ForEach(favs, id: \.uniqueIdentifier) { accessory in
                            AccessoryTile(accessory: accessory)
                        }
                    }
                    .padding(.horizontal, HomeDesign.safeAreaH)
                    .padding(.vertical, 48)
                }
            }
        }
    }
}
