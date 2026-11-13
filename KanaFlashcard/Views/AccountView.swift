import SwiftUI

/// Account sheet. Signed out: sign in or create an account (username and password) so kanji progress
/// and the word bank are the same on iPhone, iPad and Mac. Signed in: the sync status, Sync Now,
/// Sign Out and Delete Account; when the device's progress came from another account, the choice of
/// what to do with it first. Presented by `AccountButton` with the presenting tab's theme.
struct AccountView: View {
    @Environment(AuthService.self) private var auth
    @Environment(SyncService.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast

    private enum Mode {
        case signIn, createAccount
    }

    private enum Field: Hashable {
        case username, password
    }

    @State private var mode: Mode = .signIn
    @State private var username = ""
    @State private var password = ""
    /// A sign-in, sign-up, sign-out or deletion is running: inputs are disabled meanwhile.
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    /// The account the Delete alert is about, captured when it opens: if another account signs in
    /// (in another window) before the learner confirms, that one is never deleted.
    @State private var deletionUserId: String?
    /// A deletion request is running (its session may turn out to have ended).
    @State private var isDeleting = false
    @State private var isSigningOut = false
    /// Some progress could not be synced before signing out: ask first.
    @State private var showingSignOutWarning = false
    /// Signed in to another account than the one this device's progress came from.
    @State private var showingAccountChoice = false
    /// Bumped by a successful sign-in or new account, so the success haptic lands with the switch.
    @State private var signInCount = 0
    /// Bumped by a failed request, so the error haptic lands with the error banner.
    @State private var failureCount = 0
    @FocusState private var focusedField: Field?

    private static let minimumPasswordLength = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.cards) {
                    if auth.isSignedIn {
                        signedInContent
                            .transition(.opacity)
                    } else {
                        signedOutContent
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, Spacing.margin)
                .padding(.top, 4)
                .padding(.bottom, Spacing.margin)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .appBackground(.browse)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Closing never cancels a request: it finishes and updates the account in the background.
                    Button(role: .close, action: { dismiss() })
                        .keyboardShortcut(.cancelAction)
                }
            }
            .bottomActionBar {
                primaryAction
            }
        }
        .animation(motion, value: auth.isSignedIn)
        .animation(motion, value: sync.needsAccountChoice)
        .sensoryFeedback(.success, trigger: signInCount)
        .sensoryFeedback(.error, trigger: failureCount)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            // A stale error from the other state would only confuse. A session that ended by itself
            // (or a deletion it cut short) is explained instead of switching silently.
            password = ""
            if signedIn {
                errorMessage = nil
                if sync.needsAccountChoice {
                    showingAccountChoice = true
                }
            } else {
                errorMessage = sessionEndedMessage
                prefillAfterSessionEnded()
            }
        }
        .onAppear {
            if !auth.isSignedIn {
                errorMessage = errorMessage ?? sessionEndedMessage
                prefillAfterSessionEnded()
                focusedField = username.isEmpty ? .username : .password
            } else if sync.needsAccountChoice {
                showingAccountChoice = true
            }
        }
        .alert("Delete Account?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive, action: deleteAccount)
        } message: {
            Text("This deletes \(auth.username.map { "the account \($0)" } ?? "your account") and the copy of your progress saved with it. The kanji progress and word bank already on your devices stay on them, and your other devices stop syncing. This cannot be undone.")
        }
        .alert("Some Progress Hasn’t Synced", isPresented: $showingSignOutWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await finishSignOut() }
            }
        } message: {
            Text("Some changes on this device couldn’t be sent to your account. New progress stays here and is added to your account when you sign in on this device again. A reset or deletion made since the last sync stays on this device only.")
        }
        .confirmationDialog("Progress From Another Account", isPresented: $showingAccountChoice, titleVisibility: .visible) {
            Button("Add It to \(accountName)") {
                Task {
                    await sync.addThisDeviceProgress()
                    announceSyncResult()
                }
            }
            Button("Use \(accountName)’s Progress", role: .destructive) {
                Task {
                    await sync.useAccountProgress()
                    announceSyncResult()
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("The kanji progress and word bank on this device came from another account. Add them to \(accountName), or replace them on this device with \(accountName)’s progress. Nothing syncs until you choose.")
        }
    }

    // MARK: - State helpers

    private var motion: Animation {
        reduceMotion ? .appFade : .appSmooth
    }

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedUsername.isEmpty && !password.isEmpty && !isWorking
    }

    private var isSyncing: Bool {
        if case .syncing = sync.status { return true }
        return false
    }

    private var accountName: String {
        auth.username ?? "this account"
    }

    /// Why the device is signed out, when it was not the learner's own doing.
    private var sessionEndedMessage: String? {
        guard !auth.isSignedIn, auth.sessionEndReason == .expired else { return nil }
        return isDeleting
            ? "Your session had ended, so the account was not deleted. Sign in, then delete it again."
            : AuthError.sessionExpired.errorDescription
    }

    /// After a session ended by itself: Sign In, with the username filled in.
    private func prefillAfterSessionEnded() {
        guard auth.sessionEndReason == .expired, username.isEmpty, let last = auth.lastUsername else { return }
        mode = .signIn
        username = last
    }

    // MARK: - Primary action

    /// One primary action: Sign In / Create Account when signed out, Sync Now when signed in.
    /// While a request runs the button keeps its colour, says what is happening and shows a spinner;
    /// a second press does nothing.
    @ViewBuilder
    private var primaryAction: some View {
        if auth.isSignedIn && sync.needsAccountChoice {
            PrimaryActionButton(
                title: isSyncing ? "Syncing…" : "Set Up Sync",
                systemImage: isSyncing ? nil : "arrow.triangle.2.circlepath",
                isEnabled: !isWorking
            ) {
                guard !isSyncing, !isWorking else { return }
                showingAccountChoice = true
            }
            .overlay(alignment: .leading) { spinner(isShown: isSyncing) }
            .keyboardShortcut(.defaultAction)
        } else if auth.isSignedIn {
            PrimaryActionButton(
                title: isSyncing ? "Syncing…" : "Sync Now",
                systemImage: isSyncing ? nil : "arrow.triangle.2.circlepath",
                isEnabled: !isWorking
            ) {
                guard !isSyncing, !isWorking else { return }
                Task {
                    await sync.syncNow(userInitiated: true)
                    announceSyncResult()
                }
            }
            .overlay(alignment: .leading) { spinner(isShown: isSyncing) }
            .keyboardShortcut(.defaultAction)
        } else {
            PrimaryActionButton(
                title: signedOutActionTitle,
                isEnabled: isWorking || canSubmit,
                action: submit
            )
            .overlay(alignment: .leading) { spinner(isShown: isWorking) }
            // Return submits from anywhere in the sheet; inside a field, onSubmit does the same.
            .keyboardShortcut(.defaultAction)
        }
    }

    private var signedOutActionTitle: String {
        switch (mode, isWorking) {
        case (.signIn, false): return "Sign In"
        case (.signIn, true): return "Signing In…"
        case (.createAccount, false): return "Create Account"
        case (.createAccount, true): return "Creating Account…"
        }
    }

    /// The spinner inside the primary button, at its leading end. At accessibility sizes the title can
    /// fill the whole button, so only the "…ing" title shows that work is under way.
    @ViewBuilder
    private func spinner(isShown: Bool) -> some View {
        if isShown && !isAccessibilitySize {
            ProgressView()
                .tint(.white)
                .padding(.leading, 22)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Signed out

    @ViewBuilder
    private var signedOutContent: some View {
        ScreenSubtitle(text: "Sign in to keep your kanji progress and word bank the same on iPhone, iPad and Mac. The progress on this device is added to the account you sign in to.")
            .padding(.bottom, 4)

        VStack(alignment: .leading, spacing: 18) {
            if auth.sessionEndReason == .deleted {
                Label("Account deleted. The progress on this device stays here.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            modeChoice

            VStack(alignment: .leading, spacing: 14) {
                usernameField
                passwordField
            }

            if let errorMessage {
                ErrorBanner(message: errorMessage)
                    .transition(.opacity)
            }

            noResetNote
        }
        .contentCard(padding: 18)
        .disabled(isWorking)
        .animation(.appQuick, value: mode)
        .animation(.appSmooth, value: errorMessage)
    }

    /// Sign In or Create Account, as two tiles side by side (stacked at accessibility sizes).
    private var modeChoice: some View {
        let layout = isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            modeTile(.signIn, title: "Sign In")
            modeTile(.createAccount, title: "Create Account")
        }
    }

    private func modeTile(_ tileMode: Mode, title: String) -> some View {
        SelectTile(isSelected: mode == tileMode, minHeight: 44) {
            guard mode != tileMode else { return }
            mode = tileMode
            errorMessage = nil
        } content: {
            // Side padding clears the selected tile's check badge in the top corner.
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, isAccessibilitySize ? 28 : 20)
        }
        .accessibilityLabel(title)
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            AccountFieldLabel(text: "Username")
            TextField("Username", text: $username, prompt: Text("Your username"))
                .textFieldStyle(.plain)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focusedField, equals: .username)
                .onSubmit {
                    // Return goes on to the password, or signs in once both are filled.
                    if canSubmit {
                        submit()
                    } else {
                        focusedField = .password
                    }
                }
                .modifier(AccountFieldBox(isFocused: focusedField == .username))
        }
    }

    private var passwordField: some View {
        let isLongEnough = password.count >= Self.minimumPasswordLength
        return VStack(alignment: .leading, spacing: 6) {
            AccountFieldLabel(text: "Password")
            SecureField("Password", text: $password, prompt: Text(mode == .createAccount ? "Choose a password" : "Your password"))
                .textFieldStyle(.plain)
                .textContentType(mode == .createAccount ? .newPassword : .password)
                .submitLabel(mode == .createAccount ? .join : .go)
                .focused($focusedField, equals: .password)
                .onSubmit(submit)
                .modifier(AccountFieldBox(isFocused: focusedField == .password))

            if mode == .createAccount {
                Label {
                    Text("At least \(Self.minimumPasswordLength) characters")
                } icon: {
                    Image(systemName: isLongEnough ? "checkmark.circle.fill" : "circle")
                        .contentTransition(.symbolEffect(.replace))
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(isLongEnough ? Color.correct : Color.inkSecondary)
                .padding(.top, 2)
                .transition(.opacity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("At least \(Self.minimumPasswordLength) characters")
                .accessibilityValue(isLongEnough ? "Done" : "Not yet")
            }
        }
    }

    private var noResetNote: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "key.fill")
                .font(.footnote)
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)
            // The app has no associated domain, so the system never offers to save the password.
            Text(mode == .createAccount
                ? "Accounts have no email, so a forgotten password cannot be reset. Save it in the Passwords app or another safe place now."
                : "Accounts have no email, so a forgotten password cannot be reset. Keep yours somewhere safe.")
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Signed in

    @ViewBuilder
    private var signedInContent: some View {
        ScreenSubtitle(text: "Your kanji progress and word bank stay the same on every device you sign in on.")
            .padding(.bottom, 4)

        accountCard
        deleteCard
    }

    private var accountCard: some View {
        let layout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 14))

        return VStack(alignment: .leading, spacing: 16) {
            layout {
                IconCircle(systemImage: "person.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: "Signed in as")
                    Text(auth.username ?? "")
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            if sync.needsAccountChoice {
                accountChoiceStatus
            } else {
                SyncStatusLine(status: sync.status, lastSyncedAt: sync.lastSyncedAt)
            }

            if !auth.sessionIsPersisted {
                Label {
                    Text("This device couldn’t save your sign-in, so you’ll need to sign in again the next time you open the app.")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.wrong)
                }
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Button(action: signOut) {
                    HStack(spacing: 8) {
                        if isSigningOut {
                            ProgressView()
                                .accessibilityHidden(true)
                            Text("Signing Out…")
                        } else {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(theme.accent)

                Text("Signing out keeps your progress on this device. Progress you make while signed out is added to your account when you sign in here again; resets and deletions stay on this device.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentCard(padding: 18)
        .disabled(isWorking)
    }

    /// Signed in to another account than the one this device's progress came from.
    private var accountChoiceStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Not syncing yet", systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text("The progress on this device came from another account. Choose whether to add it to \(accountName) or to use \(accountName)’s progress here.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            // "Use the account's progress" failed (offline, server error): nothing changed here.
            if case .failed(let message) = sync.status {
                ErrorBanner(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.appSmooth, value: sync.status)
    }

    /// Deleting is the only signed-in action that can fail, so its error shows here.
    private var deleteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Delete Account")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Removes your account and the copy of your progress saved with it. The progress already on your devices stays on them.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage {
                ErrorBanner(message: errorMessage)
                    .transition(.opacity)
            }

            // No destructive role here: it would paint the system red over the app's own wrong colour.
            // The alert's Delete button carries the role.
            Button {
                deletionUserId = auth.userId
                showingDeleteAlert = true
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Color.wrong)
        }
        .contentCard(padding: 18)
        .disabled(isWorking)
        .animation(.appSmooth, value: errorMessage)
    }

    // MARK: - Actions

    private func submit() {
        guard canSubmit else { return }
        let name = trimmedUsername
        let secret = password
        let creating = mode == .createAccount
        // Disabled fields lose focus; the focus comes back after a failure so the learner can retype.
        let previousFocus = focusedField
        isWorking = true
        errorMessage = nil

        Task {
            var failed = false
            do {
                if creating {
                    try await auth.signUp(username: name, password: secret)
                } else {
                    try await auth.signIn(username: name, password: secret)
                }
                password = ""
                signInCount += 1
                announce("Signed in as \(auth.username ?? name)")
            } catch {
                // The password stays, so a mistyped username can be fixed without retyping it.
                fail(with: error)
                failed = true
            }
            isWorking = false
            focusedField = failed ? (previousFocus ?? .password) : nil
        }
    }

    /// Sends unsynced progress first; if that fails, asks before signing out.
    private func signOut() {
        guard !isWorking else { return }
        isWorking = true
        isSigningOut = true
        errorMessage = nil
        Task {
            if sync.hasPendingChanges {
                await sync.syncNow(userInitiated: true)
                if auth.isSignedIn, case .failed = sync.status {
                    isWorking = false
                    isSigningOut = false
                    showingSignOutWarning = true
                    return
                }
            }
            await finishSignOut()
        }
    }

    private func finishSignOut() async {
        let name = auth.username
        isWorking = true
        isSigningOut = true
        await auth.signOut()
        // Ready to sign back in: same account, Sign In tab.
        mode = .signIn
        username = name ?? ""
        password = ""
        isWorking = false
        isSigningOut = false
        if !auth.isSignedIn {
            announce("Signed out")
        }
    }

    private func deleteAccount() {
        guard !isWorking, let target = deletionUserId else { return }
        isWorking = true
        isDeleting = true
        errorMessage = nil
        Task {
            do {
                try await auth.deleteAccount(userId: target)
                mode = .signIn
                username = ""
                password = ""
                announce("Account deleted")
            } catch where auth.userId != target {
                // The account is not the one signed in any more: nothing was deleted.
                fail(message: auth.isSignedIn
                    ? "You are signed in to another account now, so nothing was deleted."
                    : "Your session had ended, so the account was not deleted. Sign in, then delete it again.")
            } catch {
                fail(with: error)
            }
            isDeleting = false
            isWorking = false
            deletionUserId = nil
        }
    }

    private func fail(with error: Error) {
        fail(message: error.localizedDescription)
    }

    private func fail(message: String) {
        errorMessage = message
        failureCount += 1
        announce(message)
    }

    /// After Sync Now or the account choice: says how it went (the button's own title change is not
    /// spoken by VoiceOver).
    private func announceSyncResult() {
        guard auth.isSignedIn else { return }
        switch sync.status {
        case .failed(let message):
            announce("Sync failed. \(message)")
        case .idle where !sync.needsAccountChoice && sync.lastSyncedAt != nil:
            announce("Synced")
        default:
            break
        }
    }

    /// High priority, so the focus moving to a field right after cannot cut it off.
    private func announce(_ text: String) {
        var spoken = AttributedString(text)
        spoken.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(spoken).post()
    }
}

// MARK: - Sync status

/// Status line in the account card: a symbol and a short label in a semantic colour, like StatusLabel.
/// The relative time is refreshed every 20 seconds, only while it is on screen and only when it shows a time.
private struct SyncStatusLine: View {
    let status: SyncService.Status
    let lastSyncedAt: Date?
    @Environment(\.appTheme) private var theme

    var body: some View {
        Group {
            if case .syncing = status {
                line("Syncing…", systemImage: "arrow.triangle.2.circlepath", color: theme.accent)
            } else if case .failed(let message) = status {
                VStack(alignment: .leading, spacing: 4) {
                    line("Sync failed", systemImage: "xmark.circle.fill", color: Color.wrong)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let lastSyncedAt {
                        TimelineView(.periodic(from: .now, by: 20)) { context in
                            Text("Last synced \(Self.relative(lastSyncedAt, now: context.date))")
                                .font(.footnote)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                }
            } else if let lastSyncedAt {
                TimelineView(.periodic(from: .now, by: 20)) { context in
                    line(Self.syncedText(lastSyncedAt, now: context.date), systemImage: "checkmark.circle.fill", color: Color.correct)
                }
            } else {
                line("Not synced yet", systemImage: "arrow.triangle.2.circlepath", color: Color.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func line(_ text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    /// "Synced just now" for the first minute, then "Synced 2 minutes ago".
    static func syncedText(_ date: Date, now: Date) -> String {
        now.timeIntervalSince(date) < 60 ? "Synced just now" : "Synced \(relative(date, now: now))"
    }

    static func relative(_ date: Date, now: Date) -> String {
        if now.timeIntervalSince(date) < 60 { return "just now" }
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

// MARK: - Fields

/// Small label above a field inside a card. VoiceOver reads the field's own name instead.
private struct AccountFieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .accessibilityHidden(true)
    }
}

/// A text field's box: the screen base inside the white card, an accent outline while it has focus
/// (so keyboard users on the Mac see where typing goes), a plain outline with Increase Contrast.
private struct AccountFieldBox: ViewModifier {
    let isFocused: Bool
    @Environment(\.appTheme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
        content
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(Color.appBase, in: shape)
            .overlay {
                if isFocused {
                    shape.strokeBorder(theme.accent, lineWidth: 2)
                } else if contrast == .increased {
                    shape.strokeBorder(Color.primary.opacity(0.4), lineWidth: 1.5)
                }
            }
            .opacity(isEnabled ? 1 : 0.6)
            .animation(.appQuick, value: isFocused)
    }
}
