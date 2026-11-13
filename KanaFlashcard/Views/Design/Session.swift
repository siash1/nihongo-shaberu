import SwiftUI

// The frame shared by every study session (flashcards, Kanji lessons and tests)
// and the result card that ends one.

// MARK: - Session chrome

private struct SessionChrome: ViewModifier {
    let title: String
    let remaining: Int?
    let progress: Double?
    let onClose: () -> Void

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appBackground(.task)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // A Close button replaces Back, which also keeps the back swipe from fighting card drags.
            .navigationBarBackButtonHidden(true)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close, action: onClose)
                }
                if let remaining {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(remaining) left")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.appSmooth, value: remaining)
                            .padding(.horizontal, 4)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
            }
            .safeAreaBar(edge: .top) {
                if let progress {
                    ProgressCapsule(value: progress)
                        .frame(maxWidth: 640)
                        .padding(.horizontal, Spacing.margin)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }
            }
    }
}

extension View {
    /// Inline title, Close button, "N left", progress bar, hidden tab bar and the full-screen wash.
    func sessionChrome(
        title: String,
        remaining: Int? = nil,
        progress: Double? = nil,
        onClose: @escaping () -> Void
    ) -> some View {
        modifier(SessionChrome(title: title, remaining: remaining, progress: progress, onClose: onClose))
    }
}

// MARK: - Result card

/// The last card of every session: the score is the largest text in the app.
struct ResultCard: View {
    enum Kind { case success, empty }

    var kind: Kind = .success
    let eyebrow: String
    /// Hero number such as "8/10". Omitted for "Review complete" and empty results.
    var score: String?
    var caption: String?
    var title: String?
    var message: String?
    /// Kanji learned in a lesson, shown as practice squares.
    var kanji: [String] = []

    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                card
                    .frame(maxWidth: min(proxy.size.width - 48, 420))
                    .padding(.top, 52)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var card: some View {
        VStack(spacing: 12) {
            Eyebrow(text: eyebrow)
                .padding(.top, 40)

            if let title {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }

            if let score {
                Text(score)
                    .font(.system(size: 72, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if let caption {
                Text(caption)
                    .font(.title3)
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            if !kanji.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56, maximum: 56), spacing: 8)], spacing: 8) {
                    ForEach(kanji.indices, id: \.self) { index in
                        PracticeSquare(text: kanji[index], side: 56)
                    }
                }
                .padding(.top, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Learned: \(kanji.joined(separator: ", "))")
            }

            if let message {
                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .heroCard(padding: 24)
        .overlay(alignment: .top) {
            badge
                .offset(y: -36)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var badge: some View {
        switch kind {
        case .success:
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.correctFill, in: .circle)
                .overlay { Circle().strokeBorder(Color.cardFill, lineWidth: 4) }
                .accessibilityHidden(true)
        case .empty:
            Image(systemName: "tray")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
                .frame(width: 72, height: 72)
                .background(Color.appBase, in: .circle)
                .overlay { Circle().strokeBorder(Color.cardFill, lineWidth: 4) }
                .accessibilityHidden(true)
        }
    }
}
