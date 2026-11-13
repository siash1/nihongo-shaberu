// End-to-end check of the app's Swift networking against a running Convex backend: signs up a
// random user, syncs snapshots from two "devices", reads the status, refreshes, signs out and
// deletes the account. Uses the app's own ConvexClient and ProgressSnapshot.
//
//   swiftc KanaFlashcard/Models/ProgressSnapshot.swift KanaFlashcard/Services/Backend/ConvexClient.swift \
//     tests/SyncCLI/main.swift -o /tmp/synccli
//   BASE_URL=http://127.0.0.1:3210 /tmp/synccli        (VERBOSE=1 prints client logs)
//
// Exit status 0 when every check passes.

import Foundation

let environment = ProcessInfo.processInfo.environment
let baseURL = URL(string: environment["BASE_URL"] ?? "http://127.0.0.1:3210")!
let verbose = environment["VERBOSE"] != nil
@Sendable func printClientLog(_ line: String) {
    print("    [client] \(line)")
}
let client = ConvexClient(deploymentURL: baseURL, log: verbose ? printClientLog : nil)

var failures = 0
var checks = 0

func check(_ condition: Bool, _ message: @autoclosure () -> String, line: UInt = #line) {
    checks += 1
    print(condition ? "  ok   \(message())" : "  FAIL \(message())  (line \(line))")
    if !condition { failures += 1 }
}

func info(_ message: String) {
    print("  info \(message)")
}

func step(_ name: String) {
    print("— \(name)")
}

let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}()

func canonical(_ snapshot: ProgressSnapshot) -> String {
    String(decoding: try! encoder.encode(snapshot), as: UTF8.self)
}

/// Runs a call and returns its outcome.
func result<T>(of call: () async throws -> T) async -> Result<T, Error> {
    do {
        return .success(try await call())
    } catch {
        return .failure(error)
    }
}

/// Runs a call and returns its error (nil when it succeeded).
func error<T>(of call: () async throws -> T) async -> Error? {
    do {
        _ = try await call()
        return nil
    } catch {
        return error
    }
}

func signUp(_ username: String, _ password: String) async throws -> ConvexAPI.SignInResult {
    try await client.mutation(ConvexAPI.signUp, args: ConvexAPI.Credentials(username: username, password: password))
}

func signIn(_ username: String, _ password: String) async throws -> ConvexAPI.SignInResult {
    try await client.mutation(ConvexAPI.signIn, args: ConvexAPI.Credentials(username: username, password: password))
}

func refresh(_ refreshToken: String) async throws -> ConvexAPI.RefreshResult {
    try await client.mutation(ConvexAPI.refreshSession, args: ConvexAPI.RefreshTokenArgs(refreshToken: refreshToken))
}

func me(_ token: String?) async throws -> ConvexAPI.Me? {
    try await client.query(ConvexAPI.me, args: ConvexEmptyArgs(), accessToken: token)
}

func status(_ token: String?) async throws -> ConvexAPI.StatusResult {
    try await client.query(ConvexAPI.status, args: ConvexEmptyArgs(), accessToken: token)
}

func sync(_ snapshot: ProgressSnapshot, _ token: String?) async throws -> ConvexAPI.SyncResult {
    try await client.mutation(ConvexAPI.sync, args: ConvexAPI.SyncArgs(snapshot: snapshot), accessToken: token)
}

func userErrorCode(_ result: ConvexAPI.SignInResult?) -> String? {
    result?.status == "error" ? result?.userError?.error : nil
}

func nowMs() -> Double {
    (Date().timeIntervalSince1970 * 1000).rounded(.down)
}

print("Backend: \(baseURL.absoluteString)")

// MARK: - JWT helper

