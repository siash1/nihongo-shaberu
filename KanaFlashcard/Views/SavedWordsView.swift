import SwiftUI

/// Every saved word, grouped by JLPT level. Swipe a row to delete it.
struct SavedWordsView: View {
    @Bindable var viewModel: WordPracticeViewModel
    @State private var savedWords: [WordCard] = []
    @State private var showingClearAlert = false
    @State private var listWidth: CGFloat = 0
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var totalSize: CGFloat = 56

    var body: some View {
        Group {
            if savedWords.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("No Saved Words")
                    } icon: {
                        // On the wash: never the system .secondary.
                        Image(systemName: "tray")
                            .foregroundStyle(.primary.opacity(0.72))
                    }
                } description: {
                    Text("Words you practice are saved here.")
                        .foregroundStyle(.primary.opacity(0.72))
                }
            } else {
                wordList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground(.browse)
        .navigationTitle("Word Bank")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !savedWords.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Label("Clear All", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .alert("Clear All Words?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                WordStorageService.clearAllWords()
                savedWords = []
                viewModel.refreshSavedWordCounts()
            }
        } message: {
            Text("This will remove all \(savedWords.count) saved words. This cannot be undone.")
        }
        .onAppear {
            savedWords = WordStorageService.loadAllWords()
        }
    }

    // MARK: - List

    private var wordList: some View {
        List {
            Section {
                totalRow
                    .listRowBackground(Color.clear)
            }

            ForEach(JLPTLevel.allCases, id: \.self) { level in
                let levelWords = savedWords.filter { $0.level == level }
                if !levelWords.isEmpty {
                    Section {
                        ForEach(levelWords) { word in
                            wordRow(word)
                                .listRowBackground(Color.cardFill)
                        }
                        .onDelete { indexSet in
                            deleteWords(indexSet, from: levelWords)
                        }
                    } header: {
                        levelHeader(level, count: levelWords.count)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.custom(Spacing.section))
        .scrollContentBackground(.hidden)
        // 20pt margins on phones; on wide screens the column stays 640pt and centred.
        .contentMargins(.horizontal, max(Spacing.margin, (listWidth - 640) / 2), for: .scrollContent)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            listWidth = width
        }
    }

    /// The first row sits on the wash: the total as a hero number and a count per level.
    private var totalRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return VStack(alignment: .leading, spacing: 4) {
            layout {
                Text("\(savedWords.count)")
                    .font(.system(size: totalSize, weight: .heavy))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(savedWords.count == 1 ? "word saved" : "words saved")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.72))
            }
            Text(levelSummary(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.72))
        }
        // Read as a sentence, without the middle dots.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(savedWords.count) \(savedWords.count == 1 ? "word" : "words") saved. \(levelSummary(separator: ", "))")
    }

    private func levelSummary(separator: String) -> String {
        JLPTLevel.allCases.compactMap { level in
            let count = savedWords.filter { $0.level == level }.count
            return count > 0 ? "\(level.rawValue) \(count)" : nil
        }
        .joined(separator: separator)
    }

    private func levelHeader(_ level: JLPTLevel, count: Int) -> some View {
        // The count moves under the level at large text sizes instead of squeezing beside it.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        return layout {
            Text(level.rawValue)
                .font(.title3.bold())
                .foregroundStyle(.primary)
            if !stacked {
                Spacer(minLength: 8)
            }
            Text(count == 1 ? "1 word" : "\(count) words")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(0.72))
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func wordRow(_ word: WordCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.word)
                .font(.title2.weight(.semibold))
                .japanese()
            if dynamicTypeSize.isAccessibilitySize {
                Text(word.romaji)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
            } else {
                Text("\(Text(word.romaji).fontWeight(.semibold).foregroundStyle(theme.accent)) · \(Text(word.meaning))")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.word), \(word.romaji), \(word.meaning)")
    }

    private func deleteWords(_ indexSet: IndexSet, from levelWords: [WordCard]) {
        for index in indexSet {
            WordStorageService.deleteWord(levelWords[index])
        }
        savedWords = WordStorageService.loadAllWords()
        viewModel.refreshSavedWordCounts()
    }
}
