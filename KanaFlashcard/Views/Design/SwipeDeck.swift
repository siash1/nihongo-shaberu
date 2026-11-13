import SwiftUI

/// A pile of flashcards: tap to flip, then throw right for Correct or left for Wrong.
/// Used by the Practice and Words tabs. The buttons in `DeckActionBar` do the same things.
struct SwipeDeck<Item, Front: View, Back: View>: View {
    let controller: DeckController<Item>
    /// The card on top, or nil when the session is over.
    let item: Item?
    /// Cards left, including the one on top.
    let remaining: Int
    let isRevealed: Bool
    let accessibilityLabel: (Item) -> String
    let accessibilityAnswer: (Item) -> String
    @ViewBuilder let front: (Item) -> Front
    @ViewBuilder let back: (Item) -> Back

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @GestureState private var isTouching = false
    @State private var dealt = false
    @AccessibilityFocusState private var cardFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cardWidth = min(size.width - 48, 400)
            let cardHeight = max(200, min(cardWidth * 1.3, size.height - 40))
            let card = CGSize(width: cardWidth, height: cardHeight)

            TimelineView(.animation(paused: !controller.isAnimating)) { context in
                let now = context.date
                let topOffset = controller.motion.offset(at: now)
                let progress = isRevealed && !reduceMotion ? min(abs(topOffset.width) / DeckPhysics.commitDistance, 1) : 0
                let underCount = max(0, min(2, remaining - 1))

                ZStack {
                    // Cards in the pile, back to front, keyed by deal number: when the top card is
                    // thrown, the card behind keeps its identity and its pose animates up into place.
                    ForEach(Array((controller.dealID...controller.dealID + underCount).reversed()), id: \.self) { deal in
                        let depth = deal - controller.dealID
                        // While a card is held towards a side, the pile already leans into its next pose.
                        let pose = depth == 0 ? 0 : Double(depth) - 0.5 * progress
                        Group {
                            if depth == 0, let item {
                                topCard(item, card: card, offset: topOffset, cardCenterY: size.height / 2 - 12)
                            } else if depth > 0 {
                                pileCard(depth: pose, card: card)
                            }
                        }
                        .scaleEffect(reduceMotion ? 1 : 1 - 0.06 * pose, anchor: .bottom)
                        .offset(y: 12 * pose)
                        .zIndex(Double(-depth))
                        .offset(y: dealt || reduceMotion ? 0 : 40)
                        .opacity(dealt ? 1 : 0)
                        .animation(reduceMotion ? .appFade : .appSmooth.delay(Double(underCount - depth) * 0.05), value: dealt)
                        // The thrown card is drawn by its flying copy, so its slot vanishes instantly.
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    }

                    ForEach(controller.flying) { flyingCard in
                        thrownCard(flyingCard, card: card, now: now)
                            .zIndex(10)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
            .coordinateSpace(.named("deck"))
            .onAppear {
                controller.deckWidth = size.width
                controller.cardHeight = card.height
                controller.reduceMotion = reduceMotion
                dealt = true
            }
            .onChange(of: size) { _, newSize in
                controller.deckWidth = newSize.width
            }
            .onChange(of: reduceMotion) { _, newValue in
                controller.reduceMotion = newValue
            }
        }
        .onChange(of: isTouching) { _, touching in
            // onEnded is not called when the system cancels a touch; put the card back then.
            guard !touching, let id = controller.activeTouchID else { return }
            DispatchQueue.main.async {
                controller.cancelTouch(id: id)
            }
        }
        .onChange(of: controller.dealID) { _, _ in
            // The graded card is gone; keep VoiceOver on the deck by moving to the new top card.
            guard item != nil else { return }
            DispatchQueue.main.async { cardFocused = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: controller.flipCount)
        // Tick only when a held card crosses the throw line, not when the line resets on release.
        .sensoryFeedback(.selection, trigger: controller.pastThreshold) { _, _ in
            controller.activeTouchID != nil
        }
        .sensoryFeedback(trigger: controller.commitCount) { _, _ in
            controller.lastCommitWasCorrect ? .success : .error
        }
    }

    // MARK: - Top card

    private func topCard(_ item: Item, card: CGSize, offset: CGSize, cardCenterY: CGFloat) -> some View {
        let rotation = reduceMotion ? 0 : min(max(offset.width / 20, -15), 15) * controller.grabSign

        return faces(item, card: card, showsBack: controller.isFlipped)
            .overlay { IntentOverlay(x: isRevealed ? offset.width : 0, strength: 1) }
            .contentShape(.rect(cornerRadius: Radius.hero))
            .scaleEffect(controller.isPressed && !reduceMotion ? 0.98 : 1)
            .rotationEffect(.degrees(rotation))
            .offset(x: offset.width, y: offset.height - 12)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("deck"))
                    .updating($isTouching) { _, state, _ in state = true }
                    .onChanged { value in
                        controller.touchChanged(
                            startLocation: value.startLocation,
                            translation: value.translation,
                            cardCenterY: cardCenterY,
                            canGrade: isRevealed
                        )
                    }
                    .onEnded { value in
                        controller.touchEnded(item: self.item, velocity: value.velocity, isRevealed: isRevealed)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(item))
            .accessibilityValue(isRevealed ? accessibilityAnswer(item) : "Answer hidden")
            .accessibilityHint(isRevealed ? "Use the actions to mark it correct or wrong" : "Double-tap to show the answer")
            .accessibilityAddTraits(.isButton)
            .accessibilityFocused($cardFocused)
            .accessibilityAction {
                let revealing = !controller.isFlipped
                controller.flip(isRevealed: isRevealed)
                if revealing {
                    AccessibilityNotification.Announcement(accessibilityAnswer(item)).post()
                }
            }
            .accessibilityActions {
                if isRevealed {
                    Button("Mark correct") { controller.commit(item: item, correct: true) }
                    Button("Mark wrong") { controller.commit(item: item, correct: false) }
                }
            }
    }

    private func faces(_ item: Item, card: CGSize, showsBack: Bool) -> some View {
        FlipCard(angle: showsBack ? 180 : 0, reduceMotion: reduceMotion) {
            CardFace(size: card, fill: .cardFill) {
                front(item)
            } footer: {
                Label("\(Press.verb) to flip", systemImage: Press.symbol)
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .foregroundStyle(Color.inkSecondary)
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : controller.blockedSwipeCount)
            }
        } back: {
            CardFace(size: card, fill: theme.accentFill) {
                back(item)
            } footer: {
                // Teaches the swipe directions on the card itself.
                HStack {
                    Label("Wrong", systemImage: "arrow.left")
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Correct")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                // A hint on a fixed-size card: it stops growing before the words break.
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Pile and thrown cards

    /// A blank card in the pile. Its depth pose (scale and drop) is applied by the slot around it.
    private func pileCard(depth: Double, card: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
        return shape
            .fill(Color.cardFill)
            .overlay { shape.fill(theme.accent.opacity(0.06 * depth)) }
            .overlay {
                shape.strokeBorder(contrast == .increased ? Color.primary.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .frame(width: card.width, height: card.height)
            .offset(y: -12)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func thrownCard(_ flying: FlyingCard<Item>, card: CGSize, now: Date) -> some View {
        let offset = flying.motion.offset(at: now)
        let rotation = reduceMotion ? 0 : min(max(offset.width / 20, -15), 15) * flying.grabSign
        let fade = reduceMotion ? max(0, 1 - now.timeIntervalSince(flying.start) / 0.25) : 1
        let direction: CGFloat = flying.isCorrect ? 1 : -1

        return faces(flying.item, card: card, showsBack: flying.showsBack)
            .overlay { IntentOverlay(x: direction * DeckPhysics.commitDistance, strength: 1) }
            .rotationEffect(.degrees(rotation))
            .offset(x: offset.width, y: offset.height - 12)
            .opacity(fade)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Card face

/// One side of a flashcard: content on top, a footer line at the bottom.
private struct CardFace<Content: View, Footer: View>: View {
    let size: CGSize
    let fill: Color
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 12) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer()
        }
        .padding(24)
        .frame(width: size.width, height: size.height)
        .background { HeroShape(fill: fill) }
    }
}

// MARK: - Swipe feedback

/// The coloured border and stamp that grow as a card is dragged towards a side.
private struct IntentOverlay: View {
    /// Horizontal offset of the card; positive is towards Correct.
    let x: CGFloat
    let strength: CGFloat

    var body: some View {
        let progress = min(abs(x) / DeckPhysics.commitDistance, 1) * strength
        let stamp = min(max((abs(x) - 24) / 96, 0), 1) * strength
        let isCorrect = x > 0
        let color = isCorrect ? Color.correctFill : Color.wrongFill
        let shape = RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)

        ZStack(alignment: isCorrect ? .topLeading : .topTrailing) {
            shape.fill(color.opacity(0.12 * progress))
            shape.strokeBorder(color.opacity(progress), lineWidth: 4)

            if x != 0 {
                HStack(spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                    Text(isCorrect ? "CORRECT" : "WRONG")
                }
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color, in: .rect(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white, lineWidth: 2)
                }
                .rotationEffect(.degrees(isCorrect ? -12 : 12))
                .scaleEffect(0.8 + 0.2 * stamp)
                .opacity(stamp)
                .padding(22)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Button bar

/// The bottom bar under a deck: "Show Answer", then Wrong and Correct, which throw the card
/// exactly like a swipe. Every gesture on the card also exists here.
struct DeckActionBar<Item>: View {
    let controller: DeckController<Item>
    let item: Item?
    let isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            if let item {
                if isRevealed {
                    // Side by side, matching the swipe directions; stacked when large text needs the width.
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 12))
                        : AnyLayout(HStackLayout(spacing: 12))
                    layout {
                        gradeButton(item, correct: false)
                        gradeButton(item, correct: true)
                    }
                    .transition(transition)
                } else {
                    PrimaryActionButton(title: "Show Answer") {
                        controller.flip(isRevealed: false)
                    }
                    .transition(transition)
                }
            }
        }
        .animation(reduceMotion ? .appFade : .appSmooth, value: isRevealed)
        // The Cards menu (Space, ←, →) drives the same actions as these buttons, only while the
        // deck is on screen: a deck left open under another tab must not catch keys.
        .focusedSceneValue(\.deckActions, isOnScreen ? commandActions : nil)
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
    }

    @State private var isOnScreen = false

    private var commandActions: DeckCommandActions? {
        guard let item else { return nil }
        if isRevealed {
            return DeckCommandActions(grade: { correct in controller.commit(item: item, correct: correct) })
        }
        return DeckCommandActions(showAnswer: { controller.flip(isRevealed: false) })
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    private func gradeButton(_ item: Item, correct: Bool) -> some View {
        // The button on the side the card is being dragged towards swells; the other fades.
        let towards = correct == (controller.dragDirection > 0)
        let emphasis = controller.dragProgress

        return Button {
            controller.commit(item: item, correct: correct)
        } label: {
            Label(correct ? "Correct" : "Wrong", systemImage: correct ? "checkmark" : "xmark")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(correct ? Color.correctFill : Color.wrongFill)
        .scaleEffect(reduceMotion ? 1 : (towards ? 1 + 0.06 * emphasis : 1))
        .opacity(towards || emphasis == 0 ? 1 : 1 - 0.5 * emphasis)
    }
}
