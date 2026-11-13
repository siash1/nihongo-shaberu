import Foundation

/// The three tests available for every unit.
enum KanjiTestKind: String, CaseIterable, Identifiable {
    case kanji
    case words
    case sentences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kanji: return "Kanji Quiz"
        case .words: return "Word Test"
        case .sentences: return "Sentence Test"
        }
    }

    var subtitle: String {
        switch self {
        case .kanji: return "Match each kanji with its meaning"
        case .words: return "Read and understand words, one by one"
        case .sentences: return "Read the kanji inside full sentences"
        }
    }

    var systemImage: String {
        switch self {
        case .kanji: return "character.zh"
        case .words: return "textformat.abc"
        case .sentences: return "text.bubble.fill"
        }
    }
}

/// What is shown once a question has been answered.
struct KanjiReveal {
    let japanese: String
    var reading = ""        // kana; empty for single-kanji questions
    var romaji = ""
    let meaning: String
    var note: String?       // memory story
    var speech = ""         // text for the speaker button; empty hides it
}

/// A multiple-choice question.
struct KanjiQuizQuestion: Identifiable {
    enum PromptStyle {
        case kanji, word, sentence, meaning
    }

    let id = UUID()
    let instruction: String
    let prompt: String
    let promptStyle: PromptStyle
    var hint: String?
    var choices: [String]
    let answer: String
    var largeChoices = false   // choices are Japanese, shown big in a grid
    let reveal: KanjiReveal
}

/// Builds questions from the course data. Wrong options are taken from the same unit
/// first, and never include an option that could also be read as correct.
enum KanjiQuizBuilder {
    static let wordQuestionLimit = 12
    static let sentenceQuestionLimit = 10

    // MARK: - Kanji

    static func kanjiQuestions(for entries: [KanjiEntry], pool: [KanjiEntry]) -> [KanjiQuizQuestion] {
        entries.shuffled().map { entry in
            Bool.random() ? meaningQuestion(for: entry, pool: pool) : kanjiQuestion(for: entry, pool: pool)
        }
    }

    /// Shows the kanji and asks for its meaning.
    static func meaningQuestion(for entry: KanjiEntry, pool: [KanjiEntry]) -> KanjiQuizQuestion {
        let others = distractors(for: entry, pool: pool)
        return KanjiQuizQuestion(
            instruction: "What does this kanji mean?",
            prompt: entry.character,
            promptStyle: .kanji,
            choices: (others.map(\.meaning) + [entry.meaning]).shuffled(),
            answer: entry.meaning,
            reveal: reveal(for: entry)
        )
    }

    /// Shows the meaning and asks for the kanji.
    static func kanjiQuestion(for entry: KanjiEntry, pool: [KanjiEntry]) -> KanjiQuizQuestion {
        let others = distractors(for: entry, pool: pool)
        return KanjiQuizQuestion(
            instruction: "Which kanji means…",
            prompt: entry.meaning,
            promptStyle: .meaning,
            choices: (others.map(\.character) + [entry.character]).shuffled(),
            answer: entry.character,
            largeChoices: true,
            reveal: reveal(for: entry)
        )
    }

    private static func distractors(for entry: KanjiEntry, pool: [KanjiEntry]) -> [KanjiEntry] {
        pick(from: pool, fallback: KanjiData.allKanji, key: \.character) { other in
            other.character == entry.character || meaningsOverlap(other.meaning, entry.meaning)
        }
    }

    private static func reveal(for entry: KanjiEntry) -> KanjiReveal {
        KanjiReveal(japanese: entry.character, meaning: entry.meaning, note: entry.mnemonic)
    }

    // MARK: - Words

    static func wordQuestions(for words: [KanjiWord], pool: [KanjiWord], limit: Int = wordQuestionLimit) -> [KanjiQuizQuestion] {
        words.shuffled().prefix(limit).map { word in
            Bool.random() ? wordMeaningQuestion(for: word, pool: pool) : wordReadingQuestion(for: word, pool: pool)
        }
    }

