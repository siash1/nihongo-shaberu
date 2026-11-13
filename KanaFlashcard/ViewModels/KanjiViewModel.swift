import AVFoundation
import Observation

@Observable
final class KanjiViewModel {
    let units = KanjiData.units

    private(set) var progress = KanjiProgressStore.load()
    private let speechService = SpeechService()

    // MARK: - Learning progress

    var totalKanjiCount: Int {
        KanjiData.allKanji.count
    }

    var learnedCount: Int {
        progress.learnedKanji.count
    }

    var learnedKanji: Set<String> {
        progress.learnedKanji
    }

    /// True when there is anything for Reset Progress to clear.
    var hasProgress: Bool {
        !progress.learnedKanji.isEmpty || !progress.bestScores.isEmpty
    }

    /// The first unit that still has kanji to learn.
    var nextUnit: KanjiUnit? {
        units.first { nextKanji(in: $0) != nil }
    }

    func isLearned(_ entry: KanjiEntry) -> Bool {
        progress.learnedKanji.contains(entry.character)
    }

    func learnedCount(in unit: KanjiUnit) -> Int {
        unit.kanji.filter(isLearned).count
    }

    func nextKanji(in unit: KanjiUnit) -> KanjiEntry? {
        unit.kanji.first { !isLearned($0) }
    }

    func markLearned(_ entry: KanjiEntry) {
        guard progress.learnedKanji.insert(entry.character).inserted else { return }
        KanjiProgressStore.save(progress)
    }

    // MARK: - Test scores

    func bestScore(for kind: KanjiTestKind, in unit: KanjiUnit) -> Int? {
        progress.bestScores[scoreKey(kind, unit)]
    }

    func recordScore(_ percent: Int, for kind: KanjiTestKind, in unit: KanjiUnit) {
        let key = scoreKey(kind, unit)
        guard percent > progress.bestScores[key] ?? -1 else { return }
        progress.bestScores[key] = percent
        KanjiProgressStore.save(progress)
    }

    /// A unit is complete once every kanji is learned and all three tests have been taken.
    func isComplete(_ unit: KanjiUnit) -> Bool {
        nextKanji(in: unit) == nil && KanjiTestKind.allCases.allSatisfy { bestScore(for: $0, in: unit) != nil }
    }

    func resetProgress() {
        progress = KanjiProgress()
        KanjiProgressStore.clear()
    }

    private func scoreKey(_ kind: KanjiTestKind, _ unit: KanjiUnit) -> String {
        "\(unit.number)-\(kind.rawValue)"
    }

    // MARK: - Questions

    func questions(for kind: KanjiTestKind, in unit: KanjiUnit) -> [KanjiQuizQuestion] {
        switch kind {
        case .kanji:
            return KanjiQuizBuilder.kanjiQuestions(for: unit.kanji, pool: unit.kanji)
        case .words:
            return KanjiQuizBuilder.wordQuestions(for: unit.words, pool: unit.words)
        case .sentences:
            return KanjiQuizBuilder.sentenceQuestions(for: unit.sentences, pool: unit.sentences)
        }
    }

    func reviewQuestions() -> [KanjiQuizQuestion] {
        KanjiQuizBuilder.reviewQuestions(learned: progress.learnedKanji, units: units)
    }

    // MARK: - Audio

    func speak(_ text: String) {
        // Use the playback category so the audio is heard even with the silent switch on.
        // Leave play-and-record alone: the Talk tab may be recording, and it plays through the speaker anyway.
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category != .playAndRecord {
            try? audioSession.setCategory(.playback)
        }
        speechService.speak(text)
    }

    func stopSpeaking() {
        speechService.stopSpeaking()
    }
}
