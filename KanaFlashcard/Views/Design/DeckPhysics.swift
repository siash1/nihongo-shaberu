import SwiftUI

// The maths behind the flashcard deck, kept free of views so it can be tested on its own.
// Values follow Apple's "Designing Fluid Interfaces" (via the apple-design skill).

enum DeckPhysics {
    /// A card counts as thrown once its projected resting point is this far from the centre.
    static let commitDistance: CGFloat = 120
    /// The card must already lean this far to the committing side, so a sloppy tap never grades it.
    static let minimumLean: CGFloat = 24
    /// Movement before a touch becomes a drag instead of a tap.
    static let slop: CGFloat = 10
    /// Scroll-like deceleration used to project where a flick would come to rest.
    static let decelerationRate: CGFloat = 0.998

    /// How far a flick carries the card after release: v / 1000 × d / (1 − d), about 0.5 × v.
    static func project(_ velocity: CGFloat) -> CGFloat {
        (velocity / 1000) * decelerationRate / (1 - decelerationRate)
    }

    /// Progressive resistance: the further past the boundary, the less the card follows.
    static func rubberband(_ overshoot: CGFloat, dimension: CGFloat, constant: CGFloat = 0.55) -> CGFloat {
        guard dimension > 0 else { return 0 }
        return (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
    }

    enum Decision: Equatable {
        case correct, wrong, cancel
    }

    /// Decides what a released card does, from where it is and how fast it is moving.
    static func decide(offset: CGFloat, velocity: CGFloat, canGrade: Bool) -> Decision {
        guard canGrade else { return .cancel }
        // Moving back towards the centre: the learner changed their mind. Velocity beats position.
        if (offset > 0 && velocity < -100) || (offset < 0 && velocity > 100) {
            return .cancel
        }
        let projected = offset + project(velocity)
        if projected >= commitDistance && offset >= minimumLean { return .correct }
        if projected <= -commitDistance && offset <= -minimumLean { return .wrong }
        return .cancel
    }
}

/// One axis of a spring animation, evaluated in closed form so the card's exact on-screen
/// position and velocity are known at any moment (needed to catch it mid-flight).
struct AxisSpring {
    var from: Double
    var to: Double
    /// Points per second.
    var initialVelocity: Double
    var start: Date
    var spring: Spring

    func value(at date: Date) -> Double {
        from + spring.value(target: to - from, initialVelocity: initialVelocity, time: elapsed(at: date))
    }

    func velocity(at date: Date) -> Double {
        spring.velocity(target: to - from, initialVelocity: initialVelocity, time: elapsed(at: date))
    }

    private func elapsed(at date: Date) -> TimeInterval {
        max(0, date.timeIntervalSince(start))
    }
}

/// Where a card is: held still (resting or under the finger) or moving on two independent springs.
enum CardMotion {
    case still(CGSize)
    case moving(x: AxisSpring, y: AxisSpring)

    func offset(at date: Date) -> CGSize {
        switch self {
        case .still(let offset):
            return offset
        case .moving(let x, let y):
            return CGSize(width: x.value(at: date), height: y.value(at: date))
        }
    }

    func velocity(at date: Date) -> CGSize {
        switch self {
        case .still:
            return .zero
        case .moving(let x, let y):
            return CGSize(width: x.velocity(at: date), height: y.velocity(at: date))
        }
    }

    var isMoving: Bool {
        if case .moving = self { return true }
        return false
    }

    static func spring(from: CGSize, to: CGSize, velocity: CGSize, spring: Spring, at date: Date) -> CardMotion {
        .moving(
            x: AxisSpring(from: from.width, to: to.width, initialVelocity: velocity.width, start: date, spring: spring),
            y: AxisSpring(from: from.height, to: to.height, initialVelocity: velocity.height, start: date, spring: spring)
        )
    }
}
