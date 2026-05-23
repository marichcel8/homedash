import SwiftUI
import HomeKit

/// Root-Router: zeigt je nach HomeKit-Status den passenden Bildschirm.
struct ContentView: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .animation(.easeInOut(duration: 0.3), value: store.isLoaded)
        .animation(.easeInOut(duration: 0.3), value: store.hasAuthorization)
    }

    @ViewBuilder
    private var content: some View {
        if store.isRestricted {
            PermissionView(reason: .restricted)
        } else if !store.isLoaded {
            LoadingView()
        } else if !store.hasAuthorization {
            PermissionView(reason: store.permissionWasDenied ? .denied : .undetermined)
        } else if store.homes.isEmpty {
            EmptyStateView(
                symbol: "house.slash",
                title: "empty.noHomes.title",
                message: "empty.noHomes.body"
            )
        } else {
            HomeDashboardView()
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2.0)
            Text("root.loading", bundle: .main)
                .font(HomeDesign.sectionFont)
                .foregroundStyle(.primary.opacity(0.85))
        }
    }
}

#Preview("Loading") {
    ContentView()
        .environment(HomeStore())
}
