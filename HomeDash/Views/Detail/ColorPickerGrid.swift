import SwiftUI
import HomeKit

/// tvOS-taugliche Farbauswahl. 16 Hue-Werte × 7 Sättigungs-Stufen als
/// fokussierbares Raster. Bei Auswahl wird automatisch eingeschaltet,
/// falls das Licht aus war. Focus = Outline wie überall sonst in der App.
struct ColorPickerGrid: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var currentHue: Double = 0
    @State private var currentSaturation: Double = 100

    private let hueSteps: [Double] = stride(from: 0.0, through: 337.5, by: 22.5).map { $0 }
    private let saturationSteps: [Double] = [10, 25, 40, 55, 70, 85, 100]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("detail.color", bundle: .main)
                .font(HomeDesign.sectionFont)
                .foregroundStyle(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 8),
                      spacing: 16) {
                ForEach(hueSteps, id: \.self) { hue in
                    ColorSwatch(
                        color: Color(hue: hue / 360.0, saturation: 1, brightness: 1),
                        isSelected: abs(currentHue - hue) < 11
                    ) {
                        applyColor(hue: hue, sat: currentSaturation)
                    }
                }
            }

            Text("detail.saturation", bundle: .main)
                .font(HomeDesign.tileTitleFont)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 7),
                      spacing: 16) {
                ForEach(saturationSteps, id: \.self) { sat in
                    ColorSwatch(
                        color: Color(hue: currentHue / 360.0,
                                     saturation: sat / 100.0,
                                     brightness: 1),
                        isSelected: abs(currentSaturation - sat) < 8
                    ) {
                        applyColor(hue: currentHue, sat: sat)
                    }
                }
            }
        }
        .padding(28)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
        .onAppear {
            if let h = accessory.firstCharacteristic(HMCharacteristicTypeHue)?.value as? Double {
                currentHue = h
            }
            if let s = accessory.firstCharacteristic(HMCharacteristicTypeSaturation)?.value as? Double {
                currentSaturation = s
            }
        }
    }

    private func applyColor(hue: Double, sat: Double) {
        currentHue = hue
        currentSaturation = sat
        Task {
            if !accessory.isOn { await store.toggle(accessory) }
            await store.setSaturation(accessory, sat)
            await store.setHue(accessory, hue)
        }
    }
}

private struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color)
            .frame(height: 96)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white, lineWidth: 4)
                        .padding(6)
                }
            }
            .focusableTap(isFocused: $isFocused, onTap: action)
            .focusOutline(isFocused: isFocused, cornerRadius: 18, shadowRadius: 18)
    }
}
