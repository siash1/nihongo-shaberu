import SwiftUI

/// Runs a multiple-choice test: kanji, words, sentences, or a mixed review.
///
/// Answering is tap-only. On Continue the answered question leaves like a thrown card:
/// to the right when it was right, to the left when it was missed (it goes back into the pile),
/// and the next question rises from the pile.
struct KanjiQuizView: View {
    @Bindable var viewModel: KanjiViewModel
    let title: String
    let makeQuestions: () -> [KanjiQuizQuestion]
    var onFinish: (Int) -> Void = { _ in }

    @State private var session: KanjiQuizSession?
    @State private var isAdvancing = false   // a question change is still animating
    @State private var width: CGFloat = 400  // screen width, so a thrown question fully leaves it
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let session {
                content(session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        .sessionChrome(
            title: title,
            remaining: remaining,
            progress: session?.progress ?? 0,
            onClose: { dismiss() }
        )
        .bottomActionBar {
            bottomBar
        }
        // Haptic lands on the same frame as the right/wrong colours.
        .sensoryFeedback(trigger: session?.answerCount ?? 0) { _, _ in
            session?.answeredCorrectly == true ? .success : .error
        }
        .onAppear {
            if session == nil {
                session = KanjiQuizSession(questions: makeQuestions())
            }
        }
        .onDisappear {
            viewModel.stopSpeaking()
        }
    }

    private var remaining: Int? {
        guard let session, !session.isComplete else { return nil }
        return session.remainingCount
    }

    private var stepAnimation: Animation {
        reduceMotion ? .appFade : .appSmooth
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ session: KanjiQuizSession) -> some View {
        if let question = session.currentQuestion {
            ScrollView {
                KanjiQuestionView(
                    question: question,
                    selectedChoice: session.selectedChoice,
                    onSelect: { choice in
                        withAnimation(.appSmooth) {
                            session.select(choice)
                        }
                        // The score counts as soon as the last answer is in,
                        // even if the learner leaves before tapping Continue.
                        if session.isFinalAnswer {
                            onFinish(session.scorePercent)
                        }
                    },
                    onSpeak: { viewModel.speak($0) }
                )
                .frame(maxWidth: 640)
                .padding(.horizontal, Spacing.margin)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            // A new identity for every presentation, so a missed question that comes straight
            // back still arrives like any other.
            .id(session.presentationNumber)
            // SwiftUI removes a view with the transition it had in its last render, which is the
            // answered state: so the direction comes from the answer, before advance() runs.
            .transition(questionTransition(leavesRight: session.answeredCorrectly))
        } else if session.isComplete {
            result(session)
                .transition(reduceMotion ? .opacity : AnyTransition(QuizArrival()))
        }
    }

    @ViewBuilder
    private func result(_ session: KanjiQuizSession) -> some View {
        if session.totalCount == 0 {
            ResultCard(
                kind: .empty,
                eyebrow: title,
                title: "Nothing to Test Yet",
                message: "Learn some kanji first, then come back."
            )
        } else {
            ResultCard(
                eyebrow: "Test complete",
                score: session.scoreText,
                caption: "correct on first try"
            )
        }
    }

    private func questionTransition(leavesRight: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return AnyTransition(
            AsymmetricTransition(
                insertion: QuizArrival(),
                removal: QuizThrow(direction: leavesRight ? 1 : -1, distance: width + 100)
            )
        )
    }

    // MARK: - Bottom action

    @ViewBuilder
    private var bottomBar: some View {
        if let session {
            if session.isComplete {
                PrimaryActionButton(title: "Done") {
                    // Ignore the second tap of a double-tap on the last "Continue".
                    guard !isAdvancing else { return }
                    dismiss()
                }
                .transition(.quizMaterialize(reduceMotion: reduceMotion))
            } else if session.isAnswered {
                PrimaryActionButton(title: "Continue") {
                    guard !isAdvancing else { return }
                    isAdvancing = true
                    withAnimation(stepAnimation) {
                        session.advance()
                    } completion: {
                        isAdvancing = false
                    }
                }
                .transition(.quizMaterialize(reduceMotion: reduceMotion))
            }
        }
    }
}

// MARK: - Question motion

/// An answered question leaves like a thrown card: off the side of the screen with a slight turn.
private struct QuizThrow: Transition {
    let direction: CGFloat   // 1 = right (correct), -1 = left (missed)
    let distance: CGFloat

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(.degrees(phase.isIdentity ? 0 : 8 * direction))
            .offset(x: phase.isIdentity ? 0 : distance * direction)
    }
}

/// The next question rises from the pile, like a promoted card.
private struct QuizArrival: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.94)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

