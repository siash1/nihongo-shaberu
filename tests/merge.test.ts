// Merge rules of the progress sync CRDT (convex/lib/merge.ts).
// Run: npm test   (node --test tests/merge.test.ts; Node strips the types)
// A different random seed: MERGE_SEED=123 npm test

import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  bestScores,
  canonicalize,
  compareCodePoints,
  emptySnapshot,
  encodeSnapshot,
  isLive,
  merge,
  sanitizeSnapshot,
  compactWords,
  enforceAccountLimits,
  wordTextBytes,
  ACCOUNT_LIMITS,
  SNAPSHOT_LIMITS,
  type ProgressSnapshot,
  type WordEntry,
} from "../convex/lib/merge.ts";
import {
  int,
  mulberry32,
  pick,
  randomSnapshot,
  shuffle,
  KANJI_POOL,
  LEVELS,
  SCORE_KEY_POOL,
  TEXT_POOL,
  WORD_POOL,
  type Rng,
} from "./support/random.ts";

const SEED = Number(process.env.MERGE_SEED ?? 20261113);
const RUNS = Number(process.env.MERGE_RUNS ?? 3000);

function snap(partial: Partial<ProgressSnapshot>): ProgressSnapshot {
  return { ...emptySnapshot(), ...partial };
}

function word(
  w: string,
  level: string,
  addedAt: number,
  deletedAt = 0,
  text: Partial<WordEntry> = {},
): WordEntry {
  return {
    key: `${w}|${level}`,
    word: w,
    romaji: `${w}-romaji`,
    meaning: `${w}-meaning`,
    level,
    addedAt,
    deletedAt,
    ...text,
  };
}

function eq(actual: ProgressSnapshot, expected: ProgressSnapshot, message?: string) {
  assert.equal(encodeSnapshot(actual), encodeSnapshot(expected), message);
}

function liveWords(s: ProgressSnapshot): string[] {
  return s.words.filter((w) => isLive(w, s.wordsClearedAt)).map((w) => w.key);
}

// ---------------------------------------------------------------------------

