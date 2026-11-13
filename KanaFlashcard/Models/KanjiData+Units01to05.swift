import Foundation

// Units 1–5 of the NihonGoal "Minna No Nihongo Kanji" video series.
// Sentences only use kanji that appear in the course up to that unit; everything else is in kana.

extension KanjiData {

    // MARK: - Unit 1

    static let unit1 = KanjiUnit(
        number: 1,
        title: "Days of the Week & Nature",
        videoID: "cLsiM8SpQik",
        kanji: [
            KanjiEntry("日", "sun, day", on: "ニチ・ジツ", kun: "ひ・か",
                hint: "A drawing of the sun: a round sun squared off, with a line of light across the middle. One sun crossing the sky is one day.",
                words: [
                    KanjiWord("日", "ひ", "day; sun"),
                    KanjiWord("日曜日", "にちようび", "Sunday"),
                    KanjiWord("〜曜日", "〜ようび", "day of the week (ending)"),
                    KanjiWord("今日", "きょう", "today"),
                    KanjiWord("明日", "あした", "tomorrow"),
                    KanjiWord("昨日", "きのう", "yesterday"),
                    KanjiWord("毎日", "まいにち", "every day"),
                    KanjiWord("日本", "にほん", "Japan"),
                    KanjiWord("日本人", "にほんじん", "Japanese person"),
                    KanjiWord("日本語", "にほんご", "Japanese (language)"),
                    KanjiWord("〜日", "〜にち", "day of the month; number of days")
                ]),
            KanjiEntry("月", "moon, month", on: "ゲツ・ガツ", kun: "つき",
                hint: "A crescent moon with two wisps of cloud drifting across it. The moon goes round once a month.",
                words: [
                    KanjiWord("月", "つき", "moon"),
                    KanjiWord("月曜日", "げつようび", "Monday"),
                    KanjiWord("〜月", "〜がつ", "month of the year (ending)"),
                    KanjiWord("〜か月", "〜かげつ", "number of months"),
                    KanjiWord("先月", "せんげつ", "last month"),
                    KanjiWord("今月", "こんげつ", "this month"),
                    KanjiWord("来月", "らいげつ", "next month"),
                    KanjiWord("毎月", "まいつき", "every month")
                ]),
            KanjiEntry("火", "fire", on: "カ", kun: "ひ",
                hint: "A campfire: one big flame in the middle with a spark flying off on each side.",
                words: [
                    KanjiWord("火", "ひ", "fire"),
                    KanjiWord("火事", "かじ", "a fire (accident)"),
                    KanjiWord("火曜日", "かようび", "Tuesday")
                ]),
            KanjiEntry("水", "water", on: "スイ", kun: "みず",
                hint: "A stream running down the middle with water splashing out to the left and right.",
                words: [
                    KanjiWord("水", "みず", "water"),
                    KanjiWord("水道", "すいどう", "water supply"),
                    KanjiWord("水曜日", "すいようび", "Wednesday")
                ]),
            KanjiEntry("木", "tree, wood", on: "モク・ボク", kun: "き",
                hint: "A tree: a trunk, branches reaching out to the sides, and roots sweeping down into the ground.",
                words: [
                    KanjiWord("木", "き", "tree"),
                    KanjiWord("木曜日", "もくようび", "Thursday")
                ]),
            KanjiEntry("金", "gold, money", on: "キン", kun: "かね",
                hint: "A roof over a mine shaft, and two gold nuggets glittering in the ground below.",
                words: [
                    KanjiWord("金", "きん", "gold"),
                    KanjiWord("お金", "おかね", "money"),
                    KanjiWord("金曜日", "きんようび", "Friday")
                ]),
            KanjiEntry("土", "earth, soil", on: "ド・ト", kun: "つち",
                hint: "A little sprout pushing up out of the ground. The long bottom line is the earth.",
                words: [
                    KanjiWord("土", "つち", "soil"),
                    KanjiWord("土地", "とち", "land"),
                    KanjiWord("土曜日", "どようび", "Saturday")
                ]),
            KanjiEntry("山", "mountain", on: "サン", kun: "やま",
                hint: "Three mountain peaks side by side, with the tallest one in the middle.",
                words: [
                    KanjiWord("山", "やま", "mountain"),
                    KanjiWord("山田", "やまだ", "Yamada (family name)"),
                    KanjiWord("山川", "やまかわ", "Yamakawa (family name)"),
                    KanjiWord("火山", "かざん", "volcano")
                ]),
            KanjiEntry("川", "river", on: "セン", kun: "かわ",
                hint: "Three lines of water flowing downstream between the banks.",
                words: [
                    KanjiWord("川", "かわ", "river"),
                    KanjiWord("中川", "なかがわ", "Nakagawa (family name)")
                ]),
            KanjiEntry("田", "rice field", on: "デン", kun: "た",
                hint: "A rice paddy seen from above, divided into four plots by little paths.",
                words: [
                    KanjiWord("田中", "たなか", "Tanaka (family name)"),
                    KanjiWord("山田", "やまだ", "Yamada (family name)"),
                    KanjiWord("田んぼ", "たんぼ", "rice paddy")
                ])
        ],
        sentences: [
            KanjiSentence("日曜日に 山へ いきます。", "にちようび に やま へ いきます。", "I go to the mountains on Sunday.", focus: "山"),
            KanjiSentence("まいにち 水を のみます。", "まいにち みず を のみます。", "I drink water every day.", focus: "水"),
            KanjiSentence("お金が ありません。", "おかね が ありません。", "I don't have any money.", focus: "お金"),
            KanjiSentence("月が きれいです。", "つき が きれい です。", "The moon is beautiful.", focus: "月"),
            KanjiSentence("木の したに ねこが います。", "き の した に ねこ が います。", "There is a cat under the tree.", focus: "木"),
            KanjiSentence("川で さかなを みました。", "かわ で さかな を みました。", "I saw fish in the river.", focus: "川"),
            KanjiSentence("きょうは 金曜日です。", "きょう は きんようび です。", "Today is Friday.", focus: "金曜日"),
            KanjiSentence("火曜日に 日本へ いきます。", "かようび に にほん へ いきます。", "I'm going to Japan on Tuesday.", focus: "火曜日"),
            KanjiSentence("山田さんは せんせいです。", "やまだ さん は せんせい です。", "Mr. Yamada is a teacher.", focus: "山田"),
            KanjiSentence("土曜日に 川へ いきます。", "どようび に かわ へ いきます。", "I go to the river on Saturday.", focus: "土曜日")
        ]
    )

