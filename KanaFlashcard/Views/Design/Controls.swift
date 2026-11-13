import SwiftUI

// Buttons, chips, progress indicators and the bottom action bar.

// MARK: - Primary action

/// The one primary action of a screen. Lives in `bottomActionBar`, never inside scroll content.
struct PrimaryActionButton: View {
    let title: String
    var systemImage: String?
    var count: Int?
    var tint: Color?
    var isEnabled = true
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if let count, isEnabled {
                    Text("\(count)")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(count)))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.22), in: .capsule)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(tint ?? theme.accentFill)
        .disabled(!isEnabled)
    }
}

extension View {
    /// Pins content (usually one PrimaryActionButton) to the bottom, floating over the content.
    func bottomActionBar<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        safeAreaBar(edge: .bottom) {
            content()
                .frame(maxWidth: 640)
                .padding(.horizontal, Spacing.margin)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Chips and tiles

/// Capsule toggle (select-all chips). 36pt tall with a 44pt touch area.
struct Chip: View {
    let title: String
    let isSelected: Bool
    var isEnabled = true
    /// Fill when not selected. The default suits chips inside a white card; use `.cardFill` on the wash.
    var offFill: Color = .appBase
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .foregroundStyle(isSelected ? Color.white : (isEnabled ? Color.primary : Color.inkSecondary))
            .background(isSelected ? theme.accentFill : offFill, in: .capsule)
            .overlay {
                Capsule().strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
            // Pad first, then set the shape, so the whole 44pt-tall area responds to touch.
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var borderColor: Color {
        if isSelected { return .clear }
        if contrast == .increased { return .primary.opacity(0.4) }
        return .primary.opacity(colorScheme == .dark ? 0.12 : 0.08)
    }
}

/// Square-ish selectable tile (script and JLPT level choices).
struct SelectTile<Content: View>: View {
    let isSelected: Bool
    var isEnabled = true
    var minHeight: CGFloat = 52
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @Environment(\.appTheme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : (isEnabled ? Color.primary : Color.inkSecondary))
                .background(isSelected ? theme.accentFill : Color.appBase, in: shape)
                .overlay {
                    if contrast == .increased && !isSelected {
                        shape.strokeBorder(Color.primary.opacity(0.4), lineWidth: 1.5)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .foregroundStyle(.white)
                            .padding(6)
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Progress

/// 8pt bar for a session in progress.
struct ProgressCapsule: View {
    let value: Double   // 0...1
    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(theme.accent)
                    .frame(width: max(proxy.size.height, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 8)
        .animation(.appSmooth, value: value)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
    }
}

/// Ring for things the learner keeps (unit progress, course total, best score).
struct ProgressRing<Label: View>: View {
    let value: Double   // 0...1
    var size: CGFloat = 44
    var lineWidth: CGFloat = 5
    var color: Color?
    @ViewBuilder var label: () -> Label
    @Environment(\.appTheme) private var theme

    var body: some View {
        let tint = color ?? theme.accent
        ZStack {
            Circle()
                .stroke(tint.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label()
        }
        .frame(width: size, height: size)
        .animation(.appSmooth, value: value)
    }
}

/// A solid green disc with a white checkmark: "complete".
struct CompleteBadge: View {
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.correctFill, in: .circle)
            .accessibilityLabel("Complete")
    }
}
