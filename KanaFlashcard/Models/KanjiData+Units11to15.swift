import Foundation

// Units 11–15 of the NihonGoal "Minna No Nihongo Kanji" video series.

extension KanjiData {

    // MARK: - Unit 11

    static let unit11 = KanjiUnit(
        number: 11,
        title: "Giving, Lending & Studying",
        videoID: "4nn6QsU3acI",
        kanji: [
            KanjiEntry("送", "send", on: "ソウ", kun: "おく(る)",
                hint: "The road radical (辶) carrying a parcel tied with a ribbon on top: sending it on its way.",
                words: [
                    KanjiWord("送る", "おくる", "to send"),
                    KanjiWord("送金", "そうきん", "money transfer")
                ]),
            KanjiEntry("切", "cut", on: "セツ", kun: "き(る)",
                hint: "Seven (七) and a sword (刀): cutting something into seven pieces.",
                words: [
                    KanjiWord("切る", "きる", "to cut"),
                    KanjiWord("切れる", "きれる", "to cut well; to snap, run out"),
                    KanjiWord("切手", "きって", "postage stamp"),
                    KanjiWord("切符", "きっぷ", "ticket"),
                    KanjiWord("親切", "しんせつ", "kind"),
                    KanjiWord("大切", "たいせつ", "important")
                ]),
            KanjiEntry("貸", "lend", on: "タイ", kun: "か(す)",
                hint: "A stand-in (代) above a shell (貝), which was once money: handing your money to someone else for a while.",
                words: [
                    KanjiWord("貸す", "かす", "to lend"),
                    KanjiWord("貸間", "かしま", "room for rent")
                ]),
            KanjiEntry("借", "borrow", on: "シャク", kun: "か(りる)",
                hint: "A person (亻) beside 'long ago' (昔): someone who took something long ago and still has not given it back.",
                words: [
                    KanjiWord("借りる", "かりる", "to borrow"),
                    KanjiWord("借金", "しゃっきん", "debt")
                ]),
            KanjiEntry("旅", "trip, travel", on: "リョ", kun: "たび",
                hint: "A flag (方) with a line of people behind it: a tour group following the guide's flag.",
                words: [
                    KanjiWord("旅", "たび", "journey"),
                    KanjiWord("旅行", "りょこう", "trip, travel"),
                    KanjiWord("旅行する", "りょこう する", "to travel"),
                    KanjiWord("旅館", "りょかん", "Japanese-style inn")
                ]),
            KanjiEntry("教", "teach", on: "キョウ", kun: "おし(える)",
                hint: "A child (子) on the left and a hand holding a pointer (攵) on the right: teaching the young.",
                words: [
                    KanjiWord("教える", "おしえる", "to teach, tell"),
                    KanjiWord("教わる", "おそわる", "to be taught"),
                    KanjiWord("教員", "きょういん", "teacher (staff member)"),
                    KanjiWord("教会", "きょうかい", "church"),
                    KanjiWord("教室", "きょうしつ", "classroom")
                ]),
            KanjiEntry("習", "learn, practise", on: "シュウ", kun: "なら(う)",
                hint: "Wings (羽) over white (白): a white baby bird flapping its wings again and again, learning to fly.",
                words: [
                    KanjiWord("習う", "ならう", "to learn (from someone)"),
                    KanjiWord("学習", "がくしゅう", "learning, study"),
                    KanjiWord("教習", "きょうしゅう", "training, instruction"),
                    KanjiWord("自習", "じしゅう", "self-study"),
                    KanjiWord("復習", "ふくしゅう", "review"),
                    KanjiWord("練習", "れんしゅう", "practice")
                ]),
            KanjiEntry("勉", "effort", on: "ベン", kun: "",
                hint: "Escape (免) plus power (力): using all your strength to break free. That is real effort.",
                words: [
                    KanjiWord("勉強", "べんきょう", "study"),
                    KanjiWord("勉強する", "べんきょう する", "to study")
                ]),
            KanjiEntry("強", "strong", on: "キョウ", kun: "つよ(い)",
                hint: "A bow (弓) and a big horned beetle (虫): a beetle strong enough to bend a bow.",
                words: [
                    KanjiWord("強い", "つよい", "strong"),
                    KanjiWord("強まる", "つよまる", "to get stronger"),
                    KanjiWord("強める", "つよめる", "to strengthen"),
                    KanjiWord("強いて", "しいて", "if I had to; by force"),
                    KanjiWord("勉強", "べんきょう", "study")
                ]),
            KanjiEntry("花", "flower", on: "カ", kun: "はな",
                hint: "Grass (艹) that changes (化): a green plant transforming into a flower.",
                words: [
                    KanjiWord("花", "はな", "flower"),
                    KanjiWord("花びら", "はなびら", "petal"),
                    KanjiWord("火花", "ひばな", "spark"),
                    KanjiWord("生け花", "いけばな", "flower arranging"),
                    KanjiWord("花見", "はなみ", "cherry-blossom viewing"),
                    KanjiWord("花瓶", "かびん", "vase"),
                    KanjiWord("花火", "はなび", "fireworks")
                ])
        ],
        sentences: [
            KanjiSentence("国の 母に 手紙を 送ります。", "くに の はは に てがみ を おくります。", "I send a letter to my mother back home.", focus: "送ります"),
            KanjiSentence("はさみで 紙を 切ります。", "はさみ で かみ を きります。", "I cut paper with scissors.", focus: "切ります"),
            KanjiSentence("友達に お金を 貸しました。", "ともだち に おかね を かしました。", "I lent money to a friend.", focus: "貸しました"),
            KanjiSentence("先生に 本を 借りました。", "せんせい に ほん を かりました。", "I borrowed a book from the teacher.", focus: "借りました"),
            KanjiSentence("来月 日本へ 旅行します。", "らいげつ にほん へ りょこう します。", "I'll travel to Japan next month.", focus: "旅行"),
            KanjiSentence("山田先生は 英語を 教えます。", "やまだ せんせい は えいご を おしえます。", "Mr. Yamada teaches English.", focus: "教えます"),
            KanjiSentence("毎日 日本語を 勉強します。", "まいにち にほんご を べんきょう します。", "I study Japanese every day.", focus: "勉強"),
            KanjiSentence("母に 花を あげました。", "はは に はな を あげました。", "I gave flowers to my mother.", focus: "花"),
            KanjiSentence("日曜日に ピアノを 習います。", "にちようび に ピアノ を ならいます。", "I take piano lessons on Sundays.", focus: "習います"),
            KanjiSentence("父は 強い 人です。", "ちち は つよい ひと です。", "My father is a strong person.", focus: "強い")
        ]
    )