    // MARK: - Unit 2

    static let unit2 = KanjiUnit(
        number: 2,
        title: "Numbers & Money",
        videoID: "h-5glg9Rei8",
        kanji: [
            KanjiEntry("一", "one", on: "イチ", kun: "ひと(つ)",
                hint: "One single stroke, like one finger held out sideways.",
                words: [
                    KanjiWord("一", "いち", "one"),
                    KanjiWord("一日", "ついたち", "the 1st of the month"),
                    KanjiWord("一つ", "ひとつ", "one (thing)"),
                    KanjiWord("一人", "ひとり", "one person; alone"),
                    KanjiWord("一度", "いちど", "once"),
                    KanjiWord("一度も", "いちども", "not even once")
                ]),
            KanjiEntry("二", "two", on: "ニ", kun: "ふた(つ)",
                hint: "Two strokes, like two fingers held out sideways.",
                words: [
                    KanjiWord("二", "に", "two"),
                    KanjiWord("二日", "ふつか", "the 2nd; two days"),
                    KanjiWord("二十日", "はつか", "the 20th; twenty days"),
                    KanjiWord("二つ", "ふたつ", "two (things)"),
                    KanjiWord("二人", "ふたり", "two people")
                ]),
            KanjiEntry("三", "three", on: "サン", kun: "みっ(つ)",
                hint: "Three strokes, like three fingers held out sideways.",
                words: [
                    KanjiWord("三", "さん", "three"),
                    KanjiWord("三日", "みっか", "the 3rd; three days"),
                    KanjiWord("三つ", "みっつ", "three (things)")
                ]),
            KanjiEntry("四", "four", on: "シ", kun: "よん・よっ(つ)",
                hint: "A window with four sides, and a pair of curtains hanging inside it.",
                words: [
                    KanjiWord("四", "よん", "four"),
                    KanjiWord("四日", "よっか", "the 4th; four days"),
                    KanjiWord("四つ", "よっつ", "four (things)")
                ]),
            KanjiEntry("五", "five", on: "ゴ", kun: "いつ(つ)",
                hint: "Squint and you can see a blocky number 5 squeezed between a floor line and a ceiling line.",
                words: [
                    KanjiWord("五", "ご", "five"),
                    KanjiWord("五日", "いつか", "the 5th; five days"),
                    KanjiWord("五つ", "いつつ", "five (things)")
                ]),
            KanjiEntry("六", "six", on: "ロク", kun: "むっ(つ)",
                hint: "A six-legged bug hiding under a lid. You can only see two of its legs sticking out.",
                words: [
                    KanjiWord("六", "ろく", "six"),
                    KanjiWord("六日", "むいか", "the 6th; six days"),
                    KanjiWord("六つ", "むっつ", "six (things)")
                ]),
            KanjiEntry("七", "seven", on: "シチ", kun: "なな(つ)",
                hint: "Turn it upside down and you will see the number 7 with a line through it.",
                words: [
                    KanjiWord("七", "なな", "seven"),
                    KanjiWord("七日", "なのか", "the 7th; seven days"),
                    KanjiWord("七つ", "ななつ", "seven (things)")
                ]),
            KanjiEntry("八", "eight", on: "ハチ", kun: "やっ(つ)",
                hint: "It looks just like katakana ハ (ha), and it is read ハチ (hachi).",
                words: [
                    KanjiWord("八", "はち", "eight"),
                    KanjiWord("八日", "ようか", "the 8th; eight days"),
                    KanjiWord("八つ", "やっつ", "eight (things)")
                ]),
            KanjiEntry("九", "nine", on: "キュウ・ク", kun: "ここの(つ)",
                hint: "Almost 十 (ten), but one arm gives up and bends away at the end. Just short of ten is nine.",
                words: [
                    KanjiWord("九", "きゅう", "nine"),
                    KanjiWord("九つ", "ここのつ", "nine (things)"),
                    KanjiWord("九日", "ここのか", "the 9th; nine days")
                ]),
            KanjiEntry("十", "ten", on: "ジュウ", kun: "とお",
                hint: "A cross, like the Roman numeral X (ten) stood up straight.",
                words: [
                    KanjiWord("十", "じゅう", "ten"),
                    KanjiWord("十日", "とおか", "the 10th; ten days"),
                    KanjiWord("二十日", "はつか", "the 20th; twenty days"),
                    KanjiWord("十四日", "じゅうよっか", "the 14th; fourteen days"),
                    KanjiWord("二十四日", "にじゅうよっか", "the 24th; twenty-four days"),
                    KanjiWord("二十歳", "はたち", "twenty years old")
                ]),
            KanjiEntry("百", "hundred", on: "ヒャク", kun: "",
                hint: "A 一 (one) on top, and below it a box that looks like two zeros stacked up: 1 and 00 make 100.",
                words: [
                    KanjiWord("百", "ひゃく", "hundred"),
                    KanjiWord("二百", "にひゃく", "two hundred"),
                    KanjiWord("三百", "さんびゃく", "three hundred"),
                    KanjiWord("八百屋", "やおや", "greengrocer"),
                    KanjiWord("百円", "ひゃくえん", "100 yen")
                ]),
            KanjiEntry("千", "thousand", on: "セン", kun: "",
                hint: "十 (ten) wearing a feather in its hat. With the feather, ten is promoted to a thousand.",
                words: [
                    KanjiWord("千", "せん", "thousand"),
                    KanjiWord("三千", "さんぜん", "three thousand"),
                    KanjiWord("千円", "せんえん", "1,000 yen")
                ]),
            KanjiEntry("万", "ten thousand", on: "マン", kun: "",
                hint: "It is read 'man'. Picture a running man, leaning forward as he carries 10,000 yen home.",
                words: [
                    KanjiWord("一万", "いちまん", "ten thousand"),
                    KanjiWord("百万", "ひゃくまん", "one million")
                ]),
            KanjiEntry("円", "yen, circle", on: "エン", kun: "",
                hint: "A bank teller's window. You slide your yen across the counter in the middle.",
                words: [
                    KanjiWord("円", "えん", "yen"),
                    KanjiWord("一万円", "いちまんえん", "10,000 yen"),
                    KanjiWord("十万円", "じゅうまんえん", "100,000 yen"),
                    KanjiWord("百万円", "ひゃくまんえん", "1,000,000 yen"),
                    KanjiWord("円高", "えんだか", "strong yen"),
                    KanjiWord("円安", "えんやす", "weak yen")
                ])
        ],
        sentences: [
            KanjiSentence("りんごを 三つ ください。", "りんご を みっつ ください。", "Three apples, please.", focus: "三つ"),
            KanjiSentence("これは 百円です。", "これ は ひゃくえん です。", "This is 100 yen.", focus: "百円"),
            KanjiSentence("こどもが 二人 います。", "こども が ふたり います。", "I have two children.", focus: "二人"),
            KanjiSentence("一万円 かして ください。", "いちまんえん かして ください。", "Please lend me 10,000 yen.", focus: "一万円"),
            KanjiSentence("きょうは 四月 五日です。", "きょう は しがつ いつか です。", "Today is April 5th.", focus: "五日"),
            KanjiSentence("一人で 日本へ きました。", "ひとり で にほん へ きました。", "I came to Japan alone.", focus: "一人"),
            KanjiSentence("この ほんは 千円です。", "この ほん は せんえん です。", "This book is 1,000 yen.", focus: "千円"),
            KanjiSentence("七月 十日に 山へ いきます。", "しちがつ とおか に やま へ いきます。", "I'm going to the mountains on July 10th.", focus: "十日"),
            KanjiSentence("たまごを 六つ かいました。", "たまご を むっつ かいました。", "I bought six eggs.", focus: "六つ"),
            KanjiSentence("八月 九日に 日本へ いきます。", "はちがつ ここのか に にほん へ いきます。", "I'm going to Japan on August 9th.", focus: "九日")
        ]
    )

