import SwiftUI

/// Teaches the kanji of a unit one at a time: study the card, then answer a quick
/// question before moving on. Progress is saved after every kanji.
struct KanjiLearnView: View {
    @Bindable var viewModel: KanjiViewModel
    let unit: KanjiUnit

    @State private var session: KanjiLearnSession?
    @State private var isAdvancing = false   // a step change is still animating
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            if let session {
                stepView(session)
                    .id(session.stepNumber)
                    .transition(stepTransition(session))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sessionChrome(
            title: "Unit \(unit.number) Lesson",
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
        .onAppear(perform: startIfNeeded)
        .onDisappear {
            viewModel.stopSpeaking()
        }
    }

    /// Kanji still to go in this lesson, including the current one. Hidden once the lesson is over.
    private var remaining: Int? {
        guard let session, session.current != nil else { return nil }
        return session.queue.count - session.index
    }

    private var stepAnimation: Animation {
        reduceMotion ? .appFade : .appSmooth
    }

    private func startIfNeeded() {
        guard session == nil else { return }

        // Pick up where the learner left off; once everything is learned, go through the whole unit again.
        let unlearned = unit.kanji.filter { !viewModel.isLearned($0) }
        session = KanjiLearnSession(
            unit: unit,
            queue: unlearned.isEmpty ? unit.kanji : unlearned,
            known: Set(unit.kanji.filter(viewModel.isLearned).map(\.character)),
            // Capture only the view model: capturing the view would tie the session to itself and leak it.
            onLearned: { [viewModel] in viewModel.markLearned($0) }
        )
    }

    // MARK: - Steps

    /// Steps move forward right-to-left, like turning pages. Going back to the study card after a
    /// wrong answer retraces the same path in the other direction. Cross-fades with Reduce Motion.
    private func stepTransition(_ session: KanjiLearnSession) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: session.cameBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: session.willGoBack ? .trailing : .leading).combined(with: .opacity)
        )
    }

    @ViewBuilder
    private func stepView(_ session: KanjiLearnSession) -> some View {
        switch session.step {
        case .study:
            if let entry = session.current {
                ScrollView {
                    KanjiDetailCard(entry: entry, onSpeak: { viewModel.speak($0) })
                        .frame(maxWidth: 640)
                        .padding(.horizontal, Spacing.margin)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                }
            }
        case .check(let question):
            questionView(question, heading: "Do you remember?", session: session)
        case .recall(let question):
            questionView(question, heading: "Quick recall", session: session)
        case .finished:
            completionView(session)
        }
    }

    private func questionView(_ question: KanjiQuizQuestion, heading: String, session: KanjiLearnSession) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                stepHeading(heading)

                KanjiQuestionView(
                    question: question,
                    selectedChoice: session.selectedChoice,
                    onSelect: { choice in
                        withAnimation(.appSmooth) {
                            session.select(choice)
                        }
                    },
                    onSpeak: { viewModel.speak($0) }
                )
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, Spacing.margin)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Names the kind of question. It sits on a small solid tag, because accent text
    /// never goes directly on the wash. A rounded rectangle rather than a capsule, so the text
    /// stays inside it when large type wraps it onto two lines.
    private func stepHeading(_ text: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
        return Text(text)
            .font(.headline)
            .foregroundStyle(theme.accent)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.cardFill, in: shape)
            .overlay {
                if contrast == .increased {
                    shape.strokeBorder(Color.primary.opacity(0.4), lineWidth: 1.5)
                }
            }
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func completionView(_ session: KanjiLearnSession) -> some View {
        let learned = session.learnedThisSession

        if learned.isEmpty {
            ResultCard(
                eyebrow: "Review complete",
                message: "Next, test yourself on the words and sentences."
            )
        } else {
            ResultCard(
                eyebrow: "Lesson complete",
                score: "\(learned.count)",
                caption: "new kanji learned",
                message: "Next, test yourself on the words and sentences.",
                kanji: learned.map(\.character)
            )
        }
    }

    // MARK: - Bottom action

    /// One button in one place for the whole lesson; only its title and action change.
    @ViewBuilder
    private var bottomBar: some View {
        if let session, let title = actionTitle(for: session) {
            PrimaryActionButton(title: title) {
                // The button stays in place while its meaning changes, so the second tap of a
                // double-tap must not trigger the next step.
                guard !isAdvancing else { return }

                if case .finished = session.step {
                    dismiss()
                    return
                }

                isAdvancing = true
                withAnimation(stepAnimation) {
                    if case .study = session.step {
                        session.startCheck()
                    } else {
                        session.advance()
                    }
                } completion: {
                    isAdvancing = false
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            .transition(.lessonMaterialize(reduceMotion: reduceMotion))
        }
    }

    private func actionTitle(for session: KanjiLearnSession) -> String? {
        switch session.step {
        case .study:
            return "Quiz Me"
        case .check:
            guard session.isAnswered else { return nil }
            return session.answeredCorrectly ? "Continue" : "Study It Again"
        case .recall:
            return session.isAnswered ? "Continue" : nil
        case .finished:
            return "Done"
        }
    }
}

private extension AnyTransition {
    /// A floating control arriving in place: blur and scale together rather than a plain fade.
    static func lessonMaterialize(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }
}
