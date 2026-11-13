import Foundation

// Units 16–20 of the NihonGoal "Minna No Nihongo Kanji" video series.

extension KanjiData {

    // MARK: - Unit 16

    static let unit16 = KanjiUnit(
        number: 16,
        title: "Thinking & Speaking",
        videoID: "EMHUCqehXMQ",
        kanji: [
            KanjiEntry("降", "fall, get off", on: "コウ", kun: "ふ(る)・お(りる)",
                hint: "A hillside (阝) with two feet stepping down it: coming down. Rain falls, and you get off the train.",
                words: [
                    KanjiWord("降りる", "おりる", "to get off (a vehicle)"),
                    KanjiWord("降ろす", "おろす", "to let off, unload"),
                    KanjiWord("降る", "ふる", "to fall (rain, snow)"),
                    KanjiWord("降水", "こうすい", "rainfall")
                ]),
            KanjiEntry("思", "think", on: "シ", kun: "おも(う)",
                hint: "A brain (田) above a heart (心): thinking with both your head and your heart.",
                words: [
                    KanjiWord("思う", "おもう", "to think"),
                    KanjiWord("思い出す", "おもいだす", "to remember, recall")
                ]),
            KanjiEntry("寝", "sleep", on: "シン", kun: "ね(る)",
                hint: "A roof (宀), a bed standing on its side (丬) and a hand pulling up the covers: going to sleep.",
                words: [
                    KanjiWord("寝る", "ねる", "to sleep, go to bed"),
                    KanjiWord("昼寝", "ひるね", "nap"),
                    KanjiWord("寝室", "しんしつ", "bedroom")
                ]),
            KanjiEntry("終", "end", on: "シュウ", kun: "お(わる)",
                hint: "Thread (糸) and winter (冬). Winter is the end of the year, like reaching the end of the thread.",
                words: [
                    KanjiWord("終わる", "おわる", "to end, finish"),
                    KanjiWord("終電車", "しゅうでんしゃ", "last train"),
                    KanjiWord("終わり", "おわり", "the end")
                ]),
            KanjiEntry("言", "say", on: "ゲン・ゴン", kun: "い(う)",
                hint: "A mouth (口) at the bottom with sound waves rising up out of it: saying something.",
                words: [
                    KanjiWord("言う", "いう", "to say"),
                    KanjiWord("言い方", "いいかた", "way of saying"),
                    KanjiWord("言葉", "ことば", "word, language"),
                    KanjiWord("言語", "げんご", "language"),
                    KanjiWord("方言", "ほうげん", "dialect")
                ]),
            KanjiEntry("知", "know", on: "チ", kun: "し(る)",
                hint: "An arrow (矢) and a mouth (口). When you know something, the words shoot out of your mouth like an arrow.",
                words: [
                    KanjiWord("知っている", "しっている", "to know"),
                    KanjiWord("知りません", "しりません", "I don't know"),
                    KanjiWord("知らせる", "しらせる", "to inform"),
                    KanjiWord("知る", "しる", "to find out, learn of")
                ]),
            KanjiEntry("同", "same", on: "ドウ", kun: "おな(じ)",
                hint: "One (一) mouth (口) under one cover. Everyone under the same roof says the same thing.",
                words: [
                    KanjiWord("同じ", "おなじ", "same"),
                    KanjiWord("同時", "どうじ", "at the same time")
                ]),
            KanjiEntry("漢", "China (Han)", on: "カン", kun: "",
                hint: "Water (氵) on the left: across the water lies the land of the Han people, where kanji came from.",
                words: [
                    KanjiWord("漢字", "かんじ", "kanji (Chinese characters)")
                ]),
            KanjiEntry("字", "character, letter", on: "ジ", kun: "",
                hint: "A child (子) under a roof (宀): a child at home practising their letters.",
                words: [
                    KanjiWord("字", "じ", "character, handwriting"),
                    KanjiWord("漢字", "かんじ", "kanji (Chinese characters)"),
                    KanjiWord("ローマ字", "ローマじ", "romaji (Roman letters)"),
                    KanjiWord("名字", "みょうじ", "family name")
                ]),
            KanjiEntry("方", "direction, way", on: "ホウ", kun: "かた",
                hint: "A flag on a pole, blowing to one side and showing the direction.",
                words: [
                    KanjiWord("あの方", "あの かた", "that person (polite)"),
                    KanjiWord("〜方", "〜かた", "way of doing…"),
                    KanjiWord("使い方", "つかいかた", "how to use"),
                    KanjiWord("読み方", "よみかた", "way of reading"),
                    KanjiWord("〜の作り方", "〜の つくりかた", "how to make…"),
                    KanjiWord("〜の方", "〜の ほう", "the … one; towards…"),
                    KanjiWord("方言", "ほうげん", "dialect")
                ])
        ],
        sentences: [
            KanjiSentence("雨が 降って います。", "あめ が ふって います。", "It is raining.", focus: "降って"),
            KanjiSentence("東京駅で 電車を 降ります。", "とうきょうえき で でんしゃ を おります。", "I get off the train at Tokyo Station.", focus: "降ります", speech: "東京駅で電車をおります。"),
            KanjiSentence("明日は 雨だと 思います。", "あした は あめ だ と おもいます。", "I think it will rain tomorrow.", focus: "思います", speech: "あしたは雨だと思います。"),
            KanjiSentence("毎晩 十一時に 寝ます。", "まいばん じゅういちじ に ねます。", "I go to bed at eleven every night.", focus: "寝ます"),
            KanjiSentence("仕事は 五時に 終わります。", "しごと は ごじ に おわります。", "Work finishes at five.", focus: "終わります"),
            KanjiSentence("もう いちど 言って ください。", "もう いちど いって ください。", "Please say it once more.", focus: "言って"),
            KanjiSentence("山田さんを 知って いますか。", "やまだ さん を しって います か。", "Do you know Mr. Yamada?", focus: "知って"),
            KanjiSentence("友達と 同じ 学校に 行きます。", "ともだち と おなじ がっこう に いきます。", "I go to the same school as my friend.", focus: "同じ"),
            KanjiSentence("この 漢字の 読み方を 教えて ください。", "この かんじ の よみかた を おしえて ください。", "Please tell me how to read this kanji.", focus: "漢字"),
            KanjiSentence("字が きれいですね。", "じ が きれい です ね。", "Your handwriting is beautiful.", focus: "字")
        ]
    )