describe("kanji progress", () => {
  test("reset drops learned kanji and scores recorded at or before it", () => {
    const device = snap({
      learned: [
        { kanji: "日", learnedAt: 5 },
        { kanji: "本", learnedAt: 10 },
        { kanji: "人", learnedAt: 11 },
      ],
      scores: [
        { key: "1-quiz", percent: 100, recordedAt: 10 },
        { key: "2-quiz", percent: 40, recordedAt: 12 },
      ],
    });
    const reset = snap({ kanjiResetAt: 10 });
    const expected = snap({
      kanjiResetAt: 10,
      learned: [{ kanji: "人", learnedAt: 11 }],
      scores: [{ key: "2-quiz", percent: 40, recordedAt: 12 }],
    });
    eq(merge(device, reset), expected);
    eq(merge(reset, device), expected);
  });

  test("a kanji learned on two devices keeps the latest learnedAt", () => {
    const a = snap({ learned: [{ kanji: "京", learnedAt: 5 }] });
    const b = snap({ learned: [{ kanji: "京", learnedAt: 15 }] });
    eq(merge(a, b), snap({ learned: [{ kanji: "京", learnedAt: 15 }] }));
  });

  test("learning after a reset survives whatever order the snapshots meet in", () => {
    // Device A learned 京 at 5, device B at 15, device C reset at 10.
    const a = snap({ learned: [{ kanji: "京", learnedAt: 5 }] });
    const b = snap({ learned: [{ kanji: "京", learnedAt: 15 }] });
    const c = snap({ kanjiResetAt: 10 });
    const expected = snap({ kanjiResetAt: 10, learned: [{ kanji: "京", learnedAt: 15 }] });
    eq(merge(merge(a, b), c), expected);
    eq(merge(a, merge(b, c)), expected);
    eq(merge(merge(a, c), b), expected);
  });

  test("best score wins; an equal score keeps the later recording", () => {
    const a = snap({ scores: [{ key: "1-quiz", percent: 80, recordedAt: 5 }] });
    const b = snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 7 }] });
    eq(merge(a, b), snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 7 }] }));

    const tieEarly = snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 3 }] });
    const tieLate = snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 8 }] });
    eq(merge(tieEarly, tieLate), snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 8 }] }));
    eq(merge(tieLate, tieEarly), snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 8 }] }));
  });

  test("a lower but later score is kept beside the best, so a reset between them leaves it", () => {
    const a = snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 5 }] });
    const b = snap({ scores: [{ key: "1-quiz", percent: 80, recordedAt: 15 }] });
    const both = merge(a, b);
    eq(
      both,
      snap({
        scores: [
          { key: "1-quiz", percent: 90, recordedAt: 5 },
          { key: "1-quiz", percent: 80, recordedAt: 15 },
        ],
      }),
    );
    assert.equal(bestScores(both).get("1-quiz"), 90);

    const afterReset = merge(both, snap({ kanjiResetAt: 10 }));
    eq(afterReset, snap({ kanjiResetAt: 10, scores: [{ key: "1-quiz", percent: 80, recordedAt: 15 }] }));
    assert.equal(bestScores(afterReset).get("1-quiz"), 80);
    // Same result when the reset meets the 90 first.
    eq(merge(merge(a, snap({ kanjiResetAt: 10 })), b), afterReset);
  });

  test("a later, better score replaces older ones", () => {
    const s = snap({
      scores: [
        { key: "1-quiz", percent: 60, recordedAt: 1 },
        { key: "1-quiz", percent: 70, recordedAt: 2 },
        { key: "1-quiz", percent: 70, recordedAt: 2 },
        { key: "1-quiz", percent: 95, recordedAt: 9 },
      ],
    });
    eq(canonicalize(s), snap({ scores: [{ key: "1-quiz", percent: 95, recordedAt: 9 }] }));
  });

  test("zero timestamps: never learned, and a reset at 0 keeps everything after it", () => {
    const s = snap({
      learned: [
        { kanji: "日", learnedAt: 0 },
        { kanji: "本", learnedAt: 1 },
      ],
      scores: [{ key: "1-quiz", percent: 10, recordedAt: 0 }],
    });
    eq(canonicalize(s), snap({ learned: [{ kanji: "本", learnedAt: 1 }] }));
  });
});

