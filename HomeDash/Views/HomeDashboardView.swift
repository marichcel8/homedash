import SwiftUI
import HomeKit

struct HomeDashboardView: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: HomeDesign.sectionTopPadding, pinnedViews: []) {
                header
                SensorOverview()
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
        .accessibilityIdentifier("dashboard")
        .onPlayPauseCommand {
            Task { await store.refresh() }
        }
        // Nur bei strukturellen Änderungen (Home gewechselt etc.) neu aufbauen.
        // Einzelne Characteristic-Updates kommen über @Observable und resetten
        // die Scroll-Position NICHT mehr.
        .id(store.stateRevision)
        // Transienter Error-Toast: wird vom HomeStore befüllt, dismissed sich
        // selbst nach 5 s, kann jederzeit durch neuen Fehler ersetzt werden.
        .overlay(alignment: .top) {
            if let event = store.lastError {
                ErrorToast(event: event) { store.clearError() }
                    .padding(.top, 24)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.lastError)
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
                    .accessibilityIdentifier("dashboard.title")
                if let home = store.currentHome {
                    Text(home.name)
                        .font(HomeDesign.tileTitleFont)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("dashboard.homeName")
                }
            }
            Spacer()
            HStack(spacing: 24) {
                SearchButton()
                if store.homes.count > 1 {
                    HomePickerView()
                }
            }
        }
        .padding(.horizontal, HomeDesign.safeAreaH)
        // Lupe/Home-Picker sitzen rechts außen; ohne Focus-Section findet die
        // Focus-Engine sie von links stehenden Tiles aus nach oben nicht.
        .focusSection()
    }
}
