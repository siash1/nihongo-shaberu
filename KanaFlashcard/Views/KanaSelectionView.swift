import SwiftUI

/// Practice tab root: pick the kana to practise, then start a flashcard session.
struct KanaSelectionView: View {
    @Bindable var viewModel: PracticeViewModel
    @State private var isPracticing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.cards) {
                ScreenSubtitle(text: "Pick characters, then flip through them.")

                // Each script sits next to its voiced sounds; the two scripts are one section apart.
                KanaSectionCard(group: .hiragana, viewModel: viewModel)
                KanaSectionCard(group: .hiraganaDakuten, viewModel: viewModel)
                KanaSectionCard(group: .katakana, viewModel: viewModel)
                    .padding(.top, Spacing.section - Spacing.cards)
                KanaSectionCard(group: .katakanaDakuten, viewModel: viewModel)
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.margin)
            .padding(.top, 4)
            .padding(.bottom, Spacing.margin)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .appBackground(.browse)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                bulkSelectionButton
            }
        }
        .bottomActionBar {
            PrimaryActionButton(
                title: viewModel.canStartPractice ? "Start Practice" : "Pick at least 2 characters",
                count: viewModel.selectionCount,
                isEnabled: viewModel.canStartPractice,
                action: startPractice
            )
            .accessibilityLabel(startLabel)
        }
        // One tick per change, so a bulk action also gives exactly one.
        .sensoryFeedback(.selection, trigger: viewModel.selectionCount)
        .navigationDestination(isPresented: $isPracticing) {
            FlashcardView(viewModel: viewModel)
        }
    }

    /// "Select All" while nothing is picked, "Clear" as soon as anything is.
    private var bulkSelectionButton: some View {
        let isEmpty = viewModel.selectionCount == 0
        return Button(isEmpty ? "Select All" : "Clear") {
            withAnimation(.appQuick) {
                if isEmpty {
                    viewModel.selectAll()
                } else {
                    viewModel.clearSelection()
                }
            }
        }
        .accessibilityLabel(isEmpty ? "Select all characters" : "Clear selection")
    }

    private var startLabel: Text {
        let label: String = viewModel.canStartPractice
            ? "Start Practice with \(viewModel.selectionCount) characters"
            : "Pick at least 2 characters"
        return Text(label)
    }

    private func startPractice() {
        guard viewModel.canStartPractice else { return }
        isPracticing = true
    }
}

// MARK: - Sections

/// The four groups of characters, each shown as one card.
private enum KanaGroup {
    case hiragana, hiraganaDakuten, katakana, katakanaDakuten

    var title: String {
        switch self {
        case .hiragana: "Hiragana"
        case .hiraganaDakuten: "Hiragana Dakuten"
        case .katakana: "Katakana"
        case .katakanaDakuten: "Katakana Dakuten"
        }
    }

    var characters: [KanaCharacter] {
        switch self {
        case .hiragana: KanaData.hiragana
        case .hiraganaDakuten: KanaData.hiraganaDakuten
        case .katakana: KanaData.katakana
        case .katakanaDakuten: KanaData.katakanaDakuten
        }
    }

    var isDakuten: Bool {
        self == .hiraganaDakuten || self == .katakanaDakuten
    }
}

/// One script group: header with count and a select-all chip, then the character grid.
private struct KanaSectionCard: View {
    let group: KanaGroup
    let viewModel: PracticeViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                header
                if group.isDakuten {
                    Text("Voiced sounds, like \(Text("が").fontDesign(.default)) ga and \(Text("ぱ").fontDesign(.default)) pa")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(group.characters) { kana in
                    KanaGridCell(
                        kana: kana,
                        isSelected: viewModel.isSelected(kana),
                        isOutlined: contrast == .increased,
                        reduceMotion: reduceMotion
                    ) {
                        withAnimation(.appQuick) {
                            viewModel.toggle(kana)
                        }
                    }
                }
            }
        }
        .contentCard(padding: 14)
    }

    // MARK: Header

    private var header: some View {
        // At accessibility sizes the chip moves under the title instead of squeezing it.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        return layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .font(.title3.bold())
                Text("\(selectedCount) of \(group.characters.count) selected")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                    .monospacedDigit()
                    // Rolling digits are movement; Reduce Motion gets a cross-fade instead.
                    .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(selectedCount)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Chip(title: isAllSelected ? "All selected" : "Select all", isSelected: isAllSelected) {
                withAnimation(.appQuick) {
                    if isAllSelected {
                        viewModel.selectedCharacters.subtract(group.characters.map(\.id))
                    } else {
                        selectAll()
                    }
                }
            }
            .accessibilityLabel(chipLabel)
            .accessibilityHint(chipHint)
        }
        .frame(minHeight: 44)
    }

    private var chipLabel: Text {
        let label: String = isAllSelected ? "All \(group.title) selected" : "Select all \(group.title)"
        return Text(label)
    }

    /// When the chip is on, activating it deselects the section; say so, since the label only states the current state.
    private var chipHint: Text {
        let hint: String = isAllSelected ? "Deselects every \(group.title) character" : ""
        return Text(hint)
    }

    // MARK: Selection

    private var selectedCount: Int {
        group.characters.filter { viewModel.selectedCharacters.contains($0.id) }.count
    }

    private var isAllSelected: Bool {
        switch group {
        case .hiragana: viewModel.allHiraganaSelected
        case .hiraganaDakuten: viewModel.allHiraganaDakutenSelected
        case .katakana: viewModel.allKatakanaSelected
        case .katakanaDakuten: viewModel.allKatakanaDakutenSelected
        }
    }

    private func selectAll() {
        switch group {
        case .hiragana: viewModel.selectAllHiragana()
        case .hiraganaDakuten: viewModel.selectAllHiraganaDakuten()
        case .katakana: viewModel.selectAllKatakana()
        case .katakanaDakuten: viewModel.selectAllKatakanaDakuten()
        }
    }

    /// 5 columns, 4 at accessibility 1-2, 3 from accessibility 3 up.
    private var columns: [GridItem] {
        let count: Int
        if dynamicTypeSize >= .accessibility3 {
            count = 3
        } else if dynamicTypeSize.isAccessibilitySize {
            count = 4
        } else {
            count = 5
        }
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }
}

// MARK: - Cell

/// One kana in the grid. Solid accent with a check badge when selected; never moves or resizes.
/// No shadow: there are 142 of these on one screen.
private struct KanaGridCell: View {
    let kana: KanaCharacter
    let isSelected: Bool
    let isOutlined: Bool
    let reduceMotion: Bool
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(kana.character)
                    .font(.title)
                    .japanese()
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                Text(kana.romaji)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.white : Color.inkSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                isSelected ? theme.accentFill : Color.appBase,
                in: .rect(cornerRadius: Radius.cell, style: .continuous)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                if isOutlined {
                    RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.4), lineWidth: 1.5)
                }
            }
            .contentShape(.rect(cornerRadius: Radius.cell, style: .continuous))
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .accessibilityLabel(Text(verbatim: "\(kana.character), \(kana.romaji)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
