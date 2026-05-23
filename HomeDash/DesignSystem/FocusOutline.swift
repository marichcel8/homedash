import SwiftUI

/// Einheitlicher Focus-Look für ALLE fokussierbaren Elemente in HomeDash.
///
/// - **Killt den tvOS-System-Focus-Halo** (`.focusEffectDisabled()`) – sonst
///   würde Apples Default-Aura (weißer Glow + Reflexion oben drauf) auf
///   jedem Button mitlaufen und unseren eigenen Outline überstrahlen.
/// - Rendert einen Outline in `Color.primary` (weiß im Dark, schwarz im Light).
/// - Dezente Skalierung + dezenter Schatten zur Tiefenwirkung.
///
/// Verwendung:
/// ```
/// Button(...) { ... }
///   .buttonStyle(.plain)
///   .focused($isFocused)
///   .focusOutline(isFocused: isFocused, cornerRadius: 20)
/// ```
struct FocusOutline: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let scale: CGFloat
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .focusEffectDisabled()   // <- kein System-Halo mehr
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(isFocused ? 1 : 0),
                            lineWidth: lineWidth)
            )
            .scaleEffect(isFocused ? scale : 1.0)
            .shadow(color: Color.black.opacity(isFocused ? 0.35 : 0.15),
                    radius: isFocused ? shadowRadius : 4,
                    x: 0, y: isFocused ? shadowRadius / 2 : 2)
            .animation(HomeDesign.focusAnimation, value: isFocused)
    }
}

/// Variante für kreisrunde Elemente (Stepper, Stern, Close).
struct FocusOutlineCircle: ViewModifier {
    let isFocused: Bool
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .focusEffectDisabled()
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isFocused ? 1 : 0),
                            lineWidth: lineWidth)
            )
            .scaleEffect(isFocused ? HomeDesign.focusScale : 1.0)
            .shadow(color: Color.black.opacity(isFocused ? 0.35 : 0.15),
                    radius: isFocused ? 12 : 4,
                    x: 0, y: isFocused ? 6 : 2)
            .animation(HomeDesign.focusAnimation, value: isFocused)
    }
}

extension View {
    func focusOutline(isFocused: Bool,
                      cornerRadius: CGFloat = 20,
                      lineWidth: CGFloat = HomeDesign.focusOutlineWidth,
                      scale: CGFloat = HomeDesign.focusScale,
                      shadowRadius: CGFloat = 12) -> some View {
        modifier(FocusOutline(isFocused: isFocused,
                              cornerRadius: cornerRadius,
                              lineWidth: lineWidth,
                              scale: scale,
                              shadowRadius: shadowRadius))
    }

    func focusOutlineCircle(isFocused: Bool,
                            lineWidth: CGFloat = HomeDesign.focusOutlineWidth) -> some View {
        modifier(FocusOutlineCircle(isFocused: isFocused, lineWidth: lineWidth))
    }
}
