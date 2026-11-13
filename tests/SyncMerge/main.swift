// Merge tests for ProgressSnapshot (no Xcode needed):
//
//   swiftc -O KanaFlashcard/Models/ProgressSnapshot.swift tests/SyncMerge/main.swift -o /tmp/syncmerge
//   /tmp/syncmerge [path/to/merge-cases.json]
//
// Scenario tests mirror the merge rules in the sync design; property tests check the algebra on
// random snapshots; fixture tests (tests/fixtures/merge-cases.json, generated from the TypeScript
// merge) check that Swift and TypeScript produce byte-identical canonical results.

import Foundation

typealias Snapshot = ProgressSnapshot
typealias Learned = ProgressSnapshot.LearnedKanji
typealias Score = ProgressSnapshot.Score
typealias Word = ProgressSnapshot.Word

var failures = 0
var checks = 0

func check(_ condition: Bool, _ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL (line \(line)): \(message())")
    }
}

func section(_ name: String) {
    print("— \(name)")
}

let canonicalEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}()

func canonical(_ snapshot: Snapshot) -> String {
    String(decoding: try! canonicalEncoder.encode(snapshot), as: UTF8.self)
}

func word(_ key: String, _ text: String = "w", romaji: String = "r", meaning: String = "m", level: String = "N5",
          added: Double, deleted: Double = 0) -> Word {
    Word(key: key, word: text, romaji: romaji, meaning: meaning, level: level, addedAt: added, deletedAt: deleted)
}

func scalars(_ string: String) -> [UInt32] {
    string.unicodeScalars.map(\.value)
}

func isNFC(_ string: String) -> Bool {
    Array(string.utf8) == Array(string.precomposedStringWithCanonicalMapping.utf8)
}

// MARK: - Scenarios

section("reset and learned kanji")
do {
    let a = Snapshot(kanjiResetAt: 100, learned: [Learned(kanji: "日", learnedAt: 50)])
    let b = Snapshot(learned: [
        Learned(kanji: "日", learnedAt: 150),
        Learned(kanji: "月", learnedAt: 90),
        Learned(kanji: "火", learnedAt: 200),
        Learned(kanji: "水", learnedAt: 100),   // == reset → dropped (<=)
    ])
    let m = Snapshot.merge(a, b)
    check(m.kanjiResetAt == 100, "kanjiResetAt is the max")
    check(m.learned == [Learned(kanji: "日", learnedAt: 150), Learned(kanji: "火", learnedAt: 200)],
          "learned after reset only, sorted by code point: \(m.learned)")

    let latest = Snapshot.merge(
        Snapshot(learned: [Learned(kanji: "日", learnedAt: 200)]),
        Snapshot(learned: [Learned(kanji: "日", learnedAt: 300), Learned(kanji: "日", learnedAt: 250)])
    )
    check(latest.learned == [Learned(kanji: "日", learnedAt: 300)], "latest learnedAt kept: \(latest.learned)")

    // A learning after a reset survives whatever order the snapshots meet in.
    let before = Snapshot(learned: [Learned(kanji: "日", learnedAt: 5)])
    let after = Snapshot(learned: [Learned(kanji: "日", learnedAt: 15)])
    let reset = Snapshot(kanjiResetAt: 10)
    let orders = [
        Snapshot.merge(Snapshot.merge(before, after), reset),
        Snapshot.merge(before, Snapshot.merge(after, reset)),
        Snapshot.merge(Snapshot.merge(before, reset), after),
    ]
    check(orders.allSatisfy { $0.learned == [Learned(kanji: "日", learnedAt: 15)] && $0.kanjiResetAt == 10 },
          "learning after a reset survives any grouping: \(orders.map(\.learned))")

    let neverLearned = Snapshot.merge(Snapshot(learned: [Learned(kanji: "日", learnedAt: 0)]), .empty)
    check(neverLearned.learned.isEmpty, "learnedAt 0 with no reset is dropped (0 <= 0)")
}

