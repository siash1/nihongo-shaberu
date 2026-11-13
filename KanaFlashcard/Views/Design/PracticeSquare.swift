import SwiftUI

// The app's signature element: every Japanese glyph being studied sits in a practice square
// with dashed centre guides, the writing grid Japanese children learn in.
// Use it only around Japanese to be studied: never on grid cells, list rows or as decoration.

struct PracticeSquare: View {
    enum Style {
        /// On a white card: tinted square, ink glyph.
        case plain
        /// On a solid accent surface: white square lines, white glyph.
        case onFill
    }

    let text: String
    var side: CGFloat
    var style: Style = .plain
    @Environment(\.appTheme) private var theme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
        ZStack {
            shape.fill(fill)
            shape.strokeBorder(line.opacity(style == .plain ? 0.3 : 0.4), lineWidth: 1.5)
            if side >= 56 {
                guides
            }
            Text(text)
                .font(.system(size: side * 0.62, weight: .medium))
                .japanese()
                .foregroundStyle(style == .plain ? Color.primary : Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(side * 0.06)
        }
        .frame(width: side, height: side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var fill: Color {
        style == .plain ? theme.accent.opacity(0.07) : Color.white.opacity(0.16)
    }

    private var line: Color {
        style == .plain ? theme.accent : .white
    }

    private var guides: some View {
        let inset = side * 0.08
        return Path { path in
            path.move(to: CGPoint(x: side / 2, y: inset))
            path.addLine(to: CGPoint(x: side / 2, y: side - inset))
            path.move(to: CGPoint(x: inset, y: side / 2))
            path.addLine(to: CGPoint(x: side - inset, y: side / 2))
        }
        .stroke(line.opacity(style == .plain ? 0.3 : 0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        .frame(width: side, height: side)
    }
}

/// A word set one character per square, wrapping after `perRow` squares.
/// Words longer than two rows fall back to plain large text.
struct PracticeSquareWord: View {
    let word: String
    /// Width available for the row of squares.
    let width: CGFloat
    var maxSide: CGFloat = 96
    var perRow = 5
    var style: PracticeSquare.Style = .plain

    private let gap: CGFloat = 6

    var body: some View {
        let characters = Array(word).map(String.init)
        if characters.count > perRow * 2 || characters.isEmpty {
            Text(word)
                .font(.system(size: 48, weight: .medium))
                .japanese()
                .foregroundStyle(style == .plain ? Color.primary : Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
        } else {
            let columns = min(perRow, characters.count)
            let side = max(24, min(maxSide, (width - gap * CGFloat(columns - 1)) / CGFloat(columns)))
            let rows = stride(from: 0, to: characters.count, by: columns).map {
                Array(characters[$0..<min($0 + columns, characters.count)])
            }
            VStack(spacing: gap) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: gap) {
                        ForEach(rows[rowIndex].indices, id: \.self) { index in
                            PracticeSquare(text: rows[rowIndex][index], side: side, style: style)
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(word)
        }
    }
}
