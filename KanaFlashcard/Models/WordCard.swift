import Foundation

struct WordCard: Identifiable, Equatable, Codable {
    let id: UUID
    let word: String        // Japanese word (hiragana or katakana)
    let romaji: String      // Romanized pronunciation
    let meaning: String     // English meaning
    let level: JLPTLevel

    init(word: String, romaji: String, meaning: String, level: JLPTLevel = .n5) {
        self.id = UUID()
        self.word = word
        self.romaji = romaji
        self.meaning = meaning
        self.level = level
    }

    // Exclude id from Codable — generate fresh UUID on decode
    enum CodingKeys: String, CodingKey {
        case word, romaji, meaning, level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.romaji = try container.decode(String.self, forKey: .romaji)
        self.meaning = try container.decode(String.self, forKey: .meaning)
        self.level = try container.decode(JLPTLevel.self, forKey: .level)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(romaji, forKey: .romaji)
        try container.encode(meaning, forKey: .meaning)
        try container.encode(level, forKey: .level)
    }
}
