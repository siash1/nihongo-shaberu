// End-to-end flow of the app's real account and sync code against a running Convex backend:
// AuthService, SyncService, KanjiViewModel, KanjiProgressStore, WordStorageService, LocalProgress,
// ConvexClient and ProgressSnapshot, compiled from the app sources (only SpeechService and the
// keychain are stubbed, see Stubs.swift).
//
// Two "devices" are two copies of this executable, deviceA and deviceB: each has its own
// UserDefaults domain (named after the process) and its own session file, and each step is a new
// process, like a relaunch. `tests/AppFlow/run.sh` builds them and runs the steps in order:
//
//   BASE_URL=http://127.0.0.1:3210 tests/AppFlow/run.sh
//
// Exit status 0 when every check of the step passes.

import Foundation

let environment = ProcessInfo.processInfo.environment
let baseURL = URL(string: environment["BASE_URL"] ?? "http://127.0.0.1:3210")!
guard let username = environment["APPFLOW_USER"], let password = environment["APPFLOW_PASSWORD"] else {
    print("Set APPFLOW_USER and APPFLOW_PASSWORD (tests/AppFlow/run.sh does).")
    exit(2)
}
/// A second account, for switching accounts on one device.
let username2 = environment["APPFLOW_USER2"] ?? "\(username)_2"
let step = CommandLine.arguments.dropFirst().first ?? ""
let device = ProcessInfo.processInfo.processName
let defaultsDomain = Bundle.main.bundleIdentifier ?? device

var failures = 0
var checks = 0

func check(_ condition: Bool, _ message: @autoclosure () -> String, line: UInt = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("  FAIL (line \(line)): \(message())")
    }
}

func info(_ text: String) {
    print("  · \(text)")
}

/// Every request the client sends: function path, and whether it carried an access token.
nonisolated final class RequestLog: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [(path: String, authorized: Bool)] = []

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        guard let request = task.originalRequest, let body = request.httpBody,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let path = object["path"] as? String
        else { return }
        let authorized = request.value(forHTTPHeaderField: "Authorization") != nil
        lock.withLock { entries.append((path, authorized)) }
    }

    var all: [(path: String, authorized: Bool)] {
        lock.withLock { entries }
    }

    func count(of path: String) -> Int {
        all.filter { $0.path == path }.count
    }
}

let requests = RequestLog()
let urlSession = URLSession(configuration: .ephemeral, delegate: requests, delegateQueue: nil)
@Sendable nonisolated func printClientLog(_ message: String) {
    print("    client: \(message)")
}
let client = ConvexClient(
    deploymentURL: baseURL, session: urlSession, log: environment["VERBOSE"] != nil ? printClientLog : nil
)

func entry(_ character: String) -> KanjiEntry {
    KanjiData.allKanji.first { $0.character == character }!
}

let unit1 = KanjiData.units[0]

func waitUntil(seconds: Double, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(seconds)
    while !condition() {
        if Date() > deadline { return false }
        try? await Task.sleep(for: .milliseconds(50))
    }
    return true
}

func liveWords() -> Set<String> {
    Set(WordStorageService.loadAllWords().map(\.word))
}

