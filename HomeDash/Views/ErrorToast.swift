import SwiftUI

/// Toast-Banner am oberen Rand des Dashboards, das transient ein
/// `HomeStore.ErrorEvent` anzeigt. Auto-Dismiss nach 5 Sekunden über
/// `.task(id:)` – das resettet sich automatisch, wenn ein neues Event
/// reinkommt (id ändert sich), und die Animation läuft neu.
///
/// Style: yellow-tinted Glass-Card, klar als Warnung erkennbar, ohne den
/// Dashboard-Inhalt komplett zu verdecken.
struct ErrorToast: View {
    let event: HomeStore.ErrorEvent
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(HomeDesign.sectionFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(event.message)
                    .font(HomeDesign.tileStatusFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.yellow.opacity(0.45), lineWidth: 2)
        )
        .padding(.horizontal, HomeDesign.safeAreaH)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .task(id: event.id) {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            onDismiss()
        }
    }

    private var headline: String {
        if let name = event.accessoryName, !name.isEmpty {
            let fmt = NSLocalizedString("error.toast.title %@", comment: "")
            return String(format: fmt, name)
        }
        return NSLocalizedString("error.toast.titleGeneric", comment: "")
    }
}