    // MARK: - Unit 12

    static let unit12 = KanjiUnit(
        number: 12,
        title: "Action Verbs",
        videoID: "5ih85W0nA8k",
        kanji: [
            KanjiEntry("歩", "walk", on: "ホ", kun: "ある(く)",
                hint: "Stop (止) on top and a little (少) below: stop a little, step a little. Walking one step at a time.",
                words: [
                    KanjiWord("歩く", "あるく", "to walk"),
                    KanjiWord("歩いて", "あるいて", "on foot"),
                    KanjiWord("散歩", "さんぽ", "a walk, stroll"),
                    KanjiWord("歩道", "ほどう", "sidewalk")
                ]),
            KanjiEntry("待", "wait", on: "タイ", kun: "ま(つ)",
                hint: "A person on the road (彳) by the temple (寺): waiting at the temple gate for someone to arrive.",
                words: [
                    KanjiWord("待つ", "まつ", "to wait")
                ]),
            KanjiEntry("立", "stand", on: "リツ", kun: "た(つ)",
                hint: "A person standing on the ground with their arms and legs apart.",
                words: [
                    KanjiWord("立つ", "たつ", "to stand"),
                    KanjiWord("立ち上がる", "たちあがる", "to stand up"),
                    KanjiWord("国立大学", "こくりつ だいがく", "national university"),
                    KanjiWord("私立大学", "しりつ だいがく", "private university"),
                    KanjiWord("国立病院", "こくりつ びょういん", "national hospital"),
                    KanjiWord("国立図書館", "こくりつ としょかん", "national library")
                ]),
            KanjiEntry("止", "stop", on: "シ", kun: "と(まる)",
                hint: "A footprint planted firmly on the ground line: stop right here.",
                words: [
                    KanjiWord("止める", "とめる", "to stop (something), park"),
                    KanjiWord("止まる", "とまる", "to stop"),
                    KanjiWord("中止", "ちゅうし", "cancellation")
                ]),
            KanjiEntry("雨", "rain", on: "ウ", kun: "あめ",
                hint: "Four raindrops on a window pane, with the cloud stretched across the top.",
                words: [
                    KanjiWord("雨", "あめ", "rain"),
                    KanjiWord("大雨", "おおあめ", "heavy rain"),
                    KanjiWord("雨天", "うてん", "rainy weather")
                ]),
            KanjiEntry("入", "enter", on: "ニュウ", kun: "はい(る)・い(れる)",
                hint: "Like 人 (person), but leaning the other way: a person bending forward to duck in through a doorway.",
                words: [
                    KanjiWord("入る", "はいる", "to enter"),
                    KanjiWord("入れる", "いれる", "to put in"),
                    KanjiWord("入れ物", "いれもの", "container"),
                    KanjiWord("入り口", "いりぐち", "entrance"),
                    KanjiWord("押し入れ", "おしいれ", "closet"),
                    KanjiWord("入学", "にゅうがく", "entering a school"),
                    KanjiWord("新入生", "しんにゅうせい", "new student")
                ]),
            KanjiEntry("出", "go out, exit", on: "シュツ", kun: "で(る)・だ(す)",
                hint: "One mountain (山) on top of another: a sprout pushing its way out, higher and higher.",
                words: [
                    KanjiWord("出る", "でる", "to go out, leave"),
                    KanjiWord("出す", "だす", "to take out, send"),
                    KanjiWord("思い出す", "おもいだす", "to remember, recall"),
                    KanjiWord("出かける", "でかける", "to go out (somewhere)"),
                    KanjiWord("出会う", "であう", "to meet by chance"),
                    KanjiWord("外出", "がいしゅつ", "going out"),
                    KanjiWord("出生", "しゅっしょう", "birth"),
                    KanjiWord("出口", "でぐち", "exit")
                ]),
            KanjiEntry("売", "sell", on: "バイ", kun: "う(る)",
                hint: "A merchant standing behind the covered table of his market stall, selling his goods.",
                words: [
                    KanjiWord("売る", "うる", "to sell"),
                    KanjiWord("売り出し", "うりだし", "sale"),
                    KanjiWord("売り場", "うりば", "sales counter"),
                    KanjiWord("売店", "ばいてん", "kiosk")
                ]),
            KanjiEntry("使", "use", on: "シ", kun: "つか(う)",
                hint: "A person (亻) next to an official (吏). The official uses a person to get the job done.",
                words: [
                    KanjiWord("使う", "つかう", "to use"),
                    KanjiWord("使い方", "つかいかた", "how to use"),
                    KanjiWord("大使", "たいし", "ambassador"),
                    KanjiWord("大使館", "たいしかん", "embassy")
                ]),
            KanjiEntry("作", "make", on: "サク", kun: "つく(る)",
                hint: "A person (亻) next to a saw (乍): a person making something with a saw.",
                words: [
                    KanjiWord("作る", "つくる", "to make"),
                    KanjiWord("作家", "さっか", "writer, author"),
                    KanjiWord("作", "さく", "a work (of art)"),
                    KanjiWord("作物", "さくもつ", "crops"),
                    KanjiWord("作文", "さくぶん", "essay, composition")
                ])
        ],
        sentences: [
            KanjiSentence("駅まで 歩いて 行きます。", "えき まで あるいて いきます。", "I walk to the station.", focus: "歩いて"),
            KanjiSentence("駅の 前で 友達を 待ちます。", "えき の まえ で ともだち を まちます。", "I wait for my friend in front of the station.", focus: "待ちます"),
            KanjiSentence("電車の 中で 立って 本を 読みます。", "でんしゃ の なか で たって ほん を よみます。", "I stand and read a book on the train.", focus: "立って"),
            KanjiSentence("ここに 車を 止めて ください。", "ここ に くるま を とめて ください。", "Please park the car here.", focus: "止めて"),
            KanjiSentence("今日は 雨です。", "きょう は あめ です。", "It's rainy today.", focus: "雨"),
            KanjiSentence("来年 大学に 入ります。", "らいねん だいがく に はいります。", "I'll enter university next year.", focus: "入ります"),
            KanjiSentence("八時に うちを 出ます。", "はちじ に うち を でます。", "I leave home at eight.", focus: "出ます"),
            KanjiSentence("あの 店で 花を 売って います。", "あの みせ で はな を うって います。", "They sell flowers at that shop.", focus: "売って"),
            KanjiSentence("この 電話を 使って ください。", "この でんわ を つかって ください。", "Please use this telephone.", focus: "使って"),
            KanjiSentence("母は 毎日 ごはんを 作ります。", "はは は まいにち ごはん を つくります。", "My mother makes meals every day.", focus: "作ります")
        ]
    )

