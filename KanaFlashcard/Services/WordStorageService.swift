import Foundation

/// The stored word bank: every word ever saved, with timestamps, so deletes and clears sync.
/// Words that are deleted stay as tombstones until a clear covers them.
nonisolated struct WordBank: Codable, Equatable, Sendable {
    /// The last Clear All, 0 = never.
    var clearedAt: Double = 0
    /// Unique by `key`.
    var entries: [ProgressSnapshot.Word] = []
}

/// The saved word bank. The public API (used by the views) only ever sees LIVE words.
struct WordStorageService {
    private static let storageKey = "wordBank"
    /// The pre-sync format: a plain `[WordCard]` array.
    private static let legacyStorageKey = "savedWords"

    /// New words are not saved past this many live words: the most an account keeps
    /// (`ACCOUNT_LIMITS.maxLiveWords` in convex/lib/merge.ts), so the bank always syncs.
    static let maxLiveWords = 5000

    /// The identity of a saved word, `"<word>|<level>"`.
    static func key(for card: WordCard) -> String {
        "\(card.word)|\(card.level.rawValue)".precomposedStringWithCanonicalMapping
    }

    // MARK: - Words for the views (live only)

    /// Live words, oldest first.
    static func loadAllWords() -> [WordCard] {
        let bank = loadBank()
        return bank.entries
            .filter { $0.isLive(wordsClearedAt: bank.clearedAt) }
            .sorted { lhs, rhs in
                lhs.addedAt != rhs.addedAt
                    ? lhs.addedAt < rhs.addedAt
                    : ProgressSnapshot.codePointPrecedes(lhs.key, rhs.key)
            }
            .compactMap { entry in
                guard let level = JLPTLevel(rawValue: entry.level) else { return nil }
                return WordCard(word: entry.word, romaji: entry.romaji, meaning: entry.meaning, level: level)
            }
    }

    /// The bank holds `maxLiveWords` words: new words are not saved until some are removed.
    static var isFull: Bool {
        let bank = loadBank()
        return bank.entries.lazy.filter { $0.isLive(wordsClearedAt: bank.clearedAt) }.count >= maxLiveWords
    }

    static func loadWords(for levels: [JLPTLevel]) -> [WordCard] {
        let levelSet = Set(levels)
        return loadAllWords().filter { levelSet.contains($0.level) }
    }

    /// Adds words that are not already live. A word that was deleted (or cleared) comes back
    /// with fresh text; a live word keeps its original entry. Once the bank holds
    /// `maxLiveWords` words, new words are not saved.
    static func saveWords(_ newWords: [WordCard]) {
        var bank = loadBank()
        var indexByKey = index(of: bank)
        let now = ProgressClock.now()
        var changed = false
        var liveCount = bank.entries.filter { $0.isLive(wordsClearedAt: bank.clearedAt) }.count

        for card in newWords.map({ fittedForSync($0) }) {
            let key = key(for: card)
            guard liveCount < maxLiveWords else { break }
            if let index = indexByKey[key] {
                let entry = bank.entries[index]
                guard !entry.isLive(wordsClearedAt: bank.clearedAt) else { continue }
                bank.entries[index] = ProgressSnapshot.Word(
                    key: key, word: card.word, romaji: card.romaji, meaning: card.meaning,
                    level: card.level.rawValue,
                    addedAt: max(now, entry.deletedAt + 1, bank.clearedAt + 1),
                    deletedAt: entry.deletedAt
                )
            } else {
                bank.entries.append(ProgressSnapshot.Word(
                    key: key, word: card.word, romaji: card.romaji, meaning: card.meaning,
                    level: card.level.rawValue,
                    addedAt: max(now, bank.clearedAt + 1),
                    deletedAt: 0
                ))
                indexByKey[key] = bank.entries.count - 1
            }
            liveCount += 1
            changed = true
        }

        if changed {
            saveBank(bank)
            postChange()
        }
    }

    static func deleteWord(_ word: WordCard) {
        var bank = loadBank()
        let now = ProgressClock.now()
        guard let index = index(of: bank)[key(for: word)],
              bank.entries[index].isLive(wordsClearedAt: bank.clearedAt)
        else { return }
        bank.entries[index].deletedAt = max(now, bank.entries[index].addedAt)
        saveBank(bank)
        postChange()
    }

