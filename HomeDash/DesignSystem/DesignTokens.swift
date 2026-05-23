import SwiftUI

/// Designsprache von HomeDash – orientiert an Apple Home (iOS/tvOS).
/// Alle Farben sind Light/Dark-Mode-adaptiv.
enum HomeDesign {
    // MARK: - Layout
    static let tileCornerRadius: CGFloat = 24
    static let tilePadding: CGFloat = 24
    static let tileSize: CGFloat = 280
    static let tileWide: CGSize = .init(width: 580, height: 280)
    static let sceneTileSize: CGSize = .init(width: 360, height: 200)
    static let gridSpacing: CGFloat = 40
    static let sectionTopPadding: CGFloat = 56
    static let sectionBottomPadding: CGFloat = 24
    static let safeAreaH: CGFloat = 90
    static let safeAreaV: CGFloat = 60
    static let iconBubbleSize: CGFloat = 64
    static let iconSize: CGFloat = 34
    static let sceneIconSize: CGFloat = 40

    // MARK: - Focus
    static let focusScale: CGFloat = 1.04
    static let focusOutlineWidth: CGFloat = 4
    static let focusAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.78)

    // MARK: - Typography (tvOS – große Sichtdistanz)
    static let headerFont: Font = .system(size: 60, weight: .bold, design: .rounded)
    static let sectionFont: Font = .system(size: 42, weight: .semibold, design: .rounded)
    static let tileTitleFont: Font = .system(size: 30, weight: .semibold)
    static let tileStatusFont: Font = .system(size: 22, weight: .regular)
    static let sceneTitleFont: Font = .system(size: 26, weight: .semibold)
}

/// Hintergrund-Gradient, der sich automatisch an Light/Dark anpasst.
/// Niemals pures schwarz/weiß – damit Schatten/Glow sichtbar bleiben.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.07, green: 0.07, blue: 0.09),
                   Color(red: 0.02, green: 0.02, blue: 0.03)]
                : [Color(red: 0.96, green: 0.96, blue: 0.98),
                   Color(red: 0.88, green: 0.88, blue: 0.92)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