    // MARK: - Unit 13

    static let unit13 = KanjiUnit(
        number: 13,
        title: "Describing Things",
        videoID: "8VzcEv4PfOI",
        kanji: [
            KanjiEntry("明", "bright", on: "メイ", kun: "あか(るい)",
                hint: "The sun (日) and the moon (月) shining together: very bright.",
                words: [
                    KanjiWord("明るい", "あかるい", "bright"),
                    KanjiWord("明日", "あした", "tomorrow"),
                    KanjiWord("明後日", "あさって", "the day after tomorrow"),
                    KanjiWord("説明", "せつめい", "explanation"),
                    KanjiWord("証明", "しょうめい", "proof")
                ]),
            KanjiEntry("暗", "dark", on: "アン", kun: "くら(い)",
                hint: "The sun (日) beside sound (音). When the sun has gone you can only hear sounds: it is dark.",
                words: [
                    KanjiWord("暗い", "くらい", "dark"),
                    KanjiWord("真っ暗", "まっくら", "pitch dark"),
                    KanjiWord("暗記", "あんき", "memorization")
                ]),
            KanjiEntry("広", "wide, spacious", on: "コウ", kun: "ひろ(い)",
                hint: "A big roof (广) with plenty of elbow room (厶) underneath: a wide, spacious place.",
                words: [
                    KanjiWord("広い", "ひろい", "wide, spacious"),
                    KanjiWord("広げる", "ひろげる", "to spread out, widen"),
                    KanjiWord("広告", "こうこく", "advertisement")
                ]),
            KanjiEntry("多", "many", on: "タ", kun: "おお(い)",
                hint: "Katakana タ stacked on top of another タ. One, two… they keep piling up: many.",
                words: [
                    KanjiWord("多い", "おおい", "many, a lot"),
                    KanjiWord("多分", "たぶん", "probably")
                ]),
            KanjiEntry("少", "few, a little", on: "ショウ", kun: "すく(ない)・すこ(し)",
                hint: "Small (小) with one more slice cut away underneath. Even less than small: just a little.",
                words: [
                    KanjiWord("少ない", "すくない", "few, little"),
                    KanjiWord("少し", "すこし", "a little"),
                    KanjiWord("少年", "しょうねん", "boy (youth)")
                ]),
            KanjiEntry("長", "long, chief", on: "チョウ", kun: "なが(い)",
                hint: "An old man with long flowing hair, leaning on a cane. The elder with the longest hair is the chief.",
                words: [
                    KanjiWord("長い", "ながい", "long"),
                    KanjiWord("社長", "しゃちょう", "company president"),
                    KanjiWord("部長", "ぶちょう", "department manager"),
                    KanjiWord("学長", "がくちょう", "university president"),
                    KanjiWord("校長", "こうちょう", "school principal"),
                    KanjiWord("駅長", "えきちょう", "stationmaster")
                ]),
            KanjiEntry("短", "short", on: "タン", kun: "みじか(い)",
                hint: "An arrow (矢) next to a bean (豆): an arrow as short as a bean.",
                words: [
                    KanjiWord("短い", "みじかい", "short"),
                    KanjiWord("短大", "たんだい", "junior college")
                ]),
            KanjiEntry("悪", "bad", on: "アク", kun: "わる(い)",
                hint: "A twisted, ugly shape (亜) pressing down on a heart (心). A twisted heart is bad.",
                words: [
                    KanjiWord("悪い", "わるい", "bad"),
                    KanjiWord("悪日", "あくにち", "unlucky day"),
                    KanjiWord("悪口", "わるくち", "speaking ill of someone")
                ]),
            KanjiEntry("重", "heavy", on: "ジュウ", kun: "おも(い)",
                hint: "A tall stack of boxes piled on a cart, with an axle through the middle: a heavy load.",
                words: [
                    KanjiWord("重い", "おもい", "heavy"),
                    KanjiWord("重ねる", "かさねる", "to pile up, stack"),
                    KanjiWord("重大", "じゅうだい", "serious, grave"),
                    KanjiWord("貴重", "きちょう", "precious, valuable"),
                    KanjiWord("体重", "たいじゅう", "body weight")
                ]),
            KanjiEntry("軽", "light (weight)", on: "ケイ", kun: "かる(い)",
                hint: "A car (車) on the left: a small, light car, like Japan's tiny 'kei' cars.",
                words: [
                    KanjiWord("軽い", "かるい", "light (not heavy)"),
                    KanjiWord("軽率", "けいそつ", "careless, rash")
                ]),
            KanjiEntry("早", "early", on: "ソウ", kun: "はや(い)",
                hint: "The sun (日) rising over a flower stem (十): the sun just coming up, early in the morning.",
                words: [
                    KanjiWord("早い", "はやい", "early"),
                    KanjiWord("早急", "さっきゅう", "urgent"),
                    KanjiWord("早く", "はやく", "early; quickly")
                ])
        ],
        sentences: [
            KanjiSentence("この へやは 明るいです。", "この へや は あかるい です。", "This room is bright.", focus: "明るい"),
            KanjiSentence("外は もう 暗いです。", "そと は もう くらい です。", "It's already dark outside.", focus: "暗い"),
            KanjiSentence("この 大学は 広いです。", "この だいがく は ひろい です。", "This university is spacious.", focus: "広い"),
            KanjiSentence("日本は 山が 多いです。", "にほん は やま が おおい です。", "Japan has many mountains.", focus: "多い"),
            KanjiSentence("少し 休みましょう。", "すこし やすみましょう。", "Let's rest a little.", focus: "少し"),
            KanjiSentence("この 川は 長いです。", "この かわ は ながい です。", "This river is long.", focus: "長い"),
            KanjiSentence("この かばんは 重いです。", "この かばん は おもい です。", "This bag is heavy.", focus: "重い"),
            KanjiSentence("明日 早く 起きます。", "あした はやく おきます。", "I'll get up early tomorrow.", focus: "早く", speech: "あした早く起きます。"),
            KanjiSentence("今日は てんきが 悪いです。", "きょう は てんき が わるい です。", "The weather is bad today.", focus: "悪い"),
            KanjiSentence("新しい 自転車は 軽いです。", "あたらしい じてんしゃ は かるい です。", "The new bicycle is light.", focus: "軽い"),
            KanjiSentence("この えんぴつは 短いです。", "この えんぴつ は みじかい です。", "This pencil is short.", focus: "短い")
        ]
    )