/// A base64url JWT segment.
func segment(_ json: String) -> String {
    Data(json.utf8).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

// MARK: - Before the app starts

print("\(device) \(step)")

switch step {
case "a1", "b1":
    // A fresh install.
    UserDefaults.standard.removePersistentDomain(forName: defaultsDomain)
    KeychainStore.deleteSession()
case "a3":
    // An access token that looks valid for an hour but has a bad signature: the server answers
    // HTTP 401 InvalidAuthHeader, as for an expired token.
    if var stored = KeychainStore.loadSession() {
        let now = Int(Date().timeIntervalSince1970)
        let forged = "\(segment(#"{"alg":"ES256","typ":"JWT","kid":"forged"}"#)).\(segment(#"{"sub":"x","iat":\#(now),"exp":\#(now + 3600)}"#)).c2lnbmF0dXJl"
        stored.accessToken = forged
        KeychainStore.saveSession(stored)
    }
default:
    break
}

// MARK: - The app's objects, as KanaFlashcardApp creates them

let kanji = KanjiViewModel()
let auth = AuthService(client: client)
let sync = SyncService(auth: auth, kanji: kanji, client: client)

/// The server's state, without changing it (a sync of an empty snapshot changes nothing).
func serverState() async -> (snapshot: ProgressSnapshot, version: Double)? {
    do {
        let token = try await auth.validAccessToken()
        let result: ConvexAPI.SyncResult = try await client.mutation(
            ConvexAPI.sync, args: ConvexAPI.SyncArgs(snapshot: .empty), accessToken: token
        )
        return (result.snapshot, result.version)
    } catch {
        check(false, "reading the server state threw \(error)")
        return nil
    }
}

func expectAuthError(_ expected: AuthError, _ call: () async throws -> Void, line: UInt = #line) async {
    do {
        try await call()
        check(false, "expected \(expected), but it succeeded", line: line)
    } catch {
        check((error as? AuthError) == expected, "expected \(expected), got \(error)", line: line)
        if let text = (error as? AuthError)?.errorDescription { info("“\(text)”") }
    }
}

// MARK: - Steps

switch step {
case "a1":
    // Progress from before there was an account.
    kanji.markLearned(entry("日"))
    kanji.markLearned(entry("月"))
    kanji.recordScore(80, for: .kanji, in: unit1)
    WordStorageService.saveWords([
        WordCard(word: "ねこ", romaji: "neko", meaning: "cat"),
        WordCard(word: "いぬ", romaji: "inu", meaning: "dog"),
    ])

    await sync.syncNow()
    check(!auth.isSignedIn && sync.lastSyncedAt == nil && sync.status == .idle && requests.all.isEmpty,
          "signed out: no network at all (\(requests.all.map(\.path)))")

    do {
        // The app trims surrounding spaces before sending.
        try await auth.signUp(username: "  \(username) ", password: password)
    } catch {
        check(false, "sign up threw \(error)")
        exit(1)
    }
    check(auth.isSignedIn && auth.username == username, "signed up as \(String(describing: auth.username))")
    check(KeychainStore.loadSession() != nil, "session saved")
    await sync.syncNow() // joins the sync the sign-up started
    check(sync.status == .idle && sync.lastSyncedAt != nil, "first sync done: \(sync.status)")

    if case let (server, version)? = await serverState() {
        check(Set(server.learned.map(\.kanji)) == ["日", "月"], "earlier progress uploaded: \(server.learned)")
        check(server.bestScores == ["1-kanji": 80], "score uploaded: \(server.scores)")
        check(Set(server.liveWords.map(\.word)) == ["ねこ", "いぬ"], "word bank uploaded: \(server.words.map(\.key))")
        check(version >= 1, "version \(version)")
        check(LocalProgress.snapshot().normalized == server, "this device equals the server")
    }

case "b1":
    // Its own progress from before signing in.
    kanji.markLearned(entry("火"))
    WordStorageService.saveWords([WordCard(word: "やま", romaji: "yama", meaning: "mountain")])

    let suffix = UUID().uuidString.prefix(6).lowercased()
    await expectAuthError(.invalidCredentials) { try await auth.signIn(username: username, password: password + "x") }
    await expectAuthError(.userNotFound) { try await auth.signIn(username: "nobody_\(suffix)", password: password) }
    await expectAuthError(.passwordTooShort(minimumLength: 10)) { try await auth.signUp(username: "other_\(suffix)", password: "short") }
    await expectAuthError(.usernameTaken) { try await auth.signUp(username: username.uppercased(), password: password) }
    await expectAuthError(.usernameTooShort) { try await auth.signIn(username: "   ", password: password) }
    check(!auth.isSignedIn && KeychainStore.loadSession() == nil, "still signed out after the errors")

    do {
        // Usernames match case-insensitively.
        try await auth.signIn(username: username.lowercased(), password: password)
    } catch {
        check(false, "sign in threw \(error)")
        exit(1)
    }
    await sync.syncNow()
    check(await waitUntil(seconds: 5) { auth.username == username },
          "the account shows the name as registered (\(username)), not as typed: \(String(describing: auth.username))")
    check(KeychainStore.loadSession()?.username == username, "registered name saved with the session")
    check(sync.status == .idle && sync.lastSyncedAt != nil, "synced: \(sync.status)")
    check(kanji.learnedKanji == ["日", "月", "火"], "both devices' kanji: \(kanji.learnedKanji)")
    check(kanji.bestScore(for: .kanji, in: unit1) == 80, "score from device A")
    check(liveWords() == ["ねこ", "いぬ", "やま"], "both devices' words: \(liveWords())")
    check(sync.revision > 0, "revision bumped, so the word screens reload (\(sync.revision))")
    if case let (server, _)? = await serverState() {
        check(Set(server.learned.map(\.kanji)) == ["日", "月", "火"], "server has both devices' kanji")
        check(Set(server.liveWords.map(\.word)) == ["ねこ", "いぬ", "やま"], "server has both devices' words")
    }

case "a2":
    check(auth.isSignedIn && auth.username == username, "session restored at launch")
    sync.sceneBecameActive()
    await sync.syncNow()
    check(kanji.learnedKanji == ["日", "月", "火"], "device B's kanji arrived: \(kanji.learnedKanji)")
    check(liveWords() == ["ねこ", "いぬ", "やま"], "device B's word arrived: \(liveWords())")
    let before = sync.lastSyncedAt ?? .distantPast
    let syncsBefore = requests.count(of: ConvexAPI.sync)

    // Edits sync by themselves, after the debounce.
    if let dog = WordStorageService.loadAllWords().first(where: { $0.word == "いぬ" }) {
        WordStorageService.deleteWord(dog)
    }
    kanji.resetProgress()
    kanji.markLearned(entry("水"))
    let started = Date()
    check(await waitUntil(seconds: 10) { (sync.lastSyncedAt ?? .distantPast) > before && sync.status == .idle },
          "edits synced without a Sync Now: \(sync.status)")
    info(String(format: "debounced sync finished after %.1f s", Date().timeIntervalSince(started)))
    check(requests.count(of: ConvexAPI.sync) - syncsBefore == 1, "one sync for the burst of three edits: \(requests.all.map(\.path))")
    if case let (server, _)? = await serverState() {
        check(server.learned.map(\.kanji) == ["水"], "reset reached the server, the kanji learned after it stays: \(server.learned)")
        check(server.scores.isEmpty, "reset cleared the scores: \(server.scores)")
        check(Set(server.liveWords.map(\.word)) == ["ねこ", "やま"], "delete reached the server: \(server.liveWords.map(\.word))")
        check(server.words.contains { $0.word == "いぬ" && $0.deletedAt > 0 }, "deleted word kept as a tombstone")
    }
    sync.sceneEnteredBackground()

case "a3":
    let forged = KeychainStore.loadSession()?.accessToken ?? ""
    let refreshBefore = KeychainStore.loadSession()?.refreshToken
    check(forged.contains("."), "forged token in place")
    await sync.syncNow()
    check(sync.status == .idle && sync.lastSyncedAt != nil, "sync recovers from a rejected token: \(sync.status)")
    check(requests.all.map(\.path) == [ConvexAPI.sync, ConvexAPI.refreshSession, ConvexAPI.sync],
          "rejected → refresh → retry: \(requests.all.map(\.path))")
    let saved = KeychainStore.loadSession()
    check(saved?.accessToken != forged && saved?.refreshToken != refreshBefore, "rotated tokens saved")
    check(requests.all.filter { $0.path == ConvexAPI.refreshSession }.allSatisfy { !$0.authorized },
          "refresh never sends the (rejected) access token")

    // Two refreshes at once share one request.
    let refreshesBefore = requests.count(of: ConvexAPI.refreshSession)
    async let first = auth.handleUnauthorized()
    async let second = auth.handleUnauthorized()
    let both = await [first, second]
    check(both == [true, true], "both callers get a new token: \(both)")
    check(requests.count(of: ConvexAPI.refreshSession) - refreshesBefore == 1,
          "one refresh request for two callers: \(requests.count(of: ConvexAPI.refreshSession) - refreshesBefore)")
    await sync.syncNow()
    check(sync.status == .idle && auth.isSignedIn, "session still good after the refreshes: \(sync.status)")

case "apoll":
    // Stays active while device B learns 木; the 30-second status poll must bring it here.
    sync.sceneBecameActive()
    await sync.syncNow()
    let revision = sync.revision
    let started = Date()
    check(await waitUntil(seconds: 50) { kanji.learnedKanji.contains("木") },
          "a change made on another device arrives through the status poll: \(kanji.learnedKanji)")
    info(String(format: "arrived after %.1f s", Date().timeIntervalSince(started)))
    check(sync.revision > revision, "revision bumped")
    check(requests.count(of: ConvexAPI.status) >= 1, "polled progress:status")
    sync.sceneEnteredBackground()

case "b2":
    sync.sceneBecameActive()
    await sync.syncNow()
    check(kanji.learnedKanji == ["水"], "device A's reset arrived: \(kanji.learnedKanji)")
    check(kanji.bestScore(for: .kanji, in: unit1) == nil, "scores reset")
    check(liveWords() == ["ねこ", "やま"], "device A's delete arrived: \(liveWords())")

    let before = sync.lastSyncedAt ?? .distantPast
    kanji.markLearned(entry("木"))
    check(await waitUntil(seconds: 10) { (sync.lastSyncedAt ?? .distantPast) > before && sync.status == .idle },
          "learned 木 synced")

    let refreshToken = KeychainStore.loadSession()?.refreshToken ?? ""
    await auth.signOut()
    check(!auth.isSignedIn && auth.username == nil && KeychainStore.loadSession() == nil, "signed out, session forgotten")
    check(sync.status == .idle && sync.lastSyncedAt == nil, "sync state cleared")
    check(kanji.learnedKanji == ["水", "木"] && liveWords() == ["ねこ", "やま"], "progress stays on the device")
    check(requests.all.filter { $0.path == ConvexAPI.signOut }.map(\.authorized) == [false], "sign-out sent once, without the access token")
    let refreshed: ConvexAPI.RefreshResult? = try? await client.mutation(
        ConvexAPI.refreshSession, args: ConvexAPI.RefreshTokenArgs(refreshToken: refreshToken)
    )
    check(refreshed?.kind == "noSession", "the server ended the session: \(String(describing: refreshed?.kind))")
    let count = requests.all.count
    await sync.syncNow()
    sync.scheduleSync()
    try? await Task.sleep(for: .seconds(2.5))
    check(requests.all.count == count, "no network after signing out")

case "b3":
    check(!auth.isSignedIn, "still signed out after a relaunch")
    // A reset made while signed out stays on this device: it must not wipe the account.
    kanji.resetProgress()
    check(kanji.learnedKanji.isEmpty && requests.all.isEmpty, "reset here, no network while signed out")
    do {
        try await auth.signIn(username: username, password: password)
    } catch {
        check(false, "sign in threw \(error)")
        exit(1)
    }
    await sync.syncNow()
    check(sync.status == .idle && kanji.learnedKanji == ["水", "木"],
          "signed in again: the account's kanji come back, the signed-out reset stayed here: \(sync.status) \(kanji.learnedKanji)")
    if case let (server, _)? = await serverState() {
        check(server.learned.map(\.kanji).sorted() == ["木", "水"], "the account kept its kanji: \(server.learned)")
    }

case "a4":
    sync.sceneBecameActive()
    await sync.syncNow()
    do {
        try await auth.deleteAccount()
    } catch {
        check(false, "delete threw \(error)")
    }
    check(!auth.isSignedIn && KeychainStore.loadSession() == nil, "signed out after deleting the account")
    check(auth.sessionEndReason == .deleted, "ended as deleted")
    check(sync.status == .idle && sync.lastSyncedAt == nil, "sync state cleared")
    check(kanji.learnedKanji == ["水", "木"] && liveWords() == ["ねこ", "やま"], "local progress stays on the device")
    await expectAuthError(.userNotFound) { try await auth.signIn(username: username, password: password) }

case "b4":
    // Device B still holds an unexpired access token of a session the deletion revoked.
    check(auth.isSignedIn, "device B still thinks it is signed in")
    await sync.syncNow()
    check(!auth.isSignedIn && KeychainStore.loadSession() == nil, "the ended session signs the device out")
    check(sync.status == .idle, "no error shown in the sync status for an ended session: \(sync.status)")
    check(auth.sessionEndReason == .expired && auth.lastUsername == username, "the account sheet can say the session ended")
    check(requests.all.map(\.path) == [ConvexAPI.sync, ConvexAPI.refreshSession], "sync → UNAUTHENTICATED → refresh → noSession: \(requests.all.map(\.path))")
    check(kanji.learnedKanji == ["水", "木"] && liveWords() == ["ねこ", "やま"], "local progress stays on the device")

case "b5":
    // Signed out (its session ended in b4). Progress made now is this device's own.
    check(!auth.isSignedIn && sync.linkedUserId != nil, "signed out, still linked to the deleted account")
    kanji.markLearned(entry("土"))
    WordStorageService.saveWords([WordCard(word: "うみ", romaji: "umi", meaning: "sea")])
    check(requests.all.isEmpty, "no network while signed out")

case "a5":
    // Device A still holds the deleted account's progress. Another account signs up here.
    check(!auth.isSignedIn && kanji.learnedKanji == ["水", "木"], "signed out with the old account's progress")
    do {
        try await auth.signUp(username: username2, password: password)
    } catch {
        check(false, "sign up threw \(error)")
        exit(1)
    }
    check(sync.needsAccountChoice, "another account's progress: sync waits for the learner's choice")
    await sync.syncNow()
    sync.scheduleSync()
    try? await Task.sleep(for: .seconds(2.5))
    check(requests.count(of: ConvexAPI.sync) == 0, "nothing synced before the choice: \(requests.all.map(\.path))")

    await sync.useAccountProgress()
    check(!sync.needsAccountChoice && sync.linkedUserId == auth.userId && sync.status == .idle, "linked to the new account: \(sync.status)")
    check(kanji.learnedKanji.isEmpty && liveWords().isEmpty, "this device now shows the new (empty) account: \(kanji.learnedKanji) \(liveWords())")

    // The new account resets and clears, then learns and saves.
    kanji.resetProgress()
    kanji.markLearned(entry("金"))
    WordStorageService.clearAllWords()
    WordStorageService.saveWords([WordCard(word: "そら", romaji: "sora", meaning: "sky")])
    await sync.syncNow()
    if case let (server, _)? = await serverState() {
        check(server.learned.map(\.kanji) == ["金"] && server.kanjiResetAt > 0 && server.wordsClearedAt > 0,
              "the account's reset and clear are on the server: \(server.learned)")
        check(server.liveWords.map(\.word) == ["そら"], "word saved: \(server.liveWords.map(\.word))")
    }
    await auth.signOut()

case "b6":
    // Device B (its own progress made while signed out, much older than the account's reset)
    // clears its words while signed out, saves one, and signs in to the second account.
    WordStorageService.clearAllWords()
    WordStorageService.saveWords([WordCard(word: "やま", romaji: "yama", meaning: "mountain")])
    do {
        try await auth.signIn(username: username2, password: password)
    } catch {
        check(false, "sign in threw \(error)")
        exit(1)
    }
    check(sync.needsAccountChoice, "another account's progress: waits for the choice")
    guard case let (before, _)? = await serverState() else { exit(1) }
    check(requests.count(of: ConvexAPI.sync) == 1, "only the test's own read so far: \(requests.all.map(\.path))")

    await sync.addThisDeviceProgress()
    check(sync.status == .idle && !sync.needsAccountChoice && sync.linkedUserId == auth.userId, "added: \(sync.status)")
    if case let (server, _)? = await serverState() {
        check(Set(server.learned.map(\.kanji)) == ["金", "水", "木", "土"],
              "this device's kanji were added, though older than the account's reset: \(server.learned)")
        check(server.kanjiResetAt == before.kanjiResetAt && server.wordsClearedAt == before.wordsClearedAt,
              "this device's signed-out Clear All did not reach the account")
        check(Set(server.liveWords.map(\.word)) == ["そら", "やま"], "the account's word survives this device's clear: \(server.liveWords.map(\.word))")
        check(LocalProgress.snapshot().normalized == server, "this device equals the server")
    }
    do {
        try await auth.deleteAccount()
    } catch {
        check(false, "delete threw \(error)")
    }
    check(!auth.isSignedIn && auth.sessionEndReason == .deleted, "second account deleted")

default:
    print("Unknown step \(step)")
    exit(2)
}

print(failures == 0 ? "  PASS: \(checks) checks" : "  FAILED: \(failures) of \(checks) checks")
exit(failures == 0 ? 0 : 1)
