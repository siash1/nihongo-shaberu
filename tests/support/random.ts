// Seeded random snapshot generator shared by tests/merge.test.ts and
// tests/generate-fixtures.ts. Small value pools make keys and timestamps
// collide often, which is where merge rules matter.

import type {
  LearnedEntry,
  ProgressSnapshot,
  ScoreEntry,
  WordEntry,
} from "../../convex/lib/merge.ts";

export type Rng = () => number;

/** mulberry32: a small, fast, seeded PRNG returning floats in [0, 1). */
export function mulberry32(seed: number): Rng {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function int(rng: Rng, n: number): number {
  return Math.floor(rng() * n);
}

export function pick<T>(rng: Rng, items: readonly T[]): T {
  return items[int(rng, items.length)];
}

export function shuffle<T>(rng: Rng, items: T[]): T[] {
  const out = items.slice();
  for (let i = out.length - 1; i > 0; i--) {
    const j = int(rng, i + 1);
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

// Kanji, including a non-BMP one (𠮷 U+20BB7), a CJK compatibility ideograph
// whose NFC form is a different code point (U+F900 → U+8C48), and kana written
// precomposed (が) and decomposed (か + U+3099).
export const KANJI_POOL = [
  "日",
  "本",
  "人",
  "京",
  "𠮷",
  "豈",
  "豈",
  "が",
  "が",
  "パ",
  "パ",
];

export const SCORE_KEY_POOL = ["1-quiz", "1-words", "1-sentences", "2-quiz", "10-quiz", "review-mixed"];

// Words that collide after NFC (がっこう vs か+゙っこう) or differ only in
// code-point order traps (non-BMP vs BMP private use, emoji).
export const WORD_POOL = [
  "がっこう",
  "がっこう",
  "テレビ",
  "テレビ",
  "𠮷野家",
  "ねこ🐈",
  "ｶ",
  "ｶﾞ",
  "café",
  "café",
];

export const TEXT_POOL = [
  "",
  "a",
  "A",
  "gakkou",
  "school",
  "cat 🐈",
  "😀",
  "",
  "�",
  "𠮷",
  "é",
  "é",
  "Ω",
  "Ω",
  "がっこう",
  "が",
  "mixed テスト 123",
];

export const LEVELS = ["N5", "N4", "N3", "N2", "N1"];

/** Timestamps from a small set (so equal timestamps are common), incl. 0, fractions and real-looking values. */
export const TIME_POOL = [0, 0, 1, 2, 3, 5, 5, 8, 10, 10, 13, 20, 1731500000000, 1731500000000.5, 1763072345123.456];

export function randomTime(rng: Rng): number {
  return pick(rng, TIME_POOL);
}

export function randomLearned(rng: Rng): LearnedEntry {
  return { kanji: pick(rng, KANJI_POOL), learnedAt: randomTime(rng) };
}

export function randomScore(rng: Rng): ScoreEntry {
  const percents = [0, 50, 50, 80, 90, 90, 100];
  return {
    key: pick(rng, SCORE_KEY_POOL),
    percent: pick(rng, percents),
    recordedAt: randomTime(rng),
  };
}

export function randomWord(rng: Rng): WordEntry {
  const word = pick(rng, WORD_POOL);
  const level = pick(rng, LEVELS);
  return {
    // Mostly the canonical "<word>|<level>" key; sometimes a mismatching level.
    key: `${word}|${rng() < 0.9 ? level : pick(rng, LEVELS)}`,
    word,
    romaji: pick(rng, TEXT_POOL),
    meaning: pick(rng, TEXT_POOL),
    level,
    addedAt: randomTime(rng),
    deletedAt: rng() < 0.5 ? 0 : randomTime(rng),
  };
}

/** An arbitrary (not necessarily canonical) snapshot: unsorted, duplicate keys, decomposed strings. */
export function randomSnapshot(rng: Rng, size = 6): ProgressSnapshot {
  const n = () => int(rng, size + 1);
  return {
    kanjiResetAt: rng() < 0.5 ? 0 : randomTime(rng),
    learned: Array.from({ length: n() }, () => randomLearned(rng)),
    scores: Array.from({ length: n() }, () => randomScore(rng)),
    wordsClearedAt: rng() < 0.5 ? 0 : randomTime(rng),
    words: Array.from({ length: n() }, () => randomWord(rng)),
  };
}
