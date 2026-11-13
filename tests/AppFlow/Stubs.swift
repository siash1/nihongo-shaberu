import Foundation

// Stand-ins for the two app files the command-line build of tests/AppFlow cannot use:
// - SpeechService needs AVAudioSession (iOS only); KanjiViewModel only calls speak/stopSpeaking.
// - KeychainStore uses the data-protection keychain, which needs an app's signing entitlements.
//   This one keeps the session in a JSON file per "device" (APPFLOW_DIR/<process name>.session.json),
//   so a device's session survives from one step (process) to the next, like the keychain does.
// StoredSession is copied unchanged from KanaFlashcard/Services/Backend/KeychainStore.swift.

final class SpeechService {
    func speak(_ text: String, language: String = "ja-JP") {}
    func stopSpeaking() {}
}

nonisolated struct StoredSession: Codable, Equatable, Sendable {
    var username: String
    var userId: String
    var accessToken: String
    var refreshToken: String
    /// ms since 1970.
    var refreshTokenExpiresAt: Double

    init(username: String, userId: String, accessToken: String, refreshToken: String, refreshTokenExpiresAt: Double) {
        self.username = username
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
    }

    init(username: String, tokens: ConvexAPI.Tokens) {
        self.init(
            username: username,
            userId: tokens.userId,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            refreshTokenExpiresAt: tokens.refreshTokenExpiresAt
        )
    }
}

enum KeychainStore {
    static var fileURL: URL {
        let directory = ProcessInfo.processInfo.environment["APPFLOW_DIR"] ?? NSTemporaryDirectory()
        return URL(fileURLWithPath: directory)
            .appendingPathComponent("\(ProcessInfo.processInfo.processName).session.json")
    }

    static func loadSession() -> StoredSession? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    @discardableResult
    static func saveSession(_ session: StoredSession) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        return (try? data.write(to: fileURL, options: .atomic)) != nil
    }

    static func deleteSession() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
