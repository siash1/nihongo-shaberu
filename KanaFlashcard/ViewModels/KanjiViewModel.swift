import AVFoundation
import Foundation
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

    /// Learned now. Passing the check again (relearning a unit) moves `learnedAt` to now too, so
    /// the kanji stays learned even if a reset made on another device, not pulled yet, falls
    /// between the first learning and this one.
    func markLearned(_ entry: KanjiEntry) {
        let kanji = entry.character
        progress.learnedKanji.insert(kanji)
        progress.learnedAt[kanji] = ProgressClock.now(atLeast: max(progress.resetAt, progress.learnedAt[kanji] ?? 0) + 1)
        saveLocalEdit()
    }

    // MARK: - Test scores

    func bestScore(for kind: KanjiTestKind, in unit: KanjiUnit) -> Int? {
        progress.bestScores[scoreKey(kind, unit)]
    }

    /// Records every finished test, not only a new best: the best shown stays the max, and the
    /// latest score is kept beside it (see `KanjiProgress.addScore`).
    func recordScore(_ percent: Int, for kind: KanjiTestKind, in unit: KanjiUnit) {
        let key = scoreKey(kind, unit)
        let time = ProgressClock.now(atLeast: max(progress.resetAt, progress.latestScoreTime(for: key)) + 1)
        progress.addScore(percent, for: key, at: time)
        saveLocalEdit()
    }

    /// A unit is complete once every kanji is learned and all three tests have been taken.
    func isComplete(_ unit: KanjiUnit) -> Bool {
        nextKanji(in: unit) == nil && KanjiTestKind.allCases.allSatisfy { bestScore(for: $0, in: unit) != nil }
    }

    /// Clears learned kanji and scores. The reset keeps its timestamp so it reaches other devices
    /// (and removes progress there that is older than the reset).
    func resetProgress() {
        progress = KanjiProgress(resetAt: ProgressClock.now(atLeast: progress.latestTimestamp))
        saveLocalEdit()
    }

    /// Picks up progress that sync wrote to the store.
    func reloadFromStore() {
        let stored = KanjiProgressStore.load()
        if stored != progress {
            progress = stored
        }
    }

    /// Saves a local edit and tells sync about it.
    private func saveLocalEdit() {
        KanjiProgressStore.save(progress)
        NotificationCenter.default.post(name: .progressDidChangeLocally, object: nil)
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
        // (Mac Catalyst has AVAudioSession; only the macOS command-line build of tests/AppFlow lacks it.)
        #if !os(macOS)
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category != .playAndRecord {
            try? audioSession.setCategory(.playback)
        }
        #endif
        speechService.speak(text)
    }

    func stopSpeaking() {
        speechService.stopSpeaking()
    }
}
