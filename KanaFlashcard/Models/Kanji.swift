import Foundation

/// A vocabulary word that uses a kanji.
struct KanjiWord: Identifiable, Hashable {
    let word: String        // Written with kanji, e.g. 日本. "〜" marks an ending such as 〜曜日
    let reading: String     // Kana reading, e.g. にほん (spaced when it is several words)
    let meaning: String     // English meaning
    let romaji: String      // Generated from the reading unless given (こんにちは → konnichiwa)

    var id: String { "\(word)|\(reading)" }

    /// The reading as it should be sent to text-to-speech.
    var spokenText: String {
        reading
            .replacingOccurrences(of: "〜", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    init(_ word: String, _ reading: String, _ meaning: String, romaji: String? = nil) {
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.romaji = romaji ?? RomajiConverter.romaji(fromKana: reading)
    }
}

/// One kanji with everything needed to learn it: meaning, memory story, readings, example words.
struct KanjiEntry: Identifiable, Hashable {
    let character: String
    let meaning: String
    let onReading: String   // Katakana, "・"-separated. Empty when not needed at this level.
    let kunReading: String  // Hiragana, "・"-separated, okurigana in parentheses. May be empty.
    let mnemonic: String    // Picture story linking the shape to the meaning
    let words: [KanjiWord]

    var id: String { character }
    var onRomaji: String { Self.romaji(for: onReading) }
    var kunRomaji: String { Self.romaji(for: kunReading) }

    init(_ character: String, _ meaning: String, on: String, kun: String, hint: String, words: [KanjiWord]) {
        self.character = character
        self.meaning = meaning
        self.onReading = on
        self.kunReading = kun
        self.mnemonic = hint
        self.words = words
    }

    private static func romaji(for readings: String) -> String {
        readings
            .split(separator: "・")
            .map { RomajiConverter.romaji(fromKana: String($0)) }
            .joined(separator: " · ")
    }
}

/// A practice sentence that only uses kanji taught up to its unit.
struct KanjiSentence: Identifiable, Hashable {
    let japanese: String    // With kanji, spaced by phrase: 水を のみます。
    let reading: String     // Kana, spaced by word and particle: みず を のみます。
    let meaning: String
    let focus: String       // The kanji word blanked out in fill-in questions

    /// Text for the speech voice when it misreads the kanji (it says 行って as おこなって,
    /// 降ります as ふります, 明日 as あす). Only the misread word is written in kana.
    private let speech: String?

    var id: String { japanese }
    var romaji: String { RomajiConverter.romaji(fromSentence: reading) }
    var spokenText: String { speech ?? japanese.replacingOccurrences(of: " ", with: "") }
    /// The sentence with the focus word replaced by a blank. The word joiner keeps the
    /// two underscores on one line.
    var blanked: String { japanese.replacingOccurrences(of: focus, with: "＿\u{2060}＿") }

    init(_ japanese: String, _ reading: String, _ meaning: String, focus: String, speech: String? = nil) {
        self.japanese = japanese
        self.reading = reading
        self.meaning = meaning
        self.focus = focus
        self.speech = speech
    }
}

/// One unit of the course — matches one video of the NihonGoal "Minna No Nihongo Kanji" series.
struct KanjiUnit: Identifiable, Hashable {
    let number: Int
    let title: String
    let videoID: String
    let kanji: [KanjiEntry]
    let sentences: [KanjiSentence]

    var id: Int { number }
    var videoURL: URL? { URL(string: "https://www.youtube.com/watch?v=\(videoID)") }

    /// Every example word in the unit, without repeats.
    var words: [KanjiWord] {
        var seen: Set<String> = []
        return kanji.flatMap(\.words).filter { seen.insert($0.id).inserted }
    }
}