private extension AnyTransition {
    /// A floating control arriving in place: blur and scale together rather than a plain fade.
    static func quizMaterialize(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }
}

// MARK: - Question

/// One multiple-choice question. The prompt sits on a white card; once answered, the card flips
/// to its answer face (the tab colour) with the reading, meaning and memory story, and the choices
/// turn green or red. Tapping the answered card flips between question and answer.
struct KanjiQuestionView: View {
    let question: KanjiQuizQuestion
    let selectedChoice: String?
    let onSelect: (String) -> Void
    let onSpeak: (String) -> Void

    @State private var showsQuestion = false     // the answered card was turned back to its question
    @State private var isCardPressed = false     // a finger is on the answered card
    @State private var promptWidth: CGFloat = 280 // inner width of the prompt card, for word squares
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAnswered: Bool {
        selectedChoice != nil
    }

    private var isCorrect: Bool {
        selectedChoice == question.answer
    }

    private var showsAnswer: Bool {
        isAnswered && !showsQuestion
    }

    var body: some View {
        VStack(spacing: 16) {
            promptCard
            choices
        }
        .onChange(of: question.id) {
            showsQuestion = false
        }
    }

    // MARK: Prompt card

    /// Once answered, the card is a button that turns between question and answer, and it presses in
    /// under the finger like every other tappable surface. The speaker on the answer face is a button
    /// of its own, so it rides on a layer that turns with the card rather than inside the card's button.
    private var promptCard: some View {
        let angle: Double = showsAnswer ? 180 : 0
        let flip: Animation = reduceMotion ? .appFade : .appFlip

        return Button {
            guard isAnswered else { return }
            showsQuestion.toggle()
        } label: {
            FlipCard(angle: angle, reduceMotion: reduceMotion) {
                questionFace
            } back: {
                answerFace
            }
            .animation(flip, value: showsAnswer)
            .contentShape(.rect(cornerRadius: Radius.hero, style: .continuous))
        }
        .buttonStyle(PressReportingStyle(isPressed: $isCardPressed))
        // Before an answer there is nothing to turn over, so touches go to the scroll view.
        .allowsHitTesting(isAnswered)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint(cardAccessibilityHint)
        .accessibilityRemoveTraits(isAnswered ? [] : .isButton)
        .overlay {
            if !question.reveal.speech.isEmpty {
                speakerLayer(angle: angle)
                    .animation(flip, value: showsAnswer)
            }
        }
        // Both faces are measured up front: the card takes the taller one's height from the start,
        // so the choices below never jump when it flips.
        .fixedSize(horizontal: false, vertical: true)
        // Card and speaker press in together. Scoped, so the press spring never drives the flip.
        .animation(.appPress) { content in
            content
                .scaleEffect(isCardPressed && !reduceMotion ? 0.97 : 1)
                .opacity(isCardPressed ? 0.85 : 1)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showsQuestion)
    }

