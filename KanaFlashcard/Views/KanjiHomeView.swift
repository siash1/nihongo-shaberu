import SwiftUI

/// Kanji tab: overall progress, the review test, and the 20 units of the course.
/// The next lesson is always one tap away in the floating bar at the bottom.
struct KanjiHomeView: View {
    @Bindable var viewModel: KanjiViewModel
    @State private var showingResetAlert = false
    @State private var lessonUnit: KanjiUnit?   // fixed when the button is tapped, so the lesson keeps its unit
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var zoom

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                VStack(alignment: .leading, spacing: Spacing.cards) {
                    ScreenSubtitle(text: "\(viewModel.totalKanjiCount) kanji, one memory story at a time.")
                    courseCard
                    if viewModel.learnedCount >= 4 {
                        reviewRow
                    }
                }

                unitList
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, Spacing.margin)
            .padding(.top, 4)
            .padding(.bottom, Spacing.margin)
            .frame(maxWidth: .infinity)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .appBackground(.browse)
        .navigationTitle("Kanji")
        .navigationBarTitleDisplayMode(.large)
        // The lesson is pushed from a value captured at tap time. Built from live progress it would
        // switch to the next unit, or disappear, the moment the last kanji of a unit is learned.
        .navigationDestination(item: $lessonUnit) { unit in
            KanjiLearnView(viewModel: viewModel, unit: unit)
                .navigationTransition(.zoom(sourceID: "next", in: zoom))
        }
        .toolbar {
            if viewModel.hasProgress {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reset Progress", systemImage: "arrow.counterclockwise", role: .destructive) {
                            showingResetAlert = true
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                }
            }
        }
        .alert("Reset Kanji Progress?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                withAnimation(.appSmooth) {
                    viewModel.resetProgress()
                }
            }
        } message: {
            Text(viewModel.learnedCount == 0
                ? "This will clear all test scores. This cannot be undone."
                : "This will forget the \(viewModel.learnedCount) kanji you have learned and all test scores. This cannot be undone.")
        }
        .bottomActionBar {
            if let unit = viewModel.nextUnit, let next = viewModel.nextKanji(in: unit) {
                HomeLessonButton(
                    title: viewModel.learnedCount == 0 ? "Start Lesson" : "Continue with",
                    kanji: viewModel.learnedCount == 0 ? nil : next.character
                ) {
                    lessonUnit = unit
                }
                .matchedTransitionSource(id: "next", in: zoom)
            }
        }
    }

    private var stacked: Bool { dynamicTypeSize.isAccessibilitySize }

    private var completedUnitCount: Int {
        viewModel.units.filter { viewModel.isComplete($0) }.count
    }

    // MARK: - Course progress

    /// Not tappable: it reports progress, the bottom bar acts on it.
    private var courseCard: some View {
        let learned = viewModel.learnedCount
        let total = viewModel.totalKanjiCount
        let isCourseComplete = viewModel.nextUnit == nil
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 20))

        return layout {
            Group {
                if isCourseComplete {
                    CompleteBadge(size: 104)
                        .accessibilityHidden(true)
                } else {
                    ProgressRing(value: total > 0 ? Double(learned) / Double(total) : 0, size: 104, lineWidth: 12) {
                        Text("\(learned)")
                            .font(.system(size: 34, weight: .heavy))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .contentTransition(.numericText(value: Double(learned)))
                            .padding(.horizontal, 14)
                    }
                }
            }
            // The ring's stroke is drawn on its edge, so half of it sits outside the frame.
            // The badge gets the same slot so the text does not shift when the course completes.
            .padding(6)

            VStack(alignment: .leading, spacing: 4) {
                if isCourseComplete {
                    Text("You have learned every kanji in the course")
                        .font(.title3.weight(.semibold))
                    unitsCompleteLine
                } else if learned == 0 {
                    Text("Learn one kanji at a time with a memory story, then test yourself on words and sentences. Each unit follows one video lesson.")
                        .font(.callout)
                } else {
                    Text("of \(total) kanji learned")
                        .font(.title3.weight(.semibold))
                    unitsCompleteLine
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .heroCard(padding: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(courseAccessibilityLabel(learned: learned, total: total, isComplete: isCourseComplete))
    }

    private var unitsCompleteLine: some View {
        Text("\(completedUnitCount) of \(viewModel.units.count) units complete")
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }

    private func courseAccessibilityLabel(learned: Int, total: Int, isComplete: Bool) -> String {
        let units = "\(completedUnitCount) of \(viewModel.units.count) units complete"
        if isComplete { return "You have learned every kanji in the course. \(units)" }
        if learned == 0 {
            return "0 of \(total) kanji learned. Learn one kanji at a time with a memory story, then test yourself on words and sentences. Each unit follows one video lesson."
        }
        return "\(learned) of \(total) kanji learned. \(units)"
    }

    // MARK: - Review

    private var reviewRow: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 14))

        return NavigationLink {
            KanjiQuizView(
                viewModel: viewModel,
                title: "Review",
                makeQuestions: { viewModel.reviewQuestions() }
            )
            .navigationTransition(.zoom(sourceID: "review", in: zoom))
        } label: {
            // Accessibility text sizes: icon above the text and no chevron, so the text keeps the full width.
            layout {
                IconCircle(systemImage: "arrow.triangle.2.circlepath")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Review")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("A mixed test of the kanji you know")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                if !stacked {
                    HomeChevron()
                }
            }
            .frame(minHeight: 44)
            // A neutral base, so the chevron's .tertiary resolves to grey and not to the link tint.
            .foregroundStyle(Color.primary)
            .contentCard(padding: 16)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(PressStyle())
        .matchedTransitionSource(id: "review", in: zoom)
    }

    // MARK: - Units

    private var unitList: some View {
        let nextUnitID = viewModel.nextUnit?.id

        return VStack(alignment: .leading, spacing: Spacing.cards) {
            SectionHeader(title: "Units", detail: "\(completedUnitCount) of \(viewModel.units.count) complete")

            ForEach(viewModel.units) { unit in
                NavigationLink {
                    KanjiUnitView(viewModel: viewModel, unit: unit)
                } label: {
                    HomeUnitRow(
                        unit: unit,
                        learned: viewModel.learnedCount(in: unit),
                        isComplete: viewModel.isComplete(unit),
                        isNext: nextUnitID == unit.id,
                        stacked: stacked
                    )
                }
                .buttonStyle(PressStyle())
            }
        }
    }
}

