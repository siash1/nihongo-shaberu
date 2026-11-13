import SwiftUI
import UIKit

/// Talk tab: a spoken conversation with the Japanese tutor. Speak or type, and every reply comes
/// back in Japanese with romaji and an English translation, read out loud.
struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.openURL) private var openURL

    /// Type mode: the control row holds a text field instead of the big microphone.
    @State private var isTyping = false
    /// Set once the permission request has finished, because `permissionsGranted` starts out false.
    @State private var didAskPermission = false
    /// Bumped on the tap that starts a recording, so the haptic lands with the tap.
    @State private var recordingStarts = 0
    /// The reply being read out loud: the newest one, or the one whose speaker was tapped.
    @State private var speakingReplyID: UUID?
    /// Inner width of the greeting card, used to size its practice squares.
    @State private var greetingWidth: CGFloat = 304
    /// Set by the keyboard button so the field takes focus once when it appears, and not again
    /// every time the Talk tab is reopened.
    @State private var focusFieldOnAppear = false
    @FocusState private var isFieldFocused: Bool
    @Namespace private var glass

    private static let thinkingID = "thinking"

    var body: some View {
        ZStack {
            if showsConversation {
                conversation
                    .transition(.opacity)
            } else {
                welcome
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(motion, value: showsConversation)
        .appBackground(.browse)
        .navigationTitle("Talk")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaBar(edge: .bottom) { controlBar }
        .sensoryFeedback(.impact(weight: .medium), trigger: recordingStarts)
        .task {
            await viewModel.requestPermissions()
            didAskPermission = true
        }
    }

    // MARK: - State helpers

    /// The conversation replaces the welcome as soon as something was said, including while a
    /// spoken message is still being processed (it only appears in the list with the reply).
    private var showsConversation: Bool {
        !viewModel.messages.isEmpty || viewModel.isProcessing
    }

    private var showsMicrophoneOff: Bool {
        didAskPermission && !viewModel.permissionsGranted
    }

    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    private var motion: Animation {
        reduceMotion ? .appFade : .appSmooth
    }

    private var micHint: String {
        if viewModel.isRecording { return "" }
        if showsMicrophoneOff { return "Microphone access is off. Allow it in Settings, or type instead." }
        return "Records what you say and sends it to your tutor"
    }

    private var canSendTypedMessage: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isProcessing
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !viewModel.messages.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Button("Clear") {
                    viewModel.clearChat()
                }
                .accessibilityLabel("Clear conversation")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Level", selection: $viewModel.selectedLevel) {
                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                        Text(level.rawValue)
                            .tag(level)
                    }
                }
            } label: {
                Text("Level \(viewModel.selectedLevel.rawValue)")
            }
            // The spoken name starts with the visible word, so Voice Control's "Tap Level" works.
            .accessibilityLabel("Level")
            .accessibilityValue(viewModel.selectedLevel.rawValue)
            .accessibilityHint("Sets how hard your tutor's Japanese is")
        }
    }

    // MARK: - Welcome

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.cards) {
                ScreenSubtitle(text: "Speak out loud with your Japanese tutor.")

                if isCompactHeight {
                    // Landscape: the greeting on the leading half, the suggestions on the trailing half.
                    HStack(alignment: .top, spacing: Spacing.margin) {
                        greetingCard
                        VStack(alignment: .leading, spacing: Spacing.cards) {
                            if showsMicrophoneOff {
                                microphoneOffCard
                                    .padding(.bottom, Spacing.section - Spacing.cards)
                            }
                            suggestionsHeader
                            suggestionGrid
                        }
                    }
                } else {
                    greetingCard
                    if showsMicrophoneOff {
                        microphoneOffCard
                    }
                    suggestionsHeader
                        .padding(.top, Spacing.section - Spacing.cards)
                    suggestionGrid
                }
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.margin)
            .padding(.top, 4)
            .padding(.bottom, Spacing.margin)
            .animation(motion, value: showsMicrophoneOff)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollDismissesKeyboard(.interactively)
    }

    /// Shows the reply format by example: Japanese, romaji, English.
    private var greetingCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                PracticeSquareWord(word: "こんにちは", width: greetingWidth, maxSide: 56, perRow: 5)
                    .padding(.bottom, 10)
                Text("konnichiwa")
                    .font(.title2.bold())
                    .foregroundStyle(theme.accent)
                Text("Hello")
                    .font(.title3)
                    .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityElement(children: .combine)

            Divider()

            Text("Tap the microphone and speak in English or Japanese. Your tutor answers out loud, with romaji and a translation.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            greetingWidth = width
        }
        .heroCard()
    }

    private var microphoneOffCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                IconCircle(systemImage: "mic.slash.fill")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Microphone is off")
                        .font(.headline)
                    Text("Allow microphone access in Settings to talk. You can still type.")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)

            Button("Open Settings", action: openSettings)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(theme.accent)
        }
        .contentCard(padding: 20)
        .transition(.opacity)
    }

    private var suggestionsHeader: some View {
        Text("Try saying")
            .font(.title3.bold())
            .accessibilityAddTraits(.isHeader)
    }

    private var suggestionGrid: some View {
        let perRow = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        let starts = Array(stride(from: 0, to: Suggestion.all.count, by: perRow))
        return Grid(horizontalSpacing: Spacing.cards, verticalSpacing: Spacing.cards) {
            ForEach(starts, id: \.self) { start in
                GridRow {
                    ForEach(Suggestion.all[start..<min(start + perRow, Suggestion.all.count)]) { suggestion in
                        SuggestionTile(suggestion: suggestion) {
                            viewModel.sendMessage(suggestion.text)
                        }
                    }
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    // MARK: - Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                            .id(message.id)
                            .transition(arrival)
                    }

                    if viewModel.isProcessing {
                        ThinkingCard(animates: !reduceMotion)
                            .id(Self.thinkingID)
                            .transition(arrival)
                    }
                }
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.margin)
                .padding(.top, 8)
                .padding(.bottom, Spacing.margin)
                .animation(motion, value: viewModel.messages.count)
                .animation(motion, value: viewModel.isProcessing)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .onChange(of: viewModel.messages.count) {
                // A new reply is read out loud straight away, so its speaker is the one to animate.
                // A learner message does not move it: a replayed reply may still be playing.
                if let newest = viewModel.messages.last, !newest.isUser {
                    speakingReplyID = newest.id
                }
                scrollToNewest(proxy)
            }
            .onChange(of: viewModel.isProcessing) {
                guard viewModel.isProcessing else { return }
                withAnimation(reduceMotion ? nil : .appSmooth) {
                    proxy.scrollTo(Self.thinkingID, anchor: .bottom)
                }
            }
            .onChange(of: isFieldFocused) {
                guard isFieldFocused else { return }
                scrollToNewest(proxy)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        if message.isUser {
            LearnerBubble(text: message.text)
        } else {
            TutorReplyCard(
                message: message,
                isSpeaking: viewModel.isSpeaking && speakingReplyID == message.id,
                animatesSpeaker: !reduceMotion
            ) {
                speakingReplyID = message.id
                viewModel.replayMessage(message)
            }
        }
    }

    /// New messages fade in and rise 12pt; with Reduce Motion they only fade.
    private var arrival: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .opacity.combined(with: .offset(y: 12)), removal: .opacity)
    }

    private func scrollToNewest(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        // A reply can be taller than the screen: land on its first line, the Japanese, not its end.
        let anchor: UnitPoint = last.isUser ? .bottom : .top
        withAnimation(reduceMotion ? nil : .appSmooth) {
            proxy.scrollTo(last.id, anchor: anchor)
        }
    }

    // MARK: - Controls

    private var controlBar: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .transition(.opacity)
            }

            GlassEffectContainer(spacing: 8) {
                if isCompactHeight {
                    HStack(spacing: 16) {
                        if !isTyping {
                            statusLine
                        }
                        controlRow
                    }
                } else {
                    VStack(spacing: 10) {
                        statusLine
                        controlRow
                    }
                }
            }
        }
        .frame(maxWidth: 640)
        .padding(.horizontal, Spacing.margin)
        .padding(.bottom, 8)
        .animation(motion, value: viewModel.errorMessage)
    }

    private var statusText: String {
        if viewModel.isRecording { return "Listening… tap to send" }
        if viewModel.isProcessing { return "Thinking…" }
        if viewModel.isSpeaking { return "Speaking…" }
        if showsMicrophoneOff { return "Microphone is off" }
        if isTyping { return "Type in English or Japanese" }
        return "Tap to speak"
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            if viewModel.isRecording {
                Circle()
                    .fill(Color.wrong)
                    .frame(width: 8, height: 8)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
            Text(statusText)
                .contentTransition(.opacity)
        }
        .font(.subheadline)
        .foregroundStyle(.primary.opacity(0.72))
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
        .multilineTextAlignment(isCompactHeight ? .leading : .center)
        .frame(maxWidth: .infinity, alignment: isCompactHeight ? .leading : .center)
        .animation(.appQuick, value: statusText)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var controlRow: some View {
        if isTyping {
            typeRow
        } else {
            voiceRow
        }
    }

    /// Keyboard, microphone, stop speaking. The empty slot keeps the microphone centred.
    private var voiceRow: some View {
        let side: CGFloat = isCompactHeight ? 44 : 52
        let micSide: CGFloat = isCompactHeight ? 56 : 76

        return HStack(spacing: isCompactHeight ? 16 : 28) {
            glassCircle(systemImage: "keyboard.fill", label: "Type a message", side: side, action: showTypeMode)
                .glassEffectID(morphID("input"), in: glass)
                // Type mode hides the microphone, so a recording could not be stopped or sent there.
                .disabled(viewModel.isRecording)

            Button(action: toggleListening) {
                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: isCompactHeight ? 24 : 30, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(viewModel.isRecording ? Color.wrongFill : theme.accentFill)
            .frame(width: micSide, height: micSide)
            .glassEffectID(morphID("mic"), in: glass)
            .disabled(viewModel.isProcessing || !viewModel.permissionsGranted)
            .animation(.appQuick, value: viewModel.isRecording)
            .accessibilityLabel(viewModel.isRecording ? "Stop and send" : "Speak")
            .accessibilityHint(micHint)

            if viewModel.isSpeaking {
                stopSpeakingButton(side: side)
            } else {
                Color.clear
                    .frame(width: side, height: side)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(motion, value: viewModel.isSpeaking)
    }

    /// Back-to-voice microphone, the message field and Send (plus stop speaking while a reply is read).
    private var typeRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            glassCircle(systemImage: "mic.fill", label: "Speak instead", side: 44, action: showVoiceMode)
                .glassEffectID(morphID("mic"), in: glass)

            TextField("Type a message", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...3)
                .font(.body)
                // Typed Japanese shows in the standard face, as it will in the sent bubble.
                .fontDesign(viewModel.inputText.textDesign)
                .focused($isFieldFocused)
                .onSubmit {
                    viewModel.sendTypedMessage()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22, style: .continuous))
                .glassEffectID(morphID("input"), in: glass)
                .onAppear {
                    guard focusFieldOnAppear else { return }
                    focusFieldOnAppear = false
                    isFieldFocused = true
                }

            if viewModel.isSpeaking {
                stopSpeakingButton(side: 44)
            }

            Button {
                viewModel.sendTypedMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(theme.accentFill)
            .frame(width: 44, height: 44)
            .glassEffectID(morphID("send"), in: glass)
            .disabled(!canSendTypedMessage)
            .accessibilityLabel("Send")
        }
        .animation(motion, value: viewModel.isSpeaking)
    }

    private func stopSpeakingButton(side: CGFloat) -> some View {
        glassCircle(systemImage: "speaker.slash.fill", label: "Stop speaking", side: side) {
            viewModel.stopSpeaking()
        }
        .glassEffectID(morphID("stop"), in: glass)
        .glassEffectTransition(.materialize)
        .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
    }

    /// Glass shapes morph between voice and type mode; with Reduce Motion they cross-fade instead.
    private func morphID(_ id: String) -> String? {
        reduceMotion ? nil : id
    }

    /// A round glass button with an accent symbol (keyboard, stop speaking, back to voice).
    private func glassCircle(systemImage: String, label: String, side: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: side * 0.36, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(width: side, height: side)
        .accessibilityLabel(label)
    }

    // MARK: - Actions

    private func toggleListening() {
        if !viewModel.isRecording {
            recordingStarts += 1
        }
        viewModel.toggleListening()
    }

    private func showTypeMode() {
        focusFieldOnAppear = true
        withAnimation(motion) {
            isTyping = true
        }
    }

    private func showVoiceMode() {
        isFieldFocused = false
        withAnimation(motion) {
            isTyping = false
        }
    }
}

// MARK: - Suggestions

private struct Suggestion: Identifiable {
    let text: String
    let systemImage: String

    var id: String { text }

    static let all = [
        Suggestion(text: "Say hello", systemImage: "hand.wave.fill"),
        Suggestion(text: "Introduce myself", systemImage: "person.fill"),
        Suggestion(text: "Order food", systemImage: "fork.knife"),
        Suggestion(text: "Daily phrases", systemImage: "sun.max.fill"),
    ]
}

/// A suggestion the learner can send with one tap.
private struct SuggestionTile: View {
    let suggestion: Suggestion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                IconCircle(systemImage: suggestion.systemImage, size: 36)
                Text(suggestion.text)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: .infinity, alignment: .topLeading)
            .modifier(TileSurface())
            .contentShape(.rect(cornerRadius: Radius.choice, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .accessibilityHint("Sends this to your tutor")
    }
}

/// Solid tile surface at the choice radius, with the content card's shadow, rim and contrast border.
private struct TileSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.choice, style: .continuous)
        content
            .background {
                shape
                    .fill(Color.cardFill)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 4)
            }
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
    }

    private var borderColor: Color {
        if contrast == .increased { return .primary.opacity(0.4) }
        return colorScheme == .dark ? .white.opacity(0.08) : .clear
    }
}