    // MARK: - Unit 14

    static let unit14 = KanjiUnit(
        number: 14,
        title: "Daily Life & Work",
        videoID: "KoKy91nQnhI",
        kanji: [
            KanjiEntry("便", "convenience, mail", on: "ベン・ビン", kun: "",
                hint: "A person (亻) who fixes and changes things (更): someone who makes life more convenient.",
                words: [
                    KanjiWord("便利", "べんり", "convenient"),
                    KanjiWord("船便", "ふなびん", "sea mail"),
                    KanjiWord("郵便局", "ゆうびんきょく", "post office"),
                    KanjiWord("不便", "ふべん", "inconvenient")
                ]),
            KanjiEntry("利", "profit, advantage", on: "リ", kun: "",
                hint: "A rice plant (禾) and a knife (刂): harvesting the grain with a sharp blade brings a profit.",
                words: [
                    KanjiWord("利子", "りし", "interest (on money)"),
                    KanjiWord("便利", "べんり", "convenient"),
                    KanjiWord("利用", "りよう", "use, utilization")
                ]),
            KanjiEntry("元", "origin, base", on: "ゲン・ガン", kun: "もと",
                hint: "Two (二) lines above a pair of walking legs (儿): the starting line where your legs set off.",
                words: [
                    KanjiWord("元", "もと", "origin; former"),
                    KanjiWord("元々", "もともと", "originally"),
                    KanjiWord("地元", "じもと", "local area, hometown"),
                    KanjiWord("元気", "げんき", "healthy, energetic"),
                    KanjiWord("元日", "がんじつ", "New Year's Day")
                ]),
            KanjiEntry("気", "spirit, air", on: "キ・ケ", kun: "",
                hint: "Steam swirling up from a cooking pot: an invisible energy in the air. This is 'ki'.",
                words: [
                    KanjiWord("気分", "きぶん", "mood, feeling"),
                    KanjiWord("病気", "びょうき", "illness"),
                    KanjiWord("電気", "でんき", "electricity; light"),
                    KanjiWord("人気", "にんき", "popularity"),
                    KanjiWord("本気", "ほんき", "seriousness"),
                    KanjiWord("天気", "てんき", "weather"),
                    KanjiWord("空気", "くうき", "air"),
                    KanjiWord("気を付ける", "き を つける", "to be careful"),
                    KanjiWord("元気", "げんき", "healthy, energetic")
                ]),
            KanjiEntry("親", "parent, close", on: "シン", kun: "おや",
                hint: "Standing (立) on a tree (木) and watching (見): a parent climbs a tree to watch over their child.",
                words: [
                    KanjiWord("親", "おや", "parent"),
                    KanjiWord("父親", "ちちおや", "father (formal)"),
                    KanjiWord("母親", "ははおや", "mother (formal)"),
                    KanjiWord("親しい", "したしい", "close, friendly"),
                    KanjiWord("両親", "りょうしん", "parents"),
                    KanjiWord("親切", "しんせつ", "kind"),
                    KanjiWord("親友", "しんゆう", "close friend")
                ]),
            KanjiEntry("有", "have, exist", on: "ユウ", kun: "あ(る)",
                hint: "A hand (ナ) holding the moon (月): to have even the moon in your hand.",
                words: [
                    KanjiWord("有名", "ゆうめい", "famous"),
                    KanjiWord("有利", "ゆうり", "advantageous")
                ]),
            KanjiEntry("名", "name", on: "メイ", kun: "な",
                hint: "Evening (夕) and a mouth (口). In the dark you call out your name so people know who is there.",
                words: [
                    KanjiWord("名前", "なまえ", "name"),
                    KanjiWord("名字", "みょうじ", "family name"),
                    KanjiWord("名刺", "めいし", "business card"),
                    KanjiWord("名作", "めいさく", "masterpiece"),
                    KanjiWord("有名", "ゆうめい", "famous")
                ]),
            KanjiEntry("地", "ground, land", on: "チ・ジ", kun: "",
                hint: "Earth (土) on the left, and on the right a snake slithering along the ground.",
                words: [
                    KanjiWord("地下", "ちか", "underground, basement"),
                    KanjiWord("地下鉄", "ちかてつ", "subway"),
                    KanjiWord("地下室", "ちかしつ", "basement room"),
                    KanjiWord("地図", "ちず", "map"),
                    KanjiWord("土地", "とち", "land"),
                    KanjiWord("地価", "ちか", "land price"),
                    KanjiWord("地主", "じぬし", "landowner"),
                    KanjiWord("地震", "じしん", "earthquake")
                ]),
            KanjiEntry("鉄", "iron", on: "テツ", kun: "",
                hint: "Metal (金) on the left and 'lose' (失) on the right: iron is the metal that loses its shine and turns to rust.",
                words: [
                    KanjiWord("鉄", "てつ", "iron"),
                    KanjiWord("鉄道", "てつどう", "railway"),
                    KanjiWord("地下鉄", "ちかてつ", "subway")
                ]),
            KanjiEntry("仕", "serve, do", on: "シ", kun: "",
                hint: "A person (亻) beside a samurai (士): a samurai serving his lord and doing his duty.",
                words: [
                    KanjiWord("仕事", "しごと", "work, job"),
                    KanjiWord("仕方", "しかた", "way, method")
                ]),
            KanjiEntry("事", "matter, affair", on: "ジ", kun: "こと",
                hint: "A hand gripping a pole that runs straight through a pile of tasks: getting things done.",
                words: [
                    KanjiWord("事", "こと", "thing, matter"),
                    KanjiWord("仕事", "しごと", "work, job"),
                    KanjiWord("家事", "かじ", "housework"),
                    KanjiWord("火事", "かじ", "a fire (accident)"),
                    KanjiWord("食事", "しょくじ", "meal"),
                    KanjiWord("お大事に", "おだいじに", "get well soon"),
                    KanjiWord("事故", "じこ", "accident"),
                    KanjiWord("用事", "ようじ", "errand"),
                    KanjiWord("事務所", "じむしょ", "office"),
                    KanjiWord("事務員", "じむいん", "office clerk")
                ])
        ],
        sentences: [
            KanjiSentence("地下鉄は 便利です。", "ちかてつ は べんり です。", "The subway is convenient.", focus: "便利"),
            KanjiSentence("お元気ですか。", "おげんき です か。", "How are you?", focus: "元気"),
            KanjiSentence("今日は 天気が いいです。", "きょう は てんき が いい です。", "The weather is nice today.", focus: "天気"),
            KanjiSentence("山田さんは 親切な 人です。", "やまだ さん は しんせつ な ひと です。", "Mr. Yamada is a kind person.", focus: "親切"),
            KanjiSentence("あの 山は 有名です。", "あの やま は ゆうめい です。", "That mountain is famous.", focus: "有名"),
            KanjiSentence("ここに 名前を 書いて ください。", "ここ に なまえ を かいて ください。", "Please write your name here.", focus: "名前"),
            KanjiSentence("父の 仕事は 医者です。", "ちち の しごと は いしゃ です。", "My father works as a doctor.", focus: "仕事"),
            KanjiSentence("電気を けして ください。", "でんき を けして ください。", "Please turn off the light.", focus: "電気"),
            KanjiSentence("友達と 食事を します。", "ともだち と しょくじ を します。", "I have a meal with a friend.", focus: "食事"),
            KanjiSentence("地図を 見せて ください。", "ちず を みせて ください。", "Please show me the map.", focus: "地図")
        ]
    )

