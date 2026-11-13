import Foundation

extension Notification.Name {
    /// Posted (on the main thread) after every local edit of synced progress: a kanji learned, a
    /// better score, a reset, words saved, deleted or cleared. `SyncService` schedules a sync on it.
    /// Writes made by the sync itself do not post it.
    static let progressDidChangeLocally = Notification.Name("progressDidChangeLocally")
}

/// Timestamps for local edits, in milliseconds since 1970.
///
/// The device clock is corrected by the offset to the server clock learned on each sync, so a
/// device whose clock runs ahead does not write timestamps the server has to clamp (which would
/// make every sync differ from the server and schedule another one).
enum ProgressClock {
    private static let offsetKey = "progressClockOffsetMs"
    /// Offsets this small are network noise; the device clock is used as it is.
    private static let ignoredOffsetMs: Double = 2_000

    private static var offsetMs: Double {
        get { UserDefaults.standard.double(forKey: offsetKey) }
        set { UserDefaults.standard.set(newValue, forKey: offsetKey) }
    }

    /// Now, on the server's clock as far as it is known.
    static func now() -> Double {
        (Date().timeIntervalSince1970 * 1000).rounded(.down) + offsetMs
    }

    /// Now, but never earlier than `minimum`, so a local edit always orders after the state it
    /// was made on (a learn after a reset, a re-add after a delete) even with a slow clock.
    static func now(atLeast minimum: Double) -> Double {
        max(now(), minimum)
    }

    /// Learns the offset from a sync response, assuming the server stamped it halfway through.
    static func recordServerTime(_ serverTime: Double, sentAt: Date, receivedAt: Date) {
        guard serverTime > 0 else { return }
        let midpoint = (sentAt.timeIntervalSince1970 + receivedAt.timeIntervalSince1970) / 2 * 1000
        let offset = (serverTime - midpoint).rounded()
        offsetMs = abs(offset) <= ignoredOffsetMs ? 0 : offset
    }
}

/// The synced part of the local stores as one `ProgressSnapshot`, and back.
enum LocalProgress {
    /// Everything that syncs, read from the stores (kanji progress + word bank).
    static func snapshot() -> ProgressSnapshot {
        let kanji = KanjiProgressStore.load()
        let bank = WordStorageService.loadBank()
        return ProgressSnapshot(
            kanjiResetAt: kanji.resetAt,
            learned: kanji.snapshotLearned,
            scores: kanji.snapshotScores,
            wordsClearedAt: bank.clearedAt,
            words: bank.entries
        )
    }

    /// The most word entries (live words and tombstones) a sync sends: the server's limit
    /// (`SNAPSHOT_LIMITS.maxWords` in convex/lib/merge.ts).
    static let maxSyncedWordEntries = 8000

    /// The snapshot a sync sends: `snapshot()`, but never more word entries than the server
    /// accepts. Beyond that the oldest tombstones are left out (only a device that deleted
    /// thousands of words without syncing gets there; the server compacts its own tombstones
    /// long before). The stores are not changed.
    static func snapshotForSync() -> ProgressSnapshot {
        var snapshot = snapshot()
        let excess = snapshot.words.count - maxSyncedWordEntries
        guard excess > 0 else { return snapshot }
        let clearedAt = snapshot.wordsClearedAt
        let oldestTombstones = snapshot.words.indices
            .filter { !snapshot.words[$0].isLive(wordsClearedAt: clearedAt) }
            .sorted { snapshot.words[$0].deletedAt < snapshot.words[$1].deletedAt }
            .prefix(excess)
        let leftOut = Set(oldestTombstones)
        snapshot.words = snapshot.words.indices.filter { !leftOut.contains($0) }.map { snapshot.words[$0] }
        return snapshot
    }

    /// Replaces the stores with a (merged) snapshot. Does not post `progressDidChangeLocally`;
    /// the caller reloads `KanjiViewModel` and bumps `SyncService.revision`.
    static func apply(_ snapshot: ProgressSnapshot) {
        KanjiProgressStore.apply(snapshot)
        WordStorageService.apply(snapshot)
    }

    /// Makes the local progress ready to join an account whose state is `server` (see
    /// `ProgressSnapshot.rebased`) and saves it. Returns whether the stores changed. Does not post
    /// `progressDidChangeLocally`.
    static func rebase(onto server: ProgressSnapshot, watermark: Double, now: Double) -> Bool {
        let local = snapshot()
        let rebased = local.rebased(onto: server, watermark: watermark, now: now)
        guard rebased != local.normalized else { return false }
        apply(rebased)
        return true
    }

