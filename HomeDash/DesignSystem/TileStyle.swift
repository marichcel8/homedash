import SwiftUI

/// Apple-Home-Tile.
///
/// **Focus-Verhalten** (was du wolltest):
/// - Einfacher Outline in `Color.primary` → weiß im Dark Mode, schwarz im Light Mode
/// - Kein Pop-Bubble, keine Farbinvertierung, sehr dezente Skalierung
///
/// **Active-Verhalten**:
/// - inaktiv: `.ultraThinMaterial` (Light/Dark-adaptiv)
/// - aktiv: vollflächige Akzentfarbe
struct TileShell<Content: View>: View {
    var isActive: Bool
    var isFocused: Bool
    var accent: Color
    var size: CGSize
    @ViewBuilder var content: () -> Content

    init(isActive: Bool,
         isFocused: Bool,
         accent: Color,
         size: CGSize = .init(width: HomeDesign.tileSize, height: HomeDesign.tileSize),
         @ViewBuilder content: @escaping () -> Content) {
        self.isActive = isActive
        self.isFocused = isFocused
        self.accent = accent
        self.size = size
        self.content = content
    }

    var body: some View {
        ZStack {
            background
            content()
                .padding(HomeDesign.tilePadding)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius,
                                    style: .continuous))
        .overlay(
            // Focus-Outline: passt sich automatisch dem ColorScheme an
            RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius,
                             style: .continuous)
                .stroke(Color.primary.opacity(isFocused ? 1 : 0),
                        lineWidth: HomeDesign.focusOutlineWidth)
        )
        .shadow(color: shadowColor,
                radius: isFocused ? 16 : 8,
                x: 0, y: isFocused ? 10 : 4)
        .scaleEffect(isFocused ? HomeDesign.focusScale : 1.0)
        .animation(HomeDesign.focusAnimation, value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    @ViewBuilder
    private var background: some View {
        if isActive {
            LinearGradient(
                colors: [accent.opacity(1.0), accent.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // ultraThinMaterial ist automatisch Light/Dark-adaptiv
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    private var shadowColor: Color {
        if isFocused && isActive {
            return accent.opacity(0.55)
        }
        return Color.black.opacity(0.3)
    }
}
