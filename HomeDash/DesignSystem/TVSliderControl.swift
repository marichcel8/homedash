import SwiftUI

/// tvOS hat keinen `Slider`. Stepper-Ersatz mit großen ±-Buttons.
/// Ohne Button-Wrapper, damit kein System-Card-Halo erscheint.
struct TVSliderControl: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accent: Color
    let valueText: (Double) -> String
    let onCommit: (Double) -> Void

    init(value: Binding<Double>,
         range: ClosedRange<Double>,
         step: Double = 1,
         accent: Color,
         valueText: @escaping (Double) -> String = { String(Int($0)) },
         onCommit: @escaping (Double) -> Void) {
        self._value = value
        self.range = range
        self.step = step
        self.accent = accent
        self.valueText = valueText
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(spacing: 32) {
            StepperButton(symbol: "minus") {
                let next = (value - step).clamped(to: range)
                value = next
                onCommit(next)
            }
            trackAndValue
            StepperButton(symbol: "plus") {
                let next = (value + step).clamped(to: range)
                value = next
                onCommit(next)
            }
        }
    }

    private var trackAndValue: some View {
        VStack(spacing: 12) {
            Text(valueText(value))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 16)
        }
    }

    private var progress: CGFloat {
        let total = range.upperBound - range.lowerBound
        guard total > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / total)
    }
}

private struct StepperButton: View {
    let symbol: String
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(width: 96, height: 96)
        .focusableTap(isFocused: $isFocused, onTap: action)
        .focusOutlineCircle(isFocused: isFocused)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