    // MARK: - Unit 17

    static let unit17 = KanjiUnit(
        number: 17,
        title: "Around Town",
        videoID: "ikhMZJ4LHr8",
        kanji: [
            KanjiEntry("図", "diagram, map", on: "ズ・ト", kun: "",
                hint: "A map in a frame: a cross marks the spot, with two dots for landmarks.",
                words: [
                    KanjiWord("図書館", "としょかん", "library"),
                    KanjiWord("地図", "ちず", "map"),
                    KanjiWord("図面", "ずめん", "drawing, blueprint")
                ]),
            KanjiEntry("館", "large building", on: "カン", kun: "",
                hint: "Food (飠) beside an official's building (官): a large public building where guests are fed.",
                words: [
                    KanjiWord("図書館", "としょかん", "library"),
                    KanjiWord("大使館", "たいしかん", "embassy"),
                    KanjiWord("映画館", "えいがかん", "movie theatre"),
                    KanjiWord("旅館", "りょかん", "Japanese-style inn"),
                    KanjiWord("会館", "かいかん", "assembly hall")
                ]),
            KanjiEntry("銀", "silver", on: "ギン", kun: "",
                hint: "Metal (金) that is good, but not quite the best (艮): one step below gold is silver.",
                words: [
                    KanjiWord("銀行", "ぎんこう", "bank"),
                    KanjiWord("銀行員", "ぎんこういん", "bank employee"),
                    KanjiWord("銀", "ぎん", "silver")
                ]),
            KanjiEntry("町", "town", on: "チョウ", kun: "まち",
                hint: "A rice field (田) beside a street sign (丁): fields and streets together make a town.",
                words: [
                    KanjiWord("町", "まち", "town"),
                    KanjiWord("町長", "ちょうちょう", "town mayor")
                ]),
            KanjiEntry("住", "live, reside", on: "ジュウ", kun: "す(む)",
                hint: "A person (亻) beside a master (主): the master of the house is the person who lives there.",
                words: [
                    KanjiWord("住んでいる", "すんでいる", "to be living (somewhere)"),
                    KanjiWord("住まい", "すまい", "home, residence"),
                    KanjiWord("住所", "じゅうしょ", "address"),
                    KanjiWord("住む", "すむ", "to live (somewhere)")
                ]),
            KanjiEntry("度", "degree, times", on: "ド", kun: "",
                hint: "Under a roof (广), a hand (又) counting things one by one: how many times, how many degrees.",
                words: [
                    KanjiWord("〜度", "〜ど", "… times; … degrees"),
                    KanjiWord("一度", "いちど", "once"),
                    KanjiWord("一度も", "いちども", "not even once"),
                    KanjiWord("今度", "こんど", "next time; this time")
                ]),
            KanjiEntry("服", "clothes", on: "フク", kun: "",
                hint: "A body (月) on the left, and on the right a hand dressing a kneeling person: putting clothes on.",
                words: [
                    KanjiWord("服", "ふく", "clothes"),
                    KanjiWord("洋服", "ようふく", "Western-style clothes")
                ]),
            KanjiEntry("着", "wear, arrive", on: "チャク", kun: "き(る)・つ(く)",
                hint: "A sheep (羊) above an eye (目): eyeing up the wool that you are going to wear.",
                words: [
                    KanjiWord("着る", "きる", "to wear, put on"),
                    KanjiWord("着せる", "きせる", "to dress (someone)"),
                    KanjiWord("着物", "きもの", "kimono"),
                    KanjiWord("上着", "うわぎ", "jacket"),
                    KanjiWord("下着", "したぎ", "underwear"),
                    KanjiWord("着く", "つく", "to arrive")
                ]),
            KanjiEntry("音", "sound", on: "オン", kun: "おと",
                hint: "Standing (立) on the sun (日). At sunrise everything wakes up and begins to make sound.",
                words: [
                    KanjiWord("音", "おと", "sound"),
                    KanjiWord("音楽", "おんがく", "music"),
                    KanjiWord("五十音", "ごじゅうおん", "the 50-sound kana chart")
                ]),
            KanjiEntry("楽", "fun, music", on: "ガク・ラク", kun: "たの(しい)",
                hint: "A white (白) drum with sparks on both sides, sitting on a wooden (木) stand. Making music is fun.",
                words: [
                    KanjiWord("楽しい", "たのしい", "fun, enjoyable"),
                    KanjiWord("楽", "らく", "easy, comfortable"),
                    KanjiWord("気楽", "きらく", "carefree, easygoing"),
                    KanjiWord("音楽", "おんがく", "music")
                ]),
            KanjiEntry("持", "hold, have", on: "ジ", kun: "も(つ)",
                hint: "A hand (扌) beside a temple (寺): holding an offering in your hand at the temple.",
                words: [
                    KanjiWord("持つ", "もつ", "to hold, carry"),
                    KanjiWord("持っている", "もっている", "to have, be holding"),
                    KanjiWord("金持ち", "かねもち", "rich person"),
                    KanjiWord("気持ち", "きもち", "feeling")
                ])
        ],
        sentences: [
            KanjiSentence("図書館で 本を 借ります。", "としょかん で ほん を かります。", "I borrow books at the library.", focus: "図書館"),
            KanjiSentence("銀行は 九時から 三時までです。", "ぎんこう は くじ から さんじ まで です。", "The bank is open from nine to three.", focus: "銀行"),
            KanjiSentence("わたしの 町は 山に 近いです。", "わたし の まち は やま に ちかい です。", "My town is close to the mountains.", focus: "町"),
            KanjiSentence("東京に 住んで います。", "とうきょう に すんで います。", "I live in Tokyo.", focus: "住んで"),
            KanjiSentence("もう 一度 言って ください。", "もう いちど いって ください。", "Please say it one more time.", focus: "一度"),
            KanjiSentence("新しい 服を 買いました。", "あたらしい ふく を かいました。", "I bought new clothes.", focus: "服"),
            KanjiSentence("十時に 東京駅に 着きます。", "じゅうじ に とうきょうえき に つきます。", "I'll arrive at Tokyo Station at ten.", focus: "着きます"),
            KanjiSentence("毎晩 音楽を 聞きます。", "まいばん おんがく を ききます。", "I listen to music every night.", focus: "音楽"),
            KanjiSentence("旅行は 楽しかったです。", "りょこう は たのしかった です。", "The trip was fun.", focus: "楽しかった"),
            KanjiSentence("かさを 持って 行きます。", "かさ を もって いきます。", "I'll take an umbrella with me.", focus: "持って")
        ]
    )