    // MARK: - Unit 3

    static let unit3 = KanjiUnit(
        number: 3,
        title: "School, Work & People",
        videoID: "fhacD_Wwza4",
        kanji: [
            KanjiEntry("学", "study, learning", on: "ガク", kun: "まな(ぶ)",
                hint: "A child (子) under a school roof, with three sparks of new ideas flying off the top.",
                words: [
                    KanjiWord("学生", "がくせい", "student"),
                    KanjiWord("学校", "がっこう", "school"),
                    KanjiWord("大学", "だいがく", "university"),
                    KanjiWord("小学校", "しょうがっこう", "elementary school"),
                    KanjiWord("中学校", "ちゅうがっこう", "junior high school"),
                    KanjiWord("小学生", "しょうがくせい", "elementary school pupil"),
                    KanjiWord("中学生", "ちゅうがくせい", "junior high school student"),
                    KanjiWord("大学生", "だいがくせい", "university student")
                ]),
            KanjiEntry("生", "life, birth", on: "セイ・ショウ", kun: "う(まれる)・い(きる)・なま",
                hint: "A plant sprouting up out of the soil (土): new life being born.",
                words: [
                    KanjiWord("先生", "せんせい", "teacher"),
                    KanjiWord("生まれる", "うまれる", "to be born"),
                    KanjiWord("生きる", "いきる", "to live"),
                    KanjiWord("生ビール", "なま ビール", "draft beer"),
                    KanjiWord("生ジュース", "なま ジュース", "fresh juice")
                ]),
            KanjiEntry("先", "ahead, previous", on: "セン", kun: "さき",
                hint: "Two legs at the bottom walking on ahead: someone who has gone before you.",
                words: [
                    KanjiWord("先週", "せんしゅう", "last week"),
                    KanjiWord("先月", "せんげつ", "last month"),
                    KanjiWord("先", "さき", "ahead; the tip")
                ]),
            KanjiEntry("会", "meet", on: "カイ", kun: "あ(う)",
                hint: "People gathering under one roof to meet and talk.",
                words: [
                    KanjiWord("会社", "かいしゃ", "company"),
                    KanjiWord("会社員", "かいしゃいん", "office worker"),
                    KanjiWord("会う", "あう", "to meet"),
                    KanjiWord("会話", "かいわ", "conversation")
                ]),
            KanjiEntry("社", "company, shrine", on: "シャ", kun: "",
                hint: "An altar (礻) beside the earth (土): a shrine on sacred ground, where a group of people gathers.",
                words: [
                    KanjiWord("会社", "かいしゃ", "company"),
                    KanjiWord("社員", "しゃいん", "company employee"),
                    KanjiWord("本社", "ほんしゃ", "head office")
                ]),
            KanjiEntry("員", "member, staff", on: "イン", kun: "",
                hint: "A mouth (口) on top of a shell (貝), which was once used as money: someone paid to speak for the group.",
                words: [
                    KanjiWord("会社員", "かいしゃいん", "office worker"),
                    KanjiWord("銀行員", "ぎんこういん", "bank employee"),
                    KanjiWord("店員", "てんいん", "shop assistant")
                ]),
            KanjiEntry("医", "medicine, healing", on: "イ", kun: "",
                hint: "An arrow (矢) lying in a box: the doctor's kit box, used for treating arrow wounds.",
                words: [
                    KanjiWord("医者", "いしゃ", "doctor"),
                    KanjiWord("医学", "いがく", "medical science")
                ]),
            KanjiEntry("者", "one who does (-er)", on: "シャ", kun: "もの",
                hint: "Someone standing on the ground (土) under the sun (日), out there doing their job.",
                words: [
                    KanjiWord("医者", "いしゃ", "doctor"),
                    KanjiWord("学者", "がくしゃ", "scholar")
                ]),
            KanjiEntry("本", "book, origin", on: "ホン", kun: "もと",
                hint: "A tree (木) with a mark at its root. The root is the origin, and books are made from trees.",
                words: [
                    KanjiWord("本", "ほん", "book"),
                    KanjiWord("本屋", "ほんや", "bookstore"),
                    KanjiWord("本人", "ほんにん", "the person himself or herself"),
                    KanjiWord("日本", "にほん", "Japan"),
                    KanjiWord("日本人", "にほんじん", "Japanese person"),
                    KanjiWord("日本語", "にほんご", "Japanese (language)"),
                    KanjiWord("古本", "ふるほん", "second-hand book"),
                    KanjiWord("本社", "ほんしゃ", "head office")
                ]),
            KanjiEntry("中", "middle, inside", on: "チュウ", kun: "なか",
                hint: "A line going straight through the middle of a box.",
                words: [
                    KanjiWord("中", "なか", "inside"),
                    KanjiWord("一日中", "いちにちじゅう", "all day long"),
                    KanjiWord("田中", "たなか", "Tanaka (family name)"),
                    KanjiWord("中川", "なかがわ", "Nakagawa (family name)"),
                    KanjiWord("中国", "ちゅうごく", "China"),
                    KanjiWord("中国人", "ちゅうごくじん", "Chinese person"),
                    KanjiWord("中国語", "ちゅうごくご", "Chinese (language)"),
                    KanjiWord("中東", "ちゅうとう", "Middle East"),
                    KanjiWord("話し中", "はなしちゅう", "busy (on the phone)")
                ]),
            KanjiEntry("国", "country", on: "コク", kun: "くに",
                hint: "A king's jewel (玉) kept safe inside the borders (囗): a country.",
                words: [
                    KanjiWord("国", "くに", "country"),
                    KanjiWord("韓国", "かんこく", "South Korea"),
                    KanjiWord("外国", "がいこく", "foreign country"),
                    KanjiWord("外国人", "がいこくじん", "foreigner"),
                    KanjiWord("国内", "こくない", "domestic, within the country")
                ]),
            KanjiEntry("人", "person", on: "ジン・ニン", kun: "ひと",
                hint: "A person walking, seen from the side: two legs in mid-stride.",
                words: [
                    KanjiWord("人", "ひと", "person"),
                    KanjiWord("男の人", "おとこ の ひと", "man"),
                    KanjiWord("女の人", "おんな の ひと", "woman"),
                    KanjiWord("あの人", "あの ひと", "that person"),
                    KanjiWord("主人", "しゅじん", "(my) husband"),
                    KanjiWord("ご主人", "ごしゅじん", "(your) husband"),
                    KanjiWord("〜人", "〜にん", "number of people"),
                    KanjiWord("三人", "さんにん", "three people"),
                    KanjiWord("一人", "ひとり", "one person; alone"),
                    KanjiWord("二人", "ふたり", "two people"),
                    KanjiWord("大人", "おとな", "adult"),
                    KanjiWord("日本人", "にほんじん", "Japanese person")
                ])
        ],
        sentences: [
            KanjiSentence("わたしは 学生です。", "わたし は がくせい です。", "I am a student.", focus: "学生"),
            KanjiSentence("山田さんは 会社員です。", "やまだ さん は かいしゃいん です。", "Mr. Yamada is an office worker.", focus: "会社員"),
            KanjiSentence("あの 人は 医者です。", "あの ひと は いしゃ です。", "That person is a doctor.", focus: "医者"),
            KanjiSentence("先生は 日本人です。", "せんせい は にほんじん です。", "The teacher is Japanese.", focus: "先生", speech: "先生はにほんじんです。"),
            KanjiSentence("かばんの 中に 本が あります。", "かばん の なか に ほん が あります。", "There is a book in the bag.", focus: "本"),
            KanjiSentence("中国から きました。", "ちゅうごく から きました。", "I came from China.", focus: "中国"),
            KanjiSentence("お国は どちらですか。", "おくに は どちら です か。", "Which country are you from?", focus: "国"),
            KanjiSentence("月曜日に 先生に 会います。", "げつようび に せんせい に あいます。", "I will meet the teacher on Monday.", focus: "会います")
        ]
    )