    /// The answer face's speaker: a second card layer at the same size and angle, empty on the front,
    /// so the button turns exactly with the card.
    private func speakerLayer(angle: Double) -> some View {
        let reveal = question.reveal
        return FlipCard(angle: angle, reduceMotion: reduceMotion) {
            Color.clear
        } back: {
            SpeakButton(label: "Listen to \(reveal.reading.isEmpty ? reveal.japanese : reveal.reading)", onFill: true) {
                onSpeak(reveal.speech)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .allowsHitTesting(showsAnswer)
        .accessibilityHidden(!showsAnswer)
    }

    private var cardAccessibilityLabel: String {
        guard showsAnswer else {
            // The fill-in blank is drawn as two full-width lines; say "blank" instead of the symbols.
            let prompt = question.prompt.replacingOccurrences(of: "＿\u{2060}＿", with: " blank ")
            return ([question.instruction, prompt] + [question.hint].compactMap { $0 })
                .joined(separator: ", ")
        }
        let reveal = question.reveal
        var parts = [isCorrect ? "Correct" : "Not quite", reveal.japanese]
        if !reveal.reading.isEmpty {
            parts += [reveal.reading, reveal.romaji]
        }
        parts.append(reveal.meaning)
        if let note = reveal.note {
            parts.append("Memory story: \(note)")
        }
        return parts.joined(separator: ". ")
    }

    private var cardAccessibilityHint: String {
        guard isAnswered else { return "" }
        return showsAnswer ? "Shows the question again" : "Shows the answer"
    }

    private var minPromptHeight: CGFloat {
        if question.promptStyle == .sentence || dynamicTypeSize.isAccessibilitySize { return 0 }
        return 220
    }

    private var questionFace: some View {
        VStack(spacing: 0) {
            Eyebrow(text: question.instruction)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                prompt

                if let hint = question.hint {
                    Text(hint)
                        .font(.body)
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)
        }
        // Ink, not the button tint, for the prompt text inside the card's button.
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            promptWidth = newWidth
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: minPromptHeight, maxHeight: .infinity)
        .background { HeroShape() }
    }

    @ViewBuilder
    private var prompt: some View {
        switch question.promptStyle {
        case .kanji:
            PracticeSquare(text: question.prompt, side: 160)
        case .word:
            PracticeSquareWord(word: question.prompt, width: promptWidth, maxSide: 88)
        case .sentence:
            Text(question.prompt)
                .font(.title)
                .japanese()
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        case .meaning:
            Text(question.prompt)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
        }
    }

    // MARK: Answer face

    private var answerFace: some View {
        let reveal = question.reveal

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                statusPill
                Spacer(minLength: 0)
                if !reveal.speech.isEmpty {
                    // Room for the speaker, which turns with the card on its own layer (speakerLayer).
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reveal.japanese)
                    .font(.title.weight(.semibold))
                    .japanese()
                    .lineSpacing(6)

                if !reveal.reading.isEmpty {
                    Text(reveal.reading)
                        .font(.body)
                        .japanese()
                        .lineSpacing(6)
                    Text(reveal.romaji)
                        .font(.subheadline.weight(.semibold))
                }

                Text(reveal.meaning)
                    .font(.body)
                    .padding(.top, 4)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let note = reveal.note {
                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 1)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                    quizMixedText(note)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { HeroShape(fill: theme.accentFill) }
    }

    /// White pill on the answer face. It keeps the light-mode greens and reds in dark mode too,
    /// because the pill itself stays white.
    private var statusPill: some View {
        Label(isCorrect ? "Correct" : "Not quite", systemImage: isCorrect ? "checkmark" : "xmark")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isCorrect ? Color.correct : Color.wrong)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white, in: .capsule)
            .environment(\.colorScheme, .light)
    }

    // MARK: Choices

    /// Two columns of square tiles for short Japanese choices; one column for everything else.
    private var usesTwoColumns: Bool {
        guard question.largeChoices else { return false }
        let longest = question.choices.map(\.count).max() ?? 0
        return longest <= 1 || (longest <= 3 && !dynamicTypeSize.isAccessibilitySize)
    }

    private var choices: some View {
        let twoColumns = usesTwoColumns

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: twoColumns ? 2 : 1),
            spacing: 10
        ) {
            ForEach(question.choices, id: \.self) { choice in
                QuizChoiceTile(
                    text: choice,
                    status: status(of: choice),
                    isPick: choice == selectedChoice,
                    isSquare: twoColumns
                ) {
                    onSelect(choice)
                }
                .disabled(isAnswered)
            }
        }
    }

    private func status(of choice: String) -> QuizChoiceTile.Status {
        guard isAnswered else { return .idle }
        if choice == question.answer { return .correct }
        return choice == selectedChoice ? .wrong : .dimmed
    }
}

