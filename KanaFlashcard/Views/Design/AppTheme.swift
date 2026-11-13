import SwiftUI
import UIKit

// The app's shared look ("Bold cards"). Every tab has its own accent and colour wash;
// everything else (cards, type, motion, right/wrong colours) is the same across tabs.
// Design rules: see the "Design system" section of CLAUDE.md.

// MARK: - Tabs

enum AppTab: Hashable, CaseIterable {
    case practice, words, kanji, talk

    var theme: AppTheme {
        switch self {
        case .practice:
            return AppTheme(
                accent: Color(light: 0x0B62CC, dark: 0x6FB3FF),
                accentFill: Color(hex: 0x0B62CC),
                washLight: [0xCDE3FF, 0xDAD9FF, 0xE6F1FF, 0xDCE9FC],
                washDark: [0x0B2B57, 0x1B1A52, 0x081B33, 0x071A34]
            )
        case .words:
            return AppTheme(
                accent: Color(light: 0xB5470B, dark: 0xFFA24D),
                accentFill: Color(hex: 0xB5470B),
                washLight: [0xFFE0C2, 0xFFE9B8, 0xFFF1E0, 0xFAE7D7],
                washDark: [0x4A2408, 0x3F3206, 0x2A1606, 0x2C1605]
            )
        case .kanji:
            return AppTheme(
                accent: Color(light: 0x4F46D8, dark: 0xA9A4FF),
                accentFill: Color(hex: 0x4F46D8),
                washLight: [0xDDD9FF, 0xF3D6F5, 0xECEAFF, 0xE5E3FC],
                washDark: [0x211C5C, 0x3A1648, 0x15123A, 0x141137]
            )
        case .talk:
            return AppTheme(
                accent: Color(light: 0x0A7570, dark: 0x5AD1C8),
                accentFill: Color(hex: 0x0A7570),
                washLight: [0xC8EFEA, 0xCFE6FB, 0xE3F7F3, 0xD9F0EF],
                washDark: [0x073F3B, 0x0A2C4A, 0x052422, 0x042623]
            )
        }
    }
}

// MARK: - Theme

struct AppTheme {
    /// Text, glyphs, strokes and progress on cards. Brighter in dark mode.
    let accent: Color
    /// Solid fill behind white text (buttons, selected tiles, answer faces). Same in both modes.
    let accentFill: Color
    /// Wash colours A (strong), B (second hue), C (soft), D (A blended into the base).
    let washLight: [UInt32]
    let washDark: [UInt32]

    func wash(_ index: Int) -> Color {
        Color(light: washLight[index], dark: washDark[index])
    }
}

extension EnvironmentValues {
    /// The theme of the tab a view is in. Set once per tab in ContentView.
    @Entry var appTheme: AppTheme = AppTab.practice.theme
}

// MARK: - Colours

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Card surface: white in light mode, #1C1C1E in dark mode. Always solid.
    static let cardFill = Color(.secondarySystemGroupedBackground)
    /// Screen base under the wash.
    static let appBase = Color(.systemGroupedBackground)
    /// Supporting text on cards and tints. Use instead of `.secondary` (which is too faint on tinted surfaces).
    static let inkSecondary = Color(light: 0x5E5E66, dark: 0xB0B0BA)

    // Right / learned. Always paired with a checkmark symbol.
    static let correct = Color(light: 0x1A7333, dark: 0x30D158)
    static let correctFill = Color(hex: 0x1A7333)
    static let correctTint = Color(light: 0xDFEBE2, dark: 0x20402A)

    // Wrong. Always paired with an xmark symbol.
    static let wrong = Color(light: 0xBF2A22, dark: 0xFF7B73)
    static let wrongFill = Color(hex: 0xBF2A22)
    static let wrongTint = Color(light: 0xF6E1E0, dark: 0x402B2C)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Shape and spacing

enum Radius {
    static let hero: CGFloat = 32       // flashcards, prompt cards, hero and result cards
    static let card: CGFloat = 24       // content cards and rows
    static let choice: CGFloat = 18     // answer choices, tiles
    static let cell: CGFloat = 14       // grid cells, level tiles
}

enum Spacing {
    static let margin: CGFloat = 20     // screen edge
    static let cards: CGFloat = 12      // between sibling cards
    static let section: CGFloat = 28    // between sections
}

// MARK: - Motion

extension Animation {
    /// Default for any state change: critically damped, no overshoot, interruptible.
    static let appSmooth = Animation.spring(response: 0.4, dampingFraction: 1)
    /// Selection and small controls.
    static let appQuick = Animation.spring(response: 0.3, dampingFraction: 1)
    /// Touch-down feedback.
    static let appPress = Animation.spring(response: 0.22, dampingFraction: 1)
    /// Card flips: a little overshoot, because a flip is a physical rotation.
    static let appFlip = Animation.spring(response: 0.4, dampingFraction: 0.8)
    /// Cross-fade used instead of movement when Reduce Motion is on.
    static let appFade = Animation.easeInOut(duration: 0.2)
}

// MARK: - Wash

/// The static colour wash behind every screen of a tab. It never scrolls and never animates.
struct Wash: View {
    enum Style {
        /// Hub screens: colour behind the large title, gone by 60% of the height.
        case browse
        /// Session screens: the whole screen is tinted so the white card stands out.
        case task
    }

    let style: Style
    @Environment(\.appTheme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        if contrast == .increased {
            Color.appBase
        } else {
            let a = theme.wash(0), b = theme.wash(1), c = theme.wash(2), d = theme.wash(3)
            let base = Color.appBase
            switch style {
            case .browse:
                MeshGradient(
                    width: 3, height: 4,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.28], [0.6, 0.24], [1, 0.32],
                        [0, 0.6], [0.5, 0.6], [1, 0.6],
                        [0, 1], [0.5, 1], [1, 1],
                    ],
                    colors: [a, c, b, c, c, d, base, base, base, base, base, base]
                )
            case .task:
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.45, 0.55], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1],
                    ],
                    colors: [a, c, b, c, c, d, d, c, a]
                )
            }
        }
    }
}

extension View {
    /// Puts the tab's wash behind the screen, under the safe areas.
    func appBackground(_ style: Wash.Style) -> some View {
        background {
            Wash(style: style)
                .ignoresSafeArea()
        }
    }

    /// Japanese text is never rounded: learners must see the standard letter shapes.
    func japanese() -> some View {
        fontDesign(.default)
    }
}

extension Text {
    /// Text version of `japanese()`, so a Japanese run can sit inside an interpolated Text.
    func japanese() -> Text {
        fontDesign(.default)
    }
}
