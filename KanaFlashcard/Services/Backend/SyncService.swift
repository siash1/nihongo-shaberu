import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// Keeps kanji progress and the word bank the same on every device signed in to the account.
///
/// A sync sends the whole local snapshot to `progress:sync`, which merges it into the server's
/// state and returns the result; that is merged with the local state as it is *after* the
/// request (edits made meanwhile are kept) and saved. Signed out, it makes no network calls.
///
/// **Which account the progress belongs to.** The device remembers the account it last synced
/// with (`linkedUserId`) and how far that sync went (a watermark). Progress made while the device
/// was not syncing (never signed in, or signed out since) is not compared with the account by
/// its timestamps when the device signs in again; it *joins* the account instead:
/// - New progress (learned kanji, scores, saved words) is added: it is stamped again just after
///   the account's state, so a reset or Clear All the account made meanwhile does not remove it.
/// - Resets, Clear All and deleted words made while not syncing stay on this device: they never
///   reach the account (the account's progress comes back here instead).
/// Signing in to a *different* account than the linked one does not sync at all until the
/// learner chooses (`needsAccountChoice`): add this device's progress to that account, or replace
/// it with the account's. Progress never moves between accounts by itself.
@Observable
final class SyncService {
    enum Status: Equatable {
        case idle
        case syncing
        case failed(String)
    }

    private(set) var status: Status = .idle
    /// The last successful sync on this device.
    private(set) var lastSyncedAt: Date?
    /// Bumped whenever a sync changed local data; views showing words reload on change.
    private(set) var revision = 0
    /// The account whose progress this device holds (the last one it synced with); nil when it
    /// never synced, or the learner chose to add it to the next account.
    private(set) var linkedUserId: String?

    /// Signed in to an account other than the one this device's progress came from: nothing
    /// syncs until the learner picks `addThisDeviceProgress()` or `useAccountProgress()`.
    var needsAccountChoice: Bool {
        guard let linkedUserId, let userId = auth.userId else { return false }
        return linkedUserId != userId
    }

    /// Signed in and syncing with that account: a reset or Clear All made now reaches every
    /// device signed in to it. Otherwise it stays on this device.
    var isSyncingWithAccount: Bool {
        auth.isSignedIn && !needsAccountChoice
    }

    /// Local edits not on the server yet, or a sync scheduled or running (read on demand, e.g.
    /// before signing out; not observed).
    var hasPendingChanges: Bool {
        isSyncingWithAccount && (hasUnsyncedChanges || debounceTask != nil || runTask != nil)
    }

    @ObservationIgnored private let auth: AuthService
    @ObservationIgnored private let kanji: KanjiViewModel
    @ObservationIgnored private let client: ConvexClient

    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var rerunRequested = false
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var isActive = false
    /// The server version seen in the last sync or status poll.
    @ObservationIgnored private var lastSeenVersion: Double?
    /// Local edits that have not reached the server yet (or a sync that failed).
    @ObservationIgnored private var hasUnsyncedChanges = false
    @ObservationIgnored private var changeObserver: NSObjectProtocol?
    /// The running sync was asked for by the learner (Sync Now): it shows "Syncing…" even after a
    /// failure. Automatic retries after a failure keep showing the failure instead, so the
    /// account icon does not flip back and forth while offline.
    @ObservationIgnored private var userRequested = false
    /// Failures in a row, for the back-off of automatic retries.
    @ObservationIgnored private var consecutiveFailures = 0
    /// No automatic retry before this (back-off after failures, or the server's rate limit).
    @ObservationIgnored private var retryNotBefore: Date?
    /// The server turned the snapshot away for its content (too large, invalid): sending it again
    /// would fail the same way, so automatic retries wait for a local edit or Sync Now.
    @ObservationIgnored private var blockedUntilLocalEdit = false
    /// Every entry of the local stores stamped at or before this was on the server after the last
    /// sync with `linkedUserId`; anything later was made since.
    @ObservationIgnored private var watermark: Double = 0
    /// Signed out since the last sync with `linkedUserId`: the next sign-in to it joins (above).
    @ObservationIgnored private var detached = false

    private static let debounceDelay: Duration = .seconds(2)
    private static let pollInterval: Duration = .seconds(30)
    private static let maxRetryDelay: TimeInterval = 15 * 60
    private static let lastSyncedKey = "lastSyncedAt"
    private static let linkedUserKey = "syncLinkedUserId"
    private static let watermarkKey = "syncWatermark"
    private static let detachedKey = "syncDetached"