section("scores")
do {
    let a = Snapshot(kanjiResetAt: 10, scores: [
        Score(key: "1-kanji", percent: 80, recordedAt: 20),
        Score(key: "1-words", percent: 90, recordedAt: 5),     // before reset → dropped
        Score(key: "2-kanji", percent: 70, recordedAt: 30),
    ])
    let b = Snapshot(scores: [
        Score(key: "1-kanji", percent: 90, recordedAt: 40),    // later and better → replaces 80@20
        Score(key: "2-kanji", percent: 70, recordedAt: 25),    // equal percent → the later recording stays
        Score(key: "10-kanji", percent: 100, recordedAt: 11),
    ])
    let m = Snapshot.merge(a, b)
    check(m.scores == [
        Score(key: "1-kanji", percent: 90, recordedAt: 40),
        Score(key: "10-kanji", percent: 100, recordedAt: 11),
        Score(key: "2-kanji", percent: 70, recordedAt: 30),
    ], "frontier per key, sorted by code point: \(m.scores)")
    check(Snapshot.merge(b, a) == m, "scores commute")

    // A lower but later score stays beside the best, so a reset between them leaves it.
    let best = Snapshot(scores: [Score(key: "k", percent: 90, recordedAt: 5)])
    let lower = Snapshot(scores: [Score(key: "k", percent: 50, recordedAt: 15)])
    let both = Snapshot.merge(best, lower)
    check(both.scores == [Score(key: "k", percent: 90, recordedAt: 5), Score(key: "k", percent: 50, recordedAt: 15)],
          "frontier keeps best and later-lower, by recordedAt: \(both.scores)")
    check(both.bestScores == ["k": 90], "best score is the max percent")
    let afterReset = Snapshot.merge(both, Snapshot(kanjiResetAt: 10))
    check(afterReset.scores == [Score(key: "k", percent: 50, recordedAt: 15)] && afterReset.bestScores == ["k": 50],
          "reset between them leaves the later score: \(afterReset.scores)")
    check(Snapshot.merge(best, Snapshot.merge(lower, Snapshot(kanjiResetAt: 10))) == afterReset, "same in any grouping")

    let sameTime = Snapshot.merge(Snapshot(scores: [Score(key: "k", percent: 40, recordedAt: 7)]),
                                  Snapshot(scores: [Score(key: "k", percent: 60, recordedAt: 7), Score(key: "k", percent: 60, recordedAt: 7)]))
    check(sameTime.scores == [Score(key: "k", percent: 60, recordedAt: 7)], "same time → best only, duplicates collapse")
}

