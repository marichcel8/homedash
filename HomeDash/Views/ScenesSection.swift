import SwiftUI
import HomeKit

struct ScenesSection: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        let scenes = store.scenes()
        if scenes.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("dashboard.scenes", bundle: .main)
                    .font(HomeDesign.sectionFont)
                    .foregroundStyle(.primary)
                    .padding(.bottom, HomeDesign.sectionBottomPadding)
                    .padding(.horizontal, HomeDesign.safeAreaH)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeDesign.gridSpacing) {
                        ForEach(scenes, id: \.uniqueIdentifier) { scene in
                            SceneTile(scene: scene)
                        }
                    }
                    .padding(.horizontal, HomeDesign.safeAreaH)
                    .padding(.vertical, 48)
                }
            }
        }
    }
}