describe("word bank", () => {
  test("delete then re-add makes the word live again with the new text", () => {
    const added = snap({ words: [word("ねこ", "N5", 1, 0, { meaning: "cat" })] });
    const deleted = snap({ words: [word("ねこ", "N5", 1, 5, { meaning: "cat" })] });
    const merged = merge(added, deleted);
    assert.deepEqual(liveWords(merged), []);
    assert.equal(merged.words[0].addedAt, 0, "a tombstone keeps no addedAt");
    assert.equal(merged.words[0].deletedAt, 5);

    const readded = snap({ words: [word("ねこ", "N5", 9, 5, { meaning: "a cat" })] });
    const final = merge(merged, readded);
    assert.deepEqual(liveWords(final), ["ねこ|N5"]);
    assert.equal(final.words[0].meaning, "a cat");
    assert.equal(final.words[0].addedAt, 9);
    assert.equal(final.words[0].deletedAt, 5);
  });

  test("a delete later than a concurrent re-add wins (last writer wins)", () => {
    const readd = snap({ words: [word("いぬ", "N5", 6)] });
    const del = snap({ words: [word("いぬ", "N5", 1, 7)] });
    assert.deepEqual(liveWords(merge(readd, del)), []);
  });

  test("tombstone liveness: equal addedAt and deletedAt is not live", () => {
    const s = canonicalize(snap({ words: [word("とり", "N4", 5, 5)] }));
    assert.deepEqual(liveWords(s), []);
    assert.equal(s.words.length, 1);
    assert.deepEqual({ addedAt: s.words[0].addedAt, deletedAt: s.words[0].deletedAt }, { addedAt: 0, deletedAt: 5 });
  });

  test("clear-all garbage-collects every entry at or before it", () => {
    const s = snap({
      words: [
        word("a", "N5", 3),
        word("b", "N5", 1, 4),
        word("c", "N5", 12),
        word("d", "N5", 2, 11),
        word("e", "N5", 10, 0),
      ],
    });
    const cleared = merge(s, snap({ wordsClearedAt: 10 }));
    assert.deepEqual(
      cleared.words.map((w) => [w.key, w.addedAt, w.deletedAt]),
      [
        ["c|N5", 12, 0],
        ["d|N5", 0, 11],
      ],
    );
    assert.deepEqual(liveWords(cleared), ["c|N5"]);
  });

  test("a delete before the clear is forgotten on a word added after it", () => {
    const s = snap({ wordsClearedAt: 5, words: [word("a", "N5", 8, 3)] });
    const c = canonicalize(s);
    assert.equal(c.words[0].deletedAt, 0);
    assert.deepEqual(liveWords(c), ["a|N5"]);
  });

  test("text comes from the latest add; ties pick the smallest (romaji, meaning, word, level)", () => {
    const x = word("ねこ", "N5", 4, 0, { romaji: "neko", meaning: "cat" });
    const y = word("ねこ", "N5", 4, 0, { romaji: "neko", meaning: "a cat" });
    const z = word("ねこ", "N5", 3, 0, { romaji: "aaa", meaning: "aaa" });
    for (const order of [[x, y, z], [z, y, x], [y, z, x]]) {
      const m = canonicalize(snap({ words: order }));
      assert.equal(m.words[0].meaning, "a cat");
      assert.equal(m.words[0].romaji, "neko");
    }
  });

  test("level is the last text tie-break, so a mismatching level cannot make the merge order-dependent", () => {
    const x = word("ねこ", "N5", 4, 0, { level: "N4" });
    const y = word("ねこ", "N5", 4, 0);
    eq(merge(snap({ words: [x] }), snap({ words: [y] })), merge(snap({ words: [y] }), snap({ words: [x] })));
    assert.equal(canonicalize(snap({ words: [y, x] })).words[0].level, "N4");
  });

  test("a tombstone takes its text from the latest delete", () => {
    const x = word("ねこ", "N5", 1, 9, { meaning: "deleted last" });
    const y = word("ねこ", "N5", 5, 6, { meaning: "added last" });
    const m = canonicalize(snap({ words: [y, x] }));
    assert.equal(m.words[0].meaning, "deleted last");
    assert.deepEqual([m.words[0].addedAt, m.words[0].deletedAt], [0, 9]);
  });
});

