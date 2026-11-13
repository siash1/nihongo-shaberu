import Foundation

/// The kanji course: 20 units and 220 kanji, following the NihonGoal
/// "Minna No Nihongo Kanji" video series (one unit per video).
/// The unit contents live in the `KanjiData+Units…` files.
enum KanjiData {
    static let units: [KanjiUnit] = [
        unit1, unit2, unit3, unit4, unit5,
        unit6, unit7, unit8, unit9, unit10,
        unit11, unit12, unit13, unit14, unit15,
        unit16, unit17, unit18, unit19, unit20
    ]

    static let allKanji: [KanjiEntry] = units.flatMap(\.kanji)
}