    // MARK: - Unit 15

    static let unit15 = KanjiUnit(
        number: 15,
        title: "Directions & Body",
        videoID: "wfxQqFVXZos",
        kanji: [
            KanjiEntry("東", "east", on: "トウ", kun: "ひがし",
                hint: "The sun (日) rising behind a tree (木). The sun rises in the east.",
                words: [
                    KanjiWord("東", "ひがし", "east"),
                    KanjiWord("東京", "とうきょう", "Tokyo"),
                    KanjiWord("東ヨーロッパ", "ひがし ヨーロッパ", "Eastern Europe"),
                    KanjiWord("東南アジア", "とうなん アジア", "Southeast Asia"),
                    KanjiWord("中東", "ちゅうとう", "Middle East"),
                    KanjiWord("東北", "とうほく", "Tohoku region; northeast"),
                    KanjiWord("東口", "ひがしぐち", "east exit")
                ]),
            KanjiEntry("西", "west", on: "セイ・サイ", kun: "にし",
                hint: "A bird settling down on its nest as the sun sets in the west.",
                words: [
                    KanjiWord("西", "にし", "west"),
                    KanjiWord("西ヨーロッパ", "にし ヨーロッパ", "Western Europe"),
                    KanjiWord("関西", "かんさい", "Kansai region"),
                    KanjiWord("東西", "とうざい", "east and west"),
                    KanjiWord("山西", "やまにし", "Yamanishi (family name)"),
                    KanjiWord("西山", "にしやま", "Nishiyama (family name)"),
                    KanjiWord("西川", "にしかわ", "Nishikawa (family name)"),
                    KanjiWord("西口", "にしぐち", "west exit")
                ]),
            KanjiEntry("南", "south", on: "ナン", kun: "みなみ",
                hint: "A greenhouse with a plant growing happily inside, in the warm south.",
                words: [
                    KanjiWord("南", "みなみ", "south"),
                    KanjiWord("南北", "なんぼく", "north and south"),
                    KanjiWord("南アメリカ", "みなみ アメリカ", "South America"),
                    KanjiWord("南口", "みなみぐち", "south exit")
                ]),
            KanjiEntry("北", "north", on: "ホク", kun: "きた",
                hint: "Two people sitting back to back, huddled up against the cold north wind.",
                words: [
                    KanjiWord("北", "きた", "north"),
                    KanjiWord("北アメリカ", "きた アメリカ", "North America"),
                    KanjiWord("北海道", "ほっかいどう", "Hokkaido"),
                    KanjiWord("北川", "きたがわ", "Kitagawa (family name)"),
                    KanjiWord("北口", "きたぐち", "north exit")
                ]),
            KanjiEntry("京", "capital", on: "キョウ", kun: "",
                hint: "A tall stone lantern with a roof, a window and three legs: a landmark of the capital city.",
                words: [
                    KanjiWord("京都", "きょうと", "Kyoto"),
                    KanjiWord("東京", "とうきょう", "Tokyo")
                ]),
            KanjiEntry("夜", "night", on: "ヤ", kun: "よる",
                hint: "A person (亻) under a roof, and beside them the moon with a cloud drifting past: night.",
                words: [
                    KanjiWord("夜", "よる", "night"),
                    KanjiWord("夜間", "やかん", "night-time"),
                    KanjiWord("夜中", "よなか", "middle of the night"),
                    KanjiWord("今夜", "こんや", "tonight")
                ]),
            KanjiEntry("料", "fee, ingredients", on: "リョウ", kun: "",
                hint: "Rice (米) on the left and a measuring ladle (斗) on the right: measuring out ingredients, and what you pay for them.",
                words: [
                    KanjiWord("料理", "りょうり", "cooking, cuisine"),
                    KanjiWord("料金", "りょうきん", "fee, charge"),
                    KanjiWord("無料", "むりょう", "free of charge"),
                    KanjiWord("給料", "きゅうりょう", "salary")
                ]),
            KanjiEntry("理", "reason, logic", on: "リ", kun: "",
                hint: "A king (王) beside a village (里): the king brings order and reason to the village.",
                words: [
                    KanjiWord("料理", "りょうり", "cooking, cuisine"),
                    KanjiWord("真理", "しんり", "truth"),
                    KanjiWord("生理", "せいり", "physiology; menstrual period"),
                    KanjiWord("地理", "ちり", "geography"),
                    KanjiWord("物理", "ぶつり", "physics"),
                    KanjiWord("無理", "むり", "impossible, unreasonable")
                ]),
            KanjiEntry("口", "mouth", on: "コウ", kun: "くち",
                hint: "A wide-open mouth.",
                words: [
                    KanjiWord("口", "くち", "mouth"),
                    KanjiWord("入口", "いりぐち", "entrance"),
                    KanjiWord("出口", "でぐち", "exit"),
                    KanjiWord("火口", "かこう", "crater"),
                    KanjiWord("人口", "じんこう", "population"),
                    KanjiWord("早口", "はやくち", "fast talking"),
                    KanjiWord("山口", "やまぐち", "Yamaguchi (family name)")
                ]),
            KanjiEntry("目", "eye", on: "モク", kun: "め",
                hint: "An eye turned on its side. The two lines in the middle are the pupil.",
                words: [
                    KanjiWord("目", "め", "eye"),
                    KanjiWord("一番目", "いちばんめ", "the first (in order)"),
                    KanjiWord("目的", "もくてき", "purpose")
                ]),
            KanjiEntry("足", "foot, leg", on: "ソク", kun: "あし・た(りる)",
                hint: "A kneecap (口) on top, and below it a foot striding forward.",
                words: [
                    KanjiWord("足", "あし", "foot, leg"),
                    KanjiWord("右足", "みぎあし", "right foot"),
                    KanjiWord("左足", "ひだりあし", "left foot"),
                    KanjiWord("足元", "あしもと", "at one's feet"),
                    KanjiWord("足りる", "たりる", "to be enough"),
                    KanjiWord("一足", "いっそく", "one pair (of shoes)")
                ]),
            KanjiEntry("曜", "day of the week", on: "ヨウ", kun: "",
                hint: "The sun (日) next to a bird (隹) with feathers on its head: a bird that sings at sunrise on each day of the week.",
                words: [
                    KanjiWord("〜曜日", "〜ようび", "day of the week (ending)"),
                    KanjiWord("月曜日", "げつようび", "Monday"),
                    KanjiWord("曜日", "ようび", "day of the week"),
                    KanjiWord("何曜日", "なんようび", "what day of the week")
                ])
        ],
        sentences: [
            KanjiSentence("東京は 日本の 東に あります。", "とうきょう は にほん の ひがし に あります。", "Tokyo is in the east of Japan.", focus: "東京"),
            KanjiSentence("駅の 西口で 会いましょう。", "えき の にしぐち で あいましょう。", "Let's meet at the west exit of the station.", focus: "西口"),
            KanjiSentence("北海道は 日本の 北に あります。", "ほっかいどう は にほん の きた に あります。", "Hokkaido is in the north of Japan.", focus: "北海道"),
            KanjiSentence("南の 国へ 行きたいです。", "みなみ の くに へ いきたい です。", "I want to go to a southern country.", focus: "南"),
            KanjiSentence("夜 十時に 帰りました。", "よる じゅうじ に かえりました。", "I came home at ten at night.", focus: "夜"),
            KanjiSentence("日本料理が 好きです。", "にほんりょうり が すき です。", "I like Japanese food.", focus: "料理"),
            KanjiSentence("出口は どこですか。", "でぐち は どこ です か。", "Where is the exit?", focus: "出口"),
            KanjiSentence("目が いたいです。", "め が いたい です。", "My eyes hurt.", focus: "目"),
            KanjiSentence("たくさん 歩いて、足が いたいです。", "たくさん あるいて、 あし が いたい です。", "I walked a lot and my feet hurt.", focus: "足"),
            KanjiSentence("来月 京都へ 行きます。", "らいげつ きょうと へ いきます。", "I'm going to Kyoto next month.", focus: "京都"),
            KanjiSentence("月曜日に 東京へ 行きます。", "げつようび に とうきょう へ いきます。", "I'm going to Tokyo on Monday.", focus: "月曜日")
        ]
    )
}
