import Foundation
import Observation

/// Teaches the kanji of a unit one by one:
/// study the card → prove you remember it → quick recall of an earlier kanji → next kanji.
@Observable
final class KanjiLearnSession {
    enum Step {
        case study                      // looking at the kanji card
        case check(KanjiQuizQuestion)   // pick the kanji that was just studied
        case recall(KanjiQuizQuestion)  // quick question about an earlier kanji
        case finished
    }

    let unit: KanjiUnit
    let queue: [KanjiEntry]

    private(set) var index = 0
    private(set) var step: Step = .study
    private(set) var stepNumber = 0     // changes on every transition; used to reset scrolling
    private(set) var selectedChoice: String?
    private(set) var answerCount = 0    // goes up with every answer; drives the haptic feedback
    private(set) var cameBack = false   // the last move returned to the study card
    private(set) var learnedThisSession: [KanjiEntry] = []

    private var known: Set<String>      // kanji of this unit the learner has already passed
    private let onLearned: (KanjiEntry) -> Void

    init(unit: KanjiUnit, queue: [KanjiEntry], known: Set<String>, onLearned: @escaping (KanjiEntry) -> Void) {
        self.unit = unit
        self.queue = queue
        self.known = known
        self.onLearned = onLearned
        if queue.isEmpty { step = .finished }
    }

    var current: KanjiEntry? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    var isAnswered: Bool {
        selectedChoice != nil
    }

    var answeredCorrectly: Bool {
        switch step {
        case .check(let question), .recall(let question):
            return selectedChoice == question.answer
        case .study, .finished:
            return false
        }
    }

    /// A wrong answer on the check sends the learner back to the study card.
    var willGoBack: Bool {
        if case .check = step { return isAnswered && !answeredCorrectly }
        return false
    }

    /// Progress through the lesson, 0...1, moving a little with every step.
    var progress: Double {
        guard !queue.isEmpty else { return 1 }
        let stepShare: Double
        switch step {
        case .study, .finished: stepShare = 0
        case .check: stepShare = 0.5
        case .recall: stepShare = 0.75
        }
        return min(1, (Double(index) + stepShare) / Double(queue.count))
    }

    /// Study card → "which kanji means…?" question.
    func startCheck() {
        guard let current else { return }
        move(to: .check(KanjiQuizBuilder.kanjiQuestion(for: current, pool: unit.kanji)))
    }

    func select(_ choice: String) {
        guard selectedChoice == nil else { return }
        selectedChoice = choice
        answerCount += 1

        // Passing the check is what makes a kanji learned. Save it straight away,
        // so it still counts if the learner leaves before tapping Continue.
        if case .check = step, answeredCorrectly, let current {
            if known.insert(current.character).inserted {
                learnedThisSession.append(current)
            }
            onLearned(current)
        }
    }

    /// Moves on from an answered question.
    func advance() {
        guard let current, isAnswered else { return }

        switch step {
        case .check:
            guard answeredCorrectly else {
                move(to: .study, backward: true)   // look at the card again, then retry
                return
            }

            let earlier = unit.kanji.filter { known.contains($0.character) && $0.character != current.character }
            if let earlierKanji = earlier.randomElement() {
                move(to: .recall(KanjiQuizBuilder.meaningQuestion(for: earlierKanji, pool: unit.kanji)))
            } else {
                moveToNextKanji()
            }
        case .recall:
            moveToNextKanji()
        case .study, .finished:
            break
        }
    }

    private func moveToNextKanji() {
        index += 1
        move(to: index < queue.count ? .study : .finished)
    }

    private func move(to newStep: Step, backward: Bool = false) {
        selectedChoice = nil
        cameBack = backward
        step = newStep
        stepNumber += 1
    }
}
