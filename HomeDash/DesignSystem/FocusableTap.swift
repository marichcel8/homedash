import SwiftUI

/// Macht eine beliebige View fokussierbar + tappbar – **ohne** die
/// tvOS-System-Card-Aura, die jeder `Button` automatisch bekommt.
///
/// Verwendung statt `Button(action:label:) + .buttonStyle(.plain)`:
/// ```
/// MyView(...)
///   .focusableTap(isFocused: $isFocused) { handleTap() }
///   .focusOutline(isFocused: isFocused, cornerRadius: 20)
/// ```
extension View {
    func focusableTap(isFocused: FocusState<Bool>.Binding,
                      onTap: @escaping () -> Void) -> some View {
        self
            .contentShape(Rectangle())
            .focusable(true)
            .focused(isFocused)
            .onTapGesture(perform: onTap)
    }
}