    // MARK: - Unit 4

    static let unit4 = KanjiUnit(
        number: 4,
        title: "Time of Day",
        videoID: "_Dpb0Aoc8Wk",
        kanji: [
            KanjiEntry("今", "now", on: "コン", kun: "いま",
                hint: "A roof with a clock hand underneath, pointing at this very moment: now.",
                words: [
                    KanjiWord("今", "いま", "now"),
                    KanjiWord("今日", "きょう", "today"),
                    KanjiWord("今日は", "こんにちは", "hello, good afternoon", romaji: "konnichiwa"),
                    KanjiWord("今朝", "けさ", "this morning"),
                    KanjiWord("今週", "こんしゅう", "this week"),
                    KanjiWord("今月", "こんげつ", "this month"),
                    KanjiWord("今年", "ことし", "this year")
                ]),
            KanjiEntry("朝", "morning", on: "チョウ", kun: "あさ",
                hint: "On the left the sun (日) rises through the grass, while on the right the moon (月) is still in the sky: early morning.",
                words: [
                    KanjiWord("朝", "あさ", "morning"),
                    KanjiWord("朝ごはん", "あさごはん", "breakfast"),
                    KanjiWord("毎朝", "まいあさ", "every morning")
                ]),
            KanjiEntry("昼", "daytime", on: "チュウ", kun: "ひる",
                hint: "The sun (日) sitting high above the horizon line at the bottom: the middle of the day, time for lunch.",
                words: [
                    KanjiWord("昼", "ひる", "noon, daytime"),
                    KanjiWord("昼ごはん", "ひるごはん", "lunch"),
                    KanjiWord("昼休み", "ひるやすみ", "lunch break")
                ]),
            KanjiEntry("晩", "evening", on: "バン", kun: "",
                hint: "The sun (日) on the left is escaping (免). When the sun slips away, it is evening.",
                words: [
                    KanjiWord("晩", "ばん", "evening"),
                    KanjiWord("晩ごはん", "ばんごはん", "dinner"),
                    KanjiWord("今晩", "こんばん", "tonight"),
                    KanjiWord("今晩は", "こんばんは", "good evening", romaji: "konbanwa"),
                    KanjiWord("毎晩", "まいばん", "every night")
                ]),
            KanjiEntry("時", "time, o'clock", on: "ジ", kun: "とき",
                hint: "The sun (日) next to a temple (寺). Temples rang their bells to tell everyone the time of day.",
                words: [
                    KanjiWord("時", "とき", "time, moment"),
                    KanjiWord("一時", "いちじ", "one o'clock"),
                    KanjiWord("一時半", "いちじはん", "half past one"),
                    KanjiWord("一時間", "いちじかん", "one hour"),
                    KanjiWord("一時間半", "いちじかんはん", "one and a half hours"),
                    KanjiWord("時間", "じかん", "time"),
                    KanjiWord("時計", "とけい", "clock, watch"),
                    KanjiWord("時々", "ときどき", "sometimes"),
                    KanjiWord("〜の時", "〜の とき", "when…, at the time of…")
                ]),
            KanjiEntry("分", "minute, part", on: "フン・ブン", kun: "わ(かる)",
                hint: "A knife (刀) cutting something into two parts (八): an hour cut into minutes, and an idea cut into parts you can understand.",
                words: [
                    KanjiWord("分", "ふん", "minute"),
                    KanjiWord("十分", "じゅっぷん", "ten minutes"),
                    KanjiWord("五分", "ごふん", "five minutes"),
                    KanjiWord("自分で", "じぶん で", "by oneself"),
                    KanjiWord("半分", "はんぶん", "half"),
                    KanjiWord("分かる", "わかる", "to understand"),
                    KanjiWord("分かれる", "わかれる", "to split up, be divided"),
                    KanjiWord("分ける", "わける", "to divide, share")
                ]),
            KanjiEntry("半", "half", on: "ハン", kun: "",
                hint: "One long vertical stroke slicing everything right down the middle, into two halves.",
                words: [
                    KanjiWord("二時半", "にじはん", "half past two"),
                    KanjiWord("二時間半", "にじかんはん", "two and a half hours"),
                    KanjiWord("半分", "はんぶん", "half")
                ]),
            KanjiEntry("午", "noon", on: "ゴ", kun: "",
                hint: "A sundial: an upright pole with its shadow marking twelve noon.",
                words: [
                    KanjiWord("午前", "ごぜん", "morning, a.m."),
                    KanjiWord("午後", "ごご", "afternoon, p.m.")
                ]),
            KanjiEntry("前", "before, front", on: "ゼン", kun: "まえ",
                hint: "Two horns on top like the bow of a boat, and below it a blade (刂) cutting forward through the water: the front.",
                words: [
                    KanjiWord("前", "まえ", "front; before"),
                    KanjiWord("名前", "なまえ", "name"),
                    KanjiWord("〜する前に", "〜する まえ に", "before doing…"),
                    KanjiWord("駅前", "えきまえ", "in front of the station"),
                    KanjiWord("午前", "ごぜん", "morning, a.m.")
                ]),
            KanjiEntry("後", "after, behind", on: "ゴ・コウ", kun: "あと・うし(ろ)",
                hint: "Someone on the road (彳) with a thread (幺) tied round their dragging feet, falling behind everyone else.",
                words: [
                    KanjiWord("後", "あと", "after, later"),
                    KanjiWord("後ろ", "うしろ", "behind"),
                    KanjiWord("明後日", "あさって", "the day after tomorrow"),
                    KanjiWord("午後", "ごご", "afternoon, p.m.")
                ]),
            KanjiEntry("休", "rest", on: "キュウ", kun: "やす(む)",
                hint: "A person (亻) leaning against a tree (木), taking a rest.",
                words: [
                    KanjiWord("休み", "やすみ", "holiday, break"),
                    KanjiWord("春休み", "はるやすみ", "spring vacation"),
                    KanjiWord("夏休み", "なつやすみ", "summer vacation"),
                    KanjiWord("冬休み", "ふゆやすみ", "winter vacation"),
                    KanjiWord("休む", "やすむ", "to rest, take a day off")
                ]),
            KanjiEntry("毎", "every", on: "マイ", kun: "",
                hint: "A mother (母) wearing a hat. Mum is there every day, every morning and every night.",
                words: [
                    KanjiWord("毎日", "まいにち", "every day"),
                    KanjiWord("毎週", "まいしゅう", "every week"),
                    KanjiWord("毎月", "まいつき", "every month"),
                    KanjiWord("毎年", "まいとし", "every year"),
                    KanjiWord("毎朝", "まいあさ", "every morning")
                ]),
            KanjiEntry("何", "what", on: "カ", kun: "なに・なん",
                hint: "A person (亻) shrugging next to an open mouth (口): 'What?'",
                words: [
                    KanjiWord("何", "なに", "what"),
                    KanjiWord("何曜日", "なんようび", "what day of the week"),
                    KanjiWord("何時", "なんじ", "what time"),
                    KanjiWord("何人", "なんにん", "how many people"),
                    KanjiWord("何も", "なにも", "nothing (with a negative)")
                ])
        ],
        sentences: [
            KanjiSentence("今 何時ですか。", "いま なんじ です か。", "What time is it now?", focus: "何時"),
            KanjiSentence("毎朝 六時に おきます。", "まいあさ ろくじ に おきます。", "I get up at six every morning.", focus: "毎朝"),
            KanjiSentence("午後 三時に 先生に 会います。", "ごご さんじ に せんせい に あいます。", "I'll meet the teacher at 3 p.m.", focus: "午後"),
            KanjiSentence("昼休みは 一時間です。", "ひるやすみ は いちじかん です。", "The lunch break is one hour.", focus: "昼休み"),
            KanjiSentence("今晩 べんきょうします。", "こんばん べんきょう します。", "I will study tonight.", focus: "今晩"),
            KanjiSentence("日曜日は 休みです。", "にちようび は やすみ です。", "Sunday is a day off.", focus: "休み"),
            KanjiSentence("ごはんの 後で 本を よみます。", "ごはん の あと で ほん を よみます。", "I read a book after the meal.", focus: "後"),
            KanjiSentence("今日は 何曜日ですか。", "きょう は なんようび です か。", "What day of the week is it today?", focus: "今日"),
            KanjiSentence("会社は 九時半からです。", "かいしゃ は くじはん から です。", "Work starts at 9:30.", focus: "九時半"),
            KanjiSentence("五分 休みましょう。", "ごふん やすみましょう。", "Let's rest for five minutes.", focus: "五分"),
            KanjiSentence("ごはんの 前に 水を のみます。", "ごはん の まえ に みず を のみます。", "I drink water before the meal.", focus: "前")
        ]
    )

