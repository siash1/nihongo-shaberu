import SwiftUI

/// One unit of the course, in the order a beginner should follow it:
/// 1 watch the video, 2 learn the kanji, 3 take the three tests.
struct KanjiUnitView: View {
    @Bindable var viewModel: KanjiViewModel
    let unit: KanjiUnit

    /// The kanji that was tapped. The sheet is bound to it, so it never changes while the sheet is up.
    @State private var selectedKanji: KanjiEntry?
    /// The kanji currently showing in the sheet, which the learner can page through.
    @State private var pageID: String?
    @State private var showingLesson = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appTheme) private var theme
    @Namespace private var zoom

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                header
                if let url = unit.videoURL {
                    watchSection(url)
                }
                learnSection
                testSection
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, Spacing.margin)
            .padding(.top, 4)
            .padding(.bottom, Spacing.margin)
            .frame(maxWidth: .infinity)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .appBackground(.browse)
        .navigationTitle("Unit \(unit.number)")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingLesson) {
            KanjiLearnView(viewModel: viewModel, unit: unit)
                .navigationTransition(.zoom(sourceID: "learn", in: zoom))
        }
        .sheet(item: $selectedKanji) { entry in
            KanjiPagerSheet(viewModel: viewModel, unit: unit, startID: entry.id, pageID: $pageID) {
                selectedKanji = nil
            }
            // The sheet is its own presentation: hand it the tab's look explicitly.
            .environment(\.appTheme, theme)
            .tint(theme.accent)
            // The card grows out of the kanji that was tapped, and shrinks back into the one now showing.
            .navigationTransition(.zoom(sourceID: pageID ?? entry.id, in: zoom))
        }
        .bottomActionBar {
            UnitLessonButton(title: lessonButtonTitle, kanji: lessonButtonKanji) {
                showingLesson = true
            }
            .matchedTransitionSource(id: "learn", in: zoom)
        }
    }

    private var stacked: Bool { dynamicTypeSize.isAccessibilitySize }

    private var lessonButtonTitle: String {
        if viewModel.learnedCount(in: unit) == 0 { return "Start Lesson" }
        if viewModel.nextKanji(in: unit) != nil { return "Continue with" }
        return "Learn Again"
    }

    /// The kanji shown after "Continue with", set apart so it keeps the Japanese letter shapes.
    private var lessonButtonKanji: String? {
        guard viewModel.learnedCount(in: unit) > 0 else { return nil }
        return viewModel.nextKanji(in: unit)?.character
    }

    /// Step numbers follow the sections actually shown.
    private var firstStepAfterVideo: Int { unit.videoURL == nil ? 1 : 2 }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(unit.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
            ScreenSubtitle(text: "\(unit.kanji.count) kanji · \(unit.words.count) words · \(unit.sentences.count) sentences")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - 1 Watch

    private func watchSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: Spacing.cards) {
            UnitStepHeader(number: 1, title: "Watch the lesson")

            Link(destination: url) {
                UnitRowCard(
                    systemImage: "play.rectangle.fill",
                    title: "Watch the video lesson",
                    subtitle: "Opens YouTube",
                    indicator: "arrow.up.right",
                    stacked: stacked
                ) {
                    EmptyView()
                }
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(PressStyle())
        }
    }

    // MARK: - 2 Learn

    private var learnSection: some View {
        let next = viewModel.nextKanji(in: unit)

        return VStack(alignment: .leading, spacing: Spacing.cards) {
            UnitStepHeader(
                number: firstStepAfterVideo,
                title: "Learn the kanji",
                detail: "\(viewModel.learnedCount(in: unit)) of \(unit.kanji.count) learned"
            )

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(unit.kanji) { entry in
                    UnitKanjiCell(
                        entry: entry,
                        isLearned: viewModel.isLearned(entry),
                        isNext: entry.id == next?.id
                    ) {
                        pageID = entry.id
                        selectedKanji = entry
                    }
                    .matchedTransitionSource(id: entry.id, in: zoom)
                }
            }
            .contentCard(padding: 12)
        }
    }

    /// Five columns; fewer at accessibility text sizes so each kanji keeps its room.
    private var gridColumns: [GridItem] {
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

    // MARK: - 3 Test

    private var testSection: some View {
        VStack(alignment: .leading, spacing: Spacing.cards) {
            UnitStepHeader(number: firstStepAfterVideo + 1, title: "Test yourself")

            ForEach(KanjiTestKind.allCases) { kind in
                let best = viewModel.bestScore(for: kind, in: unit)

                NavigationLink {
                    KanjiQuizView(
                        viewModel: viewModel,
                        title: kind.title,
                        makeQuestions: { viewModel.questions(for: kind, in: unit) },
                        onFinish: { viewModel.recordScore($0, for: kind, in: unit) }
                    )
                    .navigationTransition(.zoom(sourceID: kind.id, in: zoom))
                } label: {
                    UnitRowCard(
                        systemImage: kind.systemImage,
                        title: kind.title,
                        subtitle: kind.subtitle,
                        indicator: "chevron.right",
                        stacked: stacked
                    ) {
                        if let best {
                            BestScoreRing(percent: best)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(kind.title). \(kind.subtitle)")
                    .accessibilityValue(best.map { "Best score \($0) percent" } ?? "Not taken yet")
                }
                .buttonStyle(PressStyle())
                .matchedTransitionSource(id: kind.id, in: zoom)
            }
        }
    }
}

// MARK: - Step header

/// Section title with a numbered disc, so the intended order is plain to a beginner.
private struct UnitStepHeader: View {
    let number: Int
    let title: String
    var detail: String?

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(theme.accent)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)   // keeps the digit inside its 28pt disc
                .frame(width: 28, height: 28)
                .background(theme.accent.opacity(0.12), in: .circle)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    titleText
                    detailText
                }
            } else {
                titleText
                Spacer(minLength: 8)
                detailText
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number), \(title)")
        .accessibilityValue(detail ?? "")
        .accessibilityAddTraits(.isHeader)
    }

    private var titleText: some View {
        Text(title)
            .font(.title2.bold())
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var detailText: some View {
        if let detail {
            Text(detail)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(0.72))
        }
    }
}

