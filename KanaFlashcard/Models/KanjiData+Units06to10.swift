import Foundation

// Units 6–10 of the NihonGoal "Minna No Nihongo Kanji" video series.

extension KanjiData {

    // MARK: - Unit 6

    static let unit6 = KanjiUnit(
        number: 6,
        title: "Sizes & Colours",
        videoID: "h1p-sIuth6Y",
        kanji: [
            KanjiEntry("高", "tall, expensive", on: "コウ", kun: "たか(い)",
                hint: "A tall tower with a roof on top and windows on two floors. Tall, and expensive to build.",
                words: [
                    KanjiWord("高い", "たかい", "tall; expensive"),
                    KanjiWord("高校", "こうこう", "high school"),
                    KanjiWord("高校生", "こうこうせい", "high school student")
                ]),
            KanjiEntry("安", "cheap, safe", on: "アン", kun: "やす(い)",
                hint: "A woman (女) under a roof (宀). At home everyone feels safe and at ease, and staying home is cheap.",
                words: [
                    KanjiWord("安い", "やすい", "cheap"),
                    KanjiWord("円安", "えんやす", "weak yen"),
                    KanjiWord("安心", "あんしん", "peace of mind"),
                    KanjiWord("安全", "あんぜん", "safety")
                ]),
            KanjiEntry("大", "big", on: "ダイ・タイ", kun: "おお(きい)",
                hint: "A person (人) stretching both arms out wide: 'It was THIS big!'",
                words: [
                    KanjiWord("大きい", "おおきい", "big"),
                    KanjiWord("大雨", "おおあめ", "heavy rain"),
                    KanjiWord("大水", "おおみず", "flood"),
                    KanjiWord("大学", "だいがく", "university"),
                    KanjiWord("大学生", "だいがくせい", "university student"),
                    KanjiWord("大使館", "たいしかん", "embassy"),
                    KanjiWord("大人", "おとな", "adult"),
                    KanjiWord("大人しい", "おとなしい", "quiet, well-behaved"),
                    KanjiWord("大好きな", "だいすきな", "favourite, much-loved"),
                    KanjiWord("大切な", "たいせつな", "important, precious"),
                    KanjiWord("大会", "たいかい", "tournament, convention"),
                    KanjiWord("大変", "たいへん", "very; tough, serious"),
                    KanjiWord("お大事に", "おだいじに", "get well soon")
                ]),
            KanjiEntry("小", "small", on: "ショウ", kun: "ちい(さい)",
                hint: "A person with both arms hanging down close to the body, making themselves small.",
                words: [
                    KanjiWord("小さい", "ちいさい", "small"),
                    KanjiWord("小学校", "しょうがっこう", "elementary school"),
                    KanjiWord("小学生", "しょうがくせい", "elementary school pupil")
                ]),
            KanjiEntry("新", "new", on: "シン", kun: "あたら(しい)",
                hint: "Standing (立) on a tree (木) with an axe (斤): chopping fresh wood to build something new.",
                words: [
                    KanjiWord("新しい", "あたらしい", "new"),
                    KanjiWord("新聞", "しんぶん", "newspaper"),
                    KanjiWord("新年", "しんねん", "new year")
                ]),
            KanjiEntry("古", "old", on: "コ", kun: "ふる(い)",
                hint: "Ten (十) over a mouth (口). A story passed down through ten generations of mouths is old.",
                words: [
                    KanjiWord("古い", "ふるい", "old (things)"),
                    KanjiWord("古本", "ふるほん", "second-hand book"),
                    KanjiWord("中古", "ちゅうこ", "second-hand, used")
                ]),
            KanjiEntry("青", "blue", on: "セイ", kun: "あお(い)",
                hint: "Fresh plants growing on top, with the moon (月) below: the cool blue-green of young leaves in the moonlight.",
                words: [
                    KanjiWord("青", "あお", "the colour blue"),
                    KanjiWord("青い", "あおい", "blue")
                ]),
            KanjiEntry("白", "white", on: "ハク", kun: "しろ(い)",
                hint: "The sun (日) with one ray of light shooting out of the top: blinding white light.",
                words: [
                    KanjiWord("白", "しろ", "the colour white"),
                    KanjiWord("白い", "しろい", "white"),
                    KanjiWord("面白い", "おもしろい", "interesting, funny")
                ]),
            KanjiEntry("赤", "red", on: "セキ", kun: "あか(い)",
                hint: "Earth (土) on top with flames flickering underneath. Soil baked in a fire glows red.",
                words: [
                    KanjiWord("赤", "あか", "the colour red"),
                    KanjiWord("赤い", "あかい", "red"),
                    KanjiWord("赤ちゃん", "あかちゃん", "baby")
                ]),
            KanjiEntry("黒", "black", on: "コク", kun: "くろ(い)",
                hint: "A chimney grate above four flames (灬). Soot from the fire turns everything black.",
                words: [
                    KanjiWord("黒", "くろ", "the colour black"),
                    KanjiWord("黒い", "くろい", "black"),
                    KanjiWord("黒板", "こくばん", "blackboard")
                ])
        ],
        sentences: [
            KanjiSentence("この 車は 高いです。", "この くるま は たかい です。", "This car is expensive.", focus: "高い"),
            KanjiSentence("この 本は 安いです。", "この ほん は やすい です。", "This book is cheap.", focus: "安い"),
            KanjiSentence("わたしの 大学は 大きいです。", "わたし の だいがく は おおきい です。", "My university is big.", focus: "大きい"),
            KanjiSentence("小さい 車を かいました。", "ちいさい くるま を かいました。", "I bought a small car.", focus: "小さい"),
            KanjiSentence("新しい 自転車が ほしいです。", "あたらしい じてんしゃ が ほしい です。", "I want a new bicycle.", focus: "新しい"),
            KanjiSentence("わたしの 学校は 古いです。", "わたし の がっこう は ふるい です。", "My school is old.", focus: "古い"),
            KanjiSentence("白い 車と 黒い 車が あります。", "しろい くるま と くろい くるま が あります。", "There is a white car and a black car.", focus: "白い"),
            KanjiSentence("赤い 電車で 行きます。", "あかい でんしゃ で いきます。", "I go on the red train.", focus: "赤い"),
            KanjiSentence("今日は そらが 青いです。", "きょう は そら が あおい です。", "The sky is blue today.", focus: "青い")
        ]
    )

