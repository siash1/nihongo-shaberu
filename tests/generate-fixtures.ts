// Generates tests/fixtures/merge-cases.json: input pairs and the expected
// merge(a, b) from convex/lib/merge.ts. The Swift tests decode the file and
// assert that `ProgressSnapshot.merge(a, b)` gives exactly `expected`.
//
// Run: npm run fixtures   (node tests/generate-fixtures.ts)
// Deterministic: the same seed always writes the same file.
//
// File shape: a JSON array of { name, a, b, expected } where a, b and expected
// are ProgressSnapshot wire objects. Inputs are deliberately NOT canonical
// (unsorted, duplicate keys, decomposed strings); `expected` is canonical.
// Every non-ASCII character is written as a \u escape so that no editor or
// tool can re-normalise the decomposed strings in the file.

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  emptySnapshot,
  merge,
  type ProgressSnapshot,
  type WordEntry,
} from "../convex/lib/merge.ts";
import { int, mulberry32, randomSnapshot } from "./support/random.ts";

const SEED = 300;
const RANDOM_CASES = 260;

type Case = { name: string; a: ProgressSnapshot; b: ProgressSnapshot; expected: ProgressSnapshot };

function snap(partial: Partial<ProgressSnapshot>): ProgressSnapshot {
  return { ...emptySnapshot(), ...partial };
}

function w(
  word: string,
  level: string,
  addedAt: number,
  deletedAt = 0,
  text: Partial<WordEntry> = {},
): WordEntry {
  return {
    key: `${word}|${level}`,
    word,
    romaji: "romaji",
    meaning: "meaning",
    level,
    addedAt,
    deletedAt,
    ...text,
  };
}