// MARK: - Unit row

/// One unit of the course: its progress ring, title and kanji.
private struct HomeUnitRow: View {
    let unit: KanjiUnit
    let learned: Int
    let isComplete: Bool
    /// The unit the bottom bar continues with; marked so the list and the bar point at the same place.
    let isNext: Bool
    /// Accessibility text sizes: ring above the text, count under the kanji, no chevron.
    let stacked: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        let total = unit.kanji.count
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 14))

        layout {
            badge(total: total)

            VStack(alignment: .leading, spacing: 4) {
                if isNext {
                    Eyebrow(text: "Up next")
                }

                Text(unit.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(unit.kanji.map(\.character).joined(separator: " "))
                    .font(.body)
                    .japanese()
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if stacked {
                    count(total: total)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !stacked {
                count(total: total)
                HomeChevron()
            }
        }
        // A neutral base, so the chevron's .tertiary resolves to grey and not to the link tint.
        .foregroundStyle(Color.primary)
        .contentCard(padding: 16)
        .overlay {
            if isNext {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(total: total))
    }

    private func badge(total: Int) -> some View {
        ZStack {
            if isComplete {
                CompleteBadge(size: 48)
            } else {
                ProgressRing(value: total > 0 ? Double(learned) / Double(total) : 0, size: 48, lineWidth: 5) {
                    Text("\(unit.number)")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(theme.accent)
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)   // keeps the number inside its ring
                }
            }
        }
        // Half of the ring's stroke sits outside its frame; the same slot for both states keeps titles aligned.
        .padding(2.5)
    }

    private func count(total: Int) -> some View {
        Text("\(learned)/\(total)")
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }

    private func accessibilityText(total: Int) -> String {
        var parts = ["Unit \(unit.number)", unit.title, "\(learned) of \(total) kanji learned"]
        if isComplete { parts.append("complete") }
        if isNext { parts.append("up next") }
        return parts.joined(separator: ", ")
    }
}

/// Trailing chevron of a navigation row.
private struct HomeChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Lesson button

/// The bottom bar's lesson button. It looks exactly like PrimaryActionButton, but its label is a Text,
/// so the kanji in "Continue with 土" keeps the standard Japanese letter shapes instead of the rounded design.
private struct HomeLessonButton: View {
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