    // MARK: - Unit 7

    static let unit7 = KanjiUnit(
        number: 7,
        title: "Family, Food & Drink",
        videoID: "JTOigZ3LlaE",
        kanji: [
            KanjiEntry("上", "up, above", on: "ジョウ", kun: "うえ・あ(がる)",
                hint: "A marker standing above the ground line, pointing up.",
                words: [
                    KanjiWord("上", "うえ", "on top, above"),
                    KanjiWord("上着", "うわぎ", "jacket"),
                    KanjiWord("上る", "のぼる", "to climb, go up"),
                    KanjiWord("上がる", "あがる", "to rise, go up"),
                    KanjiWord("上手", "じょうず", "skilful, good at"),
                    KanjiWord("屋上", "おくじょう", "rooftop")
                ]),
            KanjiEntry("下", "down, below", on: "カ・ゲ", kun: "した・さ(がる)",
                hint: "A marker hanging below the line, pointing down.",
                words: [
                    KanjiWord("下", "した", "under, below"),
                    KanjiWord("下着", "したぎ", "underwear"),
                    KanjiWord("下手", "へた", "unskilful, poor at"),
                    KanjiWord("下がる", "さがる", "to go down, drop"),
                    KanjiWord("地下", "ちか", "underground, basement"),
                    KanjiWord("地下鉄", "ちかてつ", "subway"),
                    KanjiWord("地下室", "ちかしつ", "basement room")
                ]),
            KanjiEntry("父", "father", on: "フ", kun: "ちち",
                hint: "Dad's face: two eyebrows on top and a crossed moustache below.",
                words: [
                    KanjiWord("父", "ちち", "(my) father"),
                    KanjiWord("お父さん", "おとうさん", "father (polite)"),
                    KanjiWord("お祖父さん", "おじいさん", "grandfather"),
                    KanjiWord("伯父さん", "おじさん", "uncle")
                ]),
            KanjiEntry("母", "mother", on: "ボ", kun: "はは",
                hint: "A mother holding her baby close to her chest.",
                words: [
                    KanjiWord("母", "はは", "(my) mother"),
                    KanjiWord("お母さん", "おかあさん", "mother (polite)"),
                    KanjiWord("お祖母さん", "おばあさん", "grandmother"),
                    KanjiWord("伯母さん", "おばさん", "aunt")
                ]),
            KanjiEntry("子", "child", on: "シ", kun: "こ",
                hint: "A baby wrapped in a blanket, with its arms stretched out wide.",
                words: [
                    KanjiWord("子", "こ", "child"),
                    KanjiWord("子ども", "こども", "child, kid"),
                    KanjiWord("男の子", "おとこ の こ", "boy"),
                    KanjiWord("女の子", "おんな の こ", "girl"),
                    KanjiWord("椅子", "いす", "chair"),
                    KanjiWord("帽子", "ぼうし", "hat, cap")
                ]),
            KanjiEntry("手", "hand", on: "シュ", kun: "て",
                hint: "An open hand: the lines across are the fingers, and the curved stroke is the wrist.",
                words: [
                    KanjiWord("手", "て", "hand"),
                    KanjiWord("右手", "みぎて", "right hand"),
                    KanjiWord("左手", "ひだりて", "left hand"),
                    KanjiWord("手伝う", "てつだう", "to help"),
                    KanjiWord("手帳", "てちょう", "pocket planner"),
                    KanjiWord("手紙", "てがみ", "letter"),
                    KanjiWord("切手", "きって", "postage stamp"),
                    KanjiWord("歌手", "かしゅ", "singer"),
                    KanjiWord("選手", "せんしゅ", "athlete, player")
                ]),
            KanjiEntry("好", "like", on: "コウ", kun: "す(き)",
                hint: "A woman (女) with her child (子). A mother loves her child.",
                words: [
                    KanjiWord("好き", "すき", "like, fond of"),
                    KanjiWord("大好き", "だいすき", "love, like very much")
                ]),
            KanjiEntry("主", "master, main", on: "シュ", kun: "おも",
                hint: "A king (王) with a flame burning above his crown: the master, the main person of the house.",
                words: [
                    KanjiWord("主人", "しゅじん", "(my) husband"),
                    KanjiWord("ご主人", "ごしゅじん", "(your) husband")
                ]),
            KanjiEntry("肉", "meat", on: "ニク", kun: "",
                hint: "A slab of meat with the ribs showing inside.",
                words: [
                    KanjiWord("肉", "にく", "meat"),
                    KanjiWord("豚肉", "ぶたにく", "pork"),
                    KanjiWord("牛肉", "ぎゅうにく", "beef")
                ]),
            KanjiEntry("魚", "fish", on: "ギョ", kun: "さかな",
                hint: "A fish standing on its tail: the head on top, a scaly body (田) in the middle and tail fins (灬) at the bottom.",
                words: [
                    KanjiWord("魚", "さかな", "fish"),
                    KanjiWord("金魚", "きんぎょ", "goldfish")
                ]),
            KanjiEntry("食", "eat", on: "ショク", kun: "た(べる)",
                hint: "A roof over a good (良) meal: sitting down at home to eat.",
                words: [
                    KanjiWord("食べる", "たべる", "to eat"),
                    KanjiWord("食べ物", "たべもの", "food"),
                    KanjiWord("食堂", "しょくどう", "cafeteria"),
                    KanjiWord("食事", "しょくじ", "meal"),
                    KanjiWord("主食", "しゅしょく", "staple food"),
                    KanjiWord("昼食", "ちゅうしょく", "lunch (formal)"),
                    KanjiWord("給食", "きゅうしょく", "school lunch")
                ]),
            KanjiEntry("飲", "drink", on: "イン", kun: "の(む)",
                hint: "The food radical (飠) on the left, and on the right a person with their mouth wide open (欠), ready to drink.",
                words: [
                    KanjiWord("飲む", "のむ", "to drink"),
                    KanjiWord("飲み物", "のみもの", "a drink, beverage")
                ]),
            KanjiEntry("物", "thing", on: "ブツ・モツ", kun: "もの",
                hint: "A cow (牛) on the left. Long ago, a cow was the most valuable thing a family owned.",
                words: [
                    KanjiWord("物", "もの", "thing"),
                    KanjiWord("建物", "たてもの", "building"),
                    KanjiWord("着物", "きもの", "kimono"),
                    KanjiWord("果物", "くだもの", "fruit"),
                    KanjiWord("買い物", "かいもの", "shopping"),
                    KanjiWord("買い物する", "かいもの する", "to go shopping"),
                    KanjiWord("本物", "ほんもの", "the real thing"),
                    KanjiWord("動物", "どうぶつ", "animal"),
                    KanjiWord("生き物", "いきもの", "living creature"),
                    KanjiWord("生物", "せいぶつ", "living things; biology")
                ])
        ],
        sentences: [
            KanjiSentence("つくえの 上に 本が あります。", "つくえ の うえ に ほん が あります。", "There is a book on the desk.", focus: "上"),
            KanjiSentence("木の 下で 休みます。", "き の した で やすみます。", "I rest under the tree.", focus: "下"),
            KanjiSentence("父は 会社員です。", "ちち は かいしゃいん です。", "My father is an office worker.", focus: "父"),
            KanjiSentence("母は 魚が 好きです。", "はは は さかな が すき です。", "My mother likes fish.", focus: "魚"),
            KanjiSentence("毎朝 パンを 食べます。", "まいあさ パン を たべます。", "I eat bread every morning.", focus: "食べます"),
            KanjiSentence("毎晩 ビールを 飲みます。", "まいばん ビール を のみます。", "I drink beer every night.", focus: "飲みます"),
            KanjiSentence("子どもは 肉が 大好きです。", "こども は にく が だいすき です。", "Children love meat.", focus: "肉"),
            KanjiSentence("田中さんは テニスが 上手です。", "たなか さん は テニス が じょうず です。", "Mr. Tanaka is good at tennis.", focus: "上手"),
            KanjiSentence("手を あらいます。", "て を あらいます。", "I wash my hands.", focus: "手"),
            KanjiSentence("飲み物は 何が 好きですか。", "のみもの は なに が すき です か。", "What drinks do you like?", focus: "飲み物"),
            KanjiSentence("主人は 会社員です。", "しゅじん は かいしゃいん です。", "My husband is an office worker.", focus: "主人")
        ]
    )

