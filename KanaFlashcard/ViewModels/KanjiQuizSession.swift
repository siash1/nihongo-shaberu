import Foundation
import Observation

/// One run through a set of multiple-choice questions.
/// Same mechanic as the kana practice: a missed question goes back into the stack.
@Observable
final class KanjiQuizSession {
    private(set) var currentQuestion: KanjiQuizQuestion?
    private(set) var selectedChoice: String?
    private(set) var isComplete = false
    private(set) var answerCount = 0   // goes up with every answer; drives the haptic feedback
    private(set) var presentationNumber = 0   // changes whenever a question is shown, even the same one again

    let totalCount: Int

    private var remaining: [KanjiQuizQuestion]
    private var missedIDs: Set<UUID> = []
    private var correctFirstTry = 0

    init(questions: [KanjiQuizQuestion]) {
        remaining = questions
        totalCount = questions.count
        showNext()
    }

    var isAnswered: Bool {
        selectedChoice != nil
    }

    var answeredCorrectly: Bool {
        selectedChoice != nil && selectedChoice == currentQuestion?.answer
    }

    /// The answer just given was the last one needed: the test is over once the learner continues.
    var isFinalAnswer: Bool {
        answeredCorrectly && remaining.isEmpty
    }

    var remainingCount: Int {
        remaining.count + (currentQuestion == nil ? 0 : 1)
    }

    /// Share of the questions that are finished, 0...1. A missed question stays in the count.
    var progress: Double {
        totalCount == 0 ? 1 : Double(totalCount - remainingCount) / Double(totalCount)
    }

    var scoreText: String {
        "\(correctFirstTry)/\(totalCount)"
    }

    var scorePercent: Int {
        totalCount == 0 ? 0 : Int((Double(correctFirstTry) / Double(totalCount) * 100).rounded())
    }

    func select(_ choice: String) {
        guard let question = currentQuestion, selectedChoice == nil else { return }
        selectedChoice = choice
        answerCount += 1

        if choice != question.answer {
            missedIDs.insert(question.id)
        } else if !missedIDs.contains(question.id) {
            correctFirstTry += 1
        }
    }

    func advance() {
        guard let question = currentQuestion, let choice = selectedChoice else { return }

        if choice != question.answer {
            // Re-insert later in the stack, never as the very next question when avoidable,
            // with the options in a new order so the position cannot be memorised.
            var retry = question
            retry.choices.shuffle()
            let index = remaining.isEmpty ? 0 : Int.random(in: 1...remaining.count)
            remaining.insert(retry, at: index)
        }
        showNext()
    }

    private func showNext() {
        selectedChoice = nil
        presentationNumber += 1

        guard !remaining.isEmpty else {
            currentQuestion = nil
            isComplete = true
            return
        }
        currentQuestion = remaining.removeFirst()
    }
}