// MARK: - Choice tile

/// One answer. Solid green with a checkmark when it is the answer, solid red with an xmark when it
/// was a wrong pick, faded otherwise: right and wrong never rely on colour alone.
private struct QuizChoiceTile: View {
    enum Status {
        case idle, correct, wrong, dimmed
    }

    let text: String
    let status: Status
    let isPick: Bool
    /// An 84pt tile in a two-column grid (short Japanese choices).
    let isSquare: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(PressStyle(scale: isSquare ? 0.94 : 0.97))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isPick ? .isSelected : [])
    }

    private var label: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.choice, style: .continuous)
        let isSolid = status == .correct || status == .wrong

        // Kana and kanji in the standard face, romaji and English rounded (にほん · nihon).
        return quizMixedText(text)
            .font(font)
            .multilineTextAlignment(.center)
            .lineLimit(isSquare ? 1 : nil)
            .minimumScaleFactor(isSquare ? 0.5 : 1)
            .fixedSize(horizontal: false, vertical: !isSquare)
            .foregroundStyle(isSolid ? Color.white : Color.primary)
            .padding(.horizontal, isSquare ? 28 : 48)
            .padding(.vertical, isSquare ? 6 : 12)
            .frame(maxWidth: .infinity, minHeight: isSquare ? 84 : 60)
            .background {
                shape
                    .fill(fill)
                    .shadow(color: .black.opacity(status == .idle && colorScheme == .light ? 0.06 : 0), radius: 10, y: 3)
            }
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
            .overlay(alignment: isSquare ? .topTrailing : .trailing) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.title3)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // stays clear of the text beside it
                        .foregroundStyle(.white)
                        .padding(isSquare ? 8 : 14)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .opacity(status == .dimmed ? 0.45 : 1)
            .contentShape(shape)
    }

    private var font: Font {
        // A single kanji is a display glyph in its tile: fixed size, like the practice square.
        if isSquare && text.count == 1 {
            return .system(size: 40, weight: .medium)
        }
        return .title3.weight(.semibold)
    }

    private var fill: Color {
        switch status {
        case .correct: return .correctFill
        case .wrong: return .wrongFill
        case .idle, .dimmed: return .cardFill
        }
    }

    private var borderColor: Color {
        switch status {
        case .correct, .wrong:
            return .clear
        case .idle, .dimmed:
            if contrast == .increased { return .primary.opacity(0.4) }
            return colorScheme == .dark ? .white.opacity(0.08) : .clear
        }
    }

    private var symbol: String? {
        switch status {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        case .idle, .dimmed: return nil
        }
    }

    private var accessibilityValue: String {
        switch status {
        case .correct: return isPick ? "Correct, your answer" : "Correct answer"
        case .wrong: return "Your answer, incorrect"
        case .idle, .dimmed: return ""
        }
    }
}

// MARK: - Helpers

/// Hands a button's pressed state to the view, so the prompt card and the speaker layer above it
/// press in together.
private struct PressReportingStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

/// Text that may mix Japanese with English or romaji ("にほん · nihon", "A woman (女) under a roof").
/// Kana and kanji runs get the standard face so learners see the real shapes; the rest stays rounded.
private func quizMixedText(_ string: String) -> Text {
    var result = Text(verbatim: "")
    var run = ""
    var runIsJapanese = false

    func appendRun() {
        guard !run.isEmpty else { return }
        let piece = runIsJapanese ? Text(verbatim: run).fontDesign(.default) : Text(verbatim: run)
        result = Text("\(result)\(piece)")
        run = ""
    }

    for character in string {
        let isJapanese = character.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3000...0x30FF,   // Japanese punctuation, hiragana, katakana
                 0x3400...0x4DBF,   // kanji extension A
                 0x4E00...0x9FFF,   // kanji
                 0xFF00...0xFFEF:   // full-width forms
                return true
            default:
                return false
            }
        }
        if isJapanese != runIsJapanese {
            appendRun()
            runIsJapanese = isJapanese
        }
        run.append(character)
    }
    appendRun()
    return result
}
