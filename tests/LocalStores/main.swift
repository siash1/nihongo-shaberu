// Local store tests (migration, word bank rules, kanji snapshot conversion, the merge a sync does
// after its request). Compiled like the app, with MainActor default isolation:
//
//   swiftc -default-isolation MainActor KanaFlashcard/Models/ProgressSnapshot.swift \
//     KanaFlashcard/Models/WordCard.swift KanaFlashcard/Models/JLPTLevel.swift \
//     KanaFlashcard/Services/LocalProgress.swift KanaFlashcard/Services/KanjiProgressStore.swift \
//     KanaFlashcard/Services/WordStorageService.swift tests/LocalStores/main.swift -o /tmp/localstores
//   /tmp/localstores
//
// Uses this executable's own UserDefaults domain and removes it at the end.

import Foundation

var failures = 0
var checks = 0

func check(_ condition: Bool, _ message: @autoclosure () -> String, line: UInt = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL (line \(line)): \(message())")
    }
}

func section(_ name: String) {
    print("— \(name)")
}

let defaultsDomain = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
UserDefaults.standard.removePersistentDomain(forName: defaultsDomain)
defer { UserDefaults.standard.removePersistentDomain(forName: defaultsDomain) }

nonisolated final class Counter: @unchecked Sendable {
    var value = 0
}

let changes = Counter()
let observer = NotificationCenter.default.addObserver(forName: .progressDidChangeLocally, object: nil, queue: nil) { _ in
    changes.value += 1
}

func bank() -> WordBank {
    WordStorageService.loadBank()
}

func liveKeys() -> [String] {
    WordStorageService.loadAllWords().map { "\($0.word)|\($0.level.rawValue)" }
}

// MARK: - Migration

section("migration of pre-sync data")
do {
    let legacyKanji = #"{"learnedKanji":["日","月"],"bestScores":{"1-kanji":80}}"#
    UserDefaults.standard.set(Data(legacyKanji.utf8), forKey: "kanjiProgress")
    let legacyWords = [
        WordCard(word: "ねこ", romaji: "neko", meaning: "cat", level: .n5),
        WordCard(word: "いぬ", romaji: "inu", meaning: "dog", level: .n5),
        WordCard(word: "ねこ", romaji: "neko", meaning: "duplicate", level: .n5),
        WordCard(word: "がっこう", romaji: "gakkou", meaning: "school", level: .n4),
    ]
    UserDefaults.standard.set(try! JSONEncoder().encode(legacyWords), forKey: "savedWords")

    let before = ProgressClock.now()
    let snapshot = LocalProgress.snapshot()
    check(Set(snapshot.learned.map(\.kanji)) == ["日", "月"] && snapshot.learned.allSatisfy { $0.learnedAt >= before },
          "learned kanji get the migration time: \(snapshot.learned)")
    check(snapshot.scores.count == 1 && snapshot.scores[0].percent == 80 && snapshot.scores[0].recordedAt >= before,
          "scores get the migration time: \(snapshot.scores)")
    check(snapshot.words.count == 3 && snapshot.words.allSatisfy { $0.addedAt >= before && $0.deletedAt == 0 },
          "unique words migrated with the migration time: \(snapshot.words.map(\.key))")
    check(snapshot.words.first { $0.key == "ねこ|N5" }?.meaning == "cat", "first copy of a duplicate wins")
    check(UserDefaults.standard.data(forKey: "savedWords") == nil, "legacy word array removed")
    check(UserDefaults.standard.data(forKey: "wordBank") != nil, "word bank saved in the new format")

    let again = LocalProgress.snapshot()
    check(again == snapshot, "migration happens once (timestamps stable)")
    check(changes.value == 0, "loading never posts a change")
    check(snapshot.normalized.learned.count == 2, "migrated progress survives the merge rules (uploads on sign-in)")
}

// MARK: - Word bank rules

