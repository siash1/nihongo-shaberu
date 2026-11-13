import SwiftUI

/// Words session: a deck of AI-written (or saved) words. Tap to flip, throw right if you knew it, left if not.
struct WordFlashcardView: View {
    @Bindable var viewModel: WordPracticeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var deck = DeckController<WordCard>()
    @State private var didStart = false
    /// The view model keeps its total private, so the largest count seen in this run stands in for it.
    @State private var total = 0
    /// Set by Done. The view model is reset once the screen has gone, so the result stays put during the pop.
    @State private var resetOnExit = false
    @State private var retryTask: Task<Void, Never>?
    @ScaledMetric(relativeTo: .largeTitle) private var romajiSize: CGFloat = 44

    private enum Phase: Equatable {
        case starting
        case loading
        case deck
        case complete
        case loadFailed(String)
        case nothingToTest
    }

    private var isTest: Bool {
        viewModel.practiceMode == .test
    }

    private var phase: Phase {
        // Before the start runs, a new generation is about to load; never show a stale card.
        if !didStart { return isTest ? .starting : .loading }
        if viewModel.isLoading { return .loading }
        // Let the last card finish flying off (and its haptic play) before the result replaces the deck.
        if viewModel.isPracticeComplete { return deck.flying.isEmpty ? .complete : .deck }
        if viewModel.currentCard != nil { return .deck }
        if let error = viewModel.errorMessage { return isTest ? .nothingToTest : .loadFailed(error) }
        return .starting
    }

