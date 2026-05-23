import SwiftUI
import HomeKit

/// Universelles Detail-Sheet. Statt fester DetailViews pro Kind rendert
/// es dynamisch genau die Cards, die für das Accessory verfügbar sind.
/// So bekommt JEDES HomeKit-Gerät passende Controls – ohne dass wir für
/// jeden seltenen Service einen eigenen View schreiben müssen.
struct AccessoryDetailSheet: View {
    let accessory: HMAccessory
    @Environment(\.dismiss) private var dismiss
    @Environment(HomeStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                header
                Divider().background(Color.primary.opacity(0.08))
                ScrollView {
                    VStack(spacing: 40) {
                        capabilityCards
                    }
                    .padding(HomeDesign.safeAreaH)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 24) {
            Image(systemName: accessory.sfSymbol)
                .font(.system(size: 56, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(accessory.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(accessory.name)
                    .font(HomeDesign.headerFont)
                    .foregroundStyle(.primary)
                Text(accessory.localizedStatus())
                    .font(HomeDesign.tileTitleFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            FavoriteStarButton(uuid: accessory.uniqueIdentifier)
            CloseButton { dismiss() }
        }
        .padding(.horizontal, HomeDesign.safeAreaH)
        .padding(.vertical, 56)
    }

    @ViewBuilder
    private var capabilityCards: some View {
        // Spezialfall Thermostat: erst Ist-Temperatur, dann Modus, dann Ziel
        if accessory.kind == .thermostat {
            CurrentTemperatureDisplay(accessory: accessory)
            if accessory.supportsHeatingCoolingMode {
                HeatingCoolingModeCard(accessory: accessory)
            }
            if accessory.supportsTargetTemperature {
                TargetTemperatureCard(accessory: accessory)
            }
        }

        // Spezialfall Schloss: Status + Lock/Unlock-Buttons
        if accessory.kind == .lock {
            StatusDisplayCard(accessory: accessory)
            if accessory.supportsLock {
                LockButtonsCard(accessory: accessory)
            }
        }

        // Universelle Cards für alle anderen Geräte – nur was gebraucht wird:
        if accessory.kind != .thermostat && accessory.kind != .lock {
            if accessory.hasTogglableSwitch {
                PowerToggleRow(accessory: accessory) {
                    Task { await store.toggle(accessory) }
                }
            }
            if accessory.supportsRotationSpeed {
                RotationSpeedCard(accessory: accessory)
            }
            if accessory.supportsBrightness {
                BrightnessCard(accessory: accessory)
            }
            if accessory.supportsColorTemperature {
                ColorTemperatureCard(accessory: accessory)
            }
            if accessory.supportsHueSaturation {
                ColorPickerGrid(accessory: accessory)
            }
            if accessory.supportsTargetPosition {
                PositionCard(accessory: accessory)
            }
            if accessory.supportsTargetHumidity {
                TargetHumidityCard(accessory: accessory)
            }
            if !accessory.hasTogglableSwitch
                && !accessory.supportsRotationSpeed
                && !accessory.supportsBrightness
                && !accessory.supportsTargetPosition
                && !accessory.supportsHueSaturation {
                // Reines Sensor-Gerät: zeig wenigstens den Status groß
                StatusDisplayCard(accessory: accessory)
            }
        }
    }
}

private struct FavoriteStarButton: View {
    let uuid: UUID
    @Environment(FavoritesStore.self) private var favorites
    @FocusState private var isFocused: Bool

    var body: some View {
        let isFav = favorites.isFavorite(uuid)
        Image(systemName: isFav ? "star.fill" : "star")
            .font(.system(size: 48, weight: .semibold))
            .foregroundStyle(isFav ? AccessoryPalette.warmLight : .secondary)
            .frame(width: 80, height: 80)
            .focusableTap(isFocused: $isFocused) { favorites.toggle(uuid) }
            .focusOutlineCircle(isFocused: isFocused)
            .accessibilityLabel(Text(isFav ? "favorite.remove" : "favorite.add", bundle: .main))
    }
}

private struct CloseButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 56, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(width: 80, height: 80)
            .focusableTap(isFocused: $isFocused, onTap: action)
            .focusOutlineCircle(isFocused: isFocused)
            .accessibilityLabel(Text("detail.close", bundle: .main))
    }
}