// MARK: - Messages

/// What the learner said or typed: a solid bubble at the trailing edge.
private struct LearnerBubble: View {
    let text: String
    @Environment(\.appTheme) private var theme

    var body: some View {
        TrailingFractionLayout(fraction: 0.8) {
            Text(text)
                .font(.body)
                .fontDesign(text.textDesign)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.accentFill, in: .rect(cornerRadius: 22, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("You: \(text)")
    }
}

/// A tutor reply: each sentence as Japanese, romaji and English, with a speaker at the top.
private struct TutorReplyCard: View {
    let message: ChatMessage
    let isSpeaking: Bool
    let animatesSpeaker: Bool
    let onReplay: () -> Void

    var body: some View {
        let sentences = Self.parseResponse(message.text)
        VStack(alignment: .leading, spacing: 16) {
            if sentences.isEmpty {
                // The reply did not follow the Japanese / Romaji / English format: show it as written.
                HStack(alignment: .top, spacing: 12) {
                    Text(LocalizedStringKey(message.text))
                        .font(.body)
                        .fontDesign(message.text.textDesign)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    speakButton
                }
            } else {
                ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                    if index > 0 {
                        Divider()
                    }
                    if index == 0 {
                        HStack(alignment: .top, spacing: 12) {
                            SentenceView(sentence: sentence)
                            speakButton
                        }
                    } else {
                        SentenceView(sentence: sentence)
                    }
                }

                // Notes around the sentences (corrections, explanations).
                let extra = Self.extractExtraText(message.text)
                if !extra.isEmpty {
                    Divider()
                    Text(extra)
                        .font(.footnote)
                        .fontDesign(extra.textDesign)
                        .foregroundStyle(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .contentCard(padding: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tutor")
    }

    private var speakButton: some View {
        SpeakButton(label: "Play reply", action: onReplay)
            .symbolEffect(.variableColor.iterative, isActive: isSpeaking && animatesSpeaker)
            .accessibilityValue(isSpeaking ? "Speaking" : "")
    }

    struct ParsedSection {
        let japanese: String
        let romaji: String
        let english: String
    }

    static func parseResponse(_ text: String) -> [ParsedSection] {
        var sections: [ParsedSection] = []
        let lines = text.components(separatedBy: "\n")
        var japanese: String?
        var romaji: String?

        for line in lines {
            let stripped = line.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
            if stripped.hasPrefix("Japanese:") {
                japanese = stripped.replacingOccurrences(of: "Japanese:", with: "").trimmingCharacters(in: .whitespaces)
            } else if stripped.hasPrefix("Romaji:") {
                romaji = stripped.replacingOccurrences(of: "Romaji:", with: "").trimmingCharacters(in: .whitespaces)
            } else if stripped.hasPrefix("English:") {
                let english = stripped.replacingOccurrences(of: "English:", with: "").trimmingCharacters(in: .whitespaces)
                if let j = japanese {
                    sections.append(ParsedSection(japanese: j, romaji: romaji ?? "", english: english))
                    japanese = nil
                    romaji = nil
                }
            }
        }
        return sections
    }

    static func extractExtraText(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        let extras = lines.filter { line in
            let stripped = line.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
            return !stripped.isEmpty
                && !stripped.hasPrefix("Japanese:")
                && !stripped.hasPrefix("Romaji:")
                && !stripped.hasPrefix("English:")
        }
        return extras.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}

/// One sentence of a reply. The Japanese line is the largest text on the screen.
private struct SentenceView: View {
    let sentence: TutorReplyCard.ParsedSection
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sentence.japanese)
                .font(.title.weight(.semibold))
                .japanese()
                .lineSpacing(6)
            if !sentence.romaji.isEmpty {
                Text(sentence.romaji)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(theme.accent)
            }
            Text(sentence.english)
                .font(.callout)
                .foregroundStyle(Color.inkSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Shown while the tutor is working on a reply.
private struct ThinkingCard: View {
    let animates: Bool
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "ellipsis")
                .font(.body.weight(.bold))
                .foregroundStyle(theme.accent)
                .symbolEffect(.variableColor.iterative, isActive: animates)
                .accessibilityHidden(true)
            Text("Thinking…")
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentCard(padding: 0)
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Layout and text helpers

/// Places its one child at the trailing edge, at most `fraction` of the available width wide.
private struct TrailingFractionLayout: Layout {
    var fraction: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let size = child.sizeThatFits(childProposal(width: proposal.width))
        return CGSize(width: proposal.width ?? size.width, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        child.place(
            at: CGPoint(x: bounds.maxX, y: bounds.minY),
            anchor: .topTrailing,
            proposal: childProposal(width: bounds.width)
        )
    }

    private func childProposal(width: CGFloat?) -> ProposedViewSize {
        ProposedViewSize(width: width.map { $0 * fraction }, height: nil)
    }
}

private extension String {
    /// Kana and kanji keep the standard (unrounded) letter shapes; Latin-only text stays rounded.
    var textDesign: Font.Design {
        let hasJapanese = unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3000...0x30FF,   // Japanese punctuation, hiragana, katakana
                 0x3400...0x4DBF,   // CJK extension A
                 0x4E00...0x9FFF,   // CJK unified ideographs
                 0xFF66...0xFF9F:   // half-width katakana
                return true
            default:
                return false
            }
        }
        return hasJapanese ? .default : .rounded
    }
}

#Preview {
    NavigationStack {
        ChatView(viewModel: ChatViewModel())
    }
    .environment(\.appTheme, AppTab.talk.theme)
    .fontDesign(.rounded)
}
