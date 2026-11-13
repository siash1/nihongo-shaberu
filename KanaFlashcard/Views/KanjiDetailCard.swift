import SwiftUI

/// Everything about one kanji: the character, its meaning, a memory story, readings and example words.
///
/// The kanji, its meaning and its story are learned together, so they share one solid hero card
/// (an answer face, in the tab colour). Readings and words follow as standard cards.
struct KanjiDetailCard: View {
    let entry: KanjiEntry
    let onSpeak: (String) -> Void

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            hero

            section("How to read it") {
                readings
            }

            section("Words", detail: "\(entry.words.count)") {
                words
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 16) {
            Eyebrow(text: "New kanji", onFill: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                practiceSquare

                Text(entry.meaning)
                    .font(.largeTitle.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.character), \(entry.meaning)")

            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .accessibilityHidden(true)

                // Most stories name parts by their kanji ("A woman (女) under a roof (宀)").
                storyText(entry.mnemonic)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Memory story: \(entry.mnemonic)")
        }
        .foregroundStyle(.white)
        .heroCard(fill: theme.accentFill)
    }

    /// A 200pt practice square that shrinks only when the card is narrower than that.
    /// It is a display glyph, so it does not grow with Dynamic Type.
    private var practiceSquare: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 200)
            .overlay {
                GeometryReader { proxy in
                    PracticeSquare(text: entry.character, side: proxy.size.width, style: .onFill)
                }
            }
    }

    // MARK: - Sections

    private func section<Content: View>(
        _ title: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, detail: detail)
            content()
                .contentCard(padding: 20)
        }
    }

    private var readings: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !entry.kunReading.isEmpty {
                readingRow("Kun reading (Japanese)", kana: entry.kunReading, romaji: entry.kunRomaji)
            }
            if !entry.kunReading.isEmpty && !entry.onReading.isEmpty {
                Divider()
            }
            if !entry.onReading.isEmpty {
                readingRow("On reading (from Chinese)", kana: entry.onReading, romaji: entry.onRomaji)
            }

            Text("Kun readings are common when a kanji stands alone, on readings in compounds. The words below show which reading each word uses.")
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func readingRow(_ label: String, kana: String, romaji: String) -> some View {
        // At accessibility sizes the romaji moves under the kana instead of squeezing beside it.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 10))

        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.inkSecondary)

            layout {
                Text(kana)
                    .font(.title3)
                    .japanese()

                Text(romaji)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(entry.words.enumerated()), id: \.element.id) { index, word in
                if index > 0 {
                    Divider()
                }
                wordRow(word)
            }
        }
    }

    private func wordRow(_ word: KanjiWord) -> some View {
        // At accessibility sizes the speaker button moves under the text.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        return layout {
            VStack(alignment: .leading, spacing: 3) {
                Text(word.word)
                    .font(.title2)
                    .japanese()

                Text("\(Text(word.reading).fontDesign(.default)) · \(word.romaji)")
                    .font(.subheadline)
                    .foregroundStyle(theme.accent)

                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)

            SpeakButton(label: "Listen to \(word.reading)") {
                onSpeak(word.spokenText)
            }
        }
    }
}

/// English with kanji inside it: the kanji and kana runs get the standard face, so learners see the
/// real shapes, while the English around them stays rounded like the rest of the app.
private func storyText(_ string: String) -> Text {
    var result = Text(verbatim: "")
    var run = ""
    var runIsJapanese = false

    func appendRun() {
        guard !run.isEmpty else { return }
        let piece = runIsJapanese ? Text(verbatim: run).fontDesign(.default) : Text(verbatim: run)
        result = Text("\(result)\(piece)")
        run = ""
    }

    for character in string {
        let isJapanese = character.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3000...0x30FF,   // Japanese punctuation, hiragana, katakana
                 0x3400...0x4DBF,   // kanji extension A
                 0x4E00...0x9FFF,   // kanji
                 0xFF00...0xFFEF:   // full-width forms
                return true
            default:
                return false
            }
        }
        if isJapanese != runIsJapanese {
            appendRun()
            runIsJapanese = isJapanese
        }
        run.append(character)
    }
    appendRun()
    return result
}
