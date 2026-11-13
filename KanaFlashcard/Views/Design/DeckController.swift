import SwiftUI
import Observation

/// A card that has been graded and is flying off the screen. It ignores touches.
struct FlyingCard<Item>: Identifiable {
    let id: Int
    let item: Item
    let showsBack: Bool
    let motion: CardMotion
    let grabSign: Double
    let isCorrect: Bool
    let start: Date
}

/// State and gesture handling for the flashcard deck, shared by the deck and its button bar.
/// The view models are not changed: the deck only calls reveal and grade.
@Observable
final class DeckController<Item> {
    // MARK: Wiring (set by the screen in onAppear)

    var onReveal: () -> Void = {}
    var onGrade: (Bool) -> Void = { _ in }

    // MARK: Geometry (set by the deck view)

    var deckWidth: CGFloat = 390
    var cardHeight: CGFloat = 480
    var reduceMotion = false

    // MARK: State read by the views

    /// Increases with every graded card; cards are keyed on it, never on the item's id,
    /// because a missed last card comes straight back as "the same" card.
    private(set) var dealID = 0
    private(set) var isFlipped = false
    private(set) var motion: CardMotion = .still(.zero)
    private(set) var flying: [FlyingCard<Item>] = []
    private(set) var isPressed = false
    /// +1 when the card was grabbed in its top half, −1 in the bottom half: it swings from where it is held.
    private(set) var grabSign: Double = 1
    /// 0...1, how close a held card is to being thrown. Drives the buttons' emphasis.
    private(set) var dragProgress: CGFloat = 0
    /// +1 while a held card leans right (Correct), −1 left (Wrong), 0 otherwise.
    private(set) var dragDirection: CGFloat = 0

    // Haptic and hint triggers: each changes on the same update as the visual it belongs to.
    private(set) var flipCount = 0
    private(set) var commitCount = 0
    private(set) var lastCommitWasCorrect = true
    private(set) var pastThreshold = false
    private(set) var blockedSwipeCount = 0

    var isAnimating: Bool {
        motion.isMoving || !flying.isEmpty
    }

    // MARK: Private

    private struct Touch {
        let id: Int
        let base: CGSize
        var slopOffset: CGSize?
    }

    private var touch: Touch?
    private var touchCounter = 0
    private var generation = 0

    var activeTouchID: Int? { touch?.id }

    // MARK: Flip

    func flip(isRevealed: Bool) {
        flipCount += 1
        withAnimation(reduceMotion ? .appFade : .appFlip) {
            isFlipped.toggle()
        }
        if isFlipped && !isRevealed {
            onReveal()
        }
    }

    // MARK: Touches

    func touchChanged(startLocation: CGPoint, translation: CGSize, cardCenterY: CGFloat, canGrade: Bool) {
        let now = Date()

        if touch == nil {
            // Touch down: catch the card exactly where it is on screen, even mid-flight.
            let current = motion.offset(at: now)
            generation += 1
            motion = .still(current)
            touchCounter += 1
            touch = Touch(id: touchCounter, base: current, slopOffset: nil)
            grabSign = startLocation.y < cardCenterY + current.height ? 1 : -1
            withAnimation(.appPress) { isPressed = true }
        }

        guard var active = touch else { return }

        if active.slopOffset == nil {
            guard hypot(translation.width, translation.height) >= DeckPhysics.slop else { return }
            // Start tracking from here so the card does not jump by the slop distance.
            active.slopOffset = translation
            touch = active
        }

        let slop = active.slopOffset ?? .zero
        let dx = translation.width - slop.width
        let dy = translation.height - slop.height

        // Horizontal follows the finger 1:1 once the answer is shown; before that it resists.
        let x = canGrade
            ? active.base.width + dx
            : active.base.width + DeckPhysics.rubberband(dx, dimension: 120)
        // Vertical always resists: the card is not meant to move up or down.
        let y = active.base.height + DeckPhysics.rubberband(dy, dimension: cardHeight)
        motion = .still(CGSize(width: x, height: y))

        dragProgress = canGrade ? min(abs(x) / DeckPhysics.commitDistance, 1) : 0
        dragDirection = canGrade && x != 0 ? (x > 0 ? 1 : -1) : 0
        let past = canGrade && abs(x) >= DeckPhysics.commitDistance
        if past != pastThreshold {
            pastThreshold = past
        }
    }