section("words")
do {
    // Re-add after a delete: live, max timestamps, text from the latest add.
    let a = Snapshot(words: [word("ねこ|N5", "ねこ", romaji: "neko", meaning: "cat", added: 10, deleted: 30)])
    let b = Snapshot(words: [word("ねこ|N5", "ねこ", romaji: "neko", meaning: "a cat", added: 40, deleted: 20)])
    let m = Snapshot.merge(a, b)
    check(m.words == [word("ねこ|N5", "ねこ", romaji: "neko", meaning: "a cat", added: 40, deleted: 30)],
          "max timestamps, text from latest add: \(m.words)")
    check(m.isLive(m.words[0]), "re-added after delete is live")

    // A delete after the add makes a tombstone: addedAt 0, text from the latest delete.
    let deleted = Snapshot.merge(a, Snapshot(words: [word("ねこ|N5", "ねこ", romaji: "neko", meaning: "deleting", added: 10, deleted: 50)]))
    check(deleted.words == [word("ねこ|N5", "ねこ", romaji: "neko", meaning: "deleting", added: 0, deleted: 50)],
          "tombstone: addedAt 0, text from the latest delete: \(deleted.words)")
    check(deleted.liveWords.isEmpty, "tombstone is not live")
    check(Snapshot.merge(Snapshot(words: [word("k", added: 7, deleted: 7)]), .empty).words == [word("k", added: 0, deleted: 7)],
          "equal addedAt and deletedAt is a tombstone")

    // Ties on addedAt: smaller romaji, then meaning, then word, then level.
    let tieRomaji = Snapshot.merge(
        Snapshot(words: [word("k", "x", romaji: "ka", meaning: "a", added: 5)]),
        Snapshot(words: [word("k", "y", romaji: "ga", meaning: "z", added: 5)])
    )
    check(tieRomaji.words.first?.romaji == "ga" && tieRomaji.words.first?.word == "y", "tie → smaller romaji wins")
    let tieMeaning = Snapshot.merge(
        Snapshot(words: [word("k", "x", romaji: "ka", meaning: "b", added: 5)]),
        Snapshot(words: [word("k", "y", romaji: "ka", meaning: "a", added: 5)])
    )
    check(tieMeaning.words.first?.meaning == "a" && tieMeaning.words.first?.word == "y", "tie → smaller meaning wins")
    let tieWord = Snapshot.merge(
        Snapshot(words: [word("k", "y", romaji: "ka", meaning: "a", added: 5)]),
        Snapshot(words: [word("k", "x", romaji: "ka", meaning: "a", added: 5)])
    )
    check(tieWord.words.first?.word == "x", "tie → smaller word wins")
    let tieLevel = Snapshot.merge(
        Snapshot(words: [word("k", "x", level: "N5", added: 5)]),
        Snapshot(words: [word("k", "x", level: "N1", added: 5)])
    )
    check(tieLevel.words.first?.level == "N1", "tie → smaller level wins")
    let tieCodePoint = Snapshot.merge(
        Snapshot(words: [word("k", romaji: "\u{FF61}", added: 5)]),
        Snapshot(words: [word("k", romaji: "\u{1F600}", added: 5)])
    )
    check(tieCodePoint.words.first?.romaji == "\u{FF61}", "tie-break uses code points (U+FF61 < U+1F600), not UTF-16")

    // A clear garbage-collects every entry not touched after it.
    let cleared = Snapshot.merge(
        Snapshot(wordsClearedAt: 25, words: []),
        Snapshot(words: [
            word("a", added: 10),               // dropped
            word("b", added: 10, deleted: 25),  // dropped (== clear)
            word("c", added: 10, deleted: 30),  // tombstone kept
            word("d", added: 26, deleted: 20),  // live; the delete before the clear is forgotten
        ])
    )
    check(cleared.wordsClearedAt == 25, "wordsClearedAt is the max")
    check(cleared.words == [word("c", added: 0, deleted: 30), word("d", added: 26, deleted: 0)],
          "clear drops untouched entries: \(cleared.words)")
    check(cleared.liveWords.map(\.key) == ["d"], "only d is live")
    check(!word("x", added: 20).isLive(wordsClearedAt: 20), "added == cleared is not live")
    check(!word("x", added: 20, deleted: 20).isLive(wordsClearedAt: 0), "added == deleted is not live")
}

section("ordering and normalisation")
do {
    let keys = ["日", "a", "😀", "Z", "\u{FF61}", "é", "10-x", "1-x", "2-x"]
    let m = Snapshot.merge(Snapshot(scores: keys.map { Score(key: $0, percent: 50, recordedAt: 1) }), .empty)
    check(m.scores.map(\.key) == ["1-x", "10-x", "2-x", "Z", "a", "é", "日", "\u{FF61}", "😀"],
          "sorted by code point: \(m.scores.map(\.key))")

    // が (U+304C) and か + combining dakuten (U+304B U+3099) are one kanji/key after NFC.
    let composed = "\u{304C}"
    let decomposed = "\u{304B}\u{3099}"
    let n = Snapshot.merge(
        Snapshot(learned: [Learned(kanji: decomposed, learnedAt: 5)],
                 words: [word("\(decomposed)|N5", decomposed, romaji: "ga", meaning: "e\u{301}", added: 3)]),
        Snapshot(learned: [Learned(kanji: composed, learnedAt: 7)],
                 words: [word("\(composed)|N5", composed, romaji: "ga", meaning: "x", added: 2)])
    )
    check(n.learned.count == 1 && scalars(n.learned[0].kanji) == [0x304C] && n.learned[0].learnedAt == 7,
          "NFC-equal kanji merge into one, output NFC: \(n.learned.map { scalars($0.kanji) })")
    check(n.words.count == 1 && scalars(n.words[0].key) == [0x304C, 0x7C, 0x4E, 0x35], "NFC-equal word keys merge")
    check(n.words.first.map { scalars($0.meaning) } == [0xE9], "text fields are NFC (é composed)")
}

