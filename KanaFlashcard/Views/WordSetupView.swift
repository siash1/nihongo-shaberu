import SwiftUI

/// Words tab: pick a script and level for ten new AI-written words, or test yourself on the word bank.
struct WordSetupView: View {
    @Bindable var viewModel: WordPracticeViewModel
    @State private var showingFlashcards = false
    /// Bumped by the learner's own taps only, so the selection haptic never fires on its own.
    @State private var selectionCount = 0
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.cards) {
                ScreenSubtitle(text: "Ten new words at your level, every time.")
                    .padding(.bottom, 4)
                newWordsCard
                wordBankCard
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, Spacing.margin)
            .padding(.bottom, Spacing.section)
            .frame(maxWidth: .infinity)
        }
        .appBackground(.browse)
        .navigationTitle("Words")
        .navigationBarTitleDisplayMode(.large)
        .bottomActionBar {
            PrimaryActionButton(title: "Generate 10 Words", systemImage: "sparkles") {
                viewModel.practiceMode = .generate
                showingFlashcards = true
            }
        }
        // Deck screens are a plain push: a zoom's drag-down dismissal would steal the card swipe.
        .navigationDestination(isPresented: $showingFlashcards) {
            WordFlashcardView(viewModel: viewModel)
        }
        .sensoryFeedback(.selection, trigger: selectionCount)
        .onAppear {
            viewModel.refreshSavedWordCounts()
            dropEmptyTestLevels()
        }
    }

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Five level tiles in a row; at accessibility sizes four, then three, so they wrap instead of squeezing.
    private var levelColumns: [GridItem] {
        let count: Int
        switch dynamicTypeSize {
        case .accessibility1, .accessibility2: count = 4
        default: count = isAccessibilitySize ? 3 : 5
        }
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    // MARK: - New words

    private var newWordsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("New words")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("AI writes 10 new words for the script and level you choose.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Script")
                let layout = isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 8))
                    : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    ForEach(viewModel.scripts, id: \.self) { script in
                        scriptTile(script)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Level")
                LazyVGrid(columns: levelColumns, spacing: 8) {
                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                        levelTile(level)
                    }
                }
                Text("\(Text(viewModel.selectedLevel.rawValue).fontWeight(.semibold).foregroundStyle(.primary)) \(Self.levelName(viewModel.selectedLevel))")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }

            // A failed generation is reported here after the session is closed.
            if viewModel.practiceMode == .generate, !viewModel.isLoading, let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        }
        .contentCard(padding: 18)
    }

    private func scriptTile(_ script: String) -> some View {
        let isSelected = viewModel.selectedScript == script
        return SelectTile(isSelected: isSelected, minHeight: 96) {
            guard viewModel.selectedScript != script else { return }
            withAnimation(.appQuick) { viewModel.selectedScript = script }
            selectionCount += 1
        } content: {
            VStack(spacing: 8) {
                PracticeSquare(
                    text: script == "Katakana" ? "ア" : "あ",
                    side: 48,
                    style: isSelected ? .onFill : .plain
                )
                Text(script)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel(script)
    }

    private func levelTile(_ level: JLPTLevel) -> some View {
        SelectTile(isSelected: viewModel.selectedLevel == level) {
            guard viewModel.selectedLevel != level else { return }
            withAnimation(.appQuick) { viewModel.selectedLevel = level }
            selectionCount += 1
        } content: {
            Text(level.rawValue)
                .font(.headline.bold())
                .monospacedDigit()
        }
        .accessibilityLabel("\(level.rawValue), \(Self.levelName(level))")
    }

    private static func levelName(_ level: JLPTLevel) -> String {
        switch level {
        case .n5: return "Beginner"
        case .n4: return "Elementary"
        case .n3: return "Intermediate"
        case .n2: return "Upper intermediate"
        case .n1: return "Advanced"
        }
    }

    // MARK: - Word bank

    private var wordBankCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            wordBankHeader

            if viewModel.totalSavedWords == 0 {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "tray")
                        .font(.title3)
                        .foregroundStyle(Color.inkSecondary)
                        .accessibilityHidden(true)
                    Text("Words you practice are saved here so you can test yourself later.")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Test yourself")
                    LazyVGrid(columns: levelColumns, spacing: 8) {
                        ForEach(JLPTLevel.allCases, id: \.self) { level in
                            testLevelTile(level)
                        }
                    }
                }

                startTestButton

                Divider()

                NavigationLink {
                    SavedWordsView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 12) {
                        Text("Browse all words")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(PressStyle())
            }
        }
        .contentCard(padding: 18)
    }

    private var wordBankHeader: some View {
        let layout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            Text("Word Bank")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if !isAccessibilitySize {
                Spacer(minLength: 8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.totalSavedWords)")
                    .font(.largeTitle.weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(viewModel.totalSavedWords)))
                Text("saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func testLevelTile(_ level: JLPTLevel) -> some View {
        let count = viewModel.savedWordCounts[level] ?? 0
        return SelectTile(isSelected: viewModel.selectedTestLevels.contains(level), isEnabled: count > 0) {
            withAnimation(.appQuick) { viewModel.toggleTestLevel(level) }
            selectionCount += 1
        } content: {
            VStack(spacing: 2) {
                Text(level.rawValue)
                    .font(.subheadline.bold())
                Text("\(count)")
                    .font(.caption)
                    .monospacedDigit()
                    .opacity(0.85)
            }
        }
        .accessibilityLabel(level.rawValue)
        .accessibilityValue(Self.wordCount(count))
    }

    private var startTestButton: some View {
        let count = viewModel.selectedTestWordCount
        return Button {
            viewModel.practiceMode = .test
            showingFlashcards = true
        } label: {
            Text(count > 0 ? "Start Test · \(Self.wordCount(count))" : "Choose levels to test")
                .font(.headline)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .contentTransition(.numericText(value: Double(count)))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(theme.accent)
        .disabled(count == 0)
    }

    private static func wordCount(_ count: Int) -> String {
        count == 1 ? "1 word" : "\(count) words"
    }

    /// A level whose saved words were all deleted can no longer be tested (its tile is disabled),
    /// so it leaves the selection instead of staying stuck on.
    private func dropEmptyTestLevels() {
        for level in viewModel.selectedTestLevels where (viewModel.savedWordCounts[level] ?? 0) == 0 {
            viewModel.toggleTestLevel(level)
        }
    }
}

/// Small label above a group of tiles inside a card.
private struct FieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}
