# KanaFlashcard

Japanese Hiragana & Katakana flashcard practice app built with SwiftUI.

## Project Structure

```
KanaFlashcard/
├── KanaFlashcardApp.swift          # App entry point
├── ContentView.swift               # Root view with NavigationStack
├── Models/
│   ├── KanaCharacter.swift         # KanaCharacter model, KanaType enum
│   └── KanaData.swift              # Full hiragana (46) + katakana (46) datasets
├── ViewModels/
│   └── PracticeViewModel.swift     # @Observable VM: selection state, card logic
└── Views/
    ├── KanaSelectionView.swift     # Character grid + selection buttons
    └── FlashcardView.swift         # Flashcard practice screen
```

## Architecture

- **Pattern**: MVVM with SwiftUI's `@Observable` (Observation framework)
- **State flow**: `PracticeViewModel` is created as `@State` in `ContentView`, passed via `@Bindable` to child views
- **Navigation**: `NavigationStack` with `NavigationLink` from selection to practice

## Key Details

- Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new files in the KanaFlashcard folder are auto-detected, no pbxproj edits needed
- Target: iOS 26.1, Swift 5 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- Bundle ID: `onearvo.jap.KanaFlashcard`
- Flashcard randomization avoids immediate repeats; requires 2+ characters selected to start practice

## Build & Run

Open `KanaFlashcard.xcodeproj` in Xcode and run on simulator or device.