    init(
        auth: AuthService,
        kanji: KanjiViewModel,
        client: ConvexClient = ConvexClient(deploymentURL: BackendConfig.deploymentURL)
    ) {
        self.auth = auth
        self.kanji = kanji
        self.client = client
        let defaults = UserDefaults.standard
        linkedUserId = defaults.string(forKey: Self.linkedUserKey)
        watermark = defaults.double(forKey: Self.watermarkKey)
        detached = defaults.bool(forKey: Self.detachedKey)
        if auth.isSignedIn, linkedUserId == auth.userId, let stored = defaults.object(forKey: Self.lastSyncedKey) as? Date {
            lastSyncedAt = stored
        }

        changeObserver = NotificationCenter.default.addObserver(
            forName: .progressDidChangeLocally, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.localProgressDidChange()
            }
        }
        auth.onSignedIn = { [weak self] in
            self?.signedIn()
        }
        auth.onSignedOut = { [weak self] in
            self?.signedOut()
        }
    }

    // MARK: - Triggers

    /// Syncs now. If a sync is running, it runs once more after it (so it includes the latest
    /// local state) and this returns when that one is done. `userInitiated` (Sync Now) shows
    /// "Syncing…" at once and retries even after a failure the server would repeat.
    func syncNow(userInitiated: Bool = false) async {
        guard isSyncingWithAccount else { return }
        if userInitiated {
            userRequested = true
            blockedUntilLocalEdit = false
            retryNotBefore = nil
            status = .syncing
        }
        debounceTask?.cancel()
        debounceTask = nil
        if let runTask {
            rerunRequested = true
            await runTask.value
            return
        }
        let task = Task { await self.runSyncs() }
        runTask = task
        await task.value
    }

    /// Syncs after a short pause, so a burst of edits makes one request.
    func scheduleSync() {
        guard isSyncingWithAccount else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: Self.debounceDelay)
            guard !Task.isCancelled, let self else { return }
            self.debounceTask = nil
            await self.syncNow()
        }
    }

    /// The app came to the foreground (or launched): sync, then check for changes from other
    /// devices every 30 seconds while it stays active.
    func sceneBecameActive() {
        guard !isActive else { return }
        isActive = true
        guard isSyncingWithAccount else { return }
        if !blockedUntilLocalEdit {
            Task { await syncNow() }
        }
        startPolling()
    }

    /// The app went to the background: stop polling and send any pending edits now.
    func sceneEnteredBackground() {
        isActive = false
        stopPolling()
        guard isSyncingWithAccount else { return }
        let hasPending = debounceTask != nil || (hasUnsyncedChanges && !blockedUntilLocalEdit)
        guard hasPending || runTask != nil else { return }
        debounceTask?.cancel()
        debounceTask = nil
        // Ask for time to finish the request after the app leaves the screen.
        let assertion = BackgroundAssertion(name: "Sync progress")
        Task {
            if hasPending {
                await syncNow()
            } else if let runTask {
                await runTask.value
            }
            assertion.end()
        }
    }

    // MARK: - Account choice

    /// The learner chose to add this device's progress to the signed-in account (as at a first
    /// sign-in: new progress is added, this device's resets and deletions are not).
    func addThisDeviceProgress() async {
        guard needsAccountChoice else { return }
        setLink(nil, watermark: 0, detached: false)
        hasUnsyncedChanges = true
        startPolling()
        await syncNow(userInitiated: true)
    }

    /// The learner chose to replace this device's progress with the signed-in account's.
    func useAccountProgress() async {
        guard needsAccountChoice, let userId = auth.userId, runTask == nil else { return }
        status = .syncing
        do {
            let token = try await auth.validAccessToken(for: userId)
            let sentAt = Date()
            let pulled: ConvexAPI.SyncResult = try await client.mutation(
                ConvexAPI.sync, args: ConvexAPI.SyncArgs(snapshot: .empty), accessToken: token
            )
            guard auth.userId == userId, needsAccountChoice else {
                status = .idle
                return
            }
            ProgressClock.recordServerTime(pulled.serverTime, sentAt: sentAt, receivedAt: Date())
            if LocalProgress.replace(with: pulled.snapshot) {
                kanji.reloadFromStore()
                revision += 1
            }
            // Everything here is now the account's, stamped no later than the server's clock.
            setLink(userId, watermark: pulled.serverTime, detached: false)
            synced(version: pulled.version)
            startPolling()
        } catch {
            fail(error, userId: userId)
        }
    }

    // MARK: - Auth events

    private func localProgressDidChange() {
        guard auth.isSignedIn else { return }
        hasUnsyncedChanges = true
        blockedUntilLocalEdit = false
        scheduleSync()
    }

    private func signedIn() {
        lastSeenVersion = nil
        lastSyncedAt = nil
        hasUnsyncedChanges = true
        resetFailures()
        status = .idle
        // Another account's progress: wait for the learner's choice (AccountView asks).
        guard !needsAccountChoice else { return }
        Task { await syncNow() }
        startPolling()
    }

    /// Stops all sync work. Local data stays on the device; edits made from now on are not the
    /// account's until the next sign-in joins them (see the type's documentation).
    private func signedOut() {
        debounceTask?.cancel()
        debounceTask = nil
        stopPolling()
        rerunRequested = false
        lastSeenVersion = nil
        hasUnsyncedChanges = false
        resetFailures()
        status = .idle
        lastSyncedAt = nil
        UserDefaults.standard.removeObject(forKey: Self.lastSyncedKey)
        if linkedUserId != nil {
            setLink(linkedUserId, watermark: watermark, detached: true)
        }
    }

    // MARK: - Sync

    private func runSyncs() async {
        repeat {
            rerunRequested = false
            await performSync(retryingUnauthorized: true)
        } while rerunRequested && isSyncingWithAccount
        userRequested = false
        runTask = nil
    }

    private func performSync(retryingUnauthorized: Bool) async {
        guard let userId = auth.userId, !needsAccountChoice else { return }
        if userRequested || !isFailed {
            status = .syncing
        }
        // Progress made while not syncing with this account joins it (see the type's documentation).
        let joining = linkedUserId == nil || detached
        let joinWatermark = linkedUserId == nil ? 0 : watermark

        do {
            let token = try await auth.validAccessToken(for: userId)
            if joining {
                // Learn the account's state (and the server clock) first: a sync of an empty
                // snapshot changes nothing on the server.
                let sentAt = Date()
                let pulled: ConvexAPI.SyncResult = try await client.mutation(
                    ConvexAPI.sync, args: ConvexAPI.SyncArgs(snapshot: .empty), accessToken: token
                )
                guard auth.userId == userId, !needsAccountChoice else {
                    status = .idle
                    return
                }
                ProgressClock.recordServerTime(pulled.serverTime, sentAt: sentAt, receivedAt: Date())
                if LocalProgress.rebase(onto: pulled.snapshot, watermark: joinWatermark, now: ProgressClock.now()) {
                    kanji.reloadFromStore()
                    revision += 1
                }
            }

            let stamp = ProgressClock.now()
            let sent = LocalProgress.snapshotForSync()
            hasUnsyncedChanges = false
            let sentAt = Date()
            let result: ConvexAPI.SyncResult = try await client.mutation(
                ConvexAPI.sync, args: ConvexAPI.SyncArgs(snapshot: sent), accessToken: token
            )
            // Signed out, or into another account, while the request ran: drop the result.
            guard auth.userId == userId else {
                status = .idle
                return
            }
            ProgressClock.recordServerTime(result.serverTime, sentAt: sentAt, receivedAt: Date())
            applyServerSnapshot(result.snapshot)
            setLink(userId, watermark: stamp, detached: false)
            synced(version: result.version)
        } catch ConvexClientError.unauthorized where retryingUnauthorized {
            if await auth.handleUnauthorized(for: userId), auth.userId == userId {
                await performSync(retryingUnauthorized: false)
            } else {
                // Still signed in: the forced refresh failed (offline, server error), not the session.
                fail(auth.userId == userId ? ConvexClientError.network : AuthError.sessionExpired, userId: userId)
            }
        } catch {
            fail(error, userId: userId)
        }
    }

    /// Merges the server's state into the local state as it is now (it may have changed while
    /// the request ran) and saves the result.
    private func applyServerSnapshot(_ server: ProgressSnapshot) {
        let outcome = LocalProgress.mergeServerSnapshot(server, now: ProgressClock.now())
        if outcome.localChanged {
            kanji.reloadFromStore()
            revision += 1
        }
        if outcome.serverIsBehind {
            // Local edits made during the request: send them too.
            hasUnsyncedChanges = true
            scheduleSync()
        }
    }

    private func synced(version: Double) {
        lastSeenVersion = version
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: Self.lastSyncedKey)
        resetFailures()
        status = .idle
    }

    private func setLink(_ userId: String?, watermark: Double, detached: Bool) {
        linkedUserId = userId
        self.watermark = watermark
        self.detached = detached
        let defaults = UserDefaults.standard
        if let userId {
            defaults.set(userId, forKey: Self.linkedUserKey)
        } else {
            defaults.removeObject(forKey: Self.linkedUserKey)
        }
        defaults.set(watermark, forKey: Self.watermarkKey)
        defaults.set(detached, forKey: Self.detachedKey)
    }

    private var isFailed: Bool {
        if case .failed = status { return true }
        return false
    }

    private func resetFailures() {
        consecutiveFailures = 0
        retryNotBefore = nil
        blockedUntilLocalEdit = false
    }

    /// Automatic retries may run now (not blocked, not backing off).
    private var mayRetryAutomatically: Bool {
        !blockedUntilLocalEdit && (retryNotBefore.map { Date() >= $0 } ?? true)
    }

    private func fail(_ error: Error, userId: String) {
        hasUnsyncedChanges = true
        // A sign-out during the request is not a failure to show.
        guard auth.isSignedIn, auth.userId == userId else {
            status = .idle
            return
        }
        switch error {
        case ConvexClientError.function(let code, _) where Self.isContentRejection(code):
            blockedUntilLocalEdit = true
        case ConvexClientError.decoding:
            blockedUntilLocalEdit = true
        case ConvexClientError.rateLimited(let retryAfterMs):
            retryNotBefore = Date().addingTimeInterval(max((retryAfterMs ?? 30_000) / 1000, 1))
        default:
            // Offline or a server error: back off 30 s, 1 min, 2 min … up to 15 min.
            consecutiveFailures += 1
            let delay = min(30 * pow(2, Double(consecutiveFailures - 1)), Self.maxRetryDelay)
            retryNotBefore = Date().addingTimeInterval(delay)
        }
        let message = Self.message(for: error)
        if status != .failed(message) {
            status = .failed(message)
        }
    }

    /// The server turned the snapshot itself away: sending it again would fail the same way.
    private static func isContentRejection(_ code: String?) -> Bool {
        code == "INVALID_INPUT" || code == "WORD_BANK_FULL" || code == "PROGRESS_TOO_LARGE"
    }

    private static func message(for error: Error) -> String {
        switch error {
        case ConvexClientError.network, AuthError.network:
            return "Can’t reach the server. Your progress will sync when you’re back online."
        case let authError as AuthError:
            return authError.errorDescription ?? "Sync failed. Try again later."
        case ConvexClientError.rateLimited:
            return "Syncing is paused for a moment. It will try again by itself."
        case ConvexClientError.function(let code, _):
            switch code {
            case "WORD_BANK_FULL":
                return "Your word bank is too big to sync. Remove some words from the Word Bank, then sync again."
            case "INVALID_INPUT", "PROGRESS_TOO_LARGE":
                return "Some progress on this device can’t be synced. If this keeps happening, update the app."
            default:
                return "Sync failed on the server. Try again later."
            }
        default:
            // Includes `unauthorized` while still signed in (a signed-out device shows nothing).
            return "Sync failed. Try again later."
        }
    }

    // MARK: - Polling

    private func startPolling() {
        guard pollTask == nil, isActive, isSyncingWithAccount else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pollInterval)
                guard !Task.isCancelled, let self else { return }
                await self.poll(retryingUnauthorized: true)
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Syncs when another device changed the server state, or when local edits are still unsent
    /// (after the back-off, and never while the server would turn the snapshot away again).
    private func poll(retryingUnauthorized: Bool) async {
        guard isActive, isSyncingWithAccount, runTask == nil, debounceTask == nil else { return }
        if hasUnsyncedChanges {
            if mayRetryAutomatically {
                await syncNow()
            }
            return
        }
        guard let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken(for: userId)
            let result: ConvexAPI.StatusResult = try await client.query(
                ConvexAPI.status, args: ConvexEmptyArgs(), accessToken: token
            )
            guard isActive, auth.userId == userId else { return }
            if result.version != lastSeenVersion, mayRetryAutomatically {
                await syncNow()
            }
        } catch ConvexClientError.unauthorized where retryingUnauthorized {
            if await auth.handleUnauthorized(for: userId) {
                await poll(retryingUnauthorized: false)
            }
        } catch {
            // Quiet: the next poll tries again, and a sync reports its own errors.
        }
    }
}

/// Extra time to finish work after the app moves to the background. (Without UIKit, as in the
/// `tests/AppFlow` command-line build, there is no background to ask for.)
private final class BackgroundAssertion {
    #if canImport(UIKit)
    private var identifier: UIBackgroundTaskIdentifier = .invalid

    init(name: String) {
        identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.end()
        }
    }

    func end() {
        guard identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
        identifier = .invalid
    }
    #else
    init(name: String) {}

    func end() {}
    #endif
}