    // MARK: - Unit 8

    static let unit8 = KanjiUnit(
        number: 8,
        title: "Positions & People",
        videoID: "clkNnY4tHjI",
        kanji: [
            KanjiEntry("近", "near", on: "キン", kun: "ちか(い)",
                hint: "The road radical (辶) with an axe (斤). The firewood is only a short walk down the road: it is near.",
                words: [
                    KanjiWord("近い", "ちかい", "near, close"),
                    KanjiWord("近く", "ちかく", "nearby, neighbourhood"),
                    KanjiWord("近くの", "ちかく の", "nearby (before a noun)"),
                    KanjiWord("近道", "ちかみち", "shortcut"),
                    KanjiWord("最近", "さいきん", "recently")
                ]),
            KanjiEntry("間", "between, interval", on: "カン", kun: "あいだ",
                hint: "The sun (日) shining through the gap between the two doors of a gate (門).",
                words: [
                    KanjiWord("間", "あいだ", "between"),
                    KanjiWord("この間", "この あいだ", "the other day"),
                    KanjiWord("時間", "じかん", "time"),
                    KanjiWord("二時間", "にじかん", "two hours"),
                    KanjiWord("二週間", "にしゅうかん", "two weeks"),
                    KanjiWord("二年間", "にねんかん", "two years"),
                    KanjiWord("一週間", "いっしゅうかん", "one week")
                ]),
            KanjiEntry("右", "right", on: "ウ・ユウ", kun: "みぎ",
                hint: "A hand (ナ) over a mouth (口): the hand you eat with is your right hand.",
                words: [
                    KanjiWord("右", "みぎ", "right"),
                    KanjiWord("右手", "みぎて", "right hand"),
                    KanjiWord("右足", "みぎあし", "right foot")
                ]),
            KanjiEntry("左", "left", on: "サ", kun: "ひだり",
                hint: "A hand (ナ) over a carpenter's ruler (工). The left hand holds the ruler while the right hand draws.",
                words: [
                    KanjiWord("左", "ひだり", "left"),
                    KanjiWord("左手", "ひだりて", "left hand"),
                    KanjiWord("左足", "ひだりあし", "left foot")
                ]),
            KanjiEntry("外", "outside", on: "ガイ", kun: "そと",
                hint: "It looks like katakana タ and ト standing side by side, waiting outside the door.",
                words: [
                    KanjiWord("外", "そと", "outside"),
                    KanjiWord("外国", "がいこく", "foreign country"),
                    KanjiWord("外国語", "がいこくご", "foreign language"),
                    KanjiWord("外来語", "がいらいご", "loanword"),
                    KanjiWord("海外", "かいがい", "overseas"),
                    KanjiWord("外国人", "がいこくじん", "foreigner")
                ]),
            KanjiEntry("男", "man", on: "ダン", kun: "おとこ",
                hint: "A rice field (田) over power (力): the one using his strength in the fields.",
                words: [
                    KanjiWord("男", "おとこ", "man, male"),
                    KanjiWord("男の人", "おとこ の ひと", "man"),
                    KanjiWord("男の子", "おとこ の こ", "boy")
                ]),
            KanjiEntry("女", "woman", on: "ジョ", kun: "おんな",
                hint: "A woman kneeling gracefully with her arms crossed in front of her.",
                words: [
                    KanjiWord("女", "おんな", "woman, female"),
                    KanjiWord("女の人", "おんな の ひと", "woman"),
                    KanjiWord("女の子", "おんな の こ", "girl"),
                    KanjiWord("彼女", "かのじょ", "she; girlfriend")
                ]),
            KanjiEntry("犬", "dog", on: "ケン", kun: "いぬ",
                hint: "A big (大) person throwing a ball for the dog. The dot is the ball flying through the air.",
                words: [
                    KanjiWord("犬", "いぬ", "dog"),
                    KanjiWord("子犬", "こいぬ", "puppy")
                ])
        ],
        sentences: [
            KanjiSentence("駅は 会社から 近いです。", "えき は かいしゃ から ちかい です。", "The station is near the office.", focus: "近い"),
            KanjiSentence("銀行と 学校の 間に 本屋が あります。", "ぎんこう と がっこう の あいだ に ほんや が あります。", "There is a bookstore between the bank and the school.", focus: "間"),
            KanjiSentence("右に 行って ください。", "みぎ に いって ください。", "Please go right.", focus: "右", speech: "右にいってください。"),
            KanjiSentence("銀行は 左に あります。", "ぎんこう は ひだり に あります。", "The bank is on the left.", focus: "左"),
            KanjiSentence("外は さむいです。", "そと は さむい です。", "It's cold outside.", focus: "外"),
            KanjiSentence("あの 男の 人は 先生です。", "あの おとこ の ひと は せんせい です。", "That man is a teacher.", focus: "男"),
            KanjiSentence("女の 子が 二人 います。", "おんな の こ が ふたり います。", "There are two girls.", focus: "女"),
            KanjiSentence("犬と こうえんで あそびます。", "いぬ と こうえん で あそびます。", "I play with the dog in the park.", focus: "犬")
        ]
    )

