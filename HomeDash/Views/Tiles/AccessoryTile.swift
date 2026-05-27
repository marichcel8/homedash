import SwiftUI
import HomeKit

/// Apple-Home-Style Tile.
///
/// **Warum kein `Button`**: Auf tvOS rendert die UIKit-Focus-Engine bei
/// jedem `Button` einen System-Card-Halo (weißer Glow + Reflexion + Lift).
/// `.buttonStyle(.plain)` und `.focusEffectDisabled()` killen den nicht.
/// Lösung: `.focusable()` auf einer normalen View + manuelle Tap-Gesten.
/// Damit haben wir 100 % Kontrolle über das Aussehen – nur unser eigener
/// Outline ist sichtbar.
///
/// **Interaktion auf tvOS**:
/// - Single Tap (Select) = toggle, wenn das Gerät einen Schalter hat
/// - Long-Press auf Select (~0,5 s) = öffnet Detail (Farben/Helligkeit)
/// - Play/Pause-Knopf = Detail-Shortcut
struct AccessoryTile: View {
    let accessory: HMAccessory
    @Environment(HomeStore.self) private var store
    @FocusState private var isFocused: Bool
    @State private var showDetail = false

    // Lokaler State-Spiegel (siehe Begründung im HomeStore).
    @State private var isActive: Bool = false
    @State private var statusText: String = ""
    @State private var symbolName: String = "app.dashed"
    @State private var accent: Color = .gray
    @State private var isReachable: Bool = true
    @State private var hasRecentFailure: Bool = false

    var body: some View {
        TileShell(
            isActive: isActive,
            isFocused: isFocused,
            accent: accent
        ) {
            VStack(alignment: .leading, spacing: 0) {
                iconBubble
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 6) {
                    Text(accessory.name)
                        .font(HomeDesign.tileTitleFont)
                        .foregroundStyle(textPrimary)
                        .lineLimit(1)
                    if !statusText.isEmpty {
                        Text(statusText)
                            .font(HomeDesign.tileStatusFont)
                            .foregroundStyle(textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Offline-Geräte werden zusätzlich gedimmt, damit auf einen Blick
        // klar ist warum sie nicht reagieren. Warning-Badge hat Vorrang über
        // Offline-Badge (typischer Fall: Write schlug fehl, deshalb wurde
        // Reachability noch nicht aktualisiert).
        .opacity(isReachable ? 1.0 : 0.55)
        .overlay(alignment: .topTrailing) {
            statusBadge
        }
        .contentShape(RoundedRectangle(cornerRadius: HomeDesign.tileCornerRadius,
                                       style: .continuous))
        .focusable(true)
        .focused($isFocused)
        .onTapGesture(perform: handleTap)
        .onLongPressGesture(minimumDuration: 0.5, perform: openDetail)
        .onPlayPauseCommand(perform: openDetail)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessory.name))
        .accessibilityValue(Text(accessibilityValueText))
        // Hint richtet sich nach Tap-Verhalten: bei togglebaren Geräten
        // ist der primäre Tap = umschalten, sonst = Detail öffnen.
        .accessibilityHint(Text(accessory.hasTogglableSwitch
                                ? "a11y.tile.toggle"
                                : "a11y.tile.openDetail",
                                bundle: .main))
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showDetail) {
            AccessoryDetailSheet(accessory: accessory)
                .environment(store)
        }
        .onAppear { syncFromAccessory() }
        .onChange(of: store.revision(for: accessory)) { _, _ in
            syncFromAccessory()
        }
    }

    @ViewBuilder private var statusBadge: some View {
        if hasRecentFailure {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.orange, in: Circle())
                .padding(14)
                .accessibilityHidden(true)
        } else if !isReachable {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.85), in: Circle())
                .padding(14)
                .accessibilityHidden(true)
        }
    }

    private var accessibilityValueText: String {
        var parts: [String] = []
        if !statusText.isEmpty { parts.append(statusText) }
        if hasRecentFailure {
            parts.append(NSLocalizedString("a11y.tile.recentError", comment: ""))
        } else if !isReachable {
            parts.append(NSLocalizedString("a11y.tile.offline", comment: ""))
        }
        return parts.joined(separator: ", ")
    }

    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(iconBubbleFill)
                .frame(width: HomeDesign.iconBubbleSize,
                       height: HomeDesign.iconBubbleSize)
            Image(systemName: symbolName)
                .font(.system(size: HomeDesign.iconSize, weight: .semibold))
                .symbolRenderingMode(isActive ? .monochrome : .hierarchical)
                .foregroundStyle(iconColor)
        }
    }

    // MARK: - Farben (Light/Dark-adaptiv)
    private var iconBubbleFill: Color {
        isActive ? Color.white.opacity(0.22) : accent.opacity(0.16)
    }
    private var iconColor: Color { isActive ? .white : accent }
    private var textPrimary: Color {
        if !isReachable { return .secondary }
        return isActive ? .white : .primary
    }
    private var textSecondary: Color {
        isActive ? Color.white.opacity(0.78) : Color.secondary
    }

    // MARK: - Aktionen
    private func handleTap() {
        if accessory.hasTogglableSwitch {
            isActive.toggle()  // optimistic
            Task {
                await store.toggle(accessory)
                syncFromAccessory()
            }
        } else if accessory.kind.supportsDetailSheet {
            openDetail()
        }
    }

    private func openDetail() { showDetail = true }

    private func syncFromAccessory() {
        isActive = accessory.isActiveForTile
        statusText = accessory.localizedStatus()
        symbolName = accessory.sfSymbol
        accent = accessory.accentColor
        isReachable = accessory.isReachable
        hasRecentFailure = store.didRecentlyFail(accessory.uniqueIdentifier)
    }
}
