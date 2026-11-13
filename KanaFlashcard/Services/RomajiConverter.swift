import Foundation

/// Converts kana into simple romaji that mirrors the kana spelling
/// (long vowels stay as written: とうきょう → "toukyou").
enum RomajiConverter {

    /// Romaji for a single word or reading written in hiragana/katakana.
    static func romaji(fromKana kana: String) -> String {
        let chars = Array(hiragana(from: kana))
        var result = ""
        var doubleNext = false   // set by small っ: doubles the next consonant
        var index = 0

        while index < chars.count {
            let char = chars[index]

            if char == "っ" {
                doubleNext = true
                index += 1
                continue
            }

            if char == "ー" {
                if let last = result.last, "aiueo".contains(last) {
                    result.append(last)
                }
                index += 1
                continue
            }

            var piece: String
            if index + 1 < chars.count, let combo = digraphs[String([char, chars[index + 1]])] {
                piece = combo
                index += 2
            } else if let single = syllables[char] {
                piece = single
                index += 1
                if char == "ん", index < chars.count, "あいうえおやゆよ".contains(chars[index]) {
                    piece = "n'"
                }
            } else {
                result.append(punctuation[char] ?? char)
                index += 1
                continue
            }

            if doubleNext, let first = piece.first {
                let doubled = piece.hasPrefix("ch") ? "t" : String(first)
                if result.hasSuffix("(") {
                    // っ before an okurigana bracket belongs to the stem: みっ(つ) → mit(tsu)
                    result.insert(contentsOf: doubled, at: result.index(before: result.endIndex))
                } else {
                    result += doubled
                }
                doubleNext = false
            }
            result += piece
        }

        return result
    }

    /// Romaji for a sentence whose kana reading is spaced by word and particle,
    /// e.g. "みず を のみます。" → "Mizu o nomimasu."
    static func romaji(fromSentence reading: String) -> String {
        let words = reading.split(separator: " ").map { token -> String in
            var core = String(token)
            var tail = ""
            while let last = core.last, let mark = punctuation[last] {
                tail.insert(mark, at: tail.startIndex)
                core.removeLast()
            }
            return (particles[core] ?? romaji(fromKana: core)) + tail
        }

        var output = ""
        var capitalizeNext = true
        for char in words.joined(separator: " ") {
            if capitalizeNext, char.isLetter {
                output += String(char).uppercased()
                capitalizeNext = false
            } else {
                output.append(char)
                if ".?!".contains(char) { capitalizeNext = true }
            }
        }
        return output
    }

    // MARK: - Tables

    /// Particles are pronounced differently from how they are written.
    private static let particles: [String: String] = ["は": "wa", "へ": "e"]

    private static let punctuation: [Character: Character] = [
        "。": ".", "、": ",", "？": "?", "！": "!", "・": " ", "〜": "~"
    ]

    private static let syllables: [Character: String] = [
        "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
        "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
        "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
        "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
        "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
        "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
        "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
        "や": "ya", "ゆ": "yu", "よ": "yo",
        "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
        "わ": "wa", "を": "o", "ん": "n",
        "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
        "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
        "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
        "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
        "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
        "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
        "ゃ": "ya", "ゅ": "yu", "ょ": "yo", "ゔ": "vu"
    ]

    private static let digraphs: [String: String] = [
        "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
        "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
        "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
        "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
        "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
        "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
        "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
        "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
        "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
        "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
        "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
        // Katakana-only sounds (after folding katakana to hiragana)
        "ふぁ": "fa", "ふぃ": "fi", "ふぇ": "fe", "ふぉ": "fo",
        "てぃ": "ti", "でぃ": "di", "うぃ": "wi", "うぇ": "we", "うぉ": "wo",
        "しぇ": "she", "じぇ": "je", "ちぇ": "che"
    ]

    /// Folds katakana onto hiragana so one table covers both scripts.
    private static func hiragana(from text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if (0x30A1...0x30F6).contains(scalar.value), let folded = Unicode.Scalar(scalar.value - 0x60) {
                scalars.append(folded)
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }
}
