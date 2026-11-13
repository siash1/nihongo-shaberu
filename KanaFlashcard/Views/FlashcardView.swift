import SwiftUI

/// Practice session: a deck of kana cards. Tap to flip, throw right if you knew it, left if not.
struct FlashcardView: View {
    @Bindable var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var deck = DeckController<KanaCharacter>()
    @State private var didStart = false

    /// The result replaces the deck only once the last card has finished flying off,
    /// so its throw and its haptic are not cut short.
    private var showsResult: Bool {
        viewModel.isPracticeComplete && deck.flying.isEmpty
    }

    var body: some View {
        ZStack {
            if showsResult {
                ResultCard(
                    eyebrow: "Practice complete",
                    score: viewModel.scoreText,
                    caption: "correct on first try"
                )
                .transition(reduceMotion ? .opacity : .offset(y: 24).combined(with: .opacity))
            } else {
                SwipeDeck(
                    controller: deck,
                    item: viewModel.currentCard,
                    remaining: viewModel.remainingCount,
                    isRevealed: viewModel.isAnswerRevealed,
                    accessibilityLabel: { "\($0.type.rawValue) \($0.character)" },
                    accessibilityAnswer: { $0.romaji }
                ) { card in
                    front(card)
                } back: { card in
                    back(card)
                }
                .padding(.vertical, 8)
            }
        }
        .animation(reduceMotion ? .appFade : .appSmooth, value: showsResult)
        .sessionChrome(
            title: "Practice",
            remaining: viewModel.isPracticeComplete ? nil : viewModel.remainingCount,
            progress: progress,
            onClose: { dismiss() }
        )
        .bottomActionBar {
            if showsResult {
                PrimaryActionButton(title: "Done") { dismiss() }
            } else {
                DeckActionBar(controller: deck, item: viewModel.currentCard, isRevealed: viewModel.isAnswerRevealed)
            }
        }
        .onAppear(perform: start)
    }

    /// Share of the selected characters already cleared. A missed card stays in the count.
    private var progress: Double {
        guard viewModel.totalCards > 0 else { return 0 }
        if viewModel.isPracticeComplete { return 1 }
        return 1 - Double(viewModel.remainingCount) / Double(viewModel.totalCards)
    }

    private func start() {
        // onAppear can run again if a dismissal is cancelled; never restart the deck then.
        guard !didStart else { return }
        didStart = true
        deck.onReveal = { viewModel.revealAnswer() }
        deck.onGrade = { correct in
            if correct {
                viewModel.markCorrect()
            } else {
                viewModel.markWrong()
            }
        }
        viewModel.startPractice()
    }

    // MARK: - Faces

    private func front(_ card: KanaCharacter) -> some View {
        VStack(spacing: 16) {
            HStack {
                ScriptBadge(text: card.type.rawValue)
                Spacer()
            }
            GeometryReader { proxy in
                PracticeSquare(text: card.character, side: max(80, min(240, proxy.size.width, proxy.size.height)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func back(_ card: KanaCharacter) -> some View {
        VStack(spacing: 16) {
            HStack {
                Eyebrow(text: "Answer", onFill: true)
                Spacer()
            }
            Spacer(minLength: 0)
            PracticeSquare(text: card.character, side: 88, style: .onFill)
            Text(card.romaji)
                .font(.system(size: 76, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
        }
    }
}

/// Small capsule naming the script (HIRAGANA, KATAKANA) or level at the top of a card.
struct ScriptBadge: View {
    let text: String
    @Environment(\.appTheme) private var theme

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(theme.accent.opacity(0.12), in: .capsule)
    }
}