// Hand-picked edge cases first, then seeded random ones.
const handPicked: [string, ProgressSnapshot, ProgressSnapshot][] = [
  ["both empty", snap({}), snap({})],
  ["zeros everywhere", snap({ learned: [{ kanji: "日", learnedAt: 0 }], scores: [{ key: "1-quiz", percent: 0, recordedAt: 0 }], words: [w("ねこ", "N5", 0, 0)] }), snap({})],
  ["reset drops older learned and scores", snap({ learned: [{ kanji: "日", learnedAt: 5 }, { kanji: "本", learnedAt: 10 }, { kanji: "人", learnedAt: 11 }], scores: [{ key: "1-quiz", percent: 100, recordedAt: 10 }, { key: "2-quiz", percent: 40, recordedAt: 12 }] }), snap({ kanjiResetAt: 10 })],
  ["learned on two devices keeps the latest", snap({ learned: [{ kanji: "京", learnedAt: 5 }] }), snap({ learned: [{ kanji: "京", learnedAt: 15 }] })],
  ["equal learnedAt", snap({ learned: [{ kanji: "京", learnedAt: 7 }] }), snap({ learned: [{ kanji: "京", learnedAt: 7 }] })],
  ["learned equal to reset is dropped", snap({ learned: [{ kanji: "京", learnedAt: 7 }] }), snap({ kanjiResetAt: 7 })],
  ["best score wins", snap({ scores: [{ key: "1-quiz", percent: 80, recordedAt: 5 }] }), snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 7 }] })],
  ["equal score keeps the later recording", snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 3 }] }), snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 8 }] })],
  ["lower later score kept on the frontier", snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 5 }] }), snap({ scores: [{ key: "1-quiz", percent: 80, recordedAt: 15 }] })],
  ["frontier then reset between", snap({ scores: [{ key: "1-quiz", percent: 90, recordedAt: 5 }, { key: "1-quiz", percent: 80, recordedAt: 15 }] }), snap({ kanjiResetAt: 10 })],
  ["same time different percents", snap({ scores: [{ key: "1-quiz", percent: 70, recordedAt: 5 }] }), snap({ scores: [{ key: "1-quiz", percent: 75, recordedAt: 5 }] })],
  ["score duplicates inside one input", snap({ scores: [{ key: "1-quiz", percent: 70, recordedAt: 5 }, { key: "1-quiz", percent: 70, recordedAt: 5 }, { key: "1-quiz", percent: 60, recordedAt: 9 }, { key: "1-quiz", percent: 60, recordedAt: 2 }] }), snap({})],
  ["delete wins over older add", snap({ words: [w("ねこ", "N5", 1, 0, { meaning: "cat" })] }), snap({ words: [w("ねこ", "N5", 1, 5, { meaning: "cat" })] })],
  ["re-add after delete", snap({ words: [w("ねこ", "N5", 1, 5, { meaning: "cat" })] }), snap({ words: [w("ねこ", "N5", 9, 5, { meaning: "a cat" })] })],
  ["equal added and deleted is a tombstone", snap({ words: [w("とり", "N4", 5, 5)] }), snap({})],
  ["clear-all garbage collects", snap({ words: [w("a", "N5", 3), w("b", "N5", 1, 4), w("c", "N5", 12), w("d", "N5", 2, 11), w("e", "N5", 10, 0)] }), snap({ wordsClearedAt: 10 })],
  ["delete before the clear is forgotten", snap({ wordsClearedAt: 5 }), snap({ words: [w("a", "N5", 8, 3)] })],
  ["clear then tombstone from another device", snap({ words: [w("k", "N5", 5, 0, { romaji: "e" })], wordsClearedAt: 10 }), snap({ words: [w("k", "N5", 3, 20, { romaji: "c" })] })],
  ["text tie-break on equal addedAt", snap({ words: [w("ねこ", "N5", 4, 0, { romaji: "neko", meaning: "cat" })] }), snap({ words: [w("ねこ", "N5", 4, 0, { romaji: "neko", meaning: "a cat" })] })],
  ["text tie-break falls through to word and level", snap({ words: [w("ねこ", "N5", 4, 0, { level: "N4" })] }), snap({ words: [w("ねこ", "N5", 4, 0)] })],
  ["tombstone text from the latest delete", snap({ words: [w("ねこ", "N5", 1, 9, { meaning: "deleted last" })] }), snap({ words: [w("ねこ", "N5", 5, 6, { meaning: "added last" })] })],
  ["decomposed dakuten merges with precomposed", snap({ learned: [{ kanji: "が", learnedAt: 3 }], words: [{ key: "がっこう|N5", word: "がっこう", romaji: "gakkou", meaning: "café", level: "N5", addedAt: 2, deletedAt: 0 }] }), snap({ learned: [{ kanji: "が", learnedAt: 4 }], words: [w("がっこう", "N5", 1, 0, { romaji: "gakkou", meaning: "school" })] })],
  ["decomposed handakuten", snap({ learned: [{ kanji: "パ", learnedAt: 2 }] }), snap({ learned: [{ kanji: "パ", learnedAt: 1 }] })],
  ["CJK compatibility ideograph normalises", snap({ learned: [{ kanji: "豈", learnedAt: 1 }] }), snap({ learned: [{ kanji: "豈", learnedAt: 2 }] })],
  ["Ohm sign normalises to omega", snap({ words: [w("Ω", "N1", 1, 0, { key: "Ω|N1", word: "Ω", meaning: "Ω" })] }), snap({})],
  ["sort by code point, non-BMP last", snap({ learned: [{ kanji: "𠮷", learnedAt: 1 }, { kanji: "ｶ", learnedAt: 1 }, { kanji: "", learnedAt: 1 }] }), snap({ learned: [{ kanji: "が", learnedAt: 1 }, { kanji: "か", learnedAt: 1 }, { kanji: "A", learnedAt: 1 }] })],
  ["decomposed key sorts at NFC position", snap({ words: [w("が", "N5", 1), w("き", "N5", 1)] }), snap({ words: [w("か", "N5", 1)] })],
  ["emoji and mixed scripts", snap({ words: [w("ねこ🐈", "N3", 2, 0, { romaji: "neko 🐈", meaning: "cat 😀 テスト" }), w("𠮷野家", "N2", 3, 0, { romaji: "yoshinoya", meaning: "𠮷" })] }), snap({ words: [w("ねこ🐈", "N3", 2, 0, { romaji: "neko 😀", meaning: "cat" })] })],
  ["emoji tie-break by code point (🐈 U+1F408 < 😀 U+1F600 > U+FFFD)", snap({ words: [w("x", "N5", 1, 0, { romaji: "😀" })] }), snap({ words: [w("x", "N5", 1, 0, { romaji: "�" })] })],
  ["fractional real timestamps", snap({ kanjiResetAt: 1731500000000.5, learned: [{ kanji: "日", learnedAt: 1731500000000.5 }, { kanji: "本", learnedAt: 1763072345123.456 }] }), snap({ learned: [{ kanji: "日", learnedAt: 1731500000000.25 }] })],
  ["halfwidth katakana is not NFKC-folded", snap({ words: [w("ｶﾞ", "N5", 1)] }), snap({ words: [w("ガ", "N5", 1)] })],
];

const cases: Case[] = handPicked.map(([name, a, b]) => ({ name, a, b, expected: merge(a, b) }));

const rng = mulberry32(SEED);
for (let i = 0; i < RANDOM_CASES; i++) {
  const size = 1 + int(rng, 8);
  const a = randomSnapshot(rng, size);
  // Sometimes b builds on a merged state, as a device answer from the server would.
  const b = rng() < 0.2 ? merge(randomSnapshot(rng, size), a) : randomSnapshot(rng, size);
  cases.push({ name: `random ${i + 1} (seed ${SEED})`, a, b, expected: merge(a, b) });
}

function escapeNonAscii(json: string): string {
  return json.replace(/[\u007f-￿]/g, (c) => "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0"));
}

const out = join(dirname(fileURLToPath(import.meta.url)), "fixtures", "merge-cases.json");
mkdirSync(dirname(out), { recursive: true });
// One case per line keeps diffs readable.
writeFileSync(out, escapeNonAscii("[\n" + cases.map((c) => JSON.stringify(c)).join(",\n") + "\n]") + "\n");
console.log(`wrote ${cases.length} cases to ${out}`);