describe("strings", () => {
  test("NFC normalisation merges decomposed and precomposed kana", () => {
    const a = snap({
      learned: [{ kanji: "が", learnedAt: 3 }],
      words: [
        {
          key: "がっこう|N5",
          word: "がっこう",
          romaji: "gakkou",
          meaning: "café",
          level: "N5",
          addedAt: 2,
          deletedAt: 0,
        },
      ],
    });
    const b = snap({
      learned: [{ kanji: "が", learnedAt: 4 }],
      words: [word("がっこう", "N5", 1, 0, { romaji: "gakkou", meaning: "school" })],
    });
    const m = merge(a, b);
    assert.deepEqual(m.learned, [{ kanji: "が", learnedAt: 4 }]);
    assert.equal(m.words.length, 1);
    assert.equal(m.words[0].key, "がっこう|N5");
    assert.equal(m.words[0].word, "がっこう");
    assert.equal(m.words[0].meaning, "café");
    assert.equal(m.words[0].meaning.length, 4);
  });

  test("singleton canonical decompositions are applied (U+F900 → U+8C48, U+2126 → U+03A9)", () => {
    const m = canonicalize(snap({ learned: [{ kanji: "豈", learnedAt: 1 }, { kanji: "豈", learnedAt: 2 }] }));
    assert.deepEqual(m.learned, [{ kanji: "豈", learnedAt: 2 }]);
  });

  test("sorting is by code point (= UTF-8 bytes), not UTF-16 units", () => {
    // U+FF76 (halfwidth ｶ) sorts AFTER U+20BB7 (𠮷) in UTF-16 units, BEFORE in code points.
    const m = canonicalize(
      snap({
        learned: [
          { kanji: "𠮷", learnedAt: 1 },
          { kanji: "ｶ", learnedAt: 1 },
          { kanji: "", learnedAt: 1 },
          { kanji: "が", learnedAt: 1 },
          { kanji: "か", learnedAt: 1 },
          { kanji: "A", learnedAt: 1 },
        ],
      }),
    );
    assert.deepEqual(
      m.learned.map((e) => e.kanji),
      ["A", "か", "が", "", "ｶ", "𠮷"],
    );
    // JS's default sort would put 𠮷 (surrogates D842 DFB7) before U+E000.
    assert.deepEqual(["𠮷", ""].sort(), ["𠮷", ""]);
  });

  test("a decomposed kana key sorts at its NFC position", () => {
    const m = canonicalize(
      snap({
        words: [
          word("が", "N5", 1), // NFC: が U+304C
          word("き", "N5", 1), // U+304D
          word("か", "N5", 1), // U+304B
        ],
      }),
    );
    assert.deepEqual(m.words.map((w) => w.key), ["か|N5", "が|N5", "き|N5"]);
  });

  test("compareCodePoints agrees with UTF-8 byte order on random strings", () => {
    const rng = mulberry32(SEED);
    const alphabet = ["a", "Z", "é", "か", "が", "゙", "", "�", "ｶ", "𠮷", "😀", "🐈", "́"];
    for (let i = 0; i < 2000; i++) {
      const s = Array.from({ length: int(rng, 5) }, () => pick(rng, alphabet)).join("");
      const t = Array.from({ length: int(rng, 5) }, () => pick(rng, alphabet)).join("");
      const bytes = Buffer.compare(Buffer.from(s, "utf8"), Buffer.from(t, "utf8"));
      assert.equal(Math.sign(compareCodePoints(s, t)), bytes, `${JSON.stringify(s)} vs ${JSON.stringify(t)}`);
    }
  });
});