    private static func wordMeaningQuestion(for word: KanjiWord, pool: [KanjiWord]) -> KanjiQuizQuestion {
        let kanji = kanjiCharacters(in: word.word)
        // Words sharing a kanji tend to have near-identical meanings (火 "fire" / 火事 "a fire"), so skip them.
        let others = pick(from: pool, fallback: allWords, key: \.meaning) { other in
            other.meaning == word.meaning
                || !kanji.isDisjoint(with: kanjiCharacters(in: other.word))
                || meaningsOverlap(other.meaning, word.meaning)
        }
        return KanjiQuizQuestion(
            instruction: "What does this word mean?",
            prompt: word.word,
            promptStyle: .word,
            choices: (others.map(\.meaning) + [word.meaning]).shuffled(),
            answer: word.meaning,
            reveal: reveal(for: word)
        )
    }

    private static func wordReadingQuestion(for word: KanjiWord, pool: [KanjiWord]) -> KanjiQuizQuestion {
        let pattern = readingPattern(for: word.word)
        let answer = word.spokenText

        // Never offer the word itself or a related form (旅行 / 旅行する, 曜日 / 〜曜日).
        let isRelated: (KanjiWord) -> Bool = { other in
            other.word == word.word
                || other.spokenText.contains(answer)
                || answer.contains(other.spokenText)
        }

        // Prefer readings that fit the kana visible in the word (書く → きく, いく),
        // so the okurigana alone does not give the answer away.
        var others = pick(from: pool, fallback: allWords, key: \.reading) { other in
            isRelated(other)
                || other.reading.replacingOccurrences(of: " ", with: "")
                    .range(of: pattern, options: .regularExpression) == nil
        }
        // Nothing else in the course fits the visible kana (食べる is the only reading ending in べる):
        // the kana alone would give the reading away, so ask for the meaning instead.
        if others.isEmpty {
            return wordMeaningQuestion(for: word, pool: pool)
        }
        if others.count < 3 {
            let used = Set(others.map(\.reading))
            others += pick(from: pool, fallback: allWords, key: \.reading) { other in
                isRelated(other) || used.contains(other.reading)
            }.prefix(3 - others.count)
        }

        return KanjiQuizQuestion(
            instruction: "How do you read this word?",
            prompt: word.word,
            promptStyle: .word,
            choices: (others.map { readingChoice($0) } + [readingChoice(word)]).shuffled(),
            answer: readingChoice(word),
            reveal: reveal(for: word)
        )
    }

    private static func readingChoice(_ word: KanjiWord) -> String {
        "\(word.reading) · \(word.romaji)"
    }

    /// 書く → "^[^〜]+く$": a run of kanji can be any kana, the kana written in the word must match.
    /// A kanji run never matches 〜, so 日 (ひ) is not offered 〜日 (〜にち), a reading 日 also has.
    private static func readingPattern(for word: String) -> String {
        var pattern = "^"
        var inKanji = false
        for character in word {
            if character == "々" || !kanjiCharacters(in: String(character)).isEmpty {
                if !inKanji { pattern += "[^〜]+" }
                inKanji = true
            } else {
                pattern += NSRegularExpression.escapedPattern(for: String(character))
                inKanji = false
            }
        }
        return pattern + "$"
    }

    private static func reveal(for word: KanjiWord) -> KanjiReveal {
        KanjiReveal(japanese: word.word, reading: word.reading, romaji: word.romaji, meaning: word.meaning, speech: word.spokenText)
    }

    // MARK: - Sentences

    static func sentenceQuestions(for sentences: [KanjiSentence], pool: [KanjiSentence], limit: Int = sentenceQuestionLimit) -> [KanjiQuizQuestion] {
        sentences.shuffled().prefix(limit).map { sentence in
            Bool.random() ? sentenceMeaningQuestion(for: sentence, pool: pool) : fillInQuestion(for: sentence, pool: pool)
        }
    }