section("wire format")
do {
    let snapshot = Snapshot(
        kanjiResetAt: 1,
        learned: [Learned(kanji: "日", learnedAt: 2)],
        scores: [Score(key: "1-kanji", percent: 85, recordedAt: 3)],
        wordsClearedAt: 4,
        words: [word("ねこ|N5", "ねこ", added: 5, deleted: 6)]
    )
    let object = try! JSONSerialization.jsonObject(with: try! JSONEncoder().encode(snapshot)) as! [String: Any]
    check(Set(object.keys) == ["kanjiResetAt", "learned", "scores", "wordsClearedAt", "words"], "snapshot keys: \(object.keys.sorted())")
    check(Set(((object["learned"] as! [[String: Any]])[0]).keys) == ["kanji", "learnedAt"], "learned keys")
    check(Set(((object["scores"] as! [[String: Any]])[0]).keys) == ["key", "percent", "recordedAt"], "score keys")
    check(Set(((object["words"] as! [[String: Any]])[0]).keys) == ["key", "word", "romaji", "meaning", "level", "addedAt", "deletedAt"], "word keys")

    let float = #"{"kanjiResetAt":0,"learned":[],"scores":[{"key":"1-kanji","percent":85.0,"recordedAt":1.7e12}],"wordsClearedAt":0,"words":[]}"#
    let decoded = try? JSONDecoder().decode(Snapshot.self, from: Data(float.utf8))
    check(decoded?.scores.first?.percent == 85 && decoded?.scores.first?.recordedAt == 1.7e12, "percent 85.0 decodes as 85")
    let fractional = float.replacingOccurrences(of: "85.0", with: "85.5")
    check((try? JSONDecoder().decode(Snapshot.self, from: Data(fractional.utf8))) == nil, "percent 85.5 is rejected")

    let clamped = Snapshot(kanjiResetAt: 500, learned: [Learned(kanji: "日", learnedAt: -3)],
                           scores: [Score(key: "k", percent: 1, recordedAt: 200)], wordsClearedAt: 50,
                           words: [word("w", added: 300, deleted: 99)]).clampingTimestamps(to: 100)
    check(clamped.kanjiResetAt == 100 && clamped.learned[0].learnedAt == 0 && clamped.scores[0].recordedAt == 100
          && clamped.wordsClearedAt == 50 && clamped.words[0].addedAt == 100 && clamped.words[0].deletedAt == 99,
          "clampingTimestamps clamps to [0, limit]")
}

// MARK: - Properties

/// SplitMix64: deterministic, so a failure reproduces.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

var rng = SeededGenerator(state: 0x5EED_CAFE)

let kanjiPool = ["日", "月", "火", "水", "\u{304C}", "\u{304B}\u{3099}", "😀", "\u{FF61}", "𠮷", "A", "a"]
let scoreKeyPool = ["1-kanji", "1-words", "2-sentences", "10-kanji", "\u{304C}-x", "\u{304B}\u{3099}-x", "😀"]
let wordKeyPool = ["ねこ|N5", "いぬ|N5", "\u{304C}っこう|N4", "\u{304B}\u{3099}っこう|N4", "😀|N1", "\u{FF71}|N3", "z|N2"]
let textPool = ["neko", "inu", "", "Neko", "\u{E9}", "e\u{301}", "😀", "\u{FF71}", "cat", "a cat"]
let levelPool = ["N5", "N4", "N3", "N2", "N1"]

func randomTime(_ max: Int = 12) -> Double {
    Double(Int.random(in: 0...max, using: &rng))
}

func randomSnapshot() -> Snapshot {
    func some<T>(_ make: () -> T) -> [T] {
        (0..<Int.random(in: 0...5, using: &rng)).map { _ in make() }
    }
    return Snapshot(
        kanjiResetAt: Bool.random(using: &rng) ? 0 : randomTime(8),
        learned: some { Learned(kanji: kanjiPool.randomElement(using: &rng)!, learnedAt: randomTime()) },
        scores: some {
            Score(key: scoreKeyPool.randomElement(using: &rng)!,
                  percent: [0, 50, 50, 80, 100].randomElement(using: &rng)!,
                  recordedAt: randomTime())
        },
        wordsClearedAt: Bool.random(using: &rng) ? 0 : randomTime(8),
        words: some {
            Word(key: wordKeyPool.randomElement(using: &rng)!,
                 word: textPool.randomElement(using: &rng)!,
                 romaji: textPool.randomElement(using: &rng)!,
                 meaning: textPool.randomElement(using: &rng)!,
                 level: levelPool.randomElement(using: &rng)!,
                 addedAt: randomTime(),
                 deletedAt: Bool.random(using: &rng) ? 0 : randomTime())
        }
    )
}

