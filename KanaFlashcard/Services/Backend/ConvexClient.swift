import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Foundation-only (with ProgressSnapshot.swift), so `tests/SyncCLI` can compile it with `swiftc`.

/// Why a Convex call failed.
nonisolated enum ConvexClientError: Error, Equatable, Sendable {
    /// No response, or a transport failure (any non-2xx status other than 401/403/560, e.g. the
    /// 400 `BadJsonBody` the server sends for a body that is not JSON).
    case network
    /// The access token was rejected before the function ran (HTTP 401
    /// `{"code":"InvalidAuthHeader",…}`: expired, malformed or badly signed), or the function threw
    /// `ConvexError({ code: "UNAUTHENTICATED" })` (the session behind a still-valid token was
    /// signed out, superseded or deleted).
    case unauthorized
    /// The function threw. `code` is `errorData.code` of a `ConvexError`, nil for other errors
    /// (whose message production deployments redact to "Server Error").
    case function(code: String?, message: String)
    /// The function threw `ConvexError({ code: "RATE_LIMITED", retryAfterMs })`: too many
    /// calls (sign-ups from one network, or syncs of one account). Try again after the delay.
    case rateLimited(retryAfterMs: Double?)
    /// The response was not the expected shape.
    case decoding
}

/// A client for the Convex public HTTP API (`POST /api/query`, `/api/mutation`), mirroring
/// `convex/browser/http_client.ts`. Observed wire behaviour (convex 1.50, see `tests/e2e.test.mjs`):
/// - success: HTTP 200 `{"status":"success","value":…}`; every number is a float (`3.0`) and
///   there may be no `logLines`.
/// - function error: `{"status":"error","errorMessage":…,"errorData":…?}` with HTTP 200 on the
///   local backend and 560 on others; both are read the same way, by the body's `status`.
///   `errorData` (only for a `ConvexError`) is `{code, message}`; `errorMessage` holds a request id
///   and stack, so it is never shown to the learner.
/// - rejected token: HTTP 401 `{"code":"InvalidAuthHeader","message":…}`, no `status` key.
nonisolated final class ConvexClient: Sendable {
    let deploymentURL: URL
    private let session: URLSession
    private let log: (@Sendable (String) -> Void)?

    /// - Parameter log: receives details of failures (status, body) for debugging; nil = silent.
    init(deploymentURL: URL, session: URLSession = .shared, log: (@Sendable (String) -> Void)? = nil) {
        self.deploymentURL = deploymentURL
        self.session = session
        self.log = log
    }

    func query<Args: Encodable & Sendable, Value: Decodable & Sendable>(
        _ path: String,
        args: Args,
        accessToken: String? = nil,
        timeout: TimeInterval = 30,
        as type: Value.Type = Value.self
    ) async throws -> Value {
        try await call("query", path: path, args: args, accessToken: accessToken, timeout: timeout)
    }

    func mutation<Args: Encodable & Sendable, Value: Decodable & Sendable>(
        _ path: String,
        args: Args,
        accessToken: String? = nil,
        timeout: TimeInterval = 30,
        as type: Value.Type = Value.self
    ) async throws -> Value {
        try await call("mutation", path: path, args: args, accessToken: accessToken, timeout: timeout)
    }

    // MARK: - Request

    private struct RequestBody<Args: Encodable>: Encodable {
        let path: String
        let args: Args
        let format = "json"
    }

    private struct ResponseHead: Decodable {
        let status: String
        let errorMessage: String?
        let errorData: ErrorData?
    }

    /// `errorData` is whatever the function passed to `ConvexError`; only an object's `code`,
    /// `message` and `retryAfterMs` are read.
    private struct ErrorData: Decodable {
        let code: String?
        let message: String?
        let retryAfterMs: Double?

        private enum CodingKeys: String, CodingKey { case code, message, retryAfterMs }

        init(from decoder: Decoder) throws {
            let container = try? decoder.container(keyedBy: CodingKeys.self)
            code = try? container?.decodeIfPresent(String.self, forKey: .code)
            message = try? container?.decodeIfPresent(String.self, forKey: .message)
            retryAfterMs = try? container?.decodeIfPresent(Double.self, forKey: .retryAfterMs)
        }
    }

    private struct Success<Value: Decodable>: Decodable {
        let value: Value

        private enum CodingKeys: String, CodingKey { case value }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if container.contains(.value) {
                value = try container.decode(Value.self, forKey: .value)
            } else {
                // A function returning `undefined`/`null`: decode the value from JSON null.
                value = try JSONDecoder().decode(Value.self, from: Data("null".utf8))
            }
        }
    }

    /// `@concurrent`: the JSON coding of a large snapshot and the network wait run off the
    /// caller's actor (with approachable concurrency a plain nonisolated async function would
    /// run on the main actor of its caller).
    @concurrent
    private func call<Args: Encodable & Sendable, Value: Decodable & Sendable>(
        _ kind: String,
        path: String,
        args: Args,
        accessToken: String?,
        timeout: TimeInterval
    ) async throws -> Value {
        var request = URLRequest(url: deploymentURL.appendingPathComponent("api").appendingPathComponent(kind))
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            request.httpBody = try JSONEncoder().encode(RequestBody(path: path, args: args))
        } catch {
            log?("\(path): could not encode args: \(error)")
            throw ConvexClientError.decoding
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            log?("\(path): \(error.localizedDescription)")
            throw ConvexClientError.network
        }
        guard let http = response as? HTTPURLResponse else { throw ConvexClientError.network }

        switch http.statusCode {
        case 200..<300, 560:
            break
        case 401, 403:
            log?("\(path): HTTP \(http.statusCode) \(String(decoding: data.prefix(500), as: UTF8.self))")
            throw ConvexClientError.unauthorized
        default:
            log?("\(path): HTTP \(http.statusCode) \(String(decoding: data.prefix(500), as: UTF8.self))")
            throw ConvexClientError.network
        }

        let decoder = JSONDecoder()
        let head: ResponseHead
        do {
            head = try decoder.decode(ResponseHead.self, from: data)
        } catch {
            log?("\(path): unreadable response \(String(decoding: data.prefix(500), as: UTF8.self))")
            throw ConvexClientError.decoding
        }

        switch head.status {
        case "success":
            do {
                return try decoder.decode(Success<Value>.self, from: data).value
            } catch {
                log?("\(path): could not decode \(Value.self): \(error)")
                throw ConvexClientError.decoding
            }
        case "error":
            let code = head.errorData?.code
            if code == "UNAUTHENTICATED" {
                throw ConvexClientError.unauthorized
            }
            if code == "RATE_LIMITED" {
                log?("\(path): rate limited, retry after \(head.errorData?.retryAfterMs ?? 0) ms")
                throw ConvexClientError.rateLimited(retryAfterMs: head.errorData?.retryAfterMs)
            }
            let message = head.errorData?.message ?? head.errorMessage ?? "Server Error"
            log?("\(path): function error \(code ?? "-"): \(message)")
            throw ConvexClientError.function(code: code, message: message)
        default:
            log?("\(path): unknown status \(head.status)")
            throw ConvexClientError.decoding
        }
    }
}