    // MARK: - Unit 9

    static let unit9 = KanjiUnit(
        number: 9,
        title: "Everyday Verbs",
        videoID: "rwQHwiIqkwg",
        kanji: [
            KanjiEntry("書", "write", on: "ショ", kun: "か(く)",
                hint: "A hand gripping a brush at the top, writing on the sheet of paper (日) below.",
                words: [
                    KanjiWord("書く", "かく", "to write"),
                    KanjiWord("書き方", "かきかた", "how to write"),
                    KanjiWord("図書館", "としょかん", "library"),
                    KanjiWord("辞書", "じしょ", "dictionary")
                ]),
            KanjiEntry("聞", "hear, ask", on: "ブン", kun: "き(く)",
                hint: "An ear (耳) pressed up against a gate (門), listening to what is being said inside.",
                words: [
                    KanjiWord("聞く", "きく", "to listen; to ask"),
                    KanjiWord("聞こえる", "きこえる", "to be heard, can hear"),
                    KanjiWord("新聞", "しんぶん", "newspaper")
                ]),
            KanjiEntry("読", "read", on: "ドク", kun: "よ(む)",
                hint: "Words (言) on the left and selling (売) on the right: reading out the words on the price tags at a market.",
                words: [
                    KanjiWord("読む", "よむ", "to read"),
                    KanjiWord("読み方", "よみかた", "way of reading")
                ]),
            KanjiEntry("見", "see, look", on: "ケン", kun: "み(る)",
                hint: "A big eye (目) walking around on two legs, looking at everything.",
                words: [
                    KanjiWord("見る", "みる", "to see, watch"),
                    KanjiWord("見せる", "みせる", "to show"),
                    KanjiWord("見える", "みえる", "to be visible, can see"),
                    KanjiWord("意見", "いけん", "opinion"),
                    KanjiWord("見学", "けんがく", "study visit, tour")
                ]),
            KanjiEntry("話", "talk, speak", on: "ワ", kun: "はな(す)",
                hint: "Words (言) plus a tongue (舌): moving your tongue to make words.",
                words: [
                    KanjiWord("話", "はなし", "talk, story"),
                    KanjiWord("話す", "はなす", "to speak"),
                    KanjiWord("話し中", "はなしちゅう", "busy (on the phone)"),
                    KanjiWord("電話", "でんわ", "telephone"),
                    KanjiWord("電話する", "でんわ する", "to make a phone call"),
                    KanjiWord("会話", "かいわ", "conversation"),
                    KanjiWord("世話", "せわ", "care, looking after")
                ]),
            KanjiEntry("買", "buy", on: "バイ", kun: "か(う)",
                hint: "A net (罒) over a shell (貝), and shells were once money: filling your shopping net and paying with shells.",
                words: [
                    KanjiWord("買う", "かう", "to buy"),
                    KanjiWord("買い物", "かいもの", "shopping"),
                    KanjiWord("買い物する", "かいもの する", "to go shopping")
                ]),
            KanjiEntry("起", "get up", on: "キ", kun: "お(きる)",
                hint: "Run (走) plus self (己): you get yourself up and get going.",
                words: [
                    KanjiWord("起きる", "おきる", "to get up, wake up"),
                    KanjiWord("起こる", "おこる", "to happen"),
                    KanjiWord("起こす", "おこす", "to wake (someone) up")
                ]),
            KanjiEntry("帰", "return home", on: "キ", kun: "かえ(る)",
                hint: "Two footsteps on the left heading back to the house, where the broom (帚) and the housework are waiting.",
                words: [
                    KanjiWord("帰る", "かえる", "to go home, return"),
                    KanjiWord("帰国する", "きこく する", "to return to one's country")
                ]),
            KanjiEntry("友", "friend", on: "ユウ", kun: "とも",
                hint: "Two hands reaching towards each other: friends holding hands.",
                words: [
                    KanjiWord("友達", "ともだち", "friend"),
                    KanjiWord("友人", "ゆうじん", "friend (formal)")
                ]),
            KanjiEntry("達", "reach, attain", on: "タツ", kun: "",
                hint: "The road radical (辶) with earth (土) and a sheep (羊): walking the sheep down the road until you reach the pasture.",
                words: [
                    KanjiWord("友達", "ともだち", "friend"),
                    KanjiWord("速達", "そくたつ", "express mail")
                ])
        ],
        sentences: [
            KanjiSentence("手紙を 書きます。", "てがみ を かきます。", "I write a letter.", focus: "書きます"),
            KanjiSentence("毎朝 新聞を 読みます。", "まいあさ しんぶん を よみます。", "I read the newspaper every morning.", focus: "読みます"),
            KanjiSentence("ラジオを 聞きます。", "ラジオ を ききます。", "I listen to the radio.", focus: "聞きます"),
            KanjiSentence("日曜日に 友達と えいがを 見ます。", "にちようび に ともだち と えいが を みます。", "I watch a movie with a friend on Sunday.", focus: "見ます"),
            KanjiSentence("先生と 日本語で 話します。", "せんせい と にほんご で はなします。", "I speak with the teacher in Japanese.", focus: "話します"),
            KanjiSentence("デパートで 買い物します。", "デパート で かいもの します。", "I go shopping at the department store.", focus: "買い物"),
            KanjiSentence("毎朝 六時に 起きます。", "まいあさ ろくじ に おきます。", "I get up at six every morning.", focus: "起きます"),
            KanjiSentence("五時に うちへ 帰ります。", "ごじ に うち へ かえります。", "I go home at five o'clock.", focus: "帰ります"),
            KanjiSentence("駅で 友達に 会いました。", "えき で ともだち に あいました。", "I met a friend at the station.", focus: "友達")
        ]
    )

