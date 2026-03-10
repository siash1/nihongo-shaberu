import SwiftUI
import Observation

@Observable
final class PracticeViewModel {
    var selectedCharacters: Set<String> = []
    var currentCard: KanaCharacter?
    var isAnswerRevealed = false

    private var lastShownId: String?

    var allHiraganaSelected: Bool {
        KanaData.hiragana.allSatisfy { selectedCharacters.contains($0.id) }
    }

    var allKatakanaSelected: Bool {
        KanaData.katakana.allSatisfy { selectedCharacters.contains($0.id) }
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

    func selectAll() {
        for char in KanaData.allCharacters {
            selectedCharacters.insert(char.id)
        }
    }

    func clearSelection() {
        selectedCharacters.removeAll()
    }

    func startPractice() {
        showNextCard()
    }

    func showNextCard() {
        isAnswerRevealed = false

        let pool = KanaData.allCharacters.filter { selectedCharacters.contains($0.id) }
        guard !pool.isEmpty else { return }

        if pool.count == 1 {
            currentCard = pool.first
            lastShownId = currentCard?.id
            return
        }

        var next: KanaCharacter
        repeat {
            next = pool.randomElement()!
        } while next.id == lastShownId

        currentCard = next
        lastShownId = next.id
    }

    func revealAnswer() {
        isAnswerRevealed = true
    }
}
