import SwiftUI

/// The account button of every hub, always first at the leading edge of the top bar, so it sits in
/// the same place on all four tabs and never displaces a hub's own items (those are trailing, or
/// follow it, as Talk's Clear does).
///
/// Hubs add it with `AccountToolbarItem()` as the first item of their `.toolbar`.
struct AccountToolbarItem: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            AccountButton()
        }
    }
}

/// Opens `AccountView`. Its symbol carries the account's state: outlined when signed out, filled when
/// signed in, with an exclamation badge when something needs the learner: the last sync failed, the
/// device waits for the choice of what to do with another account's progress, or the session ended
/// by itself. Automatic retries keep the failure showing, so the symbol only changes when the state
/// does.
struct AccountButton: View {
    @Environment(AuthService.self) private var auth
    @Environment(SyncService.self) private var sync
    @Environment(\.appTheme) private var theme
    @State private var showingAccount = false

    var body: some View {
        Button {
            showingAccount = true
        } label: {
            // A Label rather than a bare Image, so the large content viewer and Voice Control get the name.
            Label("Account", systemImage: symbolName)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel("Account")
        .accessibilityValue(stateDescription)
        .accessibilityHint(auth.isSignedIn ? "" : "Sign in to keep your progress the same on all your devices")
        .sheet(isPresented: $showingAccount) {
            // Sheets inherit the presenting environment, but the sheet must look like the tab it came
            // from even if that ever changes, so the theme and both services are passed on explicitly.
            AccountView()
                .environment(auth)
                .environment(sync)
                .environment(\.appTheme, theme)
                .tint(theme.accent)
                .fontDesign(.rounded)
        }
    }

    private var syncFailed: Bool {
        if case .failed = sync.status { return true }
        return false
    }

    private var sessionEnded: Bool {
        !auth.isSignedIn && auth.sessionEndReason == .expired
    }

    private var symbolName: String {
        guard auth.isSignedIn else {
            return sessionEnded ? "person.crop.circle.badge.exclamationmark" : "person.crop.circle"
        }
        return syncFailed || sync.needsAccountChoice
            ? "person.crop.circle.badge.exclamationmark.fill"
            : "person.crop.circle.fill"
    }

    private var stateDescription: String {
        guard auth.isSignedIn else { return sessionEnded ? "Signed out. Your session ended" : "Signed out" }
        let signedIn = auth.username.map { "Signed in as \($0)" } ?? "Signed in"
        if sync.needsAccountChoice { return "\(signedIn). Not syncing yet" }
        if syncFailed { return "\(signedIn). Sync failed" }
        if case .syncing = sync.status { return "\(signedIn). Syncing" }
        return signedIn
    }
}
