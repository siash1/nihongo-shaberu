import SwiftUI

/// Two faces of one card, turned around the vertical axis.
///
/// The angle is animatable, so the faces swap at exactly 90 degrees of the animation
/// (not on the first frame), and a tap mid-flip retargets the spring from where the card is.
/// With Reduce Motion the faces cross-fade instead of rotating.
struct FlipCard<Front: View, Back: View>: View, Animatable {
    /// 0 shows the front, 180 the back.
    var angle: Double
    var reduceMotion = false
    @ViewBuilder var front: () -> Front
    @ViewBuilder var back: () -> Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        if reduceMotion {
            let progress = min(max(angle / 180, 0), 1)
            ZStack {
                front().opacity(1 - progress)
                back().opacity(progress)
            }
        } else {
            let showingBack = angle >= 90
            ZStack {
                front()
                    .opacity(showingBack ? 0 : 1)
                back()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(showingBack ? 1 : 0)
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            // The card lifts a little while it turns.
            .scaleEffect(1 + 0.04 * sin(angle * .pi / 180))
        }
    }
}
