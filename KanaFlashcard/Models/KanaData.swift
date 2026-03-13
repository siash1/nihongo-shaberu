import Foundation

struct KanaData {
    static let hiragana: [KanaCharacter] = [
        // Vowels
        KanaCharacter(character: "\u{3042}", romaji: "a", type: .hiragana),
        KanaCharacter(character: "\u{3044}", romaji: "i", type: .hiragana),
        KanaCharacter(character: "\u{3046}", romaji: "u", type: .hiragana),
        KanaCharacter(character: "\u{3048}", romaji: "e", type: .hiragana),
        KanaCharacter(character: "\u{304A}", romaji: "o", type: .hiragana),
        // K-row
        KanaCharacter(character: "\u{304B}", romaji: "ka", type: .hiragana),
        KanaCharacter(character: "\u{304D}", romaji: "ki", type: .hiragana),
        KanaCharacter(character: "\u{304F}", romaji: "ku", type: .hiragana),
        KanaCharacter(character: "\u{3051}", romaji: "ke", type: .hiragana),
        KanaCharacter(character: "\u{3053}", romaji: "ko", type: .hiragana),
        // S-row
        KanaCharacter(character: "\u{3055}", romaji: "sa", type: .hiragana),
        KanaCharacter(character: "\u{3057}", romaji: "shi", type: .hiragana),
        KanaCharacter(character: "\u{3059}", romaji: "su", type: .hiragana),
        KanaCharacter(character: "\u{305B}", romaji: "se", type: .hiragana),
        KanaCharacter(character: "\u{305D}", romaji: "so", type: .hiragana),
        // T-row
        KanaCharacter(character: "\u{305F}", romaji: "ta", type: .hiragana),
        KanaCharacter(character: "\u{3061}", romaji: "chi", type: .hiragana),
        KanaCharacter(character: "\u{3064}", romaji: "tsu", type: .hiragana),
        KanaCharacter(character: "\u{3066}", romaji: "te", type: .hiragana),
        KanaCharacter(character: "\u{3068}", romaji: "to", type: .hiragana),
        // N-row
        KanaCharacter(character: "\u{306A}", romaji: "na", type: .hiragana),
        KanaCharacter(character: "\u{306B}", romaji: "ni", type: .hiragana),
        KanaCharacter(character: "\u{306C}", romaji: "nu", type: .hiragana),
        KanaCharacter(character: "\u{306D}", romaji: "ne", type: .hiragana),
        KanaCharacter(character: "\u{306E}", romaji: "no", type: .hiragana),
        // H-row
        KanaCharacter(character: "\u{306F}", romaji: "ha", type: .hiragana),
        KanaCharacter(character: "\u{3072}", romaji: "hi", type: .hiragana),
        KanaCharacter(character: "\u{3075}", romaji: "fu", type: .hiragana),
        KanaCharacter(character: "\u{3078}", romaji: "he", type: .hiragana),
        KanaCharacter(character: "\u{307B}", romaji: "ho", type: .hiragana),
        // M-row
        KanaCharacter(character: "\u{307E}", romaji: "ma", type: .hiragana),
        KanaCharacter(character: "\u{307F}", romaji: "mi", type: .hiragana),
        KanaCharacter(character: "\u{3080}", romaji: "mu", type: .hiragana),
        KanaCharacter(character: "\u{3081}", romaji: "me", type: .hiragana),
        KanaCharacter(character: "\u{3082}", romaji: "mo", type: .hiragana),
        // Y-row
        KanaCharacter(character: "\u{3084}", romaji: "ya", type: .hiragana),
        KanaCharacter(character: "\u{3086}", romaji: "yu", type: .hiragana),
        KanaCharacter(character: "\u{3088}", romaji: "yo", type: .hiragana),
        // R-row
        KanaCharacter(character: "\u{3089}", romaji: "ra", type: .hiragana),
        KanaCharacter(character: "\u{308A}", romaji: "ri", type: .hiragana),
        KanaCharacter(character: "\u{308B}", romaji: "ru", type: .hiragana),
        KanaCharacter(character: "\u{308C}", romaji: "re", type: .hiragana),
        KanaCharacter(character: "\u{308D}", romaji: "ro", type: .hiragana),
        // W-row + N
        KanaCharacter(character: "\u{308F}", romaji: "wa", type: .hiragana),
        KanaCharacter(character: "\u{3092}", romaji: "wo", type: .hiragana),
        KanaCharacter(character: "\u{3093}", romaji: "n", type: .hiragana),
    ]