// MARK: - Row card

/// A navigation row on a card: icon, title, subtitle, an optional trailing value and an indicator.
/// At accessibility text sizes it stacks (icon, text, value) and drops the indicator.
private struct UnitRowCard<Trailing: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String
    /// "chevron.right" for a push, "arrow.up.right" for a link that leaves the app.
    let indicator: String
    let stacked: Bool
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 14))

        layout {
            IconCircle(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()

            if !stacked {
                Image(systemName: indicator)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 44)
        // A neutral base, so the indicator's .tertiary resolves to grey and not to the link tint.
        .foregroundStyle(Color.primary)
        .contentCard(padding: 16)
    }
}

/// Best first-try score of a test: a green ring with the percent inside.
private struct BestScoreRing: View {
    let percent: Int

    var body: some View {
        ProgressRing(value: Double(percent) / 100, size: 40, color: Color.correct) {
            Text("\(percent)%")
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .dynamicTypeSize(...DynamicTypeSize.large)   // keeps the percent inside its ring
                .padding(.horizontal, 5)
        }
        // Half of the ring's stroke sits outside its frame.
        .padding(2.5)
    }
}

// MARK: - Kanji cell

/// One kanji of the unit's grid. Learned kanji carry a seal, the next one to learn an accent outline.
private struct UnitKanjiCell: View {
    let entry: KanjiEntry
    let isLearned: Bool
    let isNext: Bool
    let action: () -> Void

    /// Size of the learned seal; the glyph keeps this much room above and below so the seal never covers it.
    @ScaledMetric(relativeTo: .caption) private var scaledMarkSize: CGFloat = 13
    @Environment(\.appTheme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast

    /// Capped so the seal and its headroom stay a small mark at the largest text sizes.
    private var markSize: CGFloat { min(scaledMarkSize, 24) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)

        Button(action: action) {
            Text(entry.character)
                .font(.title)
                .japanese()
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 4)
                .padding(.vertical, markSize + 6)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(isLearned ? Color.correctTint : Color.appBase, in: shape)
                .overlay {
                    if isNext {
                        shape.strokeBorder(theme.accent, lineWidth: 2)
                    } else if contrast == .increased {
                        shape.strokeBorder(
                            isLearned ? Color.correct : Color.primary.opacity(0.4),
                            lineWidth: isLearned ? 2 : 1.5
                        )
                    }
                }
                .overlay(alignment: .topTrailing) {
                    // Learned is shown with a symbol, never by colour alone.
                    if isLearned {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: markSize, weight: .semibold))
                            .foregroundStyle(Color.correct)
                            .padding(5)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Shows the kanji card")
    }

    private var accessibilityText: String {
        var text = "\(entry.character), \(entry.meaning)"
        if isLearned { text += ", learned" }
        if isNext { text += ", next to learn" }
        return text
    }
}

// MARK: - Kanji sheet

/// The unit's kanji cards, paged sideways. Opened from the grid; free browsing, not the gated lesson.
private struct KanjiPagerSheet: View {
    @Bindable var viewModel: KanjiViewModel
    let unit: KanjiUnit
    /// The kanji that was tapped: the sheet always opens on it.
    let startID: String
    @Binding var pageID: String?
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    // Not lazy: a unit has at most a dozen or so kanji, and the first page must be the tapped one.
                    HStack(spacing: 0) {
                        ForEach(unit.kanji) { entry in
                            ScrollView {
                                KanjiDetailCard(entry: entry, onSpeak: { viewModel.speak($0) })
                                    .frame(maxWidth: 640)
                                    .padding(Spacing.margin)
                                    .frame(maxWidth: .infinity)
                            }
                            .scrollIndicators(.hidden)
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $pageID)
                .scrollIndicators(.hidden)
                // The scroll position binding already starts on the tapped kanji; this makes sure of it
                // in case the scroll view reports its first page before it has scrolled.
                .onAppear {
                    proxy.scrollTo(startID)
                }
            }
            .appBackground(.task)
            .navigationTitle(positionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
    }

    /// "3 of 14"
    private var positionTitle: String {
        let index = unit.kanji.firstIndex { $0.id == (pageID ?? startID) } ?? 0
        return "\(index + 1) of \(unit.kanji.count)"
    }
}

// MARK: - Lesson button

/// The bottom bar's lesson button. It looks exactly like PrimaryActionButton, but its label is a Text,
/// so the kanji in "Continue with 土" keeps the standard Japanese letter shapes instead of the rounded design.
private struct UnitLessonButton: View {
    let title: String
    var kanji: String?
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            label
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(theme.accentFill)
    }

    private var label: Text {
        guard let kanji else { return Text(title) }
        return Text("\(title) \(Text(kanji).fontDesign(.default))")
    }
}
