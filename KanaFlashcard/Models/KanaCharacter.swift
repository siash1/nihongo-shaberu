import Foundation

enum KanaType: String, CaseIterable {
    case hiragana = "Hiragana"
    case katakana = "Katakana"
}

struct KanaCharacter: Identifiable, Hashable {
    let id: String
    let character: String
    let romaji: String
    let type: KanaType

    init(character: String, romaji: String, type: KanaType) {
        self.id = "\(type.rawValue)-\(character)"
        self.character = character
        self.romaji = romaji
        self.type = type
    }
}
