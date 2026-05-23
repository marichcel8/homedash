import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: symbol)
                .font(.system(size: 96, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AccessoryPalette.brand)

            Text(title, bundle: .main)
                .font(HomeDesign.sectionFont)
                .foregroundStyle(.primary)

            Text(message, bundle: .main)
                .font(HomeDesign.tileStatusFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 900)
        }
        .padding(HomeDesign.safeAreaH)
    }
}