/// What a learner can see: kanji progress and live words with their text.
func observable(_ s: Snapshot) -> String {
    var visible = s
    visible.words = s.liveWords.map {
        Word(key: $0.key, word: $0.word, romaji: $0.romaji, meaning: $0.meaning, level: $0.level, addedAt: $0.addedAt, deletedAt: 0)
    }
    visible.wordsClearedAt = 0
    return canonical(visible)
}

func isWellFormed(_ s: Snapshot) -> Bool {
    func strictlySorted(_ keys: [String]) -> Bool {
        zip(keys, keys.dropFirst()).allSatisfy { Snapshot.codePointPrecedes($0, $1) }
    }
    let strings = s.learned.map(\.kanji) + s.scores.map(\.key)
        + s.words.flatMap { [$0.key, $0.word, $0.romaji, $0.meaning, $0.level] }
    let scoresSorted = zip(s.scores, s.scores.dropFirst()).allSatisfy { x, y in
        let order = Snapshot.compareCodePoints(x.key, y.key)
        return order < 0 || (order == 0 && x.recordedAt < y.recordedAt)
    }
    // Pareto frontier: within a key, a later entry always has a lower percent.
    let frontier = zip(s.scores, s.scores.dropFirst()).allSatisfy { x, y in x.key != y.key || x.percent > y.percent }
    let wordsCanonical = s.words.allSatisfy { w in
        let live = w.isLive(wordsClearedAt: s.wordsClearedAt)
        return (live || w.addedAt == 0) && (w.deletedAt == 0 || w.deletedAt > s.wordsClearedAt)
    }
    return strictlySorted(s.learned.map(\.kanji))
        && scoresSorted && frontier && wordsCanonical
        && strictlySorted(s.words.map(\.key))
        && s.learned.allSatisfy { $0.learnedAt > s.kanjiResetAt }
        && s.scores.allSatisfy { $0.recordedAt > s.kanjiResetAt }
        && s.words.allSatisfy { max($0.addedAt, $0.deletedAt) > s.wordsClearedAt }
        && strings.allSatisfy(isNFC)
}

section("properties (random snapshots)")
let rounds = 4000
for _ in 0..<rounds {
    let a = randomSnapshot(), b = randomSnapshot(), c = randomSnapshot()
    let ab = Snapshot.merge(a, b)

    check(canonical(ab) == canonical(Snapshot.merge(b, a)), "commutative:\n a=\(canonical(a))\n b=\(canonical(b))")
    check(Snapshot.merge(ab, ab) == ab, "idempotent: merge(m, m) == m for m=\(canonical(ab))")
    check(ab.normalized == ab, "a merge result is normalized")
    check(Snapshot.merge(ab, b) == ab && Snapshot.merge(a, ab) == ab, "absorption: merge(merge(a, b), b) == merge(a, b)")
    check(Snapshot.merge(a.normalized, b.normalized) == ab, "normalising inputs first changes nothing")
    check(isWellFormed(ab), "sorted, unique, NFC, nothing that should be dropped: \(canonical(ab))")

    let roundTrip = try! JSONDecoder().decode(Snapshot.self, from: try! JSONEncoder().encode(ab))
    check(roundTrip == ab, "JSON round trip")

    let left = Snapshot.merge(ab, c)
    let right = Snapshot.merge(a, Snapshot.merge(b, c))
    check(canonical(left) == canonical(right), "associative:\n a=\(canonical(a))\n b=\(canonical(b))\n c=\(canonical(c))")
    check(observable(left) == observable(right), "associative on what learners see")
}

section("any grouping of many snapshots")
for _ in 0..<500 {
    let parts = (0..<Int.random(in: 2...6, using: &rng)).map { _ in randomSnapshot() }
    let leftFold = parts.dropFirst().reduce(parts[0]) { Snapshot.merge($0, $1) }
    let rightFold = parts.dropLast().reversed().reduce(parts[parts.count - 1]) { Snapshot.merge($1, $0) }
    let shuffled = parts.shuffled(using: &rng)
    let shuffledFold = shuffled.dropFirst().reduce(shuffled[0]) { Snapshot.merge($0, $1) }
    check(leftFold == rightFold && leftFold == shuffledFold, "fold order does not matter")
}