describe("sanitizeSnapshot", () => {
  const now = 1_000_000;

  test("clamps timestamps to [0, now] and normalises strings", () => {
    const r = sanitizeSnapshot(
      snap({
        kanjiResetAt: now + 5,
        wordsClearedAt: -3,
        learned: [{ kanji: "が", learnedAt: now * 10 }],
        scores: [{ key: "1-quiz", percent: 50, recordedAt: -1 }],
        words: [word("ねこ", "N5", now + 1, -0)],
      }),
      now,
    );
    assert.ok(r.ok);
    assert.equal(r.snapshot.kanjiResetAt, now);
    assert.equal(r.snapshot.wordsClearedAt, 0);
    assert.deepEqual(r.snapshot.learned, [{ kanji: "が", learnedAt: now }]);
    assert.equal(r.snapshot.scores[0].recordedAt, 0);
    assert.equal(r.snapshot.words[0].addedAt, now);
    assert.ok(Object.is(r.snapshot.words[0].deletedAt, 0));
  });

  const rejects: [string, ProgressSnapshot][] = [
    ["percent above 100", snap({ scores: [{ key: "k", percent: 101, recordedAt: 1 }] })],
    ["negative percent", snap({ scores: [{ key: "k", percent: -1, recordedAt: 1 }] })],
    ["fractional percent", snap({ scores: [{ key: "k", percent: 50.5, recordedAt: 1 }] })],
    ["unknown level", snap({ words: [word("a", "N6", 1)] })],
    ["lowercase level", snap({ words: [word("a", "n5", 1)] })],
    ["kanji longer than 8", snap({ learned: [{ kanji: "日本日本日本日本日", learnedAt: 1 }] })],
    ["key longer than 300", snap({ scores: [{ key: "k".repeat(301), percent: 1, recordedAt: 1 }] })],
    ["meaning longer than 300", snap({ words: [word("a", "N5", 1, 0, { meaning: "m".repeat(301) })] })],
    ["too many learned", snap({ learned: Array.from({ length: 2001 }, () => ({ kanji: "日", learnedAt: 1 })) })],
    ["too many scores", snap({ scores: Array.from({ length: 2001 }, () => ({ key: "k", percent: 1, recordedAt: 1 })) })],
    ["NaN timestamp", snap({ kanjiResetAt: Number.NaN })],
    ["infinite timestamp", snap({ learned: [{ kanji: "日", learnedAt: Number.POSITIVE_INFINITY }] })],
    ["lone surrogate", snap({ learned: [{ kanji: "\uD842", learnedAt: 1 }] })],
  ];
  for (const [name, input] of rejects) {
    test(`rejects ${name}`, () => {
      const r = sanitizeSnapshot(input, now);
      assert.equal(r.ok, false);
    });
  }

  test("accepts limits exactly: 8-character kanji (non-BMP counts once), 300-character fields, 2000 learned, 8000 words", () => {
    const r = sanitizeSnapshot(
      snap({
        learned: [
          { kanji: "𠮷".repeat(8), learnedAt: 1 },
          ...Array.from({ length: SNAPSHOT_LIMITS.maxLearned - 1 }, () => ({ kanji: "日", learnedAt: 1 })),
        ],
        words: [
          word("a", "N1", 1, 0, { meaning: "😀".repeat(300) }),
          ...Array.from({ length: SNAPSHOT_LIMITS.maxWords - 1 }, (_, i) => word(`w${i}`, "N5", 1)),
        ],
      }),
      now,
    );
    assert.ok(r.ok);
  });

  test("a word list over its limits is WORD_BANK_FULL, not INVALID_INPUT", () => {
    const tooMany = sanitizeSnapshot(
      snap({ words: Array.from({ length: SNAPSHOT_LIMITS.maxWords + 1 }, (_, i) => word(`w${i}`, "N5", 1)) }),
      now,
    );
    assert.deepEqual(tooMany.ok ? null : tooMany.code, "WORD_BANK_FULL");
    const big = "😀".repeat(300);
    const tooBig = sanitizeSnapshot(
      snap({
        words: Array.from({ length: 2000 }, (_, i) =>
          word(`w${i}`, "N5", 1, 0, { romaji: big, meaning: big })),
      }),
      now,
    );
    assert.deepEqual(tooBig.ok ? null : tooBig.code, "WORD_BANK_FULL");
    const bad = sanitizeSnapshot(snap({ words: [word("a", "N9", 1)] }), now);
    assert.deepEqual(bad.ok ? null : bad.code, "INVALID_INPUT");
  });

  test("wordTextBytes counts UTF-8 bytes", () => {
    assert.equal(wordTextBytes([word("a", "N5", 1, 0, { romaji: "é", meaning: "😀日" })]), 4 + 1 + 2 + 7 + 2);
  });
});

