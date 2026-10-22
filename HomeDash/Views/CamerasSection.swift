import SwiftUI
import HomeKit

/// Kamera-Reihe oben im Dashboard: große 16:9-Kacheln mit Snapshot-Vorschau.
/// Select öffnet das Livebild im Vollbild.
struct CamerasSection: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        let cameras = store.allAccessoriesInHome()
            .filter { $0.cameraProfile != nil }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if cameras.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(HomeDesign.sectionFont)
                        .foregroundStyle(AccessoryPalette.brand)
                    Text("dashboard.cameras", bundle: .main)
                        .font(HomeDesign.sectionFont)
                        .foregroundStyle(.primary)
                }
                .padding(.bottom, HomeDesign.sectionBottomPadding)
                .padding(.horizontal, HomeDesign.safeAreaH)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeDesign.gridSpacing) {
                        ForEach(cameras, id: \.uniqueIdentifier) { accessory in
                            if let profile = accessory.cameraProfile {
                                CameraTile(accessory: accessory, profile: profile)
                            }
                        }
                    }
                    .padding(.horizontal, HomeDesign.safeAreaH)
                    .padding(.vertical, 48)
                }
            }
        }
    }
}

/// Vorschau-Kachel: zeigt den letzten Snapshot und holt alle 30 s einen
/// neuen, solange die Kachel sichtbar ist.
struct CameraTile: View {
    let accessory: HMAccessory
    let profile: HMCameraProfile
    @State private var controller: CameraController
    @State private var showStream = false
    @FocusState private var isFocused: Bool

    private static let size = CGSize(width: 580, height: 326)
    private static let refreshInterval: Duration = .seconds(30)

    init(accessory: HMAccessory, profile: HMCameraProfile) {
        self.accessory = accessory
        self.profile = profile
        _controller = State(initialValue: CameraController(profile: profile))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
            if controller.source != nil {
                CameraSourceView(source: controller.source)
            } else {
                Image(systemName: accessory.isReachable ? "video.fill" : "video.slash.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.7)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(accessory.name)
                    .font(HomeDesign.tileTitleFont)
                    .lineLimit(1)
                Text(subtitle)
                    .font(HomeDesign.tileStatusFont)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(HomeDesign.tilePadding)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(isFocused ? 1 : 0),
                        lineWidth: HomeDesign.focusOutlineWidth)
        )
        .shadow(color: .black.opacity(0.3), radius: isFocused ? 16 : 8, x: 0, y: isFocused ? 10 : 4)
        .scaleEffect(isFocused ? HomeDesign.focusScale : 1.0)
        .animation(HomeDesign.focusAnimation, value: isFocused)
        .focusableTap(isFocused: $isFocused) { showStream = true }
        .focusEffectDisabled()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessory.name))
        .accessibilityHint(Text("a11y.camera.open", bundle: .main))
        .accessibilityAddTraits(.isButton)
        .fullScreenCover(isPresented: $showStream) {
            CameraFullscreenView(accessory: accessory, profile: profile)
        }
        .task {
            // Läuft nur, solange die Kachel sichtbar ist; SwiftUI bricht den
            // Task beim Verschwinden ab.
            while !Task.isCancelled {
                if !showStream && accessory.isReachable {
                    controller.takeSnapshot()
                }
                try? await Task.sleep(for: Self.refreshInterval)
            }
        }
    }

    private var subtitle: String {
        if !accessory.isReachable {
            return NSLocalizedString("status.notResponding", comment: "")
        }
        if let date = controller.snapshotDate {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return accessory.room?.name ?? ""
    }
}