/// A function result or argument that is `null`.
nonisolated struct ConvexNull: Codable, Equatable, Sendable {
    init() {}

    init(from decoder: Decoder) throws {}

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

/// `{}`, the arguments of a function that takes none.
nonisolated struct ConvexEmptyArgs: Encodable, Sendable {}

// MARK: - The app's functions

/// Paths and wire types of the Convex functions the app calls (see `convex/`).
nonisolated enum ConvexAPI {
    static let signUp = "auth:signUpWithUsernamePassword"
    static let signIn = "auth:signInWithUsernamePassword"
    static let refreshSession = "auth:refreshSession"
    static let signOut = "auth:signOut"
    static let me = "users:me"
    static let sync = "progress:sync"
    static let status = "progress:status"
    static let deleteAccount = "account:deleteAccount"

    struct Credentials: Encodable, Sendable {
        let username: String
        let password: String
    }

    struct RefreshTokenArgs: Encodable, Sendable {
        let refreshToken: String
    }

    /// A minted session. `refreshTokenExpiresAt` is ms since 1970; the access token's expiry is
    /// its JWT `exp` claim.
    struct Tokens: Codable, Equatable, Sendable {
        let accessToken: String
        let refreshToken: String
        let refreshTokenExpiresAt: Double
        let userId: String
    }

    /// `{error: CODE, …}` of a failed sign-in or sign-up.
    struct UserError: Decodable, Equatable, Sendable {
        let error: String
        let retryAfterMs: Double?
        let minimumLength: Double?
        let maximumLength: Double?
    }

    /// `{status: "complete", tokens}` or `{status: "error", userError}`.
    struct SignInResult: Decodable, Sendable {
        let status: String
        let tokens: Tokens?
        let userError: UserError?
    }

    /// `{kind: "rotated", tokens}` or `{kind: "noSession"}`.
    struct RefreshResult: Decodable, Sendable {
        let kind: String
        let tokens: Tokens?
    }

    struct Me: Decodable, Equatable, Sendable {
        let username: String
    }

    struct SyncArgs: Encodable, Sendable {
        let snapshot: ProgressSnapshot
    }

    struct SyncResult: Decodable, Sendable {
        let snapshot: ProgressSnapshot
        let version: Double
        let serverTime: Double
    }

    struct StatusResult: Decodable, Sendable {
        let version: Double
    }
}

// MARK: - JWT

/// Reads claims of a JWT without verifying it (the server verifies; the client only needs `exp`).
nonisolated enum JWT {
    /// The `exp` claim (seconds since 1970) as a date, nil when the token is unreadable.
    static func expiration(of token: String) -> Date? {
        numericClaim("exp", of: token).map { Date(timeIntervalSince1970: $0) }
    }

    /// The `iat` claim as a date.
    static func issuedAt(of token: String) -> Date? {
        numericClaim("iat", of: token).map { Date(timeIntervalSince1970: $0) }
    }

    static func numericClaim(_ name: String, of token: String) -> Double? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let payload = base64URLDecode(String(parts[1])),
              let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
              let number = object[name] as? NSNumber
        else { return nil }
        return number.doubleValue
    }

    /// base64url (RFC 4648 §5) without padding → bytes.
    static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder == 1 { return nil }
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