    static let hiraganaDakuten: [KanaCharacter] = [
        // G-row (ka + dakuten)
        KanaCharacter(character: "\u{304C}", romaji: "ga", type: .hiragana),
        KanaCharacter(character: "\u{304E}", romaji: "gi", type: .hiragana),
        KanaCharacter(character: "\u{3050}", romaji: "gu", type: .hiragana),
        KanaCharacter(character: "\u{3052}", romaji: "ge", type: .hiragana),
        KanaCharacter(character: "\u{3054}", romaji: "go", type: .hiragana),
        // Z-row (sa + dakuten)
        KanaCharacter(character: "\u{3056}", romaji: "za", type: .hiragana),
        KanaCharacter(character: "\u{3058}", romaji: "ji", type: .hiragana),
        KanaCharacter(character: "\u{305A}", romaji: "zu", type: .hiragana),
        KanaCharacter(character: "\u{305C}", romaji: "ze", type: .hiragana),
        KanaCharacter(character: "\u{305E}", romaji: "zo", type: .hiragana),
        // D-row (ta + dakuten)
        KanaCharacter(character: "\u{3060}", romaji: "da", type: .hiragana),
        KanaCharacter(character: "\u{3062}", romaji: "ji", type: .hiragana),
        KanaCharacter(character: "\u{3065}", romaji: "zu", type: .hiragana),
        KanaCharacter(character: "\u{3067}", romaji: "de", type: .hiragana),
        KanaCharacter(character: "\u{3069}", romaji: "do", type: .hiragana),
        // B-row (ha + dakuten)
        KanaCharacter(character: "\u{3070}", romaji: "ba", type: .hiragana),
        KanaCharacter(character: "\u{3073}", romaji: "bi", type: .hiragana),
        KanaCharacter(character: "\u{3076}", romaji: "bu", type: .hiragana),
        KanaCharacter(character: "\u{3079}", romaji: "be", type: .hiragana),
        KanaCharacter(character: "\u{307C}", romaji: "bo", type: .hiragana),
        // P-row (ha + handakuten)
        KanaCharacter(character: "\u{3071}", romaji: "pa", type: .hiragana),
        KanaCharacter(character: "\u{3074}", romaji: "pi", type: .hiragana),
        KanaCharacter(character: "\u{3077}", romaji: "pu", type: .hiragana),
        KanaCharacter(character: "\u{307A}", romaji: "pe", type: .hiragana),
        KanaCharacter(character: "\u{307D}", romaji: "po", type: .hiragana),
    ]

    static let katakana: [KanaCharacter] = [
        // Vowels
        KanaCharacter(character: "\u{30A2}", romaji: "a", type: .katakana),
        KanaCharacter(character: "\u{30A4}", romaji: "i", type: .katakana),
        KanaCharacter(character: "\u{30A6}", romaji: "u", type: .katakana),
        KanaCharacter(character: "\u{30A8}", romaji: "e", type: .katakana),
        KanaCharacter(character: "\u{30AA}", romaji: "o", type: .katakana),
        // K-row
        KanaCharacter(character: "\u{30AB}", romaji: "ka", type: .katakana),
        KanaCharacter(character: "\u{30AD}", romaji: "ki", type: .katakana),
        KanaCharacter(character: "\u{30AF}", romaji: "ku", type: .katakana),
        KanaCharacter(character: "\u{30B1}", romaji: "ke", type: .katakana),
        KanaCharacter(character: "\u{30B3}", romaji: "ko", type: .katakana),
        // S-row
        KanaCharacter(character: "\u{30B5}", romaji: "sa", type: .katakana),
        KanaCharacter(character: "\u{30B7}", romaji: "shi", type: .katakana),
        KanaCharacter(character: "\u{30B9}", romaji: "su", type: .katakana),
        KanaCharacter(character: "\u{30BB}", romaji: "se", type: .katakana),
        KanaCharacter(character: "\u{30BD}", romaji: "so", type: .katakana),
        // T-row
        KanaCharacter(character: "\u{30BF}", romaji: "ta", type: .katakana),
        KanaCharacter(character: "\u{30C1}", romaji: "chi", type: .katakana),
        KanaCharacter(character: "\u{30C4}", romaji: "tsu", type: .katakana),
        KanaCharacter(character: "\u{30C6}", romaji: "te", type: .katakana),
        KanaCharacter(character: "\u{30C8}", romaji: "to", type: .katakana),
        // N-row
        KanaCharacter(character: "\u{30CA}", romaji: "na", type: .katakana),
        KanaCharacter(character: "\u{30CB}", romaji: "ni", type: .katakana),
        KanaCharacter(character: "\u{30CC}", romaji: "nu", type: .katakana),
        KanaCharacter(character: "\u{30CD}", romaji: "ne", type: .katakana),
        KanaCharacter(character: "\u{30CE}", romaji: "no", type: .katakana),
        // H-row
        KanaCharacter(character: "\u{30CF}", romaji: "ha", type: .katakana),
        KanaCharacter(character: "\u{30D2}", romaji: "hi", type: .katakana),
        KanaCharacter(character: "\u{30D5}", romaji: "fu", type: .katakana),
        KanaCharacter(character: "\u{30D8}", romaji: "he", type: .katakana),
        KanaCharacter(character: "\u{30DB}", romaji: "ho", type: .katakana),
        // M-row
        KanaCharacter(character: "\u{30DE}", romaji: "ma", type: .katakana),
        KanaCharacter(character: "\u{30DF}", romaji: "mi", type: .katakana),
        KanaCharacter(character: "\u{30E0}", romaji: "mu", type: .katakana),
        KanaCharacter(character: "\u{30E1}", romaji: "me", type: .katakana),
        KanaCharacter(character: "\u{30E2}", romaji: "mo", type: .katakana),
        // Y-row
        KanaCharacter(character: "\u{30E4}", romaji: "ya", type: .katakana),
        KanaCharacter(character: "\u{30E6}", romaji: "yu", type: .katakana),
        KanaCharacter(character: "\u{30E8}", romaji: "yo", type: .katakana),
        // R-row
        KanaCharacter(character: "\u{30E9}", romaji: "ra", type: .katakana),
        KanaCharacter(character: "\u{30EA}", romaji: "ri", type: .katakana),
        KanaCharacter(character: "\u{30EB}", romaji: "ru", type: .katakana),
        KanaCharacter(character: "\u{30EC}", romaji: "re", type: .katakana),
        KanaCharacter(character: "\u{30ED}", romaji: "ro", type: .katakana),
        // W-row + N
        KanaCharacter(character: "\u{30EF}", romaji: "wa", type: .katakana),
        KanaCharacter(character: "\u{30F2}", romaji: "wo", type: .katakana),
        KanaCharacter(character: "\u{30F3}", romaji: "n", type: .katakana),
    ]

