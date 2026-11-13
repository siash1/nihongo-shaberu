import Foundation

struct WordStorageService {
    private static let storageKey = "savedWords"

    static func loadAllWords() -> [WordCard] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([WordCard].self, from: data)) ?? []
    }

    static func loadWords(for levels: [JLPTLevel]) -> [WordCard] {
        let levelSet = Set(levels)
        return loadAllWords().filter { levelSet.contains($0.level) }
    }

    static func saveWords(_ newWords: [WordCard]) {
        var existing = loadAllWords()
        let existingKeys = Set(existing.map { "\($0.word)|\($0.level.rawValue)" })
        let unique = newWords.filter { !existingKeys.contains("\($0.word)|\($0.level.rawValue)") }
        existing.append(contentsOf: unique)

        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func deleteWord(_ word: WordCard) {
        var existing = loadAllWords()
        existing.removeAll { $0.word == word.word && $0.level == word.level }
        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func clearWords(for level: JLPTLevel) {
        var existing = loadAllWords()
        existing.removeAll { $0.level == level }
        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func clearAllWords() {
        UserDefaults.standard.removeObject(forKey: storageKey)
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
}