section("word bank")
do {
    WordStorageService.clearAllWords()
    let clearedAt = bank().clearedAt
    check(bank().entries.isEmpty && clearedAt > 0, "clear all drops every entry and keeps its time")
    changes.value = 0

    WordStorageService.saveWords([
        WordCard(word: "ねこ", romaji: "neko", meaning: "cat", level: .n5),
        WordCard(word: "いぬ", romaji: "inu", meaning: "dog", level: .n5),
        WordCard(word: "ねこ", romaji: "neko", meaning: "again", level: .n5),
    ])
    check(liveKeys() == ["いぬ|N5", "ねこ|N5"], "new words live, de-duplicated, same addedAt ordered by key: \(liveKeys())")
    check(bank().entries.allSatisfy { $0.addedAt > clearedAt }, "words added after a clear are later than it")
    check(changes.value == 1, "one change posted per save")

    WordStorageService.saveWords([WordCard(word: "ねこ", romaji: "NEKO", meaning: "other", level: .n5)])
    check(WordStorageService.loadAllWords().first { $0.word == "ねこ" }?.romaji == "neko", "a live key keeps its original entry")
    check(changes.value == 1, "saving only live words posts nothing")

    WordStorageService.deleteWord(WordCard(word: "ねこ", romaji: "", meaning: "", level: .n5))
    let tombstone = bank().entries.first { $0.key == "ねこ|N5" }
    check(liveKeys() == ["いぬ|N5"], "deleted word is not shown")
    check(tombstone != nil && tombstone!.deletedAt >= tombstone!.addedAt, "delete keeps a tombstone: \(String(describing: tombstone))")
    check(changes.value == 2, "delete posts a change")

    WordStorageService.saveWords([WordCard(word: "ねこ", romaji: "neko", meaning: "a cat", level: .n5)])
    let readded = bank().entries.first { $0.key == "ねこ|N5" }!
    check(readded.isLive(wordsClearedAt: bank().clearedAt) && readded.meaning == "a cat" && readded.addedAt > readded.deletedAt,
          "re-adding a deleted word makes it live with the new text")
    check(liveKeys() == ["いぬ|N5", "ねこ|N5"], "oldest first: \(liveKeys())")

    WordStorageService.saveWords([WordCard(word: "がっこう", romaji: "gakkou", meaning: "school", level: .n4)])
    check(WordStorageService.wordCounts()[.n5] == 2 && WordStorageService.wordCounts()[.n4] == 1 && WordStorageService.totalCount() == 3,
          "counts of live words")
    check(WordStorageService.loadWords(for: [.n4]).map(\.word) == ["がっこう"], "loadWords(for:) filters by level")

    WordStorageService.clearWords(for: .n5)
    check(liveKeys() == ["がっこう|N4"], "clearing a level deletes its live words: \(liveKeys())")
    check(bank().entries.count == 3, "cleared level words stay as tombstones")

    WordStorageService.clearAllWords()
    check(WordStorageService.loadAllWords().isEmpty && bank().entries.isEmpty, "clear all")
    WordStorageService.saveWords([WordCard(word: "ねこ", romaji: "neko", meaning: "cat", level: .n5)])
    check(liveKeys() == ["ねこ|N5"], "a word saved after clear all is live")

    // Decomposed input is stored under its NFC key, so it matches the precomposed word.
    WordStorageService.saveWords([WordCard(word: "\u{304B}\u{3099}", romaji: "ga", meaning: "moth", level: .n1)])
    WordStorageService.deleteWord(WordCard(word: "\u{304C}", romaji: "", meaning: "", level: .n1))
    check(WordStorageService.loadWords(for: [.n1]).isEmpty, "NFC keys: decomposed save, precomposed delete")

    // The server turns away a snapshot with a string over 300 characters, so long text is cut.
    WordStorageService.saveWords([WordCard(
        word: String(repeating: "あ", count: 400), romaji: String(repeating: "a", count: 400),
        meaning: String(repeating: "𠮷", count: 400), level: .n2
    )])
    let long = bank().entries.first { $0.level == "N2" }
    check(long.map { $0.word.unicodeScalars.count == 290 && $0.key.unicodeScalars.count == 293 } ?? false,
          "an over-long word is cut, leaving room for its key's level")
    check(long.map { $0.romaji.unicodeScalars.count == 300 && $0.meaning.unicodeScalars.count == 300 } ?? false,
          "over-long romaji and meaning are cut to 300 characters (non-BMP counted once)")
}

// MARK: - Kanji conversion

