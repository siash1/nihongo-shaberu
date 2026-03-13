import SwiftUI
import Observation

@Observable
final class PracticeViewModel {
    var selectedCharacters: Set<String> = []
    var currentCard: KanaCharacter?
    var isAnswerRevealed = false
    var isPracticeComplete = false

    private var remainingCards: [KanaCharacter] = []
    private var correctCount = 0
    private var wrongCount = 0

    var totalCards: Int {
        selectedCharacters.count
    }

    var remainingCount: Int {
        remainingCards.count + (currentCard != nil && !isPracticeComplete ? 1 : 0)
    }

    var scoreText: String {
        "\(correctCount)/\(totalCards)"
    }

    var allHiraganaSelected: Bool {
        KanaData.hiragana.allSatisfy { selectedCharacters.contains($0.id) }
    }

    var allKatakanaSelected: Bool {
        KanaData.katakana.allSatisfy { selectedCharacters.contains($0.id) }
    }

    var allHiraganaDakutenSelected: Bool {
        KanaData.hiraganaDakuten.allSatisfy { selectedCharacters.contains($0.id) }
    }

    var allKatakanaDakutenSelected: Bool {
        KanaData.katakanaDakuten.allSatisfy { selectedCharacters.contains($0.id) }
    }

    var selectionCount: Int {
        selectedCharacters.count
    }

    var canStartPractice: Bool {
        selectedCharacters.count >= 2
    }

    func toggle(_ character: KanaCharacter) {
        if selectedCharacters.contains(character.id) {
            selectedCharacters.remove(character.id)
        } else {
            selectedCharacters.insert(character.id)
        }
    }

    func isSelected(_ character: KanaCharacter) -> Bool {
        selectedCharacters.contains(character.id)
    }

    func selectAllHiragana() {
        for char in KanaData.hiragana {
            selectedCharacters.insert(char.id)
        }
    }

    func selectAllKatakana() {
        for char in KanaData.katakana {
            selectedCharacters.insert(char.id)
        }
    }

    func selectAllHiraganaDakuten() {
        for char in KanaData.hiraganaDakuten {
            selectedCharacters.insert(char.id)
        }
    }

    func selectAllKatakanaDakuten() {
        for char in KanaData.katakanaDakuten {
            selectedCharacters.insert(char.id)
        }
    }

    func selectAll() {
        for char in KanaData.allCharacters {
            selectedCharacters.insert(char.id)
        }
    }

    func clearSelection() {
        selectedCharacters.removeAll()
    }

    func startPractice() {
        correctCount = 0
        wrongCount = 0
        isPracticeComplete = false
        remainingCards = KanaData.allCharacters.filter { selectedCharacters.contains($0.id) }.shuffled()
        showNextCard()
    }

    func markCorrect() {
        correctCount += 1
        showNextCard()
    }

    func markWrong() {
        wrongCount += 1
        if let card = currentCard {
            // Put it back at a random position in the remaining stack
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
}