    static let katakanaDakuten: [KanaCharacter] = [
        // G-row (ka + dakuten)
        KanaCharacter(character: "\u{30AC}", romaji: "ga", type: .katakana),
        KanaCharacter(character: "\u{30AE}", romaji: "gi", type: .katakana),
        KanaCharacter(character: "\u{30B0}", romaji: "gu", type: .katakana),
        KanaCharacter(character: "\u{30B2}", romaji: "ge", type: .katakana),
        KanaCharacter(character: "\u{30B4}", romaji: "go", type: .katakana),
        // Z-row (sa + dakuten)
        KanaCharacter(character: "\u{30B6}", romaji: "za", type: .katakana),
        KanaCharacter(character: "\u{30B8}", romaji: "ji", type: .katakana),
        KanaCharacter(character: "\u{30BA}", romaji: "zu", type: .katakana),
        KanaCharacter(character: "\u{30BC}", romaji: "ze", type: .katakana),
        KanaCharacter(character: "\u{30BE}", romaji: "zo", type: .katakana),
        // D-row (ta + dakuten)
        KanaCharacter(character: "\u{30C0}", romaji: "da", type: .katakana),
        KanaCharacter(character: "\u{30C2}", romaji: "ji", type: .katakana),
        KanaCharacter(character: "\u{30C5}", romaji: "zu", type: .katakana),
        KanaCharacter(character: "\u{30C7}", romaji: "de", type: .katakana),
        KanaCharacter(character: "\u{30C9}", romaji: "do", type: .katakana),
        // B-row (ha + dakuten)
        KanaCharacter(character: "\u{30D0}", romaji: "ba", type: .katakana),
        KanaCharacter(character: "\u{30D3}", romaji: "bi", type: .katakana),
        KanaCharacter(character: "\u{30D6}", romaji: "bu", type: .katakana),
        KanaCharacter(character: "\u{30D9}", romaji: "be", type: .katakana),
        KanaCharacter(character: "\u{30DC}", romaji: "bo", type: .katakana),
        // P-row (ha + handakuten)
        KanaCharacter(character: "\u{30D1}", romaji: "pa", type: .katakana),
        KanaCharacter(character: "\u{30D4}", romaji: "pi", type: .katakana),
        KanaCharacter(character: "\u{30D7}", romaji: "pu", type: .katakana),
        KanaCharacter(character: "\u{30DA}", romaji: "pe", type: .katakana),
        KanaCharacter(character: "\u{30DD}", romaji: "po", type: .katakana),
    ]

    static let allCharacters: [KanaCharacter] = hiragana + hiraganaDakuten + katakana + katakanaDakuten
}
