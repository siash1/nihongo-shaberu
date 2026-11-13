import Foundation

/// Everything that syncs between devices, in the exact wire format of the Convex functions
/// `progress:sync` (argument and result). Mirrors `convex/lib/merge.ts` field for field.
///
/// All timestamps are milliseconds since 1970 (`Double`, JSON numbers); 0 means "never".
///
/// Foundation-only and nonisolated, so it compiles in the app (MainActor default isolation)
/// and on its own with `swiftc` for the merge tests in `tests/SyncMerge`.
nonisolated struct ProgressSnapshot: Codable, Hashable, Sendable {
    nonisolated struct LearnedKanji: Codable, Hashable, Sendable {
        var kanji: String
        var learnedAt: Double

        init(kanji: String, learnedAt: Double) {
            self.kanji = kanji
            self.learnedAt = learnedAt
        }
    }

    nonisolated struct Score: Codable, Hashable, Sendable {
        /// `"<unit>-<test>"`.
        var key: String
        /// Best first-try score in percent, an integer 0…100.
        var percent: Int
        var recordedAt: Double

        init(key: String, percent: Int, recordedAt: Double) {
            self.key = key
            self.percent = percent
            self.recordedAt = recordedAt
        }

        private enum CodingKeys: String, CodingKey {
            case key, percent, recordedAt
        }

        /// The server stores every number as a float64, so `percent` may arrive as `85.0`.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            key = try container.decode(String.self, forKey: .key)
            let raw = try container.decode(Double.self, forKey: .percent)
            guard let exact = Int(exactly: raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .percent, in: container, debugDescription: "percent must be an integer, got \(raw)")
            }
            percent = exact
            recordedAt = try container.decode(Double.self, forKey: .recordedAt)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key, forKey: .key)
            try container.encode(percent, forKey: .percent)
            try container.encode(recordedAt, forKey: .recordedAt)
        }
    }

    nonisolated struct Word: Codable, Hashable, Sendable {
        /// `"<word>|<level>"`, the identity of a saved word.
        var key: String
        var word: String
        var romaji: String
        var meaning: String
        /// `"N5"` … `"N1"`.
        var level: String
        var addedAt: Double
        /// 0 = not deleted.
        var deletedAt: Double

        init(key: String, word: String, romaji: String, meaning: String, level: String, addedAt: Double, deletedAt: Double) {
            self.key = key
            self.word = word
            self.romaji = romaji
            self.meaning = meaning
            self.level = level
            self.addedAt = addedAt
            self.deletedAt = deletedAt
        }

        /// A word is LIVE iff it was added after its last delete and after the last clear;
        /// otherwise it is a tombstone that only exists so the delete syncs.
        func isLive(wordsClearedAt: Double) -> Bool {
            addedAt > max(deletedAt, wordsClearedAt)
        }
    }

    var kanjiResetAt: Double
    var learned: [LearnedKanji]
    var scores: [Score]
    var wordsClearedAt: Double
    var words: [Word]

    init(
        kanjiResetAt: Double = 0,
        learned: [LearnedKanji] = [],
        scores: [Score] = [],
        wordsClearedAt: Double = 0,
        words: [Word] = []
    ) {
        self.kanjiResetAt = kanjiResetAt
        self.learned = learned
        self.scores = scores
        self.wordsClearedAt = wordsClearedAt
        self.words = words
    }

    static let empty = ProgressSnapshot()

    func isLive(_ word: Word) -> Bool {
        word.isLive(wordsClearedAt: wordsClearedAt)
    }

    /// The words that are not tombstones.
    var liveWords: [Word] {
        words.filter(isLive)
    }

    /// The canonical form of this snapshot: NFC strings, merge rules applied, arrays sorted.
    /// Two snapshots describe the same state iff their normalized forms are equal.
    var normalized: ProgressSnapshot {
        Self.merge(self, .empty)
    }

    /// Every timestamp clamped to `[0, limit]`, as the server sanitises a client snapshot.
    func clampingTimestamps(to limit: Double) -> ProgressSnapshot {
        func clamp(_ value: Double) -> Double { Swift.min(Swift.max(value, 0), limit) }
        var copy = self
        copy.kanjiResetAt = clamp(kanjiResetAt)
        copy.wordsClearedAt = clamp(wordsClearedAt)
        copy.learned = learned.map { LearnedKanji(kanji: $0.kanji, learnedAt: clamp($0.learnedAt)) }
        copy.scores = scores.map { Score(key: $0.key, percent: $0.percent, recordedAt: clamp($0.recordedAt)) }
        copy.words = words.map {
            var word = $0
            word.addedAt = clamp(word.addedAt)
            word.deletedAt = clamp(word.deletedAt)
            return word
        }
        return copy
    }
}

