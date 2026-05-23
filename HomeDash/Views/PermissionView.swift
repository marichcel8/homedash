import SwiftUI

/// Hinweisbildschirm wenn HomeKit-Zugriff fehlt. tvOS zeigt keinen modalen Prompt,
/// daher leitet die App den Nutzer in die System-Einstellungen.
struct PermissionView: View {
    enum Reason { case undetermined, denied, restricted }
    let reason: Reason

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 120, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AccessoryPalette.brand)
                .padding(.bottom, 12)

            Text(titleKey, bundle: .main)
                .font(HomeDesign.headerFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text(bodyKey, bundle: .main)
                .font(HomeDesign.tileTitleFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 1100)

            HStack(spacing: 16) {
                Image(systemName: "gear")
                Text("permission.settings.path", bundle: .main)
            }
            .font(.system(size: 28, weight: .medium, design: .monospaced))
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(.primary)
        }
        .padding(HomeDesign.safeAreaH)
    }

    private var titleKey: LocalizedStringKey {
        switch reason {
        case .restricted:    return "permission.restricted.title"
        case .denied:        return "permission.title"
        case .undetermined:  return "permission.title"
        }
    }

    private var bodyKey: LocalizedStringKey {
        switch reason {
        case .restricted:    return "permission.restricted.body"
        case .denied:        return "permission.restricted.body"
        case .undetermined:  return "permission.body"
        }
    }
}

#Preview("Denied") {
    ZStack {
        AppBackground()
        PermissionView(reason: .denied)
    }
}
