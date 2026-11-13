import Foundation

/// Kanji course progress. Timestamps (ms since 1970) let devices merge their progress:
/// see `ProgressSnapshot.merge`.
nonisolated struct KanjiProgress: Codable, Equatable, Sendable {
    var learnedKanji: Set<String> = []
    var bestScores: [String: Int] = [:]   // "<unit>-<test>" → best first-try score, in percent
    /// When each learned kanji was learned.
    var learnedAt: [String: Double] = [:]
    /// When each best score was recorded.
    var scoreRecordedAt: [String: Double] = [:]
    /// The last Reset Progress, 0 = never. Kept after a reset so the reset reaches other devices.
    var resetAt: Double = 0
    /// Synced score entries beside the best ones: a later but lower score of a key, recorded on
    /// another device. Kept so a reset between the two leaves the later score (see
    /// `ProgressSnapshot.merge`); `bestScores` already holds the max of each key.
    var otherScores: [ProgressSnapshot.Score] = []

    init(resetAt: Double = 0) {
        self.resetAt = resetAt
    }

    /// Progress saved before sync existed has only `learnedKanji` and `bestScores`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        learnedKanji = try container.decodeIfPresent(Set<String>.self, forKey: .learnedKanji) ?? []
        bestScores = try container.decodeIfPresent([String: Int].self, forKey: .bestScores) ?? [:]
        learnedAt = try container.decodeIfPresent([String: Double].self, forKey: .learnedAt) ?? [:]
        scoreRecordedAt = try container.decodeIfPresent([String: Double].self, forKey: .scoreRecordedAt) ?? [:]
        resetAt = try container.decodeIfPresent(Double.self, forKey: .resetAt) ?? 0
        otherScores = try container.decodeIfPresent([ProgressSnapshot.Score].self, forKey: .otherScores) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case learnedKanji, bestScores, learnedAt, scoreRecordedAt, resetAt, otherScores
    }

    /// Gives every learned kanji and score without a timestamp the time `now` (the one-time
    /// migration of pre-sync data, so it uploads on first sign-in) and drops timestamps of
    /// entries that no longer exist. Returns whether anything changed.
    mutating func fillMissingTimestamps(now: Double) -> Bool {
        var changed = false
        let stamp = max(now, resetAt + 1)
        for kanji in learnedKanji where learnedAt[kanji] == nil {
            learnedAt[kanji] = stamp
            changed = true
        }
        for key in bestScores.keys where scoreRecordedAt[key] == nil {
            scoreRecordedAt[key] = stamp
            changed = true
        }
        let staleLearned = learnedAt.keys.filter { !learnedKanji.contains($0) }
        let staleScores = scoreRecordedAt.keys.filter { bestScores[$0] == nil }
        if !staleLearned.isEmpty || !staleScores.isEmpty {
            staleLearned.forEach { learnedAt[$0] = nil }
            staleScores.forEach { scoreRecordedAt[$0] = nil }
            changed = true
        }
        if otherScores.contains(where: { bestScores[$0.key] == nil }) {
            otherScores.removeAll { bestScores[$0.key] == nil }
            changed = true
        }
        return changed
    }

    /// The latest timestamp in the progress, so a reset can be placed after all of it.
    var latestTimestamp: Double {
        max(
            resetAt,
            learnedAt.values.max() ?? 0,
            scoreRecordedAt.values.max() ?? 0,
            otherScores.map(\.recordedAt).max() ?? 0
        )
    }

    /// The latest time any score of `key` was recorded, so a new best can be placed after it.
    func latestScoreTime(for key: String) -> Double {
        otherScores.filter { $0.key == key }.map(\.recordedAt).reduce(scoreRecordedAt[key] ?? 0, max)
    }

    /// A new best score of `key`, recorded at `time`. It beats every earlier entry of the key,
    /// so they are all dropped.
    mutating func setBestScore(_ percent: Int, for key: String, at time: Double) {
        bestScores[key] = percent
        scoreRecordedAt[key] = time
        otherScores.removeAll { $0.key == key }
    }

    /// A score of `key` recorded at `time`, which must be later than every entry of the key.
    /// The newest entry is always on the frontier, even when it is not the best: if a reset from
    /// another device (not pulled yet) falls between the best and this score, this score is the
    /// one that survives. Entries it beats (an equal or lower percent, earlier) are dropped.
    /// `bestScores` stays the max of the key.
    mutating func addScore(_ percent: Int, for key: String, at time: Double) {
        if percent >= bestScores[key] ?? Int.min {
            setBestScore(percent, for: key, at: time)
        } else {
            otherScores.removeAll { $0.key == key && $0.percent <= percent }
            otherScores.append(ProgressSnapshot.Score(key: key, percent: percent, recordedAt: time))
        }
    }

    // MARK: - Snapshot conversion

    init(snapshot: ProgressSnapshot) {
        resetAt = snapshot.kanjiResetAt
        for entry in snapshot.learned {
            learnedKanji.insert(entry.kanji)
            learnedAt[entry.kanji] = entry.learnedAt
        }
        // Several entries of a key form a Pareto frontier: the best (max percent, latest at a tie)
        // goes to bestScores, the rest to otherScores.
        var best: [String: ProgressSnapshot.Score] = [:]
        for score in snapshot.scores {
            if let current = best[score.key],
               score.percent < current.percent
                || (score.percent == current.percent && score.recordedAt <= current.recordedAt) {
                continue
            }
            best[score.key] = score
        }
        for score in best.values {
            bestScores[score.key] = score.percent
            scoreRecordedAt[score.key] = score.recordedAt
        }
        otherScores = snapshot.scores.filter { best[$0.key] != $0 }
    }

    /// Sorted (Set and Dictionary order changes from one load to the next), so the same progress
    /// always gives the same snapshot.
    var snapshotLearned: [ProgressSnapshot.LearnedKanji] {
        learnedKanji
            .map { ProgressSnapshot.LearnedKanji(kanji: $0, learnedAt: learnedAt[$0] ?? 0) }
            .sorted { ProgressSnapshot.codePointPrecedes($0.kanji, $1.kanji) }
    }

    var snapshotScores: [ProgressSnapshot.Score] {
        (bestScores.map { ProgressSnapshot.Score(key: $0.key, percent: $0.value, recordedAt: scoreRecordedAt[$0.key] ?? 0) }
            + otherScores)
            .sorted { x, y in
                let order = ProgressSnapshot.compareCodePoints(x.key, y.key)
                return order != 0 ? order < 0 : x.recordedAt < y.recordedAt
            }
    }
}

struct KanjiProgressStore {
    private static let storageKey = "kanjiProgress"

    /// The saved progress. Pre-sync progress is given timestamps once and saved again.
    static func load() -> KanjiProgress {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var progress = try? JSONDecoder().decode(KanjiProgress.self, from: data)
        else { return KanjiProgress() }
        if progress.fillMissingTimestamps(now: ProgressClock.now()) {
            save(progress)
        }
        return progress
    }

    static func save(_ progress: KanjiProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Stores the kanji part of a merged snapshot (used by sync; does not post a change).
    static func apply(_ snapshot: ProgressSnapshot) {
        save(KanjiProgress(snapshot: snapshot))
    }
}
