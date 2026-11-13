import Foundation

enum JLPTLevel: String, CaseIterable, Codable {
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"

    var promptDescription: String {
        switch self {
        case .n5: return "JLPT N5 (Absolute Beginner): Use only hiragana and katakana. Simple greetings, numbers, basic daily phrases. Very short sentences."
        case .n4: return "JLPT N4 (Elementary): Use hiragana, katakana, and ~150 basic kanji. Basic grammar (te-form, past tense). Simple daily conversation."
        case .n3: return "JLPT N3 (Intermediate): Use ~400 kanji. More complex grammar. Discuss everyday topics, opinions, and experiences naturally."
        case .n2: return "JLPT N2 (Upper Intermediate): Use ~700 kanji. Natural conversational Japanese. Abstract topics, explanations, and nuanced expressions."
        case .n1: return "JLPT N1 (Advanced): Use full range of kanji and grammar. Formal and informal registers, idioms, nuanced expressions, complex topics."
        }
    }
}