    // MARK: - Unit 10

    static let unit10 = KanjiUnit(
        number: 10,
        title: "Tea, Photos, Movies & Languages",
        videoID: "GWJaEkvlh80",
        kanji: [
            KanjiEntry("茶", "tea", on: "チャ・サ", kun: "",
                hint: "Plants (艹) on top, then a roof and a tree (木): leaves picked from the bush and brewed at home.",
                words: [
                    KanjiWord("お茶", "おちゃ", "tea"),
                    KanjiWord("紅茶", "こうちゃ", "black tea"),
                    KanjiWord("茶色", "ちゃいろ", "brown"),
                    KanjiWord("喫茶店", "きっさてん", "coffee shop")
                ]),
            KanjiEntry("酒", "alcohol, sake", on: "シュ", kun: "さけ",
                hint: "Water drops (氵) next to a wine jar (酉): the liquid that comes out of the jar.",
                words: [
                    KanjiWord("お酒", "おさけ", "alcohol, sake"),
                    KanjiWord("日本酒", "にほんしゅ", "Japanese sake")
                ]),
            KanjiEntry("写", "copy", on: "シャ", kun: "うつ(す)",
                hint: "A cover (冖) laid over something that is being traced underneath: making a copy.",
                words: [
                    KanjiWord("写真", "しゃしん", "photograph"),
                    KanjiWord("写す", "うつす", "to copy")
                ]),
            KanjiEntry("真", "true, real", on: "シン", kun: "ま",
                hint: "Ten (十) eyes (目) on a table, all looking at one thing. With ten eyes watching, the truth comes out.",
                words: [
                    KanjiWord("写真", "しゃしん", "photograph"),
                    KanjiWord("真ん中", "まんなか", "the very middle")
                ]),
            KanjiEntry("紙", "paper", on: "シ", kun: "かみ",
                hint: "Thread (糸) on the left. Paper is made by pressing thin threads of fibre together into a sheet.",
                words: [
                    KanjiWord("紙", "かみ", "paper"),
                    KanjiWord("手紙", "てがみ", "letter")
                ]),
            KanjiEntry("映", "project, reflect", on: "エイ", kun: "うつ(る)",
                hint: "The sun (日) beside a person standing in the centre (央): light projected onto the middle of the screen.",
                words: [
                    KanjiWord("映画", "えいが", "movie"),
                    KanjiWord("映画館", "えいがかん", "movie theatre")
                ]),
            KanjiEntry("画", "picture", on: "ガ・カク", kun: "",
                hint: "A rice field (田) set inside a frame: a picture hanging in its frame.",
                words: [
                    KanjiWord("画家", "がか", "painter"),
                    KanjiWord("映画", "えいが", "movie"),
                    KanjiWord("漫画", "まんが", "manga, comics")
                ]),
            KanjiEntry("店", "shop", on: "テン", kun: "みせ",
                hint: "Under an awning (广) stands a little sign on a counter (占): a small shop, open for business.",
                words: [
                    KanjiWord("店", "みせ", "shop"),
                    KanjiWord("売店", "ばいてん", "kiosk"),
                    KanjiWord("店員", "てんいん", "shop assistant"),
                    KanjiWord("喫茶店", "きっさてん", "coffee shop")
                ]),
            KanjiEntry("英", "English, excellent", on: "エイ", kun: "",
                hint: "Grass (艹) over the centre (央): a flower blooming in the centre of an English garden.",
                words: [
                    KanjiWord("英語", "えいご", "English (language)"),
                    KanjiWord("英国", "えいこく", "Britain")
                ]),
            KanjiEntry("語", "language, word", on: "ゴ", kun: "",
                hint: "Words (言) plus five (五) mouths (口): five mouths all talking together make a language.",
                words: [
                    KanjiWord("単語", "たんご", "word, vocabulary item"),
                    KanjiWord("言語", "げんご", "language"),
                    KanjiWord("日本語", "にほんご", "Japanese (language)"),
                    KanjiWord("中国語", "ちゅうごくご", "Chinese (language)"),
                    KanjiWord("外来語", "がいらいご", "loanword"),
                    KanjiWord("英語", "えいご", "English (language)"),
                    KanjiWord("外国語", "がいこくご", "foreign language")
                ])
        ],
        sentences: [
            KanjiSentence("毎朝 お茶を 飲みます。", "まいあさ おちゃ を のみます。", "I drink tea every morning.", focus: "お茶"),
            KanjiSentence("父は お酒が 好きです。", "ちち は おさけ が すき です。", "My father likes alcohol.", focus: "お酒"),
            KanjiSentence("山で 写真を とりました。", "やま で しゃしん を とりました。", "I took photos in the mountains.", focus: "写真"),
            KanjiSentence("友達に 手紙を 書きます。", "ともだち に てがみ を かきます。", "I write a letter to my friend.", focus: "手紙"),
            KanjiSentence("土曜日に 映画を 見ました。", "どようび に えいが を みました。", "I watched a movie on Saturday.", focus: "映画"),
            KanjiSentence("あの 店は 安いです。", "あの みせ は やすい です。", "That shop is cheap.", focus: "店"),
            KanjiSentence("山田さんは 英語を 話します。", "やまだ さん は えいご を はなします。", "Mr. Yamada speaks English.", focus: "英語"),
            KanjiSentence("日本語は 面白いです。", "にほんご は おもしろい です。", "Japanese is interesting.", focus: "日本語"),
            KanjiSentence("紙に 名前を 書いて ください。", "かみ に なまえ を かいて ください。", "Please write your name on the paper.", focus: "紙")
        ]
    )
}