describe("account limits and word compaction", () => {
  const T = 1_700_000_000_000;

  function bank(live: number, tombstones: number, clearedAt = 0): ProgressSnapshot {
    const words: WordEntry[] = [];
    for (let i = 0; i < live; i++) words.push(word(`live${i}`, "N5", T + i));
    for (let i = 0; i < tombstones; i++) words.push(word(`gone${i}`, "N4", T - 10, T + 100 + i));
    return canonicalize(snap({ wordsClearedAt: clearedAt, words }));
  }

  test("compaction drops every tombstone and keeps every live word, in order, after the new clear", () => {
    const before = bank(5, 3);
    const after = compactWords(before);
    const latestDelete = T + 102;
    assert.equal(after.wordsClearedAt, latestDelete);
    assert.deepEqual(liveWords(after).sort(), liveWords(before).sort());
    assert.equal(after.words.length, 5);
    assert.ok(after.words.every((w) => w.addedAt > latestDelete && w.deletedAt === 0));
    const order = (s: ProgressSnapshot) =>
      s.words.filter((w) => isLive(w, s.wordsClearedAt)).sort((x, y) => x.addedAt - y.addedAt).map((w) => w.key);
    assert.deepEqual(order(after), order(before), "oldest first is kept");
    eq(canonicalize(after), after, "canonical");
    eq(compactWords(after), after, "nothing left to compact");
    eq(compactWords(bank(4, 0)), bank(4, 0), "no tombstones: unchanged");
  });

  test("a compacted state converges with stale replicas: no deleted word comes back", () => {
    const deleted = word("ねこ", "N5", 0, T + 50);
    const server = canonicalize(snap({ words: [deleted, word("いぬ", "N5", T)] }));
    const compacted = compactWords(server);
    assert.deepEqual(liveWords(compacted), ["いぬ|N5"]);
    // A device that still holds ねこ live from before the delete.
    const stale = snap({ words: [word("ねこ", "N5", T - 5), word("いぬ", "N5", T)] });
    eq(merge(compacted, stale), compacted, "the stale live copy is covered by the clear");
    // An edit made after the compaction survives.
    const later = snap({ words: [word("とり", "N5", T + 1000)] });
    assert.deepEqual(liveWords(merge(compacted, later)), ["いぬ|N5", "とり|N5"]);
    // Every order of merging gives the same state.
    eq(merge(merge(compacted, stale), later), merge(compacted, merge(stale, later)));
  });

  test("timestamps of re-stamped words stay distinct at real-world magnitudes", () => {
    const words: WordEntry[] = [word("gone", "N5", 0, T + 10)];
    for (let i = 0; i < 5000; i++) words.push(word(`w${i}`, "N5", T));
    const after = compactWords(canonicalize(snap({ words })));
    assert.equal(new Set(after.words.map((w) => w.addedAt)).size, 5000);
    assert.ok(after.words.every((w) => w.addedAt > T + 10 && w.addedAt < T + 10 + 20));
  });

  test("enforceAccountLimits compacts a large bank and rejects one with too many live words", () => {
    const large = bank(100, ACCOUNT_LIMITS.compactWordsAbove);
    const ok = enforceAccountLimits(large);
    assert.ok(ok.ok);
    assert.equal(ok.snapshot.words.length, 100);
    const small = bank(10, 10);
    const untouched = enforceAccountLimits(small);
    assert.ok(untouched.ok);
    eq(untouched.snapshot, small, "small banks keep their tombstones");
    const full = enforceAccountLimits(bank(ACCOUNT_LIMITS.maxLiveWords + 1, 0));
    assert.deepEqual(full.ok ? null : full.code, "WORD_BANK_FULL");
    const atLimit = enforceAccountLimits(bank(ACCOUNT_LIMITS.maxLiveWords, ACCOUNT_LIMITS.compactWordsAbove));
    assert.ok(atLimit.ok);
    assert.ok(atLimit.snapshot.words.length <= ACCOUNT_LIMITS.compactWordsAbove);
    assert.ok(ACCOUNT_LIMITS.compactWordsAbove < SNAPSHOT_LIMITS.maxWords, "the stored bank leaves room for a device's edits");
  });
});

// ---------------------------------------------------------------------------
// Randomized properties

function same(a: ProgressSnapshot, b: ProgressSnapshot): boolean {
  return encodeSnapshot(a) === encodeSnapshot(b);
}

function check(name: string, ok: boolean, inputs: unknown) {
  if (!ok) {
    assert.fail(`${name} failed (seed ${SEED}) for ${JSON.stringify(inputs)}`);
  }
}