section("convergence (devices syncing through a server)")
for _ in 0..<500 {
    var server = Snapshot.empty
    var devices = (0..<3).map { _ in randomSnapshot().normalized }
    for _ in 0..<Int.random(in: 1...12, using: &rng) {
        let index = Int.random(in: 0..<devices.count, using: &rng)
        if Bool.random(using: &rng) {
            // A local edit: some new state merged into the device.
            devices[index] = Snapshot.merge(devices[index], randomSnapshot())
        } else {
            // A sync: the server merges the device's state, the device merges the result.
            server = Snapshot.merge(server, devices[index])
            devices[index] = Snapshot.merge(server, devices[index])
            check(devices[index] == server, "after a sync the device equals the server")
        }
    }
    for index in devices.indices {
        server = Snapshot.merge(server, devices[index])
    }
    for index in devices.indices {
        devices[index] = Snapshot.merge(server, devices[index])
    }
    check(devices.allSatisfy { $0 == server }, "every device converges to the server state")
}

// MARK: - Fixtures from the TypeScript merge

/// Accepts `[{a, b, expected}]` or `{cases: [...]}`; also the key spellings left/right and
/// merged/result/output.
func loadFixtureCases(_ url: URL) throws -> [(name: String, a: Snapshot, b: Snapshot, expected: Snapshot)] {
    let root = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    let list: [Any]
    if let array = root as? [Any] {
        list = array
    } else if let object = root as? [String: Any], let cases = object["cases"] as? [Any] {
        list = cases
    } else {
        throw NSError(domain: "fixtures", code: 1, userInfo: [NSLocalizedDescriptionKey: "unrecognised fixture layout"])
    }
    func snapshot(_ value: Any?) throws -> Snapshot {
        guard let value else { throw NSError(domain: "fixtures", code: 2, userInfo: [NSLocalizedDescriptionKey: "missing snapshot"]) }
        return try JSONDecoder().decode(Snapshot.self, from: JSONSerialization.data(withJSONObject: value))
    }
    return try list.enumerated().map { index, item in
        guard let fields = item as? [String: Any] else {
            throw NSError(domain: "fixtures", code: 3, userInfo: [NSLocalizedDescriptionKey: "case \(index) is not an object"])
        }
        let name = (fields["name"] as? String) ?? (fields["id"].map { "\($0)" }) ?? "#\(index)"
        return (
            name,
            try snapshot(fields["a"] ?? fields["left"]),
            try snapshot(fields["b"] ?? fields["right"]),
            try snapshot(fields["expected"] ?? fields["merged"] ?? fields["result"] ?? fields["output"])
        )
    }
}

let fixtureURL: URL = {
    if CommandLine.arguments.count > 1 { return URL(fileURLWithPath: CommandLine.arguments[1]) }
    // Run from the repo root (or from anywhere with the path given).
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("tests/fixtures/merge-cases.json")
}()

if FileManager.default.fileExists(atPath: fixtureURL.path) {
    section("fixtures \(fixtureURL.path)")
    do {
        let cases = try loadFixtureCases(fixtureURL)
        var mismatches = 0
        for fixture in cases {
            let merged = Snapshot.merge(fixture.a, fixture.b)
            let ok = canonical(merged) == canonical(fixture.expected)
            check(ok, "fixture \(fixture.name): Swift and TypeScript disagree\n swift=\(canonical(merged))\n ts   =\(canonical(fixture.expected))")
            if !ok { mismatches += 1 }
            check(canonical(Snapshot.merge(fixture.b, fixture.a)) == canonical(fixture.expected), "fixture \(fixture.name) reversed")
        }
        print("  \(cases.count) fixture cases, \(mismatches) mismatches")
        check(!cases.isEmpty, "fixture file has cases")
    } catch {
        check(false, "could not read fixtures: \(error)")
    }
} else {
    // The fixtures are the only check that Swift and the server merge alike: never skip them.
    check(false, "fixtures not found at \(fixtureURL.path) (run from the repo root or pass the path)")
}

print(failures == 0 ? "PASS: \(checks) checks" : "FAILED: \(failures) of \(checks) checks")
exit(failures == 0 ? 0 : 1)