section("kanji progress ↔ snapshot")
do {
    let frontier = ProgressSnapshot(
        kanjiResetAt: 3,
        learned: [.init(kanji: "日", learnedAt: 4)],
        scores: [.init(key: "1-kanji", percent: 90, recordedAt: 5), .init(key: "1-kanji", percent: 50, recordedAt: 15),
                 .init(key: "2-words", percent: 70, recordedAt: 6)]
    ).normalized
    var progress = KanjiProgress(snapshot: frontier)
    check(progress.bestScores == ["1-kanji": 90, "2-words": 70] && progress.scoreRecordedAt["1-kanji"] == 5,
          "best score per key from the frontier: \(progress.bestScores)")
    check(progress.otherScores == [.init(key: "1-kanji", percent: 50, recordedAt: 15)], "later lower score kept beside it")
    check(progress.learnedKanji == ["日"] && progress.learnedAt["日"] == 4 && progress.resetAt == 3, "learned and reset")

    var roundTrip = frontier
    roundTrip.learned = progress.snapshotLearned
    roundTrip.scores = progress.snapshotScores
    check(roundTrip.normalized == frontier, "snapshot → progress → snapshot is lossless")
    check(progress.latestScoreTime(for: "1-kanji") == 15 && progress.latestTimestamp == 15, "latest timestamps")

    progress.setBestScore(95, for: "1-kanji", at: 20)
    check(progress.otherScores.isEmpty && progress.bestScores["1-kanji"] == 95, "a new best drops the key's other entries")

    let legacy = try! JSONDecoder().decode(KanjiProgress.self, from: Data(#"{"learnedKanji":[],"bestScores":{}}"#.utf8))
    check(legacy == KanjiProgress(), "old JSON without timestamps decodes")
}

// MARK: - The merge after a sync request

section("merge after the request")
do {
    UserDefaults.standard.removePersistentDomain(forName: defaultsDomain)
    let now = ProgressClock.now()
    KanjiProgressStore.save(KanjiProgress(snapshot: ProgressSnapshot(learned: [.init(kanji: "日", learnedAt: now - 1000)])))
    WordStorageService.saveWords([WordCard(word: "ねこ", romaji: "neko", meaning: "cat", level: .n5)])

    // The request: this device's snapshot meets another device's state on the server.
    let sent = LocalProgress.snapshot()
    let otherDevice = ProgressSnapshot(
        learned: [.init(kanji: "月", learnedAt: now - 500)],
        scores: [.init(key: "3-kanji", percent: 60, recordedAt: now - 400)],
        words: [.init(key: "いぬ|N5", word: "いぬ", romaji: "inu", meaning: "dog", level: "N5", addedAt: now - 300, deletedAt: 0)]
    )
    let server = ProgressSnapshot.merge(otherDevice, sent.clampingTimestamps(to: now))

    // An edit while the request runs.
    WordStorageService.saveWords([WordCard(word: "とり", romaji: "tori", meaning: "bird", level: .n5)])

    let first = LocalProgress.mergeServerSnapshot(server, now: ProgressClock.now())
    check(first == .init(localChanged: true, serverIsBehind: true), "other device's data arrives; the edit is still unsent: \(first)")
    let local = LocalProgress.snapshot()
    check(Set(local.learned.map(\.kanji)) == ["日", "月"] && local.scores.map(\.key) == ["3-kanji"], "kanji from both devices")
    check(Set(WordStorageService.loadAllWords().map(\.word)) == ["ねこ", "いぬ", "とり"], "the edit made during the request is kept")

    // The follow-up sync sends it; then everything agrees.
    let server2 = ProgressSnapshot.merge(server, LocalProgress.snapshot())
    let second = LocalProgress.mergeServerSnapshot(server2, now: ProgressClock.now())
    check(second == .init(localChanged: false, serverIsBehind: false), "second sync changes nothing: \(second)")
    check(LocalProgress.snapshot().normalized == server2, "local equals server")

    // A clock that ran ahead: the server clamped the timestamp, the client clamps too and agrees.
    WordStorageService.saveBank(WordBank(clearedAt: 0, entries: [
        .init(key: "未来|N5", word: "未来", romaji: "mirai", meaning: "future", level: "N5", addedAt: now + 3_600_000, deletedAt: 0),
    ]))
    let clampedServer = ProgressSnapshot.merge(.empty, LocalProgress.snapshot().clampingTimestamps(to: now))
    let third = LocalProgress.mergeServerSnapshot(clampedServer, now: now)
    check(!third.serverIsBehind && LocalProgress.snapshot().words.first?.addedAt == now,
          "future timestamps are clamped locally, so the next sync is not scheduled: \(third)")
    check(changes.value > 0, "local edits posted changes")
}

// MARK: - Scores: every test is recorded

section("addScore keeps the latest score beside the best")
do {
    typealias Score = ProgressSnapshot.Score
    var progress = KanjiProgress()
    progress.addScore(90, for: "1-kanji", at: 10)
    progress.addScore(85, for: "1-kanji", at: 20)
    check(progress.bestScores["1-kanji"] == 90 && progress.otherScores == [Score(key: "1-kanji", percent: 85, recordedAt: 20)],
          "a lower, later score is kept beside the best: \(progress.otherScores)")
    progress.addScore(85, for: "1-kanji", at: 30)
    check(progress.otherScores == [Score(key: "1-kanji", percent: 85, recordedAt: 30)], "an equal later score replaces it")
    progress.addScore(70, for: "1-kanji", at: 40)
    progress.addScore(80, for: "1-kanji", at: 50)
    check(progress.otherScores == [Score(key: "1-kanji", percent: 85, recordedAt: 30), Score(key: "1-kanji", percent: 80, recordedAt: 50)],
          "a score drops the earlier ones it beats: \(progress.otherScores)")
    check(progress.bestScores["1-kanji"] == 90, "the best shown is unchanged")
    progress.addScore(90, for: "1-kanji", at: 60)
    check(progress.otherScores.isEmpty && progress.scoreRecordedAt["1-kanji"] == 60, "an equal best moves to the later time")

    // The finding's case: 90% (synced), a reset on another device, then 85% here before pulling it.
    var phone = KanjiProgress()
    phone.addScore(90, for: "1-kanji", at: 5)
    phone.addScore(85, for: "1-kanji", at: 20)
    var phoneSnapshot = ProgressSnapshot()
    phoneSnapshot.scores = phone.snapshotScores
    let merged = ProgressSnapshot.merge(phoneSnapshot, ProgressSnapshot(kanjiResetAt: 10))
    check(merged.bestScores == ["1-kanji": 85], "the score taken after the other device's reset survives it: \(merged.scores)")
}

// MARK: - Joining an account

section("joining an account: progress made while not syncing")
do {
    typealias Word = ProgressSnapshot.Word
    func word(_ w: String, _ added: Double, _ deleted: Double = 0) -> Word {
        Word(key: "\(w)|N5", word: w, romaji: w, meaning: w, level: "N5", addedAt: added, deletedAt: deleted)
    }
    let t: Double = 1_800_000_000_000

    // A device that never synced: migrated progress with old stamps, and its own reset, clear and delete.
    let device = ProgressSnapshot(
        kanjiResetAt: t + 50,
        learned: [.init(kanji: "日", learnedAt: t + 60), .init(kanji: "月", learnedAt: t + 70)],
        scores: [.init(key: "1-kanji", percent: 80, recordedAt: t + 60), .init(key: "1-kanji", percent: 50, recordedAt: t + 80)],
        wordsClearedAt: t + 55,
        words: [word("ねこ", t + 60), word("とり", t + 59), word("いぬ", t + 61, t + 62)]
    )
    // The account reset and cleared later than all of that, and has progress of its own.
    let account = ProgressSnapshot(
        kanjiResetAt: t + 1000,
        learned: [.init(kanji: "火", learnedAt: t + 1100)],
        wordsClearedAt: t + 1000,
        words: [word("そら", t + 1100), word("いぬ", t + 1050)]
    )
    let old = ProgressSnapshot.merge(account, device)
    check(old.learned.map(\.kanji) == ["火"], "(without joining, the account's reset would wipe the device's progress)")

    let now = t + 2000
    let joined = device.rebased(onto: account, watermark: 0, now: now)
    let result = ProgressSnapshot.merge(account, joined)
    check(Set(result.learned.map(\.kanji)) == ["日", "月", "火"], "the device's kanji are added: \(result.learned)")
    check(result.bestScores == ["1-kanji": 80] && result.scores.count == 1, "its best score is added: \(result.scores)")
    check(result.kanjiResetAt == t + 1000 && result.wordsClearedAt == t + 1000, "the device's reset and clear never reach the account")
    check(Set(result.liveWords.map(\.word)) == ["ねこ", "とり", "そら", "いぬ"], "its words are added; its delete does not remove the account's word: \(result.liveWords.map(\.word))")
    let ordered = result.liveWords.filter { ["ねこ", "とり"].contains($0.word) }.sorted { $0.addedAt < $1.addedAt }.map(\.word)
    check(ordered == ["とり", "ねこ"], "rebased words keep their order: \(ordered)")
    check(joined.rebased(onto: account, watermark: 0, now: now) == joined, "joining twice changes nothing more")

    // A device that synced with the account (up to the watermark), then signed out and kept going.
    let watermark = t + 500
    let linked = ProgressSnapshot(
        kanjiResetAt: t + 600,                                   // reset while signed out
        learned: [.init(kanji: "水", learnedAt: t + 700)],        // learned while signed out
        words: [word("やま", t + 100, t + 650),                   // the account's word, deleted while signed out
                word("かわ", t + 100),                            // the account's word
                word("うみ", t + 610, t + 620)]                   // added and deleted while signed out
    )
    let account2 = ProgressSnapshot(
        learned: [.init(kanji: "木", learnedAt: t + 200), .init(kanji: "金", learnedAt: t + 800)],
        words: [word("やま", t + 100), word("かわ", t + 100, t + 800)]   // かわ deleted on another device meanwhile
    )
    let result2 = ProgressSnapshot.merge(account2, linked.rebased(onto: account2, watermark: watermark, now: now))
    check(Set(result2.learned.map(\.kanji)) == ["木", "金", "水"], "a reset made while signed out stays on the device: \(result2.learned)")
    check(result2.kanjiResetAt == 0, "the account has no reset")
    check(result2.liveWords.map(\.word) == ["やま"], "a delete made while signed out stays on the device; the account's delete applies: \(result2.liveWords.map(\.word))")
    check(!result2.words.contains { $0.word == "うみ" }, "a word added and deleted while signed out never reaches the account")

    // The same through the stores.
    UserDefaults.standard.removePersistentDomain(forName: defaultsDomain)
    LocalProgress.apply(device.normalized)
    check(LocalProgress.rebase(onto: account, watermark: 0, now: now), "rebase rewrites the stores")
    check(LocalProgress.snapshot().normalized == joined, "stores hold the rebased progress")
    check(!LocalProgress.rebase(onto: account, watermark: 0, now: now), "a second rebase changes nothing")
    check(LocalProgress.replace(with: account), "replace rewrites the stores")
    check(LocalProgress.snapshot().normalized == account.normalized, "stores hold the account's progress")
}

// MARK: - Word bank limits

section("word bank limits")
do {
    UserDefaults.standard.removePersistentDomain(forName: defaultsDomain)
    let max = WordStorageService.maxLiveWords
    WordStorageService.saveWords((0..<(max + 5)).map { WordCard(word: "w\($0)", romaji: "w", meaning: "m", level: .n3) })
    check(WordStorageService.totalCount() == max && WordStorageService.isFull, "new words stop at \(max): \(WordStorageService.totalCount())")
    WordStorageService.deleteWord(WordCard(word: "w0", romaji: "", meaning: "", level: .n3))
    check(!WordStorageService.isFull, "removing a word makes room")
    WordStorageService.saveWords([WordCard(word: "new1", romaji: "n", meaning: "m", level: .n3), WordCard(word: "new2", romaji: "n", meaning: "m", level: .n3)])
    check(WordStorageService.totalCount() == max && WordStorageService.loadAllWords().contains { $0.word == "new1" }, "one more fits, then full again")

    // A device over the server's request limit leaves its oldest tombstones out of the request.
    var bank = WordBank(clearedAt: 0, entries: [])
    for i in 0..<(LocalProgress.maxSyncedWordEntries + 3) {
        bank.entries.append(.init(key: "t\(i)|N5", word: "t\(i)", romaji: "t", meaning: "t", level: "N5", addedAt: 1, deletedAt: Double(10 + i)))
    }
    bank.entries.append(.init(key: "live|N5", word: "live", romaji: "l", meaning: "l", level: "N5", addedAt: 5, deletedAt: 0))
    WordStorageService.saveBank(bank)
    let sent = LocalProgress.snapshotForSync()
    check(sent.words.count == LocalProgress.maxSyncedWordEntries, "request trimmed to the limit: \(sent.words.count)")
    check(sent.words.contains { $0.key == "live|N5" } && !sent.words.contains { $0.key == "t0|N5" || $0.key == "t2|N5" },
          "live words kept, the oldest tombstones left out")
    check(LocalProgress.snapshot().words.count == LocalProgress.maxSyncedWordEntries + 4, "the stores are not changed")
}

NotificationCenter.default.removeObserver(observer)
print(failures == 0 ? "PASS: \(checks) checks" : "FAILED: \(failures) of \(checks) checks")
exit(failures == 0 ? 0 : 1)
