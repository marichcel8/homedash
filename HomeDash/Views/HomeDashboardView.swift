import SwiftUI
import HomeKit

struct HomeDashboardView: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: HomeDesign.sectionTopPadding, pinnedViews: []) {
                header
                ScenesSection()
                FavoritesSection()
                ForEach(store.roomsInCurrentHome(), id: \.uniqueIdentifier) { room in
                    RoomSection(room: room)
                }
                if currentHomeIsEmpty {
                    EmptyStateView(
                        symbol: "lightbulb.slash",
                        title: "empty.noAccessories.title",
                        message: "empty.noAccessories.body"
                    )
                    .padding(.top, 80)
                }
            }
            .padding(.vertical, HomeDesign.safeAreaV)
        }
        .onPlayPauseCommand {
            Task { await store.refresh() }
        }
        // Nur bei strukturellen Änderungen (Home gewechselt etc.) neu aufbauen.
        // Einzelne Characteristic-Updates kommen über @Observable und resetten
        // die Scroll-Position NICHT mehr.
        .id(store.stateRevision)
    }

    private var currentHomeIsEmpty: Bool {
        guard let home = store.currentHome else { return true }
        return home.accessories.allSatisfy { acc in
            acc.services.allSatisfy { $0.serviceType == HMServiceTypeAccessoryInformation }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 8) {
                Text("app.name", bundle: .main)
                    .font(HomeDesign.headerFont)
                    .foregroundStyle(.primary)
                if let home = store.currentHome {
                    Text(home.name)
                        .font(HomeDesign.tileTitleFont)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if store.homes.count > 1 {
                HomePickerView()
            }
        }
        .padding(.horizontal, HomeDesign.safeAreaH)
    }
}
