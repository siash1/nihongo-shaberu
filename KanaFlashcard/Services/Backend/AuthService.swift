import Foundation
import Observation

/// A sign-in, sign-up or account error, with text to show the learner.
enum AuthError: LocalizedError, Equatable {
    case userNotFound
    case invalidCredentials
    case rateLimited(retryAfterMs: Double?)
    case passwordTooShort(minimumLength: Int)
    case passwordTooLong(maximumLength: Int)
    case passwordHasSurroundingWhitespace
    case passwordTooCommon
    case usernameTaken
    case usernameTooShort
    case usernameTooLong(maximumLength: Int)
    case usernameHasSurroundingWhitespace
    case usernameHasInvalidCharacters
    /// Too many accounts were created recently (from this network, or in all).
    case tooManySignUps(retryAfterMs: Double?)
    /// The server could not be reached.
    case network
    /// An action that needs an account was tried while signed out.
    case notSignedIn
    /// The session ended (expired, signed out elsewhere, account deleted); the app is now signed out.
    case sessionExpired
    /// The server failed in an unexpected way.
    case server(String?)
    /// A user error code this version does not know.
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "There is no account with that username. Check the spelling, or create an account."
        case .invalidCredentials:
            return "That password is not right. Try again."
        case .rateLimited(let retryAfterMs):
            // Anyone who knows a username can use up its password attempts, so the wait may
            // come back; devices already signed in are not affected.
            let wait = Self.waitText(retryAfterMs).map { "Try again in \($0)." } ?? "Wait a moment, then try again."
            return "Too many attempts. \(wait) If this keeps happening, someone may be trying to guess the password. Devices already signed in keep syncing."
        case .tooManySignUps(let retryAfterMs):
            let wait = Self.waitText(retryAfterMs).map { "Try again in \($0)." } ?? "Try again later."
            return "Too many accounts were created recently. \(wait)"
        case .passwordTooShort(let minimumLength):
            return "Use a password of at least \(minimumLength) characters."
        case .passwordTooLong(let maximumLength):
            return "That password is too long. Use at most \(maximumLength) characters."
        case .passwordHasSurroundingWhitespace:
            return "Remove the spaces at the start or end of the password."
        case .passwordTooCommon:
            return "That password is too common and easy to guess. Choose a different one."
        case .usernameTaken:
            return "That username is taken. Try another one."
        case .usernameTooShort:
            return "Enter a username."
        case .usernameTooLong(let maximumLength):
            return "That username is too long. Use at most \(maximumLength) characters."
        case .usernameHasSurroundingWhitespace:
            return "Remove the spaces at the start or end of the username."
        case .usernameHasInvalidCharacters:
            return "That username has characters that are not allowed. Use letters, numbers and simple symbols."
        case .network:
            return "Can’t reach the server. Check your internet connection and try again."
        case .notSignedIn:
            return "Sign in first."
        case .sessionExpired:
            return "Your session has ended. Sign in again."
        case .server:
            return "Something went wrong on the server. Try again later."
        case .unknown:
            return "Something went wrong. Try again."
        }
    }

    /// "45 seconds", "3 minutes", or nil when the wait is unknown.
    private static func waitText(_ retryAfterMs: Double?) -> String? {
        guard let retryAfterMs, retryAfterMs > 0 else { return nil }
        let seconds = Int((retryAfterMs / 1000).rounded(.up))
        if seconds < 60 {
            return "\(seconds) \(seconds == 1 ? "second" : "seconds")"
        }
        let minutes = Int((Double(seconds) / 60).rounded(.up))
        return "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
    }

    init(userError: ConvexAPI.UserError) {
        func length(_ value: Double?, default fallback: Int) -> Int {
            value.flatMap { Int(exactly: $0) } ?? fallback
        }
        switch userError.error {
        case "USER_NOT_FOUND": self = .userNotFound
        case "INVALID_CREDENTIALS": self = .invalidCredentials
        case "RATE_LIMITED": self = .rateLimited(retryAfterMs: userError.retryAfterMs)
        case "PASSWORD_TOO_SHORT": self = .passwordTooShort(minimumLength: length(userError.minimumLength, default: 10))
        case "PASSWORD_TOO_LONG": self = .passwordTooLong(maximumLength: length(userError.maximumLength, default: 1000))
        case "PASSWORD_HAS_SURROUNDING_WHITESPACE": self = .passwordHasSurroundingWhitespace
        case "PASSWORD_TOO_COMMON": self = .passwordTooCommon
        case "USERNAME_TAKEN": self = .usernameTaken
        case "USERNAME_TOO_SHORT": self = .usernameTooShort
        case "USERNAME_TOO_LONG": self = .usernameTooLong(maximumLength: length(userError.maximumLength, default: 100))
        case "USERNAME_HAS_SURROUNDING_WHITESPACE": self = .usernameHasSurroundingWhitespace
        case "USERNAME_HAS_INVALID_CHARACTERS": self = .usernameHasInvalidCharacters
        default: self = .unknown(userError.error)
        }
    }

    /// Maps a client error. `unauthorized` here means the retry after a refresh failed too.
    init(_ error: Error) {
        if let authError = error as? AuthError {
            self = authError
            return
        }
        switch error as? ConvexClientError {
        case .network: self = .network
        case .unauthorized: self = .sessionExpired
        case .rateLimited(let retryAfterMs): self = .rateLimited(retryAfterMs: retryAfterMs)
        case .function(_, let message): self = .server(message)
        case .decoding: self = .server(nil)
        case nil: self = .unknown(error.localizedDescription)
        }
    }
}

