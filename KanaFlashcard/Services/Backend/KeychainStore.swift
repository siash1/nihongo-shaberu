import Foundation
import Security
import os

/// The signed-in session, as stored in the keychain.
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

/// One generic-password keychain item holding the session JSON. Device-only and not
/// synchronizable: every device signs in on its own and has its own session.
///
/// This is the data-protection keychain (the only one Mac Catalyst has). On the Mac it works only
/// when the app is signed with an App ID: the Catalyst build gets one from the Keychain Sharing
/// entitlement (`KanaFlashcard-Catalyst.entitlements`). Without it every call fails with
/// errSecMissingEntitlement (-34018) and the Mac is signed out at each launch; failures are
/// logged, and `AuthService.sessionIsPersisted` tells the learner.
enum KeychainStore {
    private static let logger = Logger(subsystem: "onearvo.jap.KanaFlashcard", category: "Keychain")

    static let service = "onearvo.jap.KanaFlashcard.session"
    private static let account = "session"
    /// Keychain items survive deleting the app but UserDefaults does not. This flag tells a
    /// session saved by this install from one left behind by an earlier install.
    private static let installMarkerKey = "keychainSessionSaved"

    static func loadSession() -> StoredSession? {
        guard UserDefaults.standard.bool(forKey: installMarkerKey) else {
            deleteSession()
            return nil
        }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            logger.error("Loading the session failed: OSStatus \(status, privacy: .public)")
            return nil
        }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    /// Returns false when the keychain refused the item; the session then lasts only until quit.
    @discardableResult
    static func saveSession(_ session: StoredSession) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        var status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = baseQuery
            item.merge(attributes) { _, new in new }
            status = SecItemAdd(item as CFDictionary, nil)
        }
        let saved = status == errSecSuccess
        if !saved {
            // -34018 (errSecMissingEntitlement): the build has no App ID (see above).
            logger.error("Saving the session failed: OSStatus \(status, privacy: .public)")
        }
        // A failed save leaves an older item holding a superseded refresh token, which would end
        // the session if used; the next launch deletes it instead (see loadSession).
        UserDefaults.standard.set(saved, forKey: installMarkerKey)
        return saved
    }

    static func deleteSession() {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Deleting the session failed: OSStatus \(status, privacy: .public)")
        }
        UserDefaults.standard.removeObject(forKey: installMarkerKey)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}
