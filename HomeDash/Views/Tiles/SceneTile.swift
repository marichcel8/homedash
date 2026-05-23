import SwiftUI
import HomeKit

struct SceneTile: View {
    let scene: HMActionSet
    @Environment(HomeStore.self) private var store
    @FocusState private var isFocused: Bool

    var body: some View {
        TileShell(
            isActive: false,
            isFocused: isFocused,
            accent: AccessoryPalette.brand,
            size: HomeDesign.sceneTileSize
        ) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AccessoryPalette.brand.opacity(0.18))
                        .frame(width: HomeDesign.iconBubbleSize,
                               height: HomeDesign.iconBubbleSize)
                    Image(systemName: symbolForScene())
                        .font(.system(size: HomeDesign.sceneIconSize, weight: .semibold))
                        .foregroundStyle(AccessoryPalette.brand)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.name)
                        .font(HomeDesign.sceneTitleFont)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(actionsText)
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius,
                                       style: .continuous))
        .focusable(true)
        .focused($isFocused)
        .onTapGesture { Task { await store.run(scene) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(scene.name))
        .accessibilityHint(Text("a11y.scene.run", bundle: .main))
        .accessibilityAddTraits(.isButton)
    }

    private var actionsText: String {
        let count = scene.actions.count
        if count == 1 {
            return NSLocalizedString("scene.actions.singular", comment: "")
        }
        return String(format: NSLocalizedString("scene.actions.plural %@", comment: ""), "\(count)")
    }

    private func symbolForScene() -> String {
        let n = scene.name.lowercased()
        if n.contains("guten morgen") || n.contains("morning") { return "sun.horizon.fill" }
        if n.contains("ankommen") || n.contains("arrive") || n.contains("home") { return "house.fill" }
        if n.contains("verlassen") || n.contains("leave") { return "door.right.hand.open" }
        if n.contains("gute nacht") || n.contains("night") || n.contains("bett") { return "moon.stars.fill" }
        if n.contains("film") || n.contains("kino") || n.contains("movie") { return "popcorn.fill" }
        if n.contains("party") { return "music.note" }
        return "wand.and.stars"
    }
}