    static func clearWords(for level: JLPTLevel) {
        var bank = loadBank()
        let now = ProgressClock.now()
        var changed = false
        for index in bank.entries.indices
        where bank.entries[index].level == level.rawValue && bank.entries[index].isLive(wordsClearedAt: bank.clearedAt) {
            bank.entries[index].deletedAt = max(now, bank.entries[index].addedAt)
            changed = true
        }
        if changed {
            saveBank(bank)
            postChange()
        }
    }

    /// Clears the whole bank, here and (after sync) on every device.
    static func clearAllWords() {
        let bank = loadBank()
        let latest = bank.entries.reduce(bank.clearedAt) { max($0, $1.addedAt, $1.deletedAt) }
        saveBank(WordBank(clearedAt: ProgressClock.now(atLeast: latest), entries: []))
        postChange()
    }

    static func wordCounts() -> [JLPTLevel: Int] {
        let words = loadAllWords()
        var counts: [JLPTLevel: Int] = [:]
        for level in JLPTLevel.allCases {
            counts[level] = words.filter { $0.level == level }.count
        }
        return counts
    }

    static func totalCount() -> Int {
        loadAllWords().count
    }

    // MARK: - Storage

    /// The stored bank, live words and tombstones. Migrates the pre-sync `savedWords` array once,
    /// giving every word the migration time so it uploads on first sign-in.
    static func loadBank() -> WordBank {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey) {
            return (try? JSONDecoder().decode(WordBank.self, from: data)) ?? WordBank()
        }
        guard let legacy = defaults.data(forKey: legacyStorageKey),
              let cards = try? JSONDecoder().decode([WordCard].self, from: legacy)
        else { return WordBank() }

        let now = ProgressClock.now()
        var bank = WordBank()
        var seen: Set<String> = []
        for card in cards.map({ fittedForSync($0) }) {
            let key = key(for: card)
            guard seen.insert(key).inserted else { continue }
            bank.entries.append(ProgressSnapshot.Word(
                key: key, word: card.word, romaji: card.romaji, meaning: card.meaning,
                level: card.level.rawValue, addedAt: now, deletedAt: 0
            ))
        }
        saveBank(bank)
        defaults.removeObject(forKey: legacyStorageKey)
        return bank
    }

    static func saveBank(_ bank: WordBank) {
        if let data = try? JSONEncoder().encode(bank) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Stores the word part of a merged snapshot (used by sync; does not post a change).
    static func apply(_ snapshot: ProgressSnapshot) {
        saveBank(WordBank(clearedAt: snapshot.wordsClearedAt, entries: snapshot.words))
    }

    /// The server turns away a whole snapshot when one string is longer than 300 characters
    /// (Unicode scalars after NFC), which would stop every sync, so over-long text from the word
    /// generator is cut to fit. The word leaves room for the "|N5" of its key.
    private static func fittedForSync(_ card: WordCard) -> WordCard {
        func fits(_ text: String, _ limit: Int) -> Bool {
            text.precomposedStringWithCanonicalMapping.unicodeScalars.count <= limit
        }
        func cut(_ text: String, _ limit: Int) -> String {
            guard !fits(text, limit) else { return text }
            var scalars = String.UnicodeScalarView()
            scalars.append(contentsOf: text.precomposedStringWithCanonicalMapping.unicodeScalars.prefix(limit))
            return String(scalars)
        }
        guard !fits(card.word, 290) || !fits(card.romaji, 300) || !fits(card.meaning, 300) else { return card }
        return WordCard(word: cut(card.word, 290), romaji: cut(card.romaji, 300), meaning: cut(card.meaning, 300), level: card.level)
    }

    private static func index(of bank: WordBank) -> [String: Int] {
        var indexByKey: [String: Int] = [:]
        for (index, entry) in bank.entries.enumerated() where indexByKey[entry.key] == nil {
            indexByKey[entry.key] = index
        }
        return indexByKey
    }

    private static func postChange() {
        NotificationCenter.default.post(name: .progressDidChangeLocally, object: nil)
    }
}
