import SwiftUI

// Cards, press feedback and section headers shared by every tab.

// MARK: - Press feedback

/// Reacts the instant a custom surface is touched (cards, rows, cells, tiles).
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        PressBody(configuration: configuration, scale: scale)
    }

    private struct PressBody: View {
        let configuration: ButtonStyleConfiguration
        let scale: CGFloat
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
                .opacity(configuration.isPressed ? 0.85 : 1)
                .animation(.appPress, value: configuration.isPressed)
        }
    }
}

// MARK: - Content card

/// Standard card: solid surface, radius 24, a soft shadow in light mode and a rim in dark mode.
private struct ContentCardModifier: ViewModifier {
    let padding: CGFloat
    let fill: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
    }

    private var borderColor: Color {
        if contrast == .increased { return .primary.opacity(0.4) }
        return colorScheme == .dark ? .white.opacity(0.08) : .clear
    }
}

// MARK: - Hero card

/// The card for the thing being studied: radius 32, an accent-tinted shadow in light mode.
private struct HeroCardModifier: ViewModifier {
    let fill: Color
    let padding: CGFloat
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background { HeroShape(fill: fill) }
    }
}

/// The hero card's background on its own, for cards that lay out their own content (flashcards).
struct HeroShape: View {
    var fill: Color = .cardFill
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
        shape
            .fill(fill)
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.55) : theme.accentFill.opacity(0.2),
                radius: colorScheme == .dark ? 24 : 30,
                y: colorScheme == .dark ? 12 : 16
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 2, y: 1)
            .overlay {
                shape.strokeBorder(rimColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
    }

    private var rimColor: Color {
        if contrast == .increased { return .primary.opacity(0.4) }
        return colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.05)
    }
}

extension View {
    /// Standard content card (radius 24).
    func contentCard(padding: CGFloat = 18, fill: Color = .cardFill) -> some View {
        modifier(ContentCardModifier(padding: padding, fill: fill))
    }

    /// Hero card (radius 32) for the thing being studied.
    func heroCard(fill: Color = .cardFill, padding: CGFloat = 24) -> some View {
        modifier(HeroCardModifier(fill: fill, padding: padding))
    }
}

// MARK: - Headers and labels

/// Section title that sits directly on the wash. The detail moves under the title at large text sizes.
struct SectionHeader: View {
    let title: String
    var detail: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        layout {
            Text(title)
                .font(.title2.bold())
            if !stacked {
                Spacer(minLength: 8)
            }
            if let detail {
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary.opacity(0.72))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Small uppercase label at the top of a card, in the tab's accent.
struct Eyebrow: View {
    let text: String
    var onFill = false
    @Environment(\.appTheme) private var theme

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(onFill ? Color.white.opacity(0.9) : theme.accent)
    }
}

/// One-line subtitle under a large title, sitting on the wash.
struct ScreenSubtitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary.opacity(0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A 44pt circle holding an icon (used at the start of navigation rows).
struct IconCircle: View {
    let systemImage: String
    var size: CGFloat = 44
    @Environment(\.appTheme) private var theme

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3)
            .dynamicTypeSize(...DynamicTypeSize.large)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(theme.accent)
            .frame(width: size, height: size)
            .background(theme.accent.opacity(0.14), in: .circle)
            .accessibilityHidden(true)
    }
}

/// Round speaker button that plays a word or sentence.
struct SpeakButton: View {
    let label: String
    var onFill = false
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(onFill ? Color.white : theme.accent)
                .frame(width: 44, height: 44)
                .background(onFill ? Color.white.opacity(0.2) : theme.accent.opacity(0.14), in: .circle)
        }
        .buttonStyle(PressStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}

/// Status line on a card: a symbol plus a short label in a semantic colour.
struct StatusLabel: View {
    let isCorrect: Bool
    var correctText = "Correct"
    var wrongText = "Not quite"

    var body: some View {
        Label(isCorrect ? correctText : wrongText, systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.headline)
            .foregroundStyle(isCorrect ? Color.correct : Color.wrong)
    }
}

/// An inline error shown inside a card.
struct ErrorBanner: View {
    let message: String
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.wrong)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wrongTint, in: shape)
        .overlay {
            if contrast == .increased {
                shape.strokeBorder(Color.wrong, lineWidth: 2)
            }
        }
    }
}