describe(`properties (seed ${SEED}, ${RUNS} runs each)`, () => {
  test("output is canonical: sorted, NFC, unique keys, and a fixed point of canonicalize", () => {
    const rng = mulberry32(SEED + 1);
    for (let i = 0; i < RUNS; i++) {
      const a = randomSnapshot(rng);
      const b = randomSnapshot(rng);
      const m = merge(a, b);
      check("canonicalize(merge) == merge", same(canonicalize(m), m), { a, b });
      const strings = [
        ...m.learned.map((e) => e.kanji),
        ...m.scores.map((e) => e.key),
        ...m.words.flatMap((w) => [w.key, w.word, w.romaji, w.meaning, w.level]),
      ];
      check("NFC", strings.every((s) => s === s.normalize("NFC")), { a, b });
      for (let j = 1; j < m.learned.length; j++) {
        check("learned sorted+unique", compareCodePoints(m.learned[j - 1].kanji, m.learned[j].kanji) < 0, { a, b });
      }
      for (let j = 1; j < m.words.length; j++) {
        check("words sorted+unique", compareCodePoints(m.words[j - 1].key, m.words[j].key) < 0, { a, b });
      }
      for (let j = 1; j < m.scores.length; j++) {
        const c = compareCodePoints(m.scores[j - 1].key, m.scores[j].key);
        check(
          "scores sorted, frontier strictly decreasing",
          c < 0 ||
            (c === 0 &&
              m.scores[j - 1].recordedAt < m.scores[j].recordedAt &&
              m.scores[j - 1].percent > m.scores[j].percent),
          { a, b },
        );
      }
      check(
        "nothing at or before the resets survives",
        m.learned.every((e) => e.learnedAt > m.kanjiResetAt) &&
          m.scores.every((e) => e.recordedAt > m.kanjiResetAt) &&
          m.words.every((w) => Math.max(w.addedAt, w.deletedAt) > m.wordsClearedAt),
        { a, b },
      );
    }
  });

  test("commutativity: merge(a, b) == merge(b, a)", () => {
    const rng = mulberry32(SEED + 2);
    for (let i = 0; i < RUNS; i++) {
      const a = randomSnapshot(rng);
      const b = randomSnapshot(rng);
      check("commutativity", same(merge(a, b), merge(b, a)), { a, b });
    }
  });

  test("associativity: merge(merge(a, b), c) == merge(a, merge(b, c))", () => {
    const rng = mulberry32(SEED + 3);
    for (let i = 0; i < RUNS; i++) {
      const a = randomSnapshot(rng);
      const b = randomSnapshot(rng);
      const c = randomSnapshot(rng);
      check("associativity", same(merge(merge(a, b), c), merge(a, merge(b, c))), { a, b, c });
    }
  });

  test("idempotence and absorption: merge(x, x) == x, merge(merge(a, b), b) == merge(a, b)", () => {
    const rng = mulberry32(SEED + 4);
    for (let i = 0; i < RUNS; i++) {
      const a = randomSnapshot(rng);
      const b = randomSnapshot(rng);
      const x = canonicalize(a);
      check("merge(x, x) == x", same(merge(x, x), x), { a });
      check("merge(a, a) == canonicalize(a)", same(merge(a, a), x), { a });
      const ab = merge(a, b);
      check("absorption b", same(merge(ab, b), ab), { a, b });
      check("absorption a", same(merge(a, ab), ab), { a, b });
    }
  });

  test("any grouping of many snapshots gives the same result", () => {
    const rng = mulberry32(SEED + 5);
    for (let i = 0; i < RUNS / 5; i++) {
      const parts = Array.from({ length: 2 + int(rng, 5) }, () => randomSnapshot(rng, 4));
      const reference = parts.reduce(merge, emptySnapshot());
      // Random binary tree over a random permutation.
      let pool = shuffle(rng, parts);
      while (pool.length > 1) {
        const x = pool.splice(int(rng, pool.length), 1)[0];
        const y = pool.splice(int(rng, pool.length), 1)[0];
        pool.push(merge(x, y));
      }
      check("grouping", same(pool[0], reference), { parts });
    }
  });

  test("three replicas with local edits converge, merging in random orders", () => {
    const rng = mulberry32(SEED + 6);
    for (let run = 0; run < RUNS / 10; run++) {
      const replicas = [emptySnapshot(), emptySnapshot(), emptySnapshot()];
      // Each device has its own (possibly skewed) clock; ties happen.
      const skew = [0, int(rng, 4), -int(rng, 4)];
      let clock = 10;
      const history: string[] = [];
      for (let step = 0; step < 40; step++) {
        clock += int(rng, 3); // sometimes no tick: equal timestamps
        const r = int(rng, 3);
        const now = Math.max(1, clock + skew[r]);
        if (rng() < 0.35) {
          const other = (r + 1 + int(rng, 2)) % 3;
          const m = merge(replicas[r], replicas[other]);
          replicas[r] = m;
          if (rng() < 0.5) replicas[other] = m;
          history.push(`sync ${r}<->${other}`);
        } else {
          const op = localEdit(rng, replicas[r], now);
          replicas[r] = op.next;
          history.push(`${r}@${now}: ${op.name}`);
        }
      }
      // Gossip in random order until nothing changes.
      for (let round = 0; round < 10; round++) {
        for (const [i, j] of shuffle(rng, [[0, 1], [1, 2], [0, 2], [1, 0], [2, 1], [2, 0]])) {
          replicas[i] = merge(replicas[i], replicas[j]);
        }
      }
      check(
        "convergence",
        same(replicas[0], replicas[1]) && same(replicas[1], replicas[2]),
        { history, replicas },
      );
      // Hub model: the server merges every device; devices merge the server's answer.
      check(
        "hub converges to the same state",
        same(replicas.reduce(merge, emptySnapshot()), replicas[0]),
        { history },
      );
    }
  });
});