    // MARK: - Unit 18

    static let unit18 = KanjiUnit(
        number: 18,
        title: "Seasons, Health & Getting Around",
        videoID: "GvVrv5GQAIU",
        kanji: [
            KanjiEntry("春", "spring", on: "シュン", kun: "はる",
                hint: "Three (三) people (人) out enjoying the sun (日): spring has come.",
                words: [
                    KanjiWord("春", "はる", "spring"),
                    KanjiWord("春休み", "はるやすみ", "spring vacation"),
                    KanjiWord("春分", "しゅんぶん", "spring equinox")
                ]),
            KanjiEntry("夏", "summer", on: "カ", kun: "なつ",
                hint: "A person with a big, hot head on top, dragging their feet (夂) in the summer heat.",
                words: [
                    KanjiWord("夏", "なつ", "summer"),
                    KanjiWord("夏休み", "なつやすみ", "summer vacation")
                ]),
            KanjiEntry("秋", "autumn", on: "シュウ", kun: "あき",
                hint: "Rice plants (禾) and fire (火). In autumn the rice is harvested and the leaves turn fire-red.",
                words: [
                    KanjiWord("秋", "あき", "autumn"),
                    KanjiWord("秋分", "しゅうぶん", "autumn equinox")
                ]),
            KanjiEntry("冬", "winter", on: "トウ", kun: "ふゆ",
                hint: "Dragging feet (夂) with two icy drops underneath: slipping along on the ice in winter.",
                words: [
                    KanjiWord("冬", "ふゆ", "winter"),
                    KanjiWord("冬休み", "ふゆやすみ", "winter vacation")
                ]),
            KanjiEntry("道", "road, way", on: "ドウ", kun: "みち",
                hint: "The road radical (辶) carrying a head (首): heading off down the road.",
                words: [
                    KanjiWord("道", "みち", "road, way"),
                    KanjiWord("水道", "すいどう", "water supply"),
                    KanjiWord("鉄道", "てつどう", "railway"),
                    KanjiWord("書道", "しょどう", "calligraphy"),
                    KanjiWord("北海道", "ほっかいどう", "Hokkaido"),
                    KanjiWord("歩道", "ほどう", "sidewalk"),
                    KanjiWord("近道", "ちかみち", "shortcut")
                ]),
            KanjiEntry("堂", "hall", on: "ドウ", kun: "",
                hint: "A grand roof on top, with a mouth (口) and the earth (土) below: a big hall on solid ground where people gather to eat.",
                words: [
                    KanjiWord("食堂", "しょくどう", "cafeteria"),
                    KanjiWord("堂々", "どうどう", "grand, dignified")
                ]),
            KanjiEntry("建", "build", on: "ケン", kun: "た(てる)",
                hint: "A brush (聿) drawing the plans, moving along (廴). First you draw the plans, then you build.",
                words: [
                    KanjiWord("建物", "たてもの", "building"),
                    KanjiWord("建てる", "たてる", "to build")
                ]),
            KanjiEntry("病", "illness", on: "ビョウ", kun: "",
                hint: "The sickness radical (疒) is a person lying in a sickbed: ill in bed.",
                words: [
                    KanjiWord("病院", "びょういん", "hospital"),
                    KanjiWord("病気", "びょうき", "illness"),
                    KanjiWord("病室", "びょうしつ", "hospital room")
                ]),
            KanjiEntry("院", "institution", on: "イン", kun: "",
                hint: "A wall (阝) beside a complete (完) building with a roof: a walled institution such as a hospital.",
                words: [
                    KanjiWord("院長", "いんちょう", "hospital director"),
                    KanjiWord("病院", "びょういん", "hospital"),
                    KanjiWord("入院", "にゅういん", "hospitalization"),
                    KanjiWord("大学院", "だいがくいん", "graduate school")
                ]),
            KanjiEntry("体", "body", on: "タイ", kun: "からだ",
                hint: "A person (亻) and their root (本). The body is the foundation of a person.",
                words: [
                    KanjiWord("体", "からだ", "body"),
                    KanjiWord("字体", "じたい", "typeface, style of a character"),
                    KanjiWord("重体", "じゅうたい", "critical condition"),
                    KanjiWord("体重", "たいじゅう", "body weight"),
                    KanjiWord("体温", "たいおん", "body temperature"),
                    KanjiWord("体育館", "たいいくかん", "gymnasium")
                ]),
            KanjiEntry("運", "carry, luck", on: "ウン", kun: "はこ(ぶ)",
                hint: "The road radical (辶) carrying an army's cart (軍): transporting things down the road.",
                words: [
                    KanjiWord("運", "うん", "luck"),
                    KanjiWord("運転", "うんてん", "driving"),
                    KanjiWord("運転する", "うんてん する", "to drive"),
                    KanjiWord("運転手", "うんてんしゅ", "driver"),
                    KanjiWord("運動", "うんどう", "exercise"),
                    KanjiWord("運動会", "うんどうかい", "sports day"),
                    KanjiWord("運ぶ", "はこぶ", "to carry, transport")
                ]),
            KanjiEntry("乗", "ride", on: "ジョウ", kun: "の(る)",
                hint: "A person perched high up in a tree (木), riding on its branches.",
                words: [
                    KanjiWord("乗る", "のる", "to ride, get on"),
                    KanjiWord("乗り物", "のりもの", "vehicle"),
                    KanjiWord("乗り換える", "のりかえる", "to change (trains)"),
                    KanjiWord("乗り場", "のりば", "boarding area")
                ])
        ],
        sentences: [
            KanjiSentence("春に 花見を します。", "はる に はなみ を します。", "We go cherry-blossom viewing in spring.", focus: "春"),
            KanjiSentence("夏休みに 国へ 帰ります。", "なつやすみ に くに へ かえります。", "I'll go back to my country in the summer vacation.", focus: "夏休み"),
            KanjiSentence("秋は 山が きれいです。", "あき は やま が きれい です。", "The mountains are beautiful in autumn.", focus: "秋"),
            KanjiSentence("北海道の 冬は さむいです。", "ほっかいどう の ふゆ は さむい です。", "Winters in Hokkaido are cold.", focus: "冬"),
            KanjiSentence("この 道を まっすぐ 行って ください。", "この みち を まっすぐ いって ください。", "Please go straight along this road.", focus: "道", speech: "この道をまっすぐいってください。"),
            KanjiSentence("会社の 食堂で 昼ごはんを 食べます。", "かいしゃ の しょくどう で ひるごはん を たべます。", "I eat lunch at the company cafeteria.", focus: "食堂"),
            KanjiSentence("あの 白い 建物は 病院です。", "あの しろい たてもの は びょういん です。", "That white building is a hospital.", focus: "病院"),
            KanjiSentence("タバコは 体に 悪いです。", "タバコ は からだ に わるい です。", "Smoking is bad for your body.", focus: "体"),
            KanjiSentence("毎朝 八時の 電車に 乗ります。", "まいあさ はちじ の でんしゃ に のります。", "I take the 8 o'clock train every morning.", focus: "乗ります"),
            KanjiSentence("父は 車を 運転します。", "ちち は くるま を うんてん します。", "My father drives a car.", focus: "運転")
        ]
    )