/// The account on this device: sign up / in with username + password (Convex Auth), keeps the
/// session in the keychain and hands out fresh access tokens.
///
/// Refreshes are single-flight: the server revokes a session when a superseded refresh token is
/// presented after its successor was used, so two concurrent refreshes would sign the device out.
///
/// Every token is handed out for one account: a caller that started for one user never gets the
/// token of another account that signed in meanwhile (in another window), so it can never sync
/// to, or delete, the wrong account.
@Observable
final class AuthService {
    /// Why the last session ended.
    enum SessionEndReason: Equatable {
        /// The learner signed out (or signed in to another account).
        case signedOut
        /// The server ended it: signed out elsewhere, expired, or the account was deleted on
        /// another device. The learner did not ask for it, so the app says so.
        case expired
        /// The learner deleted the account on this device.
        case deleted
    }

    /// The signed-in username, nil when signed out. Right after sign-in it is the name as typed
    /// (surrounding whitespace removed); `users:me` then replaces it with the name as registered,
    /// since usernames match case-insensitively ("alice" signs in to "Alice").
    private(set) var username: String?

    var isSignedIn: Bool {
        session != nil
    }

    /// The signed-in user's id; changes when another account signs in.
    var userId: String? {
        session?.userId
    }

    /// Why the last session ended, until the next sign-in (nil after a launch).
    private(set) var sessionEndReason: SessionEndReason?
    /// The username of the session that ended last, to fill in the sign-in form.
    private(set) var lastUsername: String?
    /// False when the keychain refused the session: it then lasts only until the app quits,
    /// and the next launch starts signed out.
    private(set) var sessionIsPersisted = true

    /// Called right after a sign-in or sign-up completes (SyncService syncs).
    @ObservationIgnored var onSignedIn: (() -> Void)?
    /// Called after the session ends: sign out, account deleted, or the session expired.
    @ObservationIgnored var onSignedOut: (() -> Void)?

    private var session: StoredSession?
    @ObservationIgnored private let client: ConvexClient
    @ObservationIgnored private var refreshTask: Task<RefreshOutcome, Never>?
    /// When the current access token expires on this device's clock (from its lifetime, so a
    /// wrong device clock does not matter). Unknown after a relaunch: the `exp` claim is used then.
    @ObservationIgnored private var accessTokenExpiry: Date?

    /// Refresh when the access token has less than this left.
    private static let refreshMargin: TimeInterval = 120

    private enum RefreshOutcome {
        case rotated(accessToken: String)
        /// The session the refresh started for was replaced (another account signed in, or the
        /// same account signed in again) while it ran; the caller checks the current session.
        case sessionChanged
        case noSession
        case failed(AuthError)
    }

