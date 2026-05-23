import SwiftUI
import HomeKit

/// Wiederverwendbarer Detail-Card-Container.
struct DetailCard<Content: View>: View {
    let title: LocalizedStringKey?
    @ViewBuilder var content: () -> Content

    init(title: LocalizedStringKey? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let title {
                Text(title, bundle: .main)
                    .font(HomeDesign.sectionFont)
                    .foregroundStyle(.primary)
            }
            content()
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
    }
}

// MARK: - Power Toggle Row
struct PowerToggleRow: View {
    let accessory: HMAccessory
    let onToggle: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: accessory.isOn ? "power.circle.fill" : "power.circle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(accessory.isOn ? accessory.accentColor : .secondary)
            Text(accessory.isOn ? "status.on" : "status.off", bundle: .main)
                .font(HomeDesign.sectionFont)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(28)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
        .focusableTap(isFocused: $isFocused, onTap: onToggle)
        .focusOutline(isFocused: isFocused, cornerRadius: HomeDesign.tileCornerRadius)
    }
}

// MARK: - Brightness
struct BrightnessCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var brightness: Double = 0

    var body: some View {
        DetailCard(title: "detail.brightness") {
            TVSliderControl(
                value: $brightness, range: 0...100, step: 5,
                accent: accessory.accentColor,
                valueText: { "\(Int($0)) %" }
            ) { v in
                Task {
                    if v > 0 && !accessory.isOn { await store.toggle(accessory) }
                    await store.setBrightness(accessory, Int(v))
                }
            }
        }
        .onAppear { brightness = Double(accessory.brightness ?? 0) }
    }
}

// MARK: - Color Temperature
struct ColorTemperatureCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var mired: Double = 280

    var body: some View {
        DetailCard(title: "detail.colorTemperature") {
            TVSliderControl(
                value: $mired, range: 140...500, step: 20,
                accent: AccessoryPalette.warmLight,
                valueText: { v in
                    v < 280 ? NSLocalizedString("detail.cool", comment: "")
                            : NSLocalizedString("detail.warm", comment: "")
                }
            ) { v in
                Task { await store.setColorTemperature(accessory, Int(v)) }
            }
        }
        .onAppear {
            if let m = accessory.firstCharacteristic(HMCharacteristicTypeColorTemperature)?.value as? Int {
                mired = Double(m)
            }
        }
    }
}

// MARK: - Rotation Speed (Lüfter, Air Purifier, ...)
struct RotationSpeedCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var speed: Double = 0

    var body: some View {
        DetailCard(title: "Intensität") {
            TVSliderControl(
                value: $speed, range: 0...100, step: 10,
                accent: accessory.accentColor,
                valueText: { "\(Int($0)) %" }
            ) { v in
                Task {
                    if v > 0 && !accessory.isOn { await store.toggle(accessory) }
                    await store.setFanSpeed(accessory, percent: v)
                }
            }
        }
        .onAppear { speed = accessory.fanRotationSpeed ?? 0 }
    }
}

// MARK: - Position (Window Covering, Door, ...)
struct PositionCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var position: Double = 0

    var body: some View {
        DetailCard(title: "Position") {
            TVSliderControl(
                value: $position, range: 0...100, step: 10,
                accent: accessory.accentColor,
                valueText: { "\(Int($0)) %" }
            ) { v in
                Task { await store.setWindowCovering(accessory, position: Int(v)) }
            }
        }
        .onAppear { position = Double(accessory.doorPosition ?? 0) }
    }
}

// MARK: - Target Humidity
struct TargetHumidityCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var humidity: Double = 50

    var body: some View {
        DetailCard(title: "Ziel-Feuchtigkeit") {
            TVSliderControl(
                value: $humidity, range: 0...100, step: 5,
                accent: accessory.accentColor,
                valueText: { "\(Int($0)) %" }
            ) { v in
                Task {
                    // Reuse: writeValue auf TargetRelativeHumidity
                    if let c = accessory.firstCharacteristic(HMCharacteristicTypeTargetRelativeHumidity) {
                        await store.setCharacteristic(c, value: v, for: accessory)
                    }
                }
            }
        }
        .onAppear { humidity = accessory.targetHumidity ?? 50 }
    }
}

