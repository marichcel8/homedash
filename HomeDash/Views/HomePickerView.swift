import SwiftUI
import HomeKit

struct HomePickerView: View {
    @Environment(HomeStore.self) private var store
    @FocusState private var isFocused: Bool

    var body: some View {
        Menu {
            ForEach(store.homes, id: \.uniqueIdentifier) { home in
                Button {
                    store.selectedHomeID = home.uniqueIdentifier
                } label: {
                    HStack {
                        Text(home.name)
                        if home.uniqueIdentifier == store.currentHome?.uniqueIdentifier {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                Text(store.currentHome?.name ?? "—")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
            }
            .font(HomeDesign.tileTitleFont)
            .foregroundStyle(.primary)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .focused($isFocused)
        .focusOutline(isFocused: isFocused, cornerRadius: 999, lineWidth: 3)
        .accessibilityLabel(Text("dashboard.home.picker", bundle: .main))
    }
}