    init(client: ConvexClient = ConvexClient(deploymentURL: BackendConfig.deploymentURL)) {
        self.client = client
        if let stored = KeychainStore.loadSession() {
            session = stored
            username = stored.username
        }
    }

    // MARK: - Sign in / up / out

    func signIn(username: String, password: String) async throws {
        try await authenticate(ConvexAPI.signIn, username: username, password: password)
    }

    func signUp(username: String, password: String) async throws {
        try await authenticate(ConvexAPI.signUp, username: username, password: password)
    }

    /// Ends the session on the server (best effort) and forgets it here. Local progress stays.
    func signOut() async {
        guard let current = session else { return }
        _ = try? await client.mutation(
            ConvexAPI.signOut,
            args: ConvexAPI.RefreshTokenArgs(refreshToken: current.refreshToken),
            timeout: 10,
            as: ConvexNull.self
        )
        // Another account may have signed in (another window) while the request ran.
        guard session?.userId == current.userId else { return }
        endSession(reason: .signedOut)
    }

    /// Deletes the account `userId` (the signed-in one when nil) and its synced progress on the
    /// server, then signs out here. Local progress stays on this device. Throws
    /// `sessionExpired` when that account is no longer the one signed in.
    func deleteAccount(userId expectedUserId: String? = nil) async throws {
        guard let userId = expectedUserId ?? self.userId else { throw AuthError.notSignedIn }
        guard self.userId == userId else { throw AuthError.sessionExpired }
        do {
            let _: ConvexNull = try await authorized(for: userId) { token in
                try await self.client.mutation(ConvexAPI.deleteAccount, args: ConvexEmptyArgs(), accessToken: token)
            }
        } catch {
            throw AuthError(error)
        }
        if session?.userId == userId {
            endSession(reason: .deleted)
        }
    }

    // MARK: - Tokens

    /// An access token of the account `userId` (the signed-in one when nil), valid for at least
    /// two more minutes, refreshing it first when needed. Throws `sessionExpired` when that
    /// account is not (or no longer) signed in.
    func validAccessToken(for expectedUserId: String? = nil) async throws -> String {
        guard let current = session else { throw AuthError.notSignedIn }
        let expected = expectedUserId ?? current.userId
        guard current.userId == expected else { throw AuthError.sessionExpired }
        if let expiry = currentExpiry(of: current), expiry.timeIntervalSinceNow > Self.refreshMargin {
            return current.accessToken
        }
        switch await refresh() {
        case .rotated(let accessToken):
            guard session?.userId == expected else { throw AuthError.sessionExpired }
            return accessToken
        case .sessionChanged:
            if let latest = session, latest.userId == expected,
               let expiry = currentExpiry(of: latest), expiry.timeIntervalSinceNow > 5 {
                return latest.accessToken
            }
            throw AuthError.sessionExpired
        case .noSession:
            throw AuthError.sessionExpired
        case .failed(let error):
            // Offline: the old token still works if it has not expired yet.
            if let latest = session, latest.userId == expected,
               let expiry = currentExpiry(of: latest), expiry.timeIntervalSinceNow > 5 {
                return latest.accessToken
            }
            throw error
        }
    }

    /// Call after the server rejected an access token of `userId` (the signed-in account when
    /// nil): forces a refresh. Returns true when that account has a new token to retry with;
    /// false when its session is gone (then the app is signed out), another account signed in,
    /// or the refresh failed (still signed in).
    func handleUnauthorized(for expectedUserId: String? = nil) async -> Bool {
        guard let current = session else { return false }
        let expected = expectedUserId ?? current.userId
        guard current.userId == expected else { return false }
        switch await refresh() {
        case .rotated:
            return session?.userId == expected
        case .sessionChanged:
            return session?.userId == expected
        case .noSession, .failed:
            return false
        }
    }

    /// Runs `body` with a valid access token of `userId` (the signed-in account when nil); when
    /// the token is rejected, refreshes and runs it once more, for the same account only.
    func authorized<Value>(for expectedUserId: String? = nil, _ body: (String) async throws -> Value) async throws -> Value {
        guard let userId = expectedUserId ?? self.userId else { throw AuthError.notSignedIn }
        let token = try await validAccessToken(for: userId)
        do {
            return try await body(token)
        } catch ConvexClientError.unauthorized {
            guard self.userId == userId else { throw AuthError.sessionExpired }
            guard await handleUnauthorized(for: userId), let fresh = session, fresh.userId == userId else {
                throw self.userId == userId ? AuthError.network : AuthError.sessionExpired
            }
            return try await body(fresh.accessToken)
        }
    }

