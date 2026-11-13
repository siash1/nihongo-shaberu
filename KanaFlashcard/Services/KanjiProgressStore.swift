import Foundation

struct KanjiProgress: Codable {
    var learnedKanji: Set<String> = []
    var bestScores: [String: Int] = [:]   // "<unit>-<test>" → best first-try score, in percent
}

struct KanjiProgressStore {
    private static let storageKey = "kanjiProgress"

    static func load() -> KanjiProgress {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return KanjiProgress() }
        return (try? JSONDecoder().decode(KanjiProgress.self, from: data)) ?? KanjiProgress()
    }

    static func save(_ progress: KanjiProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