    /// Release. A touch that never moved past the slop is a tap and flips the card.
    func touchEnded(item: Item?, velocity: CGSize, isRevealed: Bool) {
        guard let active = touch else { return }
        touch = nil
        withAnimation(.appPress) { isPressed = false }
        resetDrag()

        guard active.slopOffset != nil else {
            // A tap. If it caught the card mid-way back, let it finish going back.
            snapBack(velocity: .zero)
            flip(isRevealed: isRevealed)
            return
        }

        let offset = motion.offset(at: Date())
        switch DeckPhysics.decide(offset: offset.width, velocity: velocity.width, canGrade: isRevealed) {
        case .correct:
            if let item { commit(item: item, correct: true, velocity: velocity, fromSwipe: true) }
        case .wrong:
            if let item { commit(item: item, correct: false, velocity: velocity, fromSwipe: true) }
        case .cancel:
            if !isRevealed { blockedSwipeCount += 1 }
            snapBack(velocity: velocity, horizontalShare: isRevealed ? 1 : 0.3)
        }
    }

    /// The system cancelled the touch (alert, call, app switch): put the card back.
    func cancelTouch(id: Int) {
        guard touch?.id == id else { return }
        touch = nil
        withAnimation(.appPress) { isPressed = false }
        resetDrag()
        snapBack(velocity: .zero)
    }

    // MARK: Grading

    /// Throws the card off to the right (correct) or left (wrong). Buttons call this too,
    /// so they produce exactly the same motion as a swipe.
    func commit(item: Item, correct: Bool, velocity: CGSize? = nil, fromSwipe: Bool = false) {
        let now = Date()
        let offset = motion.offset(at: now)
        let releaseVelocity = velocity ?? motion.velocity(at: now)

        if touch != nil {
            touch = nil
            withAnimation(.appPress) { isPressed = false }
        }
        resetDrag()

        let direction: CGFloat = correct ? 1 : -1
        let target = CGSize(
            width: direction * (deckWidth + 100),
            height: offset.height + min(max(DeckPhysics.project(releaseVelocity.height), -160), 160)
        )
        // With Reduce Motion the card fades out where it is instead of flying.
        let flight: CardMotion = reduceMotion
            ? .still(offset)
            : .spring(from: offset, to: target, velocity: releaseVelocity,
                      spring: Spring(response: 0.4, dampingRatio: 1), at: now)

        let card = FlyingCard(
            id: dealID, item: item, showsBack: isFlipped, motion: flight,
            grabSign: grabSign, isCorrect: correct, start: now
        )
        flying.append(card)
        commitCount += 1
        lastCommitWasCorrect = correct

        generation += 1
        motion = .still(.zero)

        // The next card rises from the pile on the same frame. A little bounce only after a throw.
        let promotion: Animation = reduceMotion
            ? .appFade
            : .spring(response: 0.35, dampingFraction: fromSwipe ? 0.8 : 1)
        withAnimation(promotion) {
            dealID += 1
            isFlipped = false
            onGrade(correct)
        }

        let id = card.id
        let lifetime = reduceMotion ? 0.3 : 0.6
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(lifetime))
            self?.flying.removeAll { $0.id == id }
        }
    }

    /// Starts a new session (the screen calls this when it appears).
    func reset() {
        generation += 1
        touch = nil
        motion = .still(.zero)
        flying = []
        isFlipped = false
        isPressed = false
        resetDrag()
        dealID += 1
    }

    // MARK: Helpers

    /// Springs the card back to the centre, carrying on at the finger's speed.
    /// `horizontalShare` scales the hand-over where the card was resisting the finger instead of following it.
    private func snapBack(velocity: CGSize, horizontalShare: CGFloat = 1) {
        let now = Date()
        let offset = motion.offset(at: now)
        guard abs(offset.width) > 0.5 || abs(offset.height) > 0.5 else {
            motion = .still(.zero)
            return
        }
        let spring = reduceMotion ? Spring(response: 0.25, dampingRatio: 1) : Spring(response: 0.4, dampingRatio: 0.8)
        let handoff = CGSize(width: velocity.width * horizontalShare, height: velocity.height * 0.3)
        motion = .spring(from: offset, to: .zero, velocity: handoff, spring: spring, at: now)

        generation += 1
        let current = generation
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(spring.settlingDuration))
            guard let self, self.generation == current else { return }
            self.motion = .still(.zero)
        }
    }

    private func resetDrag() {
        if dragProgress != 0 {
            withAnimation(.appSmooth) { dragProgress = 0 }
        }
        dragDirection = 0
        if pastThreshold { pastThreshold = false }
    }

    #if DEBUG
    /// Places the top card as if it were being held, for screenshots during development.
    func debugHold(x: CGFloat, flipped: Bool) {
        isFlipped = flipped
        motion = .still(CGSize(width: x, height: 0))
        dragProgress = min(abs(x) / DeckPhysics.commitDistance, 1)
        dragDirection = x == 0 ? 0 : (x > 0 ? 1 : -1)
    }
    #endif
}