    /// Replaces the local progress with an account's (the learner chose to use the account's
    /// progress on this device). Returns whether the stores changed. Does not post a change.
    static func replace(with server: ProgressSnapshot) -> Bool {
        let local = snapshot().normalized
        let replacement = server.normalized
        guard replacement != local else { return false }
        apply(replacement)
        return true
    }

    nonisolated struct MergeOutcome: Equatable, Sendable {
        /// The stores were rewritten: reload what shows them.
        var localChanged: Bool
        /// The local state has something the server's does not (edits made during the request):
        /// sync again.
        var serverIsBehind: Bool
    }

    /// Merges the server's state into the local state as it is NOW (read again, since edits may
    /// have happened while the request ran, and they must not be lost) and saves the result.
    ///
    /// Like the server, local timestamps later than `now` are clamped first (written by a clock
    /// running ahead before the offset was known); otherwise every sync would differ from the
    /// server and schedule another.
    static func mergeServerSnapshot(_ server: ProgressSnapshot, now: Double) -> MergeOutcome {
        let serverState = server.normalized
        let local = snapshot()
        let merged = ProgressSnapshot.merge(serverState, local.clampingTimestamps(to: now))
        let localChanged = merged != local.normalized
        if localChanged {
            apply(merged)
        }
        return MergeOutcome(localChanged: localChanged, serverIsBehind: merged != serverState)
    }
}

// MARK: - Joining an account

nonisolated extension ProgressSnapshot {
    /// This device's progress (`self`) made ready to join an account whose state is `server`.
    ///
    /// Entries stamped at or before `watermark` were on the account's server after this device's
    /// last sync with it (0 when the device never synced with it): they stay as they are, so the
    /// account's later resets and deletions apply to them. Everything later was made while the
    /// device was not syncing with the account:
    /// - learned kanji, scores and live words are stamped again just after the account's state
    ///   (after its resets, clears and deletes of the same word), so they are added to it;
    /// - a reset, Clear All or deleted word is dropped: it stays on this device only, and the
    ///   account's own progress comes back here when the result is merged with it.
    /// Rebased words keep their order (oldest first), 1/256 ms apart.
    func rebased(onto server: ProgressSnapshot, watermark: Double, now: Double) -> ProgressSnapshot {
        let local = normalized
        let server = server.normalized

        let resetAt = local.kanjiResetAt > watermark ? server.kanjiResetAt : local.kanjiResetAt
        let kanjiStamp = Swift.max(now, server.kanjiResetAt + 1, resetAt + 1)
        let learned = local.learned.map {
            $0.learnedAt > watermark ? LearnedKanji(kanji: $0.kanji, learnedAt: kanjiStamp) : $0
        }
        // Several new scores of one key get the same time: the merge keeps the best of them.
        let scores = local.scores.map {
            $0.recordedAt > watermark ? Score(key: $0.key, percent: $0.percent, recordedAt: kanjiStamp) : $0
        }

        let clearedAt = local.wordsClearedAt > watermark ? server.wordsClearedAt : local.wordsClearedAt
        var serverDeletes: [String: Double] = [:]
        for word in server.words {
            serverDeletes[word.key] = Swift.max(serverDeletes[word.key] ?? 0, word.deletedAt)
        }
        var words: [Word] = []
        var added: [Word] = []
        for word in local.words {
            if local.isLive(word) {
                if word.addedAt > watermark {
                    added.append(word)
                } else {
                    words.append(word)
                }
            } else if word.deletedAt <= watermark {
                words.append(word) // a delete the account already has
            }
            // Otherwise a delete made while not syncing: left out (this device only).
        }
        var floor = Swift.max(server.wordsClearedAt, clearedAt)
        for word in added {
            floor = Swift.max(floor, serverDeletes[word.key] ?? 0)
        }
        let base = Swift.max(now, floor + 1)
        let ordered = added.sorted {
            $0.addedAt != $1.addedAt ? $0.addedAt < $1.addedAt : Self.codePointPrecedes($0.key, $1.key)
        }
        for (index, word) in ordered.enumerated() {
            var rebased = word
            rebased.addedAt = base + Double(index) / 256
            // A delete made while not syncing is forgotten; one the account has is kept.
            rebased.deletedAt = word.deletedAt <= watermark ? word.deletedAt : 0
            words.append(rebased)
        }

        return ProgressSnapshot(
            kanjiResetAt: resetAt,
            learned: learned,
            scores: scores,
            wordsClearedAt: clearedAt,
            words: words
        ).normalized
    }
}