    // MARK: - Unit 19

    static let unit19 = KanjiUnit(
        number: 19,
        title: "Family & Home",
        videoID: "9_TceBmRTkw",
        kanji: [
            KanjiEntry("家", "house, home", on: "カ", kun: "いえ",
                hint: "A pig (豕) under a roof (宀). Long ago, families kept their pigs in the house.",
                words: [
                    KanjiWord("家", "いえ", "house"),
                    KanjiWord("家内", "かない", "(my) wife"),
                    KanjiWord("家族", "かぞく", "family"),
                    KanjiWord("画家", "がか", "painter"),
                    KanjiWord("作家", "さっか", "writer, author"),
                    KanjiWord("家事", "かじ", "housework"),
                    KanjiWord("大家", "おおや", "landlord"),
                    KanjiWord("家賃", "やちん", "rent")
                ]),
            KanjiEntry("内", "inside", on: "ナイ", kun: "うち",
                hint: "A person (人) stepping in through a doorway: inside.",
                words: [
                    KanjiWord("国内", "こくない", "domestic, within the country"),
                    KanjiWord("案内する", "あんない する", "to guide, show around"),
                    KanjiWord("家内", "かない", "(my) wife")
                ]),
            KanjiEntry("族", "tribe, family", on: "ゾク", kun: "",
                hint: "A flag (方) and an arrow (矢) with people gathered round: a clan rallying under its banner.",
                words: [
                    KanjiWord("家族", "かぞく", "family")
                ]),
            KanjiEntry("兄", "older brother", on: "キョウ・ケイ", kun: "あに",
                hint: "A big mouth (口) on legs (儿): the older brother who tells everyone what to do.",
                words: [
                    KanjiWord("兄", "あに", "(my) older brother"),
                    KanjiWord("お兄さん", "おにいさん", "older brother (polite)"),
                    KanjiWord("兄弟", "きょうだい", "siblings, brothers")
                ]),
            KanjiEntry("弟", "younger brother", on: "ダイ・テイ", kun: "おとうと",
                hint: "A boy with two tufts of spiky hair, carrying a toy bow (弓): the little brother.",
                words: [
                    KanjiWord("弟", "おとうと", "(my) younger brother"),
                    KanjiWord("弟さん", "おとうとさん", "younger brother (polite)"),
                    KanjiWord("兄弟", "きょうだい", "siblings, brothers")
                ]),
            KanjiEntry("奥", "inner part", on: "オウ", kun: "おく",
                hint: "Deep inside the house, the rice (米) is kept in a big (大) storeroom: the innermost part.",
                words: [
                    KanjiWord("奥", "おく", "the back, inner part"),
                    KanjiWord("奥さん", "おくさん", "(someone's) wife")
                ]),
            KanjiEntry("姉", "older sister", on: "シ", kun: "あね",
                hint: "A woman (女) who goes to the market (市): the older sister doing the shopping.",
                words: [
                    KanjiWord("姉", "あね", "(my) older sister"),
                    KanjiWord("お姉さん", "おねえさん", "older sister (polite)")
                ]),
            KanjiEntry("妹", "younger sister", on: "マイ", kun: "いもうと",
                hint: "A woman (女) who is not yet (未) grown up: the younger sister.",
                words: [
                    KanjiWord("妹", "いもうと", "(my) younger sister"),
                    KanjiWord("妹さん", "いもうとさん", "younger sister (polite)")
                ]),
            KanjiEntry("海", "sea", on: "カイ", kun: "うみ",
                hint: "Water (氵) that is there every (毎) day: the sea.",
                words: [
                    KanjiWord("海", "うみ", "sea"),
                    KanjiWord("北海道", "ほっかいどう", "Hokkaido"),
                    KanjiWord("海外", "かいがい", "overseas"),
                    KanjiWord("海運", "かいうん", "shipping (by sea)")
                ]),
            KanjiEntry("計", "measure, plan", on: "ケイ", kun: "はか(る)",
                hint: "Words (言) and ten (十): counting out loud to ten. Measuring and planning.",
                words: [
                    KanjiWord("時計", "とけい", "clock, watch"),
                    KanjiWord("会計", "かいけい", "accounts; the bill"),
                    KanjiWord("計画", "けいかく", "plan")
                ])
        ],
        sentences: [
            KanjiSentence("家族は 五人です。", "かぞく は ごにん です。", "There are five people in my family.", focus: "家族"),
            KanjiSentence("新しい 家を 買いました。", "あたらしい いえ を かいました。", "I bought a new house.", focus: "家"),
            KanjiSentence("兄は 東京に 住んで います。", "あに は とうきょう に すんで います。", "My older brother lives in Tokyo.", focus: "兄"),
            KanjiSentence("弟は 高校生です。", "おとうと は こうこうせい です。", "My younger brother is a high school student.", focus: "弟"),
            KanjiSentence("姉は 銀行で はたらいて います。", "あね は ぎんこう で はたらいて います。", "My older sister works at a bank.", focus: "姉"),
            KanjiSentence("妹は 音楽が 好きです。", "いもうと は おんがく が すき です。", "My younger sister likes music.", focus: "妹"),
            KanjiSentence("夏休みに 海へ 行きました。", "なつやすみ に うみ へ いきました。", "I went to the sea in the summer vacation.", focus: "海"),
            KanjiSentence("父に 時計を もらいました。", "ちち に とけい を もらいました。", "I got a watch from my father.", focus: "時計"),
            KanjiSentence("山田さんの 奥さんは 料理が 上手です。", "やまだ さん の おくさん は りょうり が じょうず です。", "Mr. Yamada's wife is good at cooking.", focus: "奥さん"),
            KanjiSentence("家内は 日本人です。", "かない は にほんじん です。", "My wife is Japanese.", focus: "家内", speech: "家内はにほんじんです。")
        ]
    )

