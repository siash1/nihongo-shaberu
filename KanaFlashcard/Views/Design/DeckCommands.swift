import SwiftUI

/// What the Cards menu can do for the deck on screen. `DeckActionBar` publishes it only while
/// it is visible; at all other times the menu items are disabled, so their plain-key shortcuts
/// (Space, ←, →) never take keys from a text field such as the Talk tab's.
struct DeckCommandActions {
    var showAnswer: (() -> Void)?
    var grade: ((_ correct: Bool) -> Void)?
}

extension FocusedValues {
    @Entry var deckActions: DeckCommandActions?
}

/// The Cards menu (Mac menu bar, iPad menu bar and ⌘ shortcut list): Space shows the answer,
/// ← and → mark it, matching the swipe directions.
///
/// The shortcuts live here rather than on the deck's buttons because the system claims plain
/// arrow keys for scrolling and focus before a button's shortcut is checked. Menu key
/// equivalents are handled first.
struct DeckCommands: Commands {
    @FocusedValue(\.deckActions) private var deck

    var body: some Commands {
        CommandMenu("Cards") {
            Button("Show Answer") { deck?.showAnswer?() }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(deck?.showAnswer == nil)

            Divider()

            Button("Mark Wrong") { deck?.grade?(false) }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(deck?.grade == nil)

            Button("Mark Correct") { deck?.grade?(true) }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(deck?.grade == nil)
        }
    }
}
