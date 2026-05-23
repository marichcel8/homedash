import SwiftUI
import HomeKit

struct RoomSection: View {
    let room: HMRoom
    @Environment(HomeStore.self) private var store

    var body: some View {
        let accessories = store.accessories(in: room)
        if accessories.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(room.name)
                        .font(HomeDesign.sectionFont)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(accessories.count)")
                        .font(HomeDesign.tileStatusFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, HomeDesign.sectionBottomPadding)
                .padding(.horizontal, HomeDesign.safeAreaH)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeDesign.gridSpacing) {
                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                            AccessoryTile(accessory: accessory)
                        }
                    }
                    // Großzügiges Padding, damit Focus-Scale + Schatten
                    // nicht vom ScrollView clipped werden.
                    .padding(.horizontal, HomeDesign.safeAreaH)
                    .padding(.vertical, 48)
                }
                // Wichtig: kein .clipped()! Sonst sieht man den Focus-Glow nicht.
            }
        }
    }
}
