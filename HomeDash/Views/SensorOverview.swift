import SwiftUI
import HomeKit

/// Status-Leiste unter dem Header: Klima, Bewegung, Türen/Fenster,
/// Schlösser, Warnungen und Offline-Geräte auf einen Blick.
/// Rein informativ und nicht fokussierbar – die Focus-Engine springt
/// direkt in die erste Tile-Reihe.
struct SensorOverview: View {
    @Environment(HomeStore.self) private var store

    var body: some View {
        let summary = store.sensorSummary()
        if summary.isEmpty { EmptyView() } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(chips(for: summary)) { chip in
                        SensorChipView(chip: chip)
                    }
                }
                .padding(.horizontal, HomeDesign.safeAreaH)
            }
            .accessibilityIdentifier("sensors.overview")
        }
    }

    private func chips(for s: SensorSummary) -> [SensorChip] {
        var result: [SensorChip] = []

        // Warnungen zuerst – wichtigste Information ganz links.
        if s.alertCount > 0 {
            result.append(.init(id: "alert", symbol: "exclamationmark.triangle.fill",
                                title: localized("sensors.alert"),
                                value: formatted("sensors.detected %@", s.alertCount),
                                tint: AccessoryPalette.security, isHighlighted: true))
        }
        if let range = s.temperatureRange {
            result.append(.init(id: "temperature", symbol: "thermometer.medium",
                                title: localized("sensors.climate"),
                                value: temperatureText(range),
                                tint: AccessoryPalette.heating, isHighlighted: false))
        }
        if let humidity = s.averageHumidity {
            result.append(.init(id: "humidity", symbol: "humidity.fill",
                                title: localized("sensors.humidity"),
                                value: "\(Int(humidity.rounded())) %",
                                tint: AccessoryPalette.cooling, isHighlighted: false))
        }
        if s.hasMotionSensors {
            result.append(.init(id: "motion", symbol: "figure.walk.motion",
                                title: localized("sensors.motion"),
                                value: s.motionDetectedCount > 0
                                    ? formatted("sensors.detected %@", s.motionDetectedCount)
                                    : localized("sensors.motion.none"),
                                tint: AccessoryPalette.sensorActive,
                                isHighlighted: s.motionDetectedCount > 0))
        }
        if s.hasContactSensors {
            result.append(.init(id: "contacts", symbol: "door.left.hand.open",
                                title: localized("sensors.openings"),
                                value: s.openCount > 0
                                    ? formatted("sensors.open %@", s.openCount)
                                    : localized("sensors.openings.allClosed"),
                                tint: AccessoryPalette.garageOpen,
                                isHighlighted: s.openCount > 0))
        }
        if s.hasLocks {
            result.append(.init(id: "locks", symbol: s.unlockedCount > 0 ? "lock.open.fill" : "lock.fill",
                                title: localized("sensors.locks"),
                                value: s.unlockedCount > 0
                                    ? formatted("sensors.unlocked %@", s.unlockedCount)
                                    : localized("sensors.locks.allLocked"),
                                tint: s.unlockedCount > 0 ? AccessoryPalette.lockOpen : AccessoryPalette.lockSecured,
                                isHighlighted: s.unlockedCount > 0))
        }
        if s.offlineCount > 0 {
            result.append(.init(id: "offline", symbol: "wifi.slash",
                                title: localized("sensors.offline"),
                                value: formatted("sensors.devices %@", s.offlineCount),
                                tint: AccessoryPalette.neutral, isHighlighted: false))
        }
        return result
    }

    private func temperatureText(_ range: ClosedRange<Double>) -> String {
        let lo = Int(range.lowerBound.rounded())
        let hi = Int(range.upperBound.rounded())
        let text = lo == hi ? "\(lo)" : "\(lo)–\(hi)"
        return String(format: NSLocalizedString("status.temperature %@", comment: ""), text)
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private func formatted(_ key: String, _ count: Int) -> String {
        String(format: NSLocalizedString(key, comment: ""), "\(count)")
    }
}

struct SensorChip: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let value: String
    let tint: Color
    /// Hervorgehoben = Zustand verdient Aufmerksamkeit (offen, Bewegung, Alarm).
    let isHighlighted: Bool
}

private struct SensorChipView: View {
    let chip: SensorChip

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: chip.symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(chip.isHighlighted ? .white : chip.tint)
                .frame(width: 52, height: 52)
                .background(
                    Circle().fill(chip.isHighlighted ? Color.white.opacity(0.22) : chip.tint.opacity(0.16))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(chip.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(chip.isHighlighted ? Color.white.opacity(0.8) : Color.secondary)
                    .lineLimit(1)
                Text(chip.value)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(chip.isHighlighted ? Color.white : Color.primary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .padding(.trailing, 28)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(chip.title))
        .accessibilityValue(Text(chip.value))
        .accessibilityIdentifier("sensor.\(chip.id)")
    }

    @ViewBuilder
    private var background: some View {
        if chip.isHighlighted {
            Rectangle().fill(chip.tint)
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}