// MARK: - Target Temperature (Thermostat)
struct TargetTemperatureCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var target: Double = 21

    var body: some View {
        DetailCard(title: "detail.targetTemperature") {
            TVSliderControl(
                value: $target, range: 5...32, step: 0.5,
                accent: accessory.accentColor,
                valueText: { "\(String(format: "%.1f", $0))°" }
            ) { v in
                Task { await store.setTargetTemperature(accessory, celsius: v) }
            }
        }
        .onAppear { target = accessory.targetTemperature ?? 21 }
    }
}

// MARK: - Current Temperature Display
struct CurrentTemperatureDisplay: View {
    let accessory: HMAccessory

    var body: some View {
        DetailCard {
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("detail.currentTemperature", bundle: .main)
                        .font(HomeDesign.tileStatusFont)
                        .foregroundStyle(.secondary)
                    Text("\(Int(round(accessory.currentTemperature ?? 0)))°")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Heating/Cooling Mode Picker (Thermostat)
struct HeatingCoolingModeCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @State private var mode: Int = 0

    var body: some View {
        DetailCard(title: "detail.mode") {
            HStack(spacing: 16) {
                ModeChip(label: "detail.mode.off",  value: 0, current: $mode,
                         symbol: "power", accent: .gray) {
                    Task { await store.setHeatingCoolingMode(accessory, mode: 0) }
                }
                ModeChip(label: "detail.mode.heat", value: 1, current: $mode,
                         symbol: "flame.fill", accent: AccessoryPalette.heating) {
                    Task { await store.setHeatingCoolingMode(accessory, mode: 1) }
                }
                ModeChip(label: "detail.mode.cool", value: 2, current: $mode,
                         symbol: "snowflake", accent: AccessoryPalette.cooling) {
                    Task { await store.setHeatingCoolingMode(accessory, mode: 2) }
                }
                ModeChip(label: "detail.mode.auto", value: 3, current: $mode,
                         symbol: "a.circle.fill", accent: AccessoryPalette.brand) {
                    Task { await store.setHeatingCoolingMode(accessory, mode: 3) }
                }
            }
        }
        .onAppear { mode = accessory.heatingCoolingMode ?? 0 }
    }
}

private struct ModeChip: View {
    let label: LocalizedStringKey
    let value: Int
    @Binding var current: Int
    let symbol: String
    let accent: Color
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .semibold))
            Text(label, bundle: .main)
                .font(HomeDesign.tileStatusFont)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(current == value ? accent.opacity(0.9) : Color.primary.opacity(0.08))
        )
        .foregroundStyle(current == value ? .white : .secondary)
        .focusableTap(isFocused: $isFocused) {
            current = value
            action()
        }
        .focusOutline(isFocused: isFocused, cornerRadius: 20)
    }
}

// MARK: - Lock Buttons
struct LockButtonsCard: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store

    var body: some View {
        HStack(spacing: 32) {
            LockActionButton(label: "detail.unlock", symbol: "lock.open.fill",
                             accent: AccessoryPalette.lockOpen) {
                Task { await store.setLock(accessory, locked: false) }
            }
            LockActionButton(label: "detail.lock", symbol: "lock.fill",
                             accent: AccessoryPalette.lockSecured) {
                Task { await store.setLock(accessory, locked: true) }
            }
        }
    }
}

private struct LockActionButton: View {
    let label: LocalizedStringKey
    let symbol: String
    let accent: Color
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .semibold))
            Text(label, bundle: .main)
                .font(HomeDesign.sectionFont)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous).fill(accent))
        .foregroundStyle(.white)
        .focusableTap(isFocused: $isFocused, onTap: action)
        .focusOutline(isFocused: isFocused, cornerRadius: HomeDesign.tileCornerRadius)
    }
}

// MARK: - Status Display
struct StatusDisplayCard: View {
    let accessory: HMAccessory

    var body: some View {
        DetailCard {
            let status = accessory.localizedStatus()
            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            } else {
                Text(accessory.isReachable ? "Bereit" : NSLocalizedString("status.notResponding", comment: ""))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