    var body: some View {
        let current = self.phase
        ZStack {
            switch current {
            case .starting:
                Color.clear
            case .loading:
                DeckPlaceholder(badge: badgeText(viewModel.selectedLevel)) {
                    loadingContent
                }
                .padding(.vertical, 8)
                .transition(swap)
            case .deck:
                SwipeDeck(
                    controller: deck,
                    item: viewModel.currentCard,
                    remaining: viewModel.remainingCount,
                    isRevealed: viewModel.isAnswerRevealed,
                    accessibilityLabel: { $0.word },
                    accessibilityAnswer: { "\($0.romaji), \($0.meaning)" }
                ) { card in
                    front(card)
                } back: { card in
                    back(card)
                }
                .padding(.vertical, 8)
                .transition(swap)
            case .complete:
                ResultCard(
                    eyebrow: isTest ? "Test complete" : "Practice complete",
                    score: viewModel.scoreText,
                    caption: "correct on first try"
                )
                .transition(reduceMotion ? .opacity : .offset(y: 24).combined(with: .opacity))
            case .loadFailed(let message):
                DeckPlaceholder {
                    errorContent(message)
                }
                .padding(.vertical, 8)
                .transition(swap)
            case .nothingToTest:
                ResultCard(
                    kind: .empty,
                    eyebrow: "Word test",
                    title: "No words to test",
                    message: "Practice new words at these levels first, then come back to test yourself."
                )
                .transition(reduceMotion ? .opacity : .offset(y: 24).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .appFade : .appSmooth, value: current)
        .sessionChrome(
            title: isTest ? "Word Test" : "Word Practice",
            remaining: current == .deck ? viewModel.remainingCount : nil,
            progress: progress(for: current),
            // With nothing to test there is nothing to come back to, so Close clears it like Done.
            onClose: { current == .nothingToTest ? finish() : dismiss() }
        )
        .bottomActionBar {
            bottomBar(for: current)
        }
        .task { await start() }
        .onChange(of: viewModel.remainingCount) { _, count in
            total = max(total, count)
        }
        .onChange(of: viewModel.isLoading) { _, loading in
            if loading { total = 0 }
        }
        .onDisappear {
            retryTask?.cancel()
            if resetOnExit { viewModel.reset() }
        }
    }

    /// Loading, error and the deck replace each other in place, so the card surface cross-fades.
    private var swap: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    /// Share of this run's words already cleared. A missed word stays in the count.
    private func progress(for phase: Phase) -> Double {
        switch phase {
        case .complete:
            return 1
        case .deck:
            let denominator = max(total, viewModel.remainingCount)
            guard denominator > 0 else { return 0 }
            return 1 - Double(viewModel.remainingCount) / Double(denominator)
        default:
            return 0
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private func bottomBar(for phase: Phase) -> some View {
        Group {
            switch phase {
            case .starting, .loading:
                // Nothing to press yet, but the space is kept so the card does not move when words arrive.
                PrimaryActionButton(title: "Show Answer") {}
                    .hidden()
                    .accessibilityHidden(true)
            case .deck:
                DeckActionBar(controller: deck, item: viewModel.currentCard, isRevealed: viewModel.isAnswerRevealed)
            case .complete, .nothingToTest:
                PrimaryActionButton(title: "Done", action: finish)
                    .transition(swap)
            case .loadFailed:
                PrimaryActionButton(title: "Try Again", systemImage: "arrow.clockwise", action: retry)
                    .transition(swap)
            }
        }
        .animation(reduceMotion ? .appFade : .appSmooth, value: phase)
    }

    // MARK: - Actions

    private func start() async {
        // .task can run again if a dismissal is cancelled; never restart the session then.
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
        // Clear anything an earlier, closed session left behind, keeping the chosen mode.
        let mode = viewModel.practiceMode
        viewModel.reset()
        viewModel.practiceMode = mode
        total = 0

        switch mode {
        case .generate:
            await viewModel.fetchWords()
            // Closing the screen while loading cancels the request on purpose; that is not an error to report.
            if Task.isCancelled {
                viewModel.errorMessage = nil
            }
        case .test:
            viewModel.startTest()
        }
        // Reset and start run in one update, so onChange misses a new count equal to a stale one
        // (a test closed midway and started again); take the starting count directly.
        total = max(total, viewModel.remainingCount)
    }

    /// Tied to the screen: closing it cancels the request, so it cannot take over the next session.
    private func retry() {
        total = 0
        retryTask?.cancel()
        retryTask = Task {
            await viewModel.fetchWords()
            if Task.isCancelled {
                // Closing the screen while loading cancels on purpose; that is not an error to report.
                viewModel.errorMessage = nil
                return
            }
            total = max(total, viewModel.remainingCount)
        }
    }

    private func finish() {
        resetOnExit = true
        dismiss()
    }

    private func badgeText(_ level: JLPTLevel) -> String {
        // A test mixes scripts, so its cards only name the level.
        isTest ? level.rawValue : "\(level.rawValue) · \(viewModel.selectedScript)"
    }

    // MARK: - Faces

    private func front(_ card: WordCard) -> some View {
        VStack(spacing: 16) {
            HStack {
                ScriptBadge(text: badgeText(card.level))
                Spacer()
            }
            GeometryReader { proxy in
                PracticeSquareWord(
                    word: card.word,
                    width: proxy.size.width,
                    maxSide: squareSide(for: card.word, height: proxy.size.height),
                    perRow: 5
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// Squares are at most 88pt and shrink so every row fits the face's height (landscape, short cards).
    private func squareSide(for word: String, height: CGFloat) -> CGFloat {
        let rows = CGFloat((max(word.count, 1) + 4) / 5)
        return max(24, min(88, (height - 6 * (rows - 1)) / rows))
    }

    private func back(_ card: WordCard) -> some View {
        VStack(spacing: 12) {
            HStack {
                Eyebrow(text: "Answer", onFill: true)
                Spacer()
            }
            // The card never grows or scrolls. When the answer needs the room (large text, landscape)
            // the word, which the front already shows, makes way for the romaji and meaning.
            ViewThatFits(in: .vertical) {
                answer(card, showsWord: true)
                answer(card, showsWord: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func answer(_ card: WordCard, showsWord: Bool) -> some View {
        VStack(spacing: 12) {
            if showsWord {
                Text(card.word)
                    .font(.title)
                    .japanese()
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            Text(card.romaji)
                .font(.system(size: romajiSize, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(card.meaning)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: - Loading and error

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .padding(.bottom, 4)
            Text("Writing your 10 words…")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("This takes a few seconds")
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.wrong)
                .accessibilityHidden(true)
            Text("Couldn’t load words")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(5)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Deck placeholder

/// A card the size and position of the deck's top card, with the pile behind it, for the loading
/// and error states. Its geometry mirrors SwipeDeck so the first word lands exactly where it was.
private struct DeckPlaceholder<Content: View>: View {
    var badge: String?
    @ViewBuilder let content: () -> Content
    @Environment(\.appTheme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, min(proxy.size.width - 48, 400))
            let height = max(200, min(width * 1.3, proxy.size.height - 40))

            ZStack {
                ForEach([2, 1], id: \.self) { depth in
                    pileCard(depth: CGFloat(depth), width: width, height: height)
                }

                VStack(spacing: 16) {
                    if let badge {
                        HStack {
                            ScriptBadge(text: badge)
                            Spacer()
                        }
                    }
                    content()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(24)
                .frame(width: width, height: height)
                .background { HeroShape() }
                .offset(y: -12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func pileCard(depth: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
        return shape
            .fill(Color.cardFill)
            .overlay { shape.fill(theme.accent.opacity(0.06 * depth)) }
            .overlay {
                shape.strokeBorder(Color.primary.opacity(contrast == .increased ? 0.4 : 0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .frame(width: width, height: height)
            .scaleEffect(1 - 0.06 * depth, anchor: .bottom)
            .offset(y: 12 * depth - 12)
            .accessibilityHidden(true)
    }
}