/** The Swift client's local edit rules (markLearned, recordScore, reset, saveWords, deleteWord, clearAllWords), on a canonical snapshot. */
function localEdit(rng: Rng, s: ProgressSnapshot, now: number): { name: string; next: ProgressSnapshot } {
  const roll = rng();
  if (roll < 0.2) {
    const kanji = pick(rng, KANJI_POOL).normalize("NFC");
    if (s.learned.some((e) => e.kanji === kanji)) return { name: `learned ${kanji} again (no-op)`, next: s };
    return { name: `learn ${kanji}`, next: canonicalize({ ...s, learned: [...s.learned, { kanji, learnedAt: now }] }) };
  }
  if (roll < 0.4) {
    const key = pick(rng, SCORE_KEY_POOL);
    const percent = int(rng, 101);
    const best = bestScores(s).get(key);
    if (best !== undefined && percent <= best) return { name: `score ${key} ${percent} (not better)`, next: s };
    return {
      name: `score ${key} ${percent}`,
      next: canonicalize({ ...s, scores: [...s.scores, { key, percent, recordedAt: now }] }),
    };
  }
  if (roll < 0.47) {
    return { name: "reset kanji", next: canonicalize({ ...s, kanjiResetAt: now, learned: [], scores: [] }) };
  }
  if (roll < 0.75) {
    const w = pick(rng, WORD_POOL).normalize("NFC");
    const level = pick(rng, LEVELS);
    const key = `${w}|${level}`;
    const existing = s.words.find((e) => e.key === key);
    if (existing && isLive(existing, s.wordsClearedAt)) return { name: `save ${key} (live, kept)`, next: s };
    const entry: WordEntry = {
      key,
      word: w,
      romaji: pick(rng, TEXT_POOL),
      meaning: pick(rng, TEXT_POOL),
      level,
      addedAt: now,
      deletedAt: existing?.deletedAt ?? 0,
    };
    return {
      name: `save ${key}`,
      next: canonicalize({ ...s, words: [...s.words.filter((e) => e.key !== key), entry] }),
    };
  }
  if (roll < 0.93) {
    const live = s.words.filter((e) => isLive(e, s.wordsClearedAt));
    if (live.length === 0) return { name: "delete (nothing live)", next: s };
    const target = pick(rng, live);
    return {
      name: `delete ${target.key}`,
      next: canonicalize({
        ...s,
        words: s.words.map((e) => (e.key === target.key ? { ...e, deletedAt: now } : e)),
      }),
    };
  }
  return { name: "clear all words", next: canonicalize({ ...s, wordsClearedAt: now, words: [] }) };
}

// ---------------------------------------------------------------------------
// Fixtures shared with the Swift tests

describe("tests/fixtures/merge-cases.json", () => {
  test("every expected value is merge(a, b) and merge(b, a) of the current merge.ts", () => {
    const url = new URL("./fixtures/merge-cases.json", import.meta.url);
    const cases = JSON.parse(readFileSync(url, "utf8")) as {
      name: string;
      a: ProgressSnapshot;
      b: ProgressSnapshot;
      expected: ProgressSnapshot;
    }[];
    assert.ok(cases.length >= 250, `only ${cases.length} cases`);
    for (const c of cases) {
      assert.equal(encodeSnapshot(merge(c.a, c.b)), encodeSnapshot(c.expected), `${c.name} (run npm run fixtures)`);
      assert.equal(encodeSnapshot(merge(c.b, c.a)), encodeSnapshot(c.expected), `${c.name} reversed`);
    }
  });
});