// MARK: - Merge

nonisolated extension ProgressSnapshot {
    /// State-based merge, identical to `merge` in `convex/lib/merge.ts` (the server runs that one;
    /// any difference would make every sync differ from the server). Commutative, associative and
    /// idempotent, so replicas converge whatever order they meet in.
    ///
    /// - `kanjiResetAt`, `wordsClearedAt`: max.
    /// - learned: entries with `learnedAt <= kanjiResetAt` dropped; per kanji the MAX remaining
    ///   `learnedAt` (a learning after a reset on any device survives).
    /// - scores: entries with `recordedAt <= kanjiResetAt` dropped; per key the Pareto frontier of
    ///   (percent, recordedAt): an entry is dropped when another of the same key has percent >= and
    ///   recordedAt >=. The best score of a key is the max percent of its entries. Usually one entry
    ///   per key; a later, lower score stays beside the best so a reset between them leaves it.
    /// - words: per key A = max `addedAt`, D = max `deletedAt`. LIVE iff A > max(D, wordsClearedAt).
    ///   Live → addedAt A, deletedAt (D > wordsClearedAt ? D : 0), text from the entries with
    ///   addedAt == A. Not live but D > wordsClearedAt → tombstone: addedAt 0, deletedAt D, text from
    ///   the entries with deletedAt == D. Otherwise dropped. Text ties → the smallest
    ///   (romaji, meaning, word, level).
    /// - Every string is NFC-normalised first. Output sorted: learned by kanji, scores by key then
    ///   recordedAt ascending, words by key; strings in Unicode code-point order.
    static func merge(_ a: ProgressSnapshot, _ b: ProgressSnapshot) -> ProgressSnapshot {
        let resetAt = Swift.max(a.kanjiResetAt, b.kanjiResetAt)
        let clearedAt = Swift.max(a.wordsClearedAt, b.wordsClearedAt)
        return ProgressSnapshot(
            kanjiResetAt: resetAt,
            learned: mergeLearned(a.learned + b.learned, resetAt: resetAt),
            scores: mergeScores(a.scores + b.scores, resetAt: resetAt),
            wordsClearedAt: clearedAt,
            words: mergeWords(a.words + b.words, clearedAt: clearedAt)
        )
    }

    private static func mergeLearned(_ entries: [LearnedKanji], resetAt: Double) -> [LearnedKanji] {
        var latest: [String: Double] = [:]
        for entry in entries where entry.learnedAt > resetAt {
            let kanji = nfc(entry.kanji)
            if let current = latest[kanji], !(entry.learnedAt > current) { continue }
            latest[kanji] = entry.learnedAt
        }
        return latest
            .map { LearnedKanji(kanji: $0.key, learnedAt: $0.value) }
            .sorted { codePointPrecedes($0.kanji, $1.kanji) }
    }

    private static func mergeScores(_ entries: [Score], resetAt: Double) -> [Score] {
        var byKey: [String: [Score]] = [:]
        for entry in entries where entry.recordedAt > resetAt {
            let key = nfc(entry.key)
            byKey[key, default: []].append(Score(key: key, percent: entry.percent, recordedAt: entry.recordedAt))
        }
        var frontier: [Score] = []
        for list in byKey.values {
            // Latest first; at equal times the best first. Walking that order, an entry is on the
            // frontier iff it beats every entry recorded at the same time or later.
            let ordered = list.sorted { x, y in
                x.recordedAt != y.recordedAt ? x.recordedAt > y.recordedAt : x.percent > y.percent
            }
            var bestSoFar = Int.min
            for entry in ordered where entry.percent > bestSoFar {
                frontier.append(entry)
                bestSoFar = entry.percent
            }
        }
        return frontier.sorted { x, y in
            let order = compareCodePoints(x.key, y.key)
            return order != 0 ? order < 0 : x.recordedAt < y.recordedAt
        }
    }

    private static func mergeWords(_ entries: [Word], clearedAt: Double) -> [Word] {
        var byKey: [String: [Word]] = [:]
        for entry in entries {
            let key = nfc(entry.key)
            byKey[key, default: []].append(Word(
                key: key,
                word: nfc(entry.word),
                romaji: nfc(entry.romaji),
                meaning: nfc(entry.meaning),
                level: nfc(entry.level),
                addedAt: entry.addedAt,
                deletedAt: entry.deletedAt
            ))
        }
        var merged: [Word] = []
        for (key, list) in byKey {
            var addedAt: Double = 0
            var deletedAt: Double = 0
            for entry in list {
                if entry.addedAt > addedAt { addedAt = entry.addedAt }
                if entry.deletedAt > deletedAt { deletedAt = entry.deletedAt }
            }
            let live = addedAt > Swift.max(deletedAt, clearedAt)
            // Garbage-collected by the clear.
            if !live && !(deletedAt > clearedAt) { continue }
            // Text comes from the add that makes the word live, or, for a tombstone, from the
            // delete that keeps it.
            var text: Word?
            for entry in list {
                if live ? entry.addedAt != addedAt : entry.deletedAt != deletedAt { continue }
                if let current = text, compareWordText(entry, current) >= 0 { continue }
                text = entry
            }
            guard let text else { continue }
            merged.append(Word(
                key: key,
                word: text.word,
                romaji: text.romaji,
                meaning: text.meaning,
                level: text.level,
                addedAt: live ? addedAt : 0,
                deletedAt: deletedAt > clearedAt ? deletedAt : 0
            ))
        }
        return merged.sorted { codePointPrecedes($0.key, $1.key) }
    }

    private static func compareWordText(_ x: Word, _ y: Word) -> Int {
        for (a, b) in [(x.romaji, y.romaji), (x.meaning, y.meaning), (x.word, y.word), (x.level, y.level)] {
            let order = compareCodePoints(a, b)
            if order != 0 { return order }
        }
        return 0
    }

    /// The best score of every key: the max percent over its (frontier) entries.
    var bestScores: [String: Int] {
        var best: [String: Int] = [:]
        for score in scores where score.percent > best[score.key] ?? Int.min {
            best[score.key] = score.percent
        }
        return best
    }

    /// Unicode code-point order, which equals UTF-8 byte order: -1, 0 or 1. Never `String <`
    /// (canonical ordering) or UTF-16 order: TypeScript compares the same way, so both sides agree.
    static func compareCodePoints(_ a: String, _ b: String) -> Int {
        if a.utf8.elementsEqual(b.utf8) { return 0 }
        return a.utf8.lexicographicallyPrecedes(b.utf8) ? -1 : 1
    }

    static func codePointPrecedes(_ a: String, _ b: String) -> Bool {
        a.utf8.lexicographicallyPrecedes(b.utf8)
    }

    /// NFC, so canonically equivalent strings (が vs か + ゙) group and compare as one in both languages.
    static func nfc(_ string: String) -> String {
        string.precomposedStringWithCanonicalMapping
    }
}
