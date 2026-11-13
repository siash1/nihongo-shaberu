import SwiftUI
import Observation

enum WordPracticeMode {
    case generate
    case test
}

@Observable
final class WordPracticeViewModel {
    var selectedScript = "Hiragana"
    var selectedLevel: JLPTLevel = .n5
    var isLoading = false
    var errorMessage: String?

    var currentCard: WordCard?
    var isAnswerRevealed = false
    var isPracticeComplete = false

    var practiceMode: WordPracticeMode = .generate
    var selectedTestLevels: Set<JLPTLevel> = []
    var savedWordCounts: [JLPTLevel: Int] = [:]

    private var remainingCards: [WordCard] = []
    private var correctCount = 0
    private var wrongCount = 0
    private var totalCount = 0
    /// Cards marked wrong at least once; they do not count as "correct on first try".
    private var missedIDs: Set<UUID> = []

    let scripts = ["Hiragana", "Katakana"]

    var remainingCount: Int {
        remainingCards.count + (currentCard != nil && !isPracticeComplete ? 1 : 0)
    }

    /// Words known first time out of all words. Every word is eventually marked correct,
    /// so counting correct answers would always give a perfect score.
    var scoreText: String {
        "\(totalCount - missedIDs.count)/\(totalCount)"
    }

    var hasFetchedWords: Bool {
        totalCount > 0
    }

    var totalSavedWords: Int {
        savedWordCounts.values.reduce(0, +)
    }

    var selectedTestWordCount: Int {
        selectedTestLevels.reduce(0) { $0 + (savedWordCounts[$1] ?? 0) }
    }

    func refreshSavedWordCounts() {
        savedWordCounts = WordStorageService.wordCounts()
    }

    func fetchWords() async {
        isLoading = true
        errorMessage = nil

        do {
            let words = try await GeminiService.generateWords(script: selectedScript, level: selectedLevel)
            WordStorageService.saveWords(words)
            refreshSavedWordCounts()
            remainingCards = words.shuffled()
            totalCount = words.count
            correctCount = 0
            wrongCount = 0
            missedIDs = []
            isPracticeComplete = false
            isAnswerRevealed = false
            showNextCard()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startTest() {
        let saved = WordStorageService.loadWords(for: Array(selectedTestLevels))
        guard !saved.isEmpty else {
            errorMessage = "No saved words for the selected levels"
            return
        }
        remainingCards = saved.shuffled()
        totalCount = saved.count
        correctCount = 0
        wrongCount = 0
        missedIDs = []
        isPracticeComplete = false
        isAnswerRevealed = false
        errorMessage = nil
        showNextCard()
    }

    func toggleTestLevel(_ level: JLPTLevel) {
        if selectedTestLevels.contains(level) {
            selectedTestLevels.remove(level)
        } else {
            selectedTestLevels.insert(level)
        }
    }

    func markCorrect() {
        correctCount += 1
        showNextCard()
    }

    func markWrong() {
        wrongCount += 1
        if let card = currentCard {
            missedIDs.insert(card.id)
            let insertIndex = remainingCards.isEmpty ? 0 : Int.random(in: 0...remainingCards.count)
            remainingCards.insert(card, at: insertIndex)
        }
        showNextCard()
    }

    func showNextCard() {
        isAnswerRevealed = false

        guard !remainingCards.isEmpty else {
            currentCard = nil
            isPracticeComplete = true
            return
        }

        currentCard = remainingCards.removeFirst()
    }

    func revealAnswer() {
        isAnswerRevealed = true
    }

    func reset() {
        currentCard = nil
        remainingCards = []
        correctCount = 0
        wrongCount = 0
        missedIDs = []
        totalCount = 0
        isPracticeComplete = false
        isAnswerRevealed = false
        errorMessage = nil
        practiceMode = .generate
    }
}