    // MARK: - Private

    private func authenticate(_ path: String, username rawUsername: String, password: String) async throws {
        let name = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AuthError.usernameTooShort }
        let result: ConvexAPI.SignInResult
        do {
            result = try await client.mutation(path, args: ConvexAPI.Credentials(username: name, password: password))
        } catch ConvexClientError.rateLimited(let retryAfterMs) where path == ConvexAPI.signUp {
            throw AuthError.tooManySignUps(retryAfterMs: retryAfterMs)
        } catch {
            throw AuthError(error)
        }
        if result.status == "complete", let tokens = result.tokens {
            if let previous = session, previous.userId != tokens.userId {
                endSession(reason: .signedOut)
            }
            store(StoredSession(username: name, tokens: tokens))
            sessionEndReason = nil
            onSignedIn?()
            Task { await self.loadRegisteredUsername() }
            return
        }
        if let userError = result.userError {
            throw AuthError(userError: userError)
        }
        throw AuthError.server(nil)
    }

    /// Shows the username as registered (best effort: on any failure the typed name stays).
    private func loadRegisteredUsername() async {
        guard let current = session else { return }
        let me = try? await client.query(
            ConvexAPI.me, args: ConvexEmptyArgs(), accessToken: current.accessToken, timeout: 10,
            as: ConvexAPI.Me?.self
        )
        // Signed out, or into another account, meanwhile: nothing to update.
        guard let registered = me?.username, var latest = session, latest.userId == current.userId,
              latest.username != registered
        else { return }
        latest.username = registered
        session = latest
        username = registered
        sessionIsPersisted = KeychainStore.saveSession(latest)
    }

    /// Joins the refresh in flight, or starts one.
    private func refresh() async -> RefreshOutcome {
        if let refreshTask {
            return await refreshTask.value
        }
        let task = Task { await self.performRefresh() }
        refreshTask = task
        return await task.value
    }

    private func performRefresh() async -> RefreshOutcome {
        defer { refreshTask = nil }
        guard let current = session else { return .noSession }
        let result: ConvexAPI.RefreshResult
        do {
            result = try await client.mutation(
                ConvexAPI.refreshSession,
                args: ConvexAPI.RefreshTokenArgs(refreshToken: current.refreshToken)
            )
        } catch {
            return .failed(AuthError(error))
        }
        // Signed out, or signed in again (maybe as another account), while the request ran: that
        // state wins, and its token is never handed out as the result of this refresh.
        guard let latest = session, latest.refreshToken == current.refreshToken else {
            return session == nil ? .noSession : .sessionChanged
        }
        if result.kind == "rotated", let tokens = result.tokens {
            store(StoredSession(username: latest.username, tokens: tokens))
            return .rotated(accessToken: tokens.accessToken)
        }
        endSession(reason: .expired)
        return .noSession
    }

    private func store(_ newSession: StoredSession) {
        let issuedAt = JWT.issuedAt(of: newSession.accessToken)
        if let issuedAt, let expiration = JWT.expiration(of: newSession.accessToken) {
            accessTokenExpiry = Date().addingTimeInterval(expiration.timeIntervalSince(issuedAt))
        } else {
            accessTokenExpiry = nil
        }
        session = newSession
        username = newSession.username
        sessionIsPersisted = KeychainStore.saveSession(newSession)
    }

    private func currentExpiry(of session: StoredSession) -> Date? {
        accessTokenExpiry ?? JWT.expiration(of: session.accessToken)
    }

    /// Forgets the session (keychain included) and tells SyncService.
    private func endSession(reason: SessionEndReason) {
        guard let ending = session else { return }
        session = nil
        lastUsername = ending.username
        username = nil
        accessTokenExpiry = nil
        sessionIsPersisted = true
        sessionEndReason = reason
        KeychainStore.deleteSession()
        onSignedOut?()
    }
}
