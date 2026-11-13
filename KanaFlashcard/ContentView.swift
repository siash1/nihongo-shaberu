import SwiftUI

struct ContentView: View {
    /// Created once by the app and shared by every window, so two iPad windows
    /// never overwrite each other's kanji progress.
    let kanjiViewModel: KanjiViewModel

    @State private var viewModel = PracticeViewModel()
    @State private var chatViewModel = ChatViewModel()
    @State private var wordViewModel = WordPracticeViewModel()
    @State private var selectedTab: AppTab = .practice

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Practice", systemImage: "rectangle.portrait.on.rectangle.portrait.angled.fill", value: AppTab.practice) {
                NavigationStack {
                    KanaSelectionView(viewModel: viewModel)
                }
                .environment(\.appTheme, AppTab.practice.theme)
                .tint(AppTab.practice.theme.accent)
            }

            Tab("Words", systemImage: "character.bubble.fill.ja", value: AppTab.words) {
                NavigationStack {
                    WordSetupView(viewModel: wordViewModel)
                }
                .environment(\.appTheme, AppTab.words.theme)
                .tint(AppTab.words.theme.accent)
            }

            Tab("Kanji", systemImage: "character.book.closed.fill.ja", value: AppTab.kanji) {
                NavigationStack {
                    KanjiHomeView(viewModel: kanjiViewModel)
                }
                .environment(\.appTheme, AppTab.kanji.theme)
                .tint(AppTab.kanji.theme.accent)
            }

            Tab("Talk", systemImage: "waveform", value: AppTab.talk) {
                NavigationStack {
                    ChatView(viewModel: chatViewModel)
                }
                .environment(\.appTheme, AppTab.talk.theme)
                .tint(AppTab.talk.theme.accent)
            }
        }
        // The selected tab's icon takes that tab's colour.
        .tint(selectedTab.theme.accent)
        // Latin text is rounded everywhere; Japanese opts out with .japanese().
        .fontDesign(.rounded)
    }
}

#Preview {
    let kanjiViewModel = KanjiViewModel()
    let auth = AuthService()
    ContentView(kanjiViewModel: kanjiViewModel)
        .environment(auth)
        .environment(SyncService(auth: auth, kanji: kanjiViewModel))
}