    // MARK: - Unit 5

    static let unit5 = KanjiUnit(
        number: 5,
        title: "Going Places",
        videoID: "CQI1aNTdxUA",
        kanji: [
            KanjiEntry("行", "go", on: "コウ・ギョウ", kun: "い(く)",
                hint: "A crossroads seen from above: the place where you choose which way to go.",
                words: [
                    KanjiWord("行く", "いく", "to go"),
                    KanjiWord("行う", "おこなう", "to carry out, hold"),
                    KanjiWord("行", "ぎょう", "line (of text)"),
                    KanjiWord("銀行", "ぎんこう", "bank"),
                    KanjiWord("銀行員", "ぎんこういん", "bank employee"),
                    KanjiWord("旅行", "りょこう", "trip, travel"),
                    KanjiWord("旅行する", "りょこう する", "to travel")
                ]),
            KanjiEntry("来", "come", on: "ライ", kun: "く(る)",
                hint: "A tree (木) with two little hands waving at you: 'Come here!'",
                words: [
                    KanjiWord("来る", "くる", "to come"),
                    KanjiWord("来週", "らいしゅう", "next week"),
                    KanjiWord("来年", "らいねん", "next year"),
                    KanjiWord("来月", "らいげつ", "next month"),
                    KanjiWord("外来語", "がいらいご", "loanword")
                ]),
            KanjiEntry("校", "school", on: "コウ", kun: "",
                hint: "A tree (木) beside people mixing together (交): children playing under the big tree in the school yard.",
                words: [
                    KanjiWord("学校", "がっこう", "school"),
                    KanjiWord("小学校", "しょうがっこう", "elementary school"),
                    KanjiWord("中学校", "ちゅうがっこう", "junior high school"),
                    KanjiWord("高校", "こうこう", "high school")
                ]),
            KanjiEntry("週", "week", on: "シュウ", kun: "",
                hint: "The road radical (辶) carrying a lap (周): one lap around all seven days is a week.",
                words: [
                    KanjiWord("先週", "せんしゅう", "last week"),
                    KanjiWord("今週", "こんしゅう", "this week"),
                    KanjiWord("毎週", "まいしゅう", "every week"),
                    KanjiWord("二週間", "にしゅうかん", "two weeks")
                ]),
            KanjiEntry("去", "past, leave", on: "キョ", kun: "",
                hint: "Earth (土) on top and a bent elbow (厶) below: someone stepping off the land and leaving. Gone, in the past.",
                words: [
                    KanjiWord("去年", "きょねん", "last year")
                ]),
            KanjiEntry("年", "year", on: "ネン", kun: "とし",
                hint: "A farmer carrying a bundle of harvested rice on his back. One harvest marks one year.",
                words: [
                    KanjiWord("今年", "ことし", "this year"),
                    KanjiWord("毎年", "まいとし", "every year"),
                    KanjiWord("一年", "いちねん", "one year"),
                    KanjiWord("一年前", "いちねんまえ", "one year ago"),
                    KanjiWord("生年月日", "せいねんがっぴ", "date of birth"),
                    KanjiWord("三年生", "さんねんせい", "third-year student"),
                    KanjiWord("去年", "きょねん", "last year")
                ]),
            KanjiEntry("駅", "station", on: "エキ", kun: "",
                hint: "A horse (馬) on the left. Stations were once the places where travellers changed horses.",
                words: [
                    KanjiWord("駅", "えき", "station"),
                    KanjiWord("東京駅", "とうきょう えき", "Tokyo Station"),
                    KanjiWord("駅前", "えきまえ", "in front of the station")
                ]),
            KanjiEntry("電", "electricity", on: "デン", kun: "",
                hint: "Rain (雨) on top, and a bolt of lightning striking down into the field (田) with its tail curling away.",
                words: [
                    KanjiWord("電車", "でんしゃ", "train"),
                    KanjiWord("電話", "でんわ", "telephone"),
                    KanjiWord("電話する", "でんわ する", "to make a phone call"),
                    KanjiWord("電気", "でんき", "electricity; light")
                ]),
            KanjiEntry("車", "car, vehicle", on: "シャ", kun: "くるま",
                hint: "A cart seen from above: the box in the middle, an axle running through it, and a wheel at each end.",
                words: [
                    KanjiWord("車", "くるま", "car"),
                    KanjiWord("自転車", "じてんしゃ", "bicycle"),
                    KanjiWord("自動車", "じどうしゃ", "automobile"),
                    KanjiWord("電車", "でんしゃ", "train")
                ]),
            KanjiEntry("自", "self", on: "ジ", kun: "",
                hint: "An eye (目) with a little stroke on top: a nose. In Japan you point at your nose to say 'me, myself'.",
                words: [
                    KanjiWord("自分", "じぶん", "oneself"),
                    KanjiWord("自己紹介", "じこ しょうかい", "self-introduction"),
                    KanjiWord("自転車", "じてんしゃ", "bicycle")
                ]),
            KanjiEntry("転", "roll, turn", on: "テン", kun: "ころ(がる)",
                hint: "A car (車) on the left, with its wheels rolling and turning over and over.",
                words: [
                    KanjiWord("運転", "うんてん", "driving"),
                    KanjiWord("運転する", "うんてん する", "to drive"),
                    KanjiWord("転がる", "ころがる", "to roll"),
                    KanjiWord("自転車", "じてんしゃ", "bicycle")
                ]),
            KanjiEntry("動", "move", on: "ドウ", kun: "うご(く)",
                hint: "Something heavy (重) plus power (力). It takes power to make a heavy thing move.",
                words: [
                    KanjiWord("動物", "どうぶつ", "animal"),
                    KanjiWord("動く", "うごく", "to move"),
                    KanjiWord("自動車", "じどうしゃ", "automobile")
                ])
        ],
        sentences: [
            KanjiSentence("毎日 電車で 会社へ 行きます。", "まいにち でんしゃ で かいしゃ へ いきます。", "I go to work by train every day.", focus: "電車"),
            KanjiSentence("来週 日本へ 行きます。", "らいしゅう にほん へ いきます。", "I'm going to Japan next week.", focus: "来週"),
            KanjiSentence("去年 日本へ 来ました。", "きょねん にほん へ きました。", "I came to Japan last year.", focus: "去年"),
            KanjiSentence("駅まで 自転車で 行きます。", "えき まで じてんしゃ で いきます。", "I go to the station by bicycle.", focus: "自転車"),
            KanjiSentence("学校は 八時半からです。", "がっこう は はちじはん から です。", "School starts at 8:30.", focus: "学校"),
            KanjiSentence("山田さんの 車は 日本の 車です。", "やまだ さん の くるま は にほん の くるま です。", "Mr. Yamada's car is a Japanese car.", focus: "車"),
            KanjiSentence("駅の 前に 銀行が あります。", "えき の まえ に ぎんこう が あります。", "There is a bank in front of the station.", focus: "銀行"),
            KanjiSentence("あの 人は 毎年 中国へ 行きます。", "あの ひと は まいとし ちゅうごく へ いきます。", "That person goes to China every year.", focus: "毎年"),
            KanjiSentence("あの 車は 動きません。", "あの くるま は うごきません。", "That car doesn't move.", focus: "動きません")
        ]
    )
}