step("JWT decoding (base64url without padding)")
do {
    func segment(_ json: String) -> String {
        Data(json.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    for payload in [#"{"exp":1800000000}"#, #"{"exp":1800000000,"a":1}"#, #"{"exp":1800000000,"ab":"?>"}"#] {
        let token = "\(segment(#"{"alg":"none"}"#)).\(segment(payload)).sig"
        check(JWT.expiration(of: token) == Date(timeIntervalSince1970: 1_800_000_000), "exp of \(payload)")
    }
    check(JWT.expiration(of: "not-a-jwt") == nil, "garbage token has no exp")
}

// MARK: - Sign up / sign in

let suffix = UUID().uuidString.prefix(8).lowercased()
let username = "cli_\(suffix)"
let password = "kana-\(UUID().uuidString)"
var deviceA: ConvexAPI.Tokens!
var deviceB: ConvexAPI.Tokens!

step("sign up \(username)")
do {
    let result = try await signUp(username, password)
    check(result.status == "complete" && result.tokens != nil, "sign up completes")
    guard let tokens = result.tokens else {
        print("Cannot continue without a session.")
        exit(1)
    }
    deviceA = tokens
    let expiry = JWT.expiration(of: tokens.accessToken)
    check(expiry.map { $0.timeIntervalSinceNow > 600 && $0.timeIntervalSinceNow < 7200 } ?? false,
          "access token exp claim about an hour ahead (\(String(describing: expiry)))")
    if let issued = JWT.issuedAt(of: tokens.accessToken), let expiry {
        info("access token lifetime \(Int(expiry.timeIntervalSince(issued))) s")
    }
    check(tokens.refreshTokenExpiresAt > nowMs(), "refreshTokenExpiresAt in the future")
} catch {
    check(false, "sign up threw \(error)")
    exit(1)
}

step("user errors")
check(userErrorCode(try? await signUp(username.uppercased(), password)) == "USERNAME_TAKEN", "same username in other case → USERNAME_TAKEN")
let short = try? await signUp("cli_short_\(suffix)", "short")
check(userErrorCode(short) == "PASSWORD_TOO_SHORT" && short?.userError?.minimumLength == 10, "short password → PASSWORD_TOO_SHORT(10)")
check(userErrorCode(try? await signUp(" cli_space_\(suffix)", password)) == "USERNAME_HAS_SURROUNDING_WHITESPACE",
      "leading space → USERNAME_HAS_SURROUNDING_WHITESPACE (the app trims before sending)")
check(userErrorCode(try? await signIn(username, password + "x")) == "INVALID_CREDENTIALS", "wrong password → INVALID_CREDENTIALS")
check(userErrorCode(try? await signIn("cli_nobody_\(suffix)", password)) == "USER_NOT_FOUND", "unknown user → USER_NOT_FOUND")

step("second device signs in")
do {
    let result = try await signIn(username.uppercased(), password)
    check(result.status == "complete", "sign in is case-insensitive")
    deviceB = result.tokens
    check(deviceB != nil && deviceB.userId == deviceA.userId && deviceB.refreshToken != deviceA.refreshToken,
          "same user, separate session")
} catch {
    check(false, "sign in threw \(error)")
    exit(1)
}

step("users:me")
let meA = try? await me(deviceA.accessToken)
check(meA?.username.lowercased() == username, "me with a token → \(String(describing: meA))")
let meNone = await result { try await me(nil) }
check((try? meNone.get()) == .some(nil), "me without a token → null")

// MARK: - Sync

step("progress sync")
let t1 = nowMs() - 60_000
let snapshotA = ProgressSnapshot(
    learned: [.init(kanji: "日", learnedAt: t1), .init(kanji: "月", learnedAt: t1 + 1), .init(kanji: "𠮷", learnedAt: t1 + 2)],
    scores: [.init(key: "1-kanji", percent: 80, recordedAt: t1)],
    words: [
        .init(key: "ねこ|N5", word: "ねこ", romaji: "neko", meaning: "cat", level: "N5", addedAt: t1, deletedAt: 0),
        .init(key: "いぬ|N5", word: "いぬ", romaji: "inu", meaning: "dog", level: "N5", addedAt: t1, deletedAt: t1 + 5),
        .init(key: "\u{304B}\u{3099}|N1", word: "\u{304B}\u{3099}", romaji: "ga", meaning: "moth", level: "N1", addedAt: t1, deletedAt: 0),
        .init(key: "𠮷野家|N2", word: "𠮷野家", romaji: "yoshinoya", meaning: "🍚", level: "N2", addedAt: t1, deletedAt: 0),
    ]
)

check(await error { try await status(nil) } as? ConvexClientError == .unauthorized, "status without a token → unauthorized")
check(await error { try await sync(snapshotA, nil) } as? ConvexClientError == .unauthorized, "sync without a token → unauthorized")
let forged = await error { try await sync(snapshotA, "eyJhbGciOiJub25lIn0.eyJleHAiOjk5OTk5OTk5OTl9.x") }
check(forged as? ConvexClientError == .unauthorized, "sync with a forged token → unauthorized (\(String(describing: forged)))")

var version: Double = 0
do {
    let initial = try await status(deviceA.accessToken)
    check(initial.version == 0, "status of a new user → version 0")

    let first = try await sync(snapshotA, deviceA.accessToken)
    check(canonical(first.snapshot) == canonical(snapshotA.normalized), "server returns the uploaded state (NFC, sorted)")
    check(first.version >= 1, "version bumped to \(first.version)")
    check(abs(first.serverTime - nowMs()) < 120_000, "serverTime is the server clock")
    version = first.version

    let again = try await sync(snapshotA, deviceA.accessToken)
    check(again.version == version && again.snapshot == first.snapshot, "same snapshot again → no new version")
    check(try await status(deviceA.accessToken).version == version, "status reports the version")

    let t2 = nowMs() - 30_000
    let snapshotB = ProgressSnapshot(
        learned: [.init(kanji: "火", learnedAt: t2)],
        scores: [.init(key: "1-kanji", percent: 90, recordedAt: t2)],
        words: [.init(key: "ねこ|N5", word: "ねこ", romaji: "neko", meaning: "cat", level: "N5", addedAt: t1, deletedAt: t2)]
    )
    let fromB = try await sync(snapshotB, deviceB.accessToken)
    let expected = ProgressSnapshot.merge(snapshotA, snapshotB)
    check(canonical(fromB.snapshot) == canonical(expected), "device B gets merge(A, B)")
    check(fromB.version > version, "B's changes bump the version")
    check(fromB.snapshot.liveWords.map(\.key).sorted() == ["が|N1", "𠮷野家|N2"], "B's delete of ねこ synced")

    let pulled = try await sync(.empty, deviceA.accessToken)
    check(canonical(pulled.snapshot) == canonical(expected) && pulled.version == fromB.version, "device A pulls the same state")
    version = pulled.version

    let future = try await sync(ProgressSnapshot(learned: [.init(kanji: "水", learnedAt: nowMs() + 86_400_000)]), deviceA.accessToken)
    let water = future.snapshot.learned.first { $0.kanji == "水" }
    check(water != nil && water!.learnedAt <= future.serverTime, "future timestamps are clamped to the server clock")

    let badPercent = await error {
        try await sync(ProgressSnapshot(scores: [.init(key: "1-kanji", percent: 101, recordedAt: t2)]), deviceA.accessToken)
    }
    check({ if case .function(code: "INVALID_INPUT", _)? = badPercent as? ConvexClientError { return true }; return false }(),
          "percent 101 → INVALID_INPUT (\(String(describing: badPercent)))")
    let badLevel = await error {
        try await sync(ProgressSnapshot(words: [.init(key: "x|N6", word: "x", romaji: "x", meaning: "x", level: "N6", addedAt: t2, deletedAt: 0)]),
                       deviceA.accessToken)
    }
    check({ if case .function(code: "INVALID_INPUT", _)? = badLevel as? ConvexClientError { return true }; return false }(),
          "level N6 → INVALID_INPUT")

    let reset = try await sync(ProgressSnapshot(kanjiResetAt: nowMs() - 1), deviceA.accessToken)
    check(reset.snapshot.learned.allSatisfy { $0.kanji == "水" } && reset.snapshot.scores.isEmpty,
          "a reset drops learned kanji and scores recorded before it")
    check(reset.snapshot.liveWords.count == 2, "a kanji reset leaves the word bank alone")
} catch {
    check(false, "sync flow threw \(error)")
}

// MARK: - Refresh, sign out

step("refresh")
do {
    let rotated = try await refresh(deviceA.refreshToken)
    check(rotated.kind == "rotated" && rotated.tokens != nil, "refresh rotates")
    if let tokens = rotated.tokens {
        check(tokens.refreshToken != deviceA.refreshToken, "new refresh token")
        let who = try await me(tokens.accessToken)
        check(who?.username.lowercased() == username, "new access token works")
        deviceA = tokens
    }

    // Reuse detection: presenting a superseded token after its successor was used ends the session.
    let b1 = deviceB.refreshToken
    let b2 = try await refresh(b1)
    if let b2Tokens = b2.tokens {
        let b3 = try await refresh(b2Tokens.refreshToken)   // successor used
        let replay = try await refresh(b1)
        check(replay.kind == "noSession", "replaying a superseded refresh token → noSession")
        if let b3Tokens = b3.tokens {
            let after = try await refresh(b3Tokens.refreshToken)
            check(after.kind == "noSession", "…and the whole session is revoked")
        }
    } else {
        check(false, "device B refresh did not rotate")
    }
    check(try await refresh("not-a-token").kind == "noSession", "unknown refresh token → noSession")
} catch {
    check(false, "refresh flow threw \(error)")
}

step("sign out")
do {
    let deviceC = try await signIn(username, password).tokens!
    let _: ConvexNull = try await client.mutation(ConvexAPI.signOut, args: ConvexAPI.RefreshTokenArgs(refreshToken: deviceC.refreshToken))
    check(try await refresh(deviceC.refreshToken).kind == "noSession", "after sign out the refresh token is dead")
    let afterSignOut = await result { try await me(deviceC.accessToken) }
    switch afterSignOut {
    case .success(let value):
        check(value == nil, "users:me after sign out → null")
    case .failure(let error):
        check(error as? ConvexClientError == .unauthorized, "users:me after sign out → unauthorized")
    }
    check(await error { try await status(deviceC.accessToken) } as? ConvexClientError == .unauthorized,
          "progress:status after sign out → unauthorized")
} catch {
    check(false, "sign out flow threw \(error)")
}

// MARK: - Delete account

step("delete account")
do {
    let _: ConvexNull = try await client.mutation(ConvexAPI.deleteAccount, args: ConvexEmptyArgs(), accessToken: deviceA.accessToken)
    check(true, "account:deleteAccount → null")
    check(userErrorCode(try? await signIn(username, password)) == "USER_NOT_FOUND", "sign in after delete → USER_NOT_FOUND")
    check(try await refresh(deviceA.refreshToken).kind == "noSession", "sessions revoked")
    check(await error { try await status(deviceA.accessToken) } as? ConvexClientError == .unauthorized,
          "old access token → unauthorized")
    let again = try await signUp(username, password)
    check(again.status == "complete", "the username is free again")
    if let tokens = again.tokens {
        check(try await status(tokens.accessToken).version == 0, "a new account with the same name starts empty")
        let _: ConvexNull = try await client.mutation(ConvexAPI.deleteAccount, args: ConvexEmptyArgs(), accessToken: tokens.accessToken)
    }
} catch {
    check(false, "delete flow threw \(error)")
}

print(failures == 0 ? "PASS: \(checks) checks" : "FAILED: \(failures) of \(checks) checks")
exit(failures == 0 ? 0 : 1)