    private static func sentenceMeaningQuestion(for sentence: KanjiSentence, pool: [KanjiSentence]) -> KanjiQuizQuestion {
        // A sentence that reads the same (written with fewer kanji in an earlier unit) means the same.
        let others = pick(from: pool, fallback: allSentences, key: \.meaning) {
            $0.meaning == sentence.meaning || $0.reading == sentence.reading
        }
        return KanjiQuizQuestion(
            instruction: "What does this sentence mean?",
            prompt: sentence.japanese,
            promptStyle: .sentence,
            choices: (others.map(\.meaning) + [sentence.meaning]).shuffled(),
            answer: sentence.meaning,
            reveal: reveal(for: sentence)
        )
    }

    /// Blanks out the key kanji word; the English meaning is given as the clue.
    private static func fillInQuestion(for sentence: KanjiSentence, pool: [KanjiSentence]) -> KanjiQuizQuestion {
        let others = pick(from: pool, fallback: allSentences, key: \.focus) { $0.focus == sentence.focus }
        return KanjiQuizQuestion(
            instruction: "Which word fits the blank?",
            prompt: sentence.blanked,
            promptStyle: .sentence,
            hint: sentence.meaning,
            choices: (others.map(\.focus) + [sentence.focus]).shuffled(),
            answer: sentence.focus,
            largeChoices: true,
            reveal: reveal(for: sentence)
        )
    }

    private static func reveal(for sentence: KanjiSentence) -> KanjiReveal {
        KanjiReveal(japanese: sentence.japanese, reading: sentence.reading, romaji: sentence.romaji, meaning: sentence.meaning, speech: sentence.spokenText)
    }

    // MARK: - Review

    /// A mixed test over everything learned so far. Sentences also use kanji from earlier units,
    /// so they are only taken from the unbroken run of fully learned units at the start of the course.
    static func reviewQuestions(learned: Set<String>, units: [KanjiUnit]) -> [KanjiQuizQuestion] {
        let entries = units.flatMap(\.kanji).filter { learned.contains($0.character) }
        let words = uniqueWords(entries.flatMap(\.words))
        let sentences = units
            .prefix { unit in unit.kanji.allSatisfy { learned.contains($0.character) } }
            .flatMap(\.sentences)

        let questions = kanjiQuestions(for: Array(entries.shuffled().prefix(6)), pool: entries)
            + wordQuestions(for: words, pool: words, limit: 6)
            + sentenceQuestions(for: sentences, pool: sentences, limit: 4)
        return questions.shuffled()
    }

    // MARK: - Helpers

    private static let allWords = uniqueWords(KanjiData.allKanji.flatMap(\.words))
    private static let allSentences = KanjiData.units.flatMap(\.sentences)

    private static func uniqueWords(_ words: [KanjiWord]) -> [KanjiWord] {
        var seen: Set<String> = []
        return words.filter { seen.insert($0.id).inserted }
    }

    /// Picks up to three wrong options with distinct `key` values, preferring `pool`.
    private static func pick<T>(from pool: [T], fallback: [T], key: (T) -> String, excluding: (T) -> Bool) -> [T] {
        var seen: Set<String> = []
        var picked: [T] = []
        for candidates in [pool, fallback] {
            for candidate in candidates.shuffled() {
                if picked.count == 3 { return picked }
                if excluding(candidate) || !seen.insert(key(candidate)).inserted { continue }
                picked.append(candidate)
            }
        }
        return picked
    }

    /// True when two meanings share a gloss, e.g. "middle, inside" and "inside",
    /// or "room (in compounds)" and "room".
    private static func meaningsOverlap(_ first: String, _ second: String) -> Bool {
        !glosses(first).isDisjoint(with: glosses(second))
    }

    /// The comma-separated parts of a meaning, lowercased and without bracketed notes.
    private static func glosses(_ meaning: String) -> Set<String> {
        let withoutNotes = meaning.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        return Set(withoutNotes.lowercased()
            .split(whereSeparator: { $0 == "," || $0 == ";" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })
    }

    private static func kanjiCharacters(in text: String) -> Set<Character> {
        Set(text.filter { character in
            character.unicodeScalars.allSatisfy { (0x4E00...0x9FFF).contains($0.value) }
        })
    }
}