    // MARK: - Unit 20

    static let unit20 = KanjiUnit(
        number: 20,
        title: "Rooms & Ideas",
        videoID: "jK8SsjWCmNo",
        kanji: [
            KanjiEntry("部", "part, section", on: "ブ", kun: "",
                hint: "Standing (立) over a mouth (口), beside a village (阝): one section of the town.",
                words: [
                    KanjiWord("部長", "ぶちょう", "department manager"),
                    KanjiWord("部分", "ぶぶん", "part, portion"),
                    KanjiWord("部屋", "へや", "room"),
                    KanjiWord("全部", "ぜんぶ", "all, everything")
                ]),
            KanjiEntry("屋", "shop, roof", on: "オク", kun: "や",
                hint: "A roof hanging over the place you arrive at (至): a house or a shop.",
                words: [
                    KanjiWord("〜屋", "〜や", "… shop"),
                    KanjiWord("本屋", "ほんや", "bookstore"),
                    KanjiWord("花屋", "はなや", "flower shop"),
                    KanjiWord("肉屋", "にくや", "butcher's shop"),
                    KanjiWord("魚屋", "さかなや", "fish shop"),
                    KanjiWord("電気屋", "でんきや", "electronics shop"),
                    KanjiWord("自転車屋", "じてんしゃや", "bicycle shop"),
                    KanjiWord("酒屋", "さかや", "liquor store"),
                    KanjiWord("屋上", "おくじょう", "rooftop"),
                    KanjiWord("部屋", "へや", "room")
                ]),
            KanjiEntry("室", "room", on: "シツ", kun: "",
                hint: "A roof (宀) over an arrival (至): you arrive and step into a room.",
                words: [
                    KanjiWord("室", "しつ", "room (in compounds)"),
                    KanjiWord("教室", "きょうしつ", "classroom"),
                    KanjiWord("病室", "びょうしつ", "hospital room")
                ]),
            KanjiEntry("窓", "window", on: "ソウ", kun: "まど",
                hint: "A roof (宀) with an opening in it, and a heart (心) below. The window is the heart of a room, letting the light in.",
                words: [
                    KanjiWord("窓", "まど", "window"),
                    KanjiWord("窓口", "まどぐち", "service counter")
                ]),
            KanjiEntry("開", "open", on: "カイ", kun: "あ(ける)・ひら(く)",
                hint: "Two hands lifting the bar (开) off a gate (門): opening the gate.",
                words: [
                    KanjiWord("開ける", "あける", "to open (something)"),
                    KanjiWord("開く", "あく", "to open (by itself)")
                ]),
            KanjiEntry("閉", "close", on: "ヘイ", kun: "し(める)",
                hint: "A gate (門) with a prop (才) wedged across it: the gate is closed.",
                words: [
                    KanjiWord("閉める", "しめる", "to close (something)"),
                    KanjiWord("閉まる", "しまる", "to close (by itself)"),
                    KanjiWord("閉じる", "とじる", "to shut (a book, eyes)")
                ]),
            KanjiEntry("歌", "song, sing", on: "カ", kun: "うた",
                hint: "Two open mouths going 'ka, ka' (可可) next to a person with their mouth wide open (欠): singing a song.",
                words: [
                    KanjiWord("歌", "うた", "song"),
                    KanjiWord("歌う", "うたう", "to sing"),
                    KanjiWord("歌手", "かしゅ", "singer")
                ]),
            KanjiEntry("意", "mind, meaning", on: "イ", kun: "",
                hint: "A sound (音) coming from the heart (心): what you really mean.",
                words: [
                    KanjiWord("意味", "いみ", "meaning"),
                    KanjiWord("意見", "いけん", "opinion"),
                    KanjiWord("意地悪", "いじわる", "mean, spiteful"),
                    KanjiWord("注意", "ちゅうい", "caution, attention")
                ]),
            KanjiEntry("味", "taste", on: "ミ", kun: "あじ",
                hint: "A mouth (口) and 'not yet' (未): 'I haven't tried it yet!' Put it in your mouth to know the taste.",
                words: [
                    KanjiWord("味", "あじ", "taste, flavour"),
                    KanjiWord("意味", "いみ", "meaning"),
                    KanjiWord("趣味", "しゅみ", "hobby")
                ]),
            KanjiEntry("天", "sky, heaven", on: "テン", kun: "",
                hint: "A big (大) person with a line above their head: the sky overhead.",
                words: [
                    KanjiWord("天気", "てんき", "weather"),
                    KanjiWord("天使", "てんし", "angel"),
                    KanjiWord("天国", "てんごく", "heaven")
                ]),
            KanjiEntry("考", "consider", on: "コウ", kun: "かんが(える)",
                hint: "An old man with a bent back, leaning on his cane, deep in thought.",
                words: [
                    KanjiWord("考える", "かんがえる", "to think about, consider"),
                    KanjiWord("考え", "かんがえ", "idea, thought"),
                    KanjiWord("考古学", "こうこがく", "archaeology")
                ])
        ],
        sentences: [
            KanjiSentence("わたしの 部屋は 広くて 明るいです。", "わたし の へや は ひろくて あかるい です。", "My room is spacious and bright.", focus: "部屋"),
            KanjiSentence("教室に 学生が 十人 います。", "きょうしつ に がくせい が じゅうにん います。", "There are ten students in the classroom.", focus: "教室"),
            KanjiSentence("窓を 開けて ください。", "まど を あけて ください。", "Please open the window.", focus: "開けて"),
            KanjiSentence("ドアを 閉めて ください。", "ドア を しめて ください。", "Please close the door.", focus: "閉めて"),
            KanjiSentence("姉は 歌が 上手です。", "あね は うた が じょうず です。", "My older sister is good at singing.", focus: "歌"),
            KanjiSentence("この 言葉の 意味が 分かりません。", "この ことば の いみ が わかりません。", "I don't understand the meaning of this word.", focus: "意味"),
            KanjiSentence("この 料理は 味が いいです。", "この りょうり は あじ が いい です。", "This dish tastes good.", focus: "味"),
            KanjiSentence("明日の 天気は 雨です。", "あした の てんき は あめ です。", "Tomorrow's weather is rain.", focus: "天気", speech: "あしたの天気は雨です。"),
            KanjiSentence("よく 考えて ください。", "よく かんがえて ください。", "Please think it over carefully.", focus: "考えて"),
            KanjiSentence("駅の 前に 花屋が あります。", "えき の まえ に はなや が あります。", "There is a flower shop in front of the station.", focus: "花屋"),
            KanjiSentence("窓から 海が 見えます。", "まど から うみ が みえます。", "You can see the sea from the window.", focus: "窓")
        ]
    )
}
