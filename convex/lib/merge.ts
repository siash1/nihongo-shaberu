// Progress snapshot merge: a state-based CRDT shared by the backend and the
// Swift client (`Models/ProgressSnapshot.swift` implements the same rules).
//
// PURE: this file has no imports, so Node can run it directly
// (`node --test tests/merge.test.ts`) and the Convex functions can bundle it.
// Only erasable TypeScript syntax is used (no enums, namespaces or parameter
// properties), which Node's built-in type stripping requires.
//
// `merge(a, b)` is commutative, associative and idempotent, so replicas that
// exchange snapshots in any order converge on the same state. Every string
// comparison uses Unicode code-point order (= UTF-8 byte order), and every
// string field is NFC-normalised first, so Swift and TypeScript agree exactly.
//
// The rules (mirrored by ProgressSnapshot.merge in the Swift app):
// - kanjiResetAt / wordsClearedAt: max.
// - learned: drop entries with learnedAt <= kanjiResetAt; per kanji keep the
//   MAX remaining learnedAt (a learning after a reset on any device survives).
// - scores: drop entries with recordedAt <= kanjiResetAt; per key keep the
//   Pareto frontier of (percent, recordedAt): an entry is dropped when another
//   entry of the same key has percent >= and recordedAt >= (a later or equal
//   time with an equal or better score). The best score of a key is the max
//   percent of its entries. One entry per key in normal use; several only after
//   concurrent recordings on different devices. This keeps "best score since
//   the last reset" exact whatever order resets and scores arrive in.
// - words: per key A = max addedAt, D = max deletedAt over all entries.
//   LIVE iff A > max(D, wordsClearedAt).
//   live      -> addedAt A, deletedAt (D > wordsClearedAt ? D : 0), text fields
//                from the entries with addedAt == A.
//   not live, D > wordsClearedAt -> tombstone: addedAt 0, deletedAt D, text
//                fields from the entries with deletedAt == D.
//   otherwise -> dropped (equivalently: max(A, D) <= wordsClearedAt).
//   Text ties are broken by the smallest (romaji, meaning, word, level).
// - Output arrays are sorted: learned by kanji, scores by key then recordedAt
//   ascending, words by key.

export type LearnedEntry = { kanji: string; learnedAt: number };

export type ScoreEntry = { key: string; percent: number; recordedAt: number };

export type WordEntry = {
  key: string;
  word: string;
  romaji: string;
  meaning: string;
  level: string;
  addedAt: number;
  deletedAt: number;
};

export type ProgressSnapshot = {
  kanjiResetAt: number;
  learned: LearnedEntry[];
  scores: ScoreEntry[];
  wordsClearedAt: number;
  words: WordEntry[];
};

export const JLPT_LEVELS: readonly string[] = ["N5", "N4", "N3", "N2", "N1"];

/**
 * Limits the server enforces on a client snapshot (`sanitizeSnapshot`).
 *
 * A device always sends its whole state, which is the account's state plus
 * its own unsynced edits, so these are looser than `ACCOUNT_LIMITS` (what the
 * server keeps); otherwise a device holding the account's full state plus one
 * new word could never sync again. Convex arrays hold at most 8192 values and
 * a request or return value at most 16 MiB, so `maxWords` and the byte budget
 * stay well under those.
 */
export const SNAPSHOT_LIMITS = {
  /** Code points of `learned[].kanji`. */
  maxKanjiLength: 8,
  /** Code points of every other string field. */
  maxStringLength: 300,
  /** Entries of `learned` (the course has 220 kanji). */
  maxLearned: 2000,
  /** Entries of `scores` (one per test key in normal use). */
  maxScores: 2000,
  /** Entries of `words`: live words and tombstones. */
  maxWords: 8000,
  /** UTF-8 bytes of all word text (key, word, romaji, meaning, level). */
  maxWordBytes: 4 * 1024 * 1024,
} as const;

/**
 * What the server keeps per account, checked on the merged state in
 * `progress:sync` (`enforceAccountLimits`). Tombstones of deleted words are
 * compacted away (`compactWords`) before the word limits are checked, so a
 * word bank only counts its live words in the long run.
 */
export const ACCOUNT_LIMITS = {
  /** Live (shown) words. The app stops saving new words at this count. */
  maxLiveWords: 5000,
  /** Above this many word entries the server compacts the tombstones away. */
  compactWordsAbove: 6000,
  /** UTF-8 bytes of all word text kept for one account. */
  maxWordBytes: 2 * 1024 * 1024,
  maxLearned: 2000,
  maxScores: 2000,
} as const;

/** Error codes of a rejected snapshot (`ConvexError({ code, message })`). */
export type SnapshotErrorCode = "INVALID_INPUT" | "WORD_BANK_FULL" | "PROGRESS_TOO_LARGE";

// ---------------------------------------------------------------------------
// Strings

/**
 * Compare two strings by Unicode code point (identical to UTF-8 byte order for
 * well-formed strings). Not `<` (UTF-16 units) and not `localeCompare`.
 */
export function compareCodePoints(a: string, b: string): number {
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    const ca = a.codePointAt(i) as number;
    const cb = b.codePointAt(j) as number;
    if (ca !== cb) {
      return ca < cb ? -1 : 1;
    }
    i += ca > 0xffff ? 2 : 1;
    j += cb > 0xffff ? 2 : 1;
  }
  if (i < a.length) return 1;
  if (j < b.length) return -1;
  return 0;
}

export function nfc(s: string): string {
  return s.normalize("NFC");
}

/** Number of Unicode code points (an emoji or a non-BMP kanji counts as 1). */
export function codePointLength(s: string): number {
  let n = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff && i + 1 < s.length) {
      const d = s.charCodeAt(i + 1);
      if (d >= 0xdc00 && d <= 0xdfff) i++;
    }
    n++;
  }
  return n;
}

/** UTF-8 length in bytes (a well-formed string; a lone surrogate counts 3). */
export function utf8Length(s: string): number {
  let n = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c < 0x80) n += 1;
    else if (c < 0x800) n += 2;
    else if (c >= 0xd800 && c <= 0xdbff && i + 1 < s.length) {
      const d = s.charCodeAt(i + 1);
      if (d >= 0xdc00 && d <= 0xdfff) {
        n += 4;
        i++;
      } else {
        n += 3;
      }
    } else n += 3;
  }
  return n;
}

/** UTF-8 bytes of the text of every word entry. */
export function wordTextBytes(words: WordEntry[]): number {
  let n = 0;
  for (const w of words) {
    n += utf8Length(w.key) + utf8Length(w.word) + utf8Length(w.romaji) +
      utf8Length(w.meaning) + utf8Length(w.level);
  }
  return n;
}

/** False when the string holds an unpaired UTF-16 surrogate (not valid Unicode). */
export function isWellFormed(s: string): boolean {
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff) {
      const d = i + 1 < s.length ? s.charCodeAt(i + 1) : 0;
      if (!(d >= 0xdc00 && d <= 0xdfff)) return false;
      i++;
    } else if (c >= 0xdc00 && c <= 0xdfff) {
      return false;
    }
  }
  return true;
}

// ---------------------------------------------------------------------------
// Snapshot helpers

export function emptySnapshot(): ProgressSnapshot {
  return {
    kanjiResetAt: 0,
    learned: [],
    scores: [],
    wordsClearedAt: 0,
    words: [],
  };
}

/** A word is LIVE (shown in the word bank) iff it was added after its last delete and the last clear. */
export function isLive(word: WordEntry, wordsClearedAt: number): boolean {
  return word.addedAt > Math.max(word.deletedAt, wordsClearedAt);
}

/** Best percent per score key (the max over its frontier entries). */
export function bestScores(snapshot: ProgressSnapshot): Map<string, number> {
  const best = new Map<string, number>();
  for (const s of snapshot.scores) {
    const cur = best.get(s.key);
    if (cur === undefined || s.percent > cur) best.set(s.key, s.percent);
  }
  return best;
}

/** The canonical form of one snapshot: `merge(s, empty)`. */
export function canonicalize(s: ProgressSnapshot): ProgressSnapshot {
  return merge(s, emptySnapshot());
}

/** Structural equality of two snapshots (field by field, arrays in order). */
export function snapshotsEqual(a: ProgressSnapshot, b: ProgressSnapshot): boolean {
  return encodeSnapshot(a) === encodeSnapshot(b);
}

/** Deterministic JSON with a fixed key order. Equal canonical states encode identically. */
export function encodeSnapshot(s: ProgressSnapshot): string {
  return JSON.stringify({
    kanjiResetAt: s.kanjiResetAt,
    learned: s.learned.map((e) => ({ kanji: e.kanji, learnedAt: e.learnedAt })),
    scores: s.scores.map((e) => ({
      key: e.key,
      percent: e.percent,
      recordedAt: e.recordedAt,
    })),
    wordsClearedAt: s.wordsClearedAt,
    words: s.words.map((e) => ({
      key: e.key,
      word: e.word,
      romaji: e.romaji,
      meaning: e.meaning,
      level: e.level,
      addedAt: e.addedAt,
      deletedAt: e.deletedAt,
    })),
  });
}

// ---------------------------------------------------------------------------
// Merge

export function merge(a: ProgressSnapshot, b: ProgressSnapshot): ProgressSnapshot {
  // Timestamps are >= 0 (the server clamps them; 0 means "never").
  const kanjiResetAt = Math.max(a.kanjiResetAt, b.kanjiResetAt);
  const wordsClearedAt = Math.max(a.wordsClearedAt, b.wordsClearedAt);
  return {
    kanjiResetAt,
    learned: mergeLearned(a.learned.concat(b.learned), kanjiResetAt),
    scores: mergeScores(a.scores.concat(b.scores), kanjiResetAt),
    wordsClearedAt,
    words: mergeWords(a.words.concat(b.words), wordsClearedAt),
  };
}

function mergeLearned(entries: LearnedEntry[], resetAt: number): LearnedEntry[] {
  const latest = new Map<string, number>();
  for (const e of entries) {
    if (!(e.learnedAt > resetAt)) continue;
    const kanji = nfc(e.kanji);
    const cur = latest.get(kanji);
    if (cur === undefined || e.learnedAt > cur) latest.set(kanji, e.learnedAt);
  }
  const out: LearnedEntry[] = [];
  for (const [kanji, learnedAt] of latest) out.push({ kanji, learnedAt });
  out.sort((x, y) => compareCodePoints(x.kanji, y.kanji));
  return out;
}

function mergeScores(entries: ScoreEntry[], resetAt: number): ScoreEntry[] {
  const byKey = new Map<string, ScoreEntry[]>();
  for (const e of entries) {
    if (!(e.recordedAt > resetAt)) continue;
    const key = nfc(e.key);
    let list = byKey.get(key);
    if (list === undefined) {
      list = [];
      byKey.set(key, list);
    }
    list.push({ key, percent: e.percent, recordedAt: e.recordedAt });
  }
  const out: ScoreEntry[] = [];
  for (const list of byKey.values()) {
    // Latest first; at equal times the best first. Walking that order, an
    // entry is on the frontier iff it beats every entry recorded at the same
    // time or later.
    list.sort((x, y) =>
      x.recordedAt !== y.recordedAt
        ? y.recordedAt - x.recordedAt
        : y.percent - x.percent,
    );
    let bestSoFar = -Infinity;
    for (const e of list) {
      if (e.percent > bestSoFar) {
        out.push(e);
        bestSoFar = e.percent;
      }
    }
  }
  out.sort((x, y) => {
    const c = compareCodePoints(x.key, y.key);
    return c !== 0 ? c : x.recordedAt - y.recordedAt;
  });
  return out;
}

function compareWordText(x: WordEntry, y: WordEntry): number {
  return (
    compareCodePoints(x.romaji, y.romaji) ||
    compareCodePoints(x.meaning, y.meaning) ||
    compareCodePoints(x.word, y.word) ||
    compareCodePoints(x.level, y.level)
  );
}

function mergeWords(entries: WordEntry[], clearedAt: number): WordEntry[] {
  const byKey = new Map<string, WordEntry[]>();
  for (const e of entries) {
    const key = nfc(e.key);
    let list = byKey.get(key);
    if (list === undefined) {
      list = [];
      byKey.set(key, list);
    }
    list.push({
      key,
      word: nfc(e.word),
      romaji: nfc(e.romaji),
      meaning: nfc(e.meaning),
      level: nfc(e.level),
      addedAt: e.addedAt,
      deletedAt: e.deletedAt,
    });
  }
  const out: WordEntry[] = [];
  for (const [key, list] of byKey) {
    let addedAt = 0;
    let deletedAt = 0;
    for (const e of list) {
      if (e.addedAt > addedAt) addedAt = e.addedAt;
      if (e.deletedAt > deletedAt) deletedAt = e.deletedAt;
    }
    const live = addedAt > Math.max(deletedAt, clearedAt);
    if (!live && !(deletedAt > clearedAt)) continue; // garbage-collected by the clear
    // Text comes from the add that makes the word live, or, for a tombstone,
    // from the delete that keeps it.
    let text: WordEntry | undefined;
    for (const e of list) {
      if (live ? e.addedAt !== addedAt : e.deletedAt !== deletedAt) continue;
      if (text === undefined || compareWordText(e, text) < 0) text = e;
    }
    const t = text as WordEntry;
    out.push({
      key,
      word: t.word,
      romaji: t.romaji,
      meaning: t.meaning,
      level: t.level,
      addedAt: live ? addedAt : 0,
      deletedAt: deletedAt > clearedAt ? deletedAt : 0,
    });
  }
  out.sort((x, y) => compareCodePoints(x.key, y.key));
  return out;
}

// ---------------------------------------------------------------------------
// Server-side sanitising of a client snapshot (before merging)

export type SanitizeResult =
  | { ok: true; snapshot: ProgressSnapshot }
  | { ok: false; code: SnapshotErrorCode; message: string };

/**
 * Validate a client snapshot and clamp every timestamp to [0, now], so a
 * device with a wrong clock cannot poison resets. Strings are NFC-normalised.
 * Returns `{ ok: false, code, message }` for input the server rejects (the
 * caller throws `ConvexError({ code, message })`): `WORD_BANK_FULL` when the
 * word list is over its size limits, `INVALID_INPUT` otherwise.
 */
export function sanitizeSnapshot(input: ProgressSnapshot, now: number): SanitizeResult {
  const { maxKanjiLength, maxStringLength } = SNAPSHOT_LIMITS;
  const fail = (message: string): SanitizeResult => ({ ok: false, code: "INVALID_INPUT", message });

  const timestamp = (value: number, field: string): number | string => {
    if (typeof value !== "number" || Number.isNaN(value)) {
      return `${field} must be a number`;
    }
    if (!Number.isFinite(value)) {
      return `${field} must be a finite number`;
    }
    return Math.min(Math.max(value, 0), now);
  };
  const text = (value: string, field: string, maxLength: number): string | null => {
    if (typeof value !== "string") return `${field} must be a string`;
    if (!isWellFormed(value)) return `${field} is not valid Unicode`;
    if (codePointLength(nfc(value)) > maxLength) {
      return `${field} is longer than ${maxLength} characters`;
    }
    return null;
  };

  const maxEntries = {
    learned: SNAPSHOT_LIMITS.maxLearned,
    scores: SNAPSHOT_LIMITS.maxScores,
    words: SNAPSHOT_LIMITS.maxWords,
  };
  for (const name of ["learned", "scores", "words"] as const) {
    if (!Array.isArray(input[name])) return fail(`${name} must be an array`);
    if (input[name].length > maxEntries[name]) {
      const message = `${name} has more than ${maxEntries[name]} entries`;
      return name === "words" ? { ok: false, code: "WORD_BANK_FULL", message } : fail(message);
    }
  }

  const kanjiResetAt = timestamp(input.kanjiResetAt, "kanjiResetAt");
  if (typeof kanjiResetAt === "string") return fail(kanjiResetAt);
  const wordsClearedAt = timestamp(input.wordsClearedAt, "wordsClearedAt");
  if (typeof wordsClearedAt === "string") return fail(wordsClearedAt);

  const learned: LearnedEntry[] = [];
  for (let i = 0; i < input.learned.length; i++) {
    const e = input.learned[i];
    const where = `learned[${i}]`;
    const err = text(e.kanji, `${where}.kanji`, maxKanjiLength);
    if (err !== null) return fail(err);
    const learnedAt = timestamp(e.learnedAt, `${where}.learnedAt`);
    if (typeof learnedAt === "string") return fail(learnedAt);
    learned.push({ kanji: nfc(e.kanji), learnedAt });
  }

  const scores: ScoreEntry[] = [];
  for (let i = 0; i < input.scores.length; i++) {
    const e = input.scores[i];
    const where = `scores[${i}]`;
    const err = text(e.key, `${where}.key`, maxStringLength);
    if (err !== null) return fail(err);
    if (!Number.isInteger(e.percent) || e.percent < 0 || e.percent > 100) {
      return fail(`${where}.percent must be an integer from 0 to 100`);
    }
    const recordedAt = timestamp(e.recordedAt, `${where}.recordedAt`);
    if (typeof recordedAt === "string") return fail(recordedAt);
    // `+ 0` turns -0 into 0.
    scores.push({ key: nfc(e.key), percent: e.percent + 0, recordedAt });
  }

  const words: WordEntry[] = [];
  for (let i = 0; i < input.words.length; i++) {
    const e = input.words[i];
    const where = `words[${i}]`;
    for (const field of ["key", "word", "romaji", "meaning", "level"] as const) {
      const err = text(e[field], `${where}.${field}`, maxStringLength);
      if (err !== null) return fail(err);
    }
    if (!JLPT_LEVELS.includes(nfc(e.level))) {
      return fail(`${where}.level must be one of ${JLPT_LEVELS.join(", ")}`);
    }
    const addedAt = timestamp(e.addedAt, `${where}.addedAt`);
    if (typeof addedAt === "string") return fail(addedAt);
    const deletedAt = timestamp(e.deletedAt, `${where}.deletedAt`);
    if (typeof deletedAt === "string") return fail(deletedAt);
    words.push({
      key: nfc(e.key),
      word: nfc(e.word),
      romaji: nfc(e.romaji),
      meaning: nfc(e.meaning),
      level: nfc(e.level),
      addedAt,
      deletedAt,
    });
  }

  if (wordTextBytes(words) > SNAPSHOT_LIMITS.maxWordBytes) {
    return {
      ok: false,
      code: "WORD_BANK_FULL",
      message: `words hold more than ${SNAPSHOT_LIMITS.maxWordBytes} bytes of text`,
    };
  }

  return {
    ok: true,
    snapshot: { kanjiResetAt, learned, scores, wordsClearedAt, words },
  };
}

// ---------------------------------------------------------------------------
// Per-account limits (server only, on the merged state)

/**
 * Removes every tombstone from a canonical snapshot, keeping every live word.
 *
 * Equivalent to a Clear All at T (the latest delete) followed by adding the
 * live words again just after it: `wordsClearedAt` becomes T and each live
 * word added at or before T gets a new `addedAt` of T + i/256 ms (i = 1, 2, …
 * in its old order; 1/256 is exact for any timestamp below 2^44 ms, so every
 * step is a distinct, strictly larger double, and 5000 words span 20 ms). Every replica that merges the result converges on it (it is an
 * ordinary state, `merge` is unchanged and needs no clock). Like any Clear All,
 * a device's unsynced edits stamped at or before T are dropped when that
 * device syncs; the server only compacts a bank above
 * `ACCOUNT_LIMITS.compactWordsAbove` entries, so that is rare.
 *
 * Pure: no clock. Returns the input unchanged when there is no tombstone.
 */
export function compactWords(snapshot: ProgressSnapshot): ProgressSnapshot {
  const s = canonicalize(snapshot);
  const live = s.words.filter((w) => isLive(w, s.wordsClearedAt));
  if (live.length === s.words.length) return s;
  let clearedAt = s.wordsClearedAt;
  for (const w of s.words) {
    if (!isLive(w, s.wordsClearedAt) && w.deletedAt > clearedAt) clearedAt = w.deletedAt;
  }
  // Oldest first, as the word bank shows them.
  const ordered = live.slice().sort((x, y) =>
    x.addedAt !== y.addedAt ? x.addedAt - y.addedAt : compareCodePoints(x.key, y.key),
  );
  let i = 0;
  const words = ordered.map((w) => {
    if (w.addedAt > clearedAt) return w;
    i += 1;
    return { ...w, addedAt: clearedAt + i / 256, deletedAt: 0 };
  });
  return canonicalize({ ...s, wordsClearedAt: clearedAt, words });
}

export type AccountLimitResult =
  | { ok: true; snapshot: ProgressSnapshot }
  | { ok: false; code: SnapshotErrorCode; message: string };

/**
 * Keeps a merged account state within `ACCOUNT_LIMITS`: compacts the word
 * tombstones when the bank is large, then rejects a state that is still over
 * a limit (`WORD_BANK_FULL` for words, `PROGRESS_TOO_LARGE` otherwise). The
 * server then never stores or returns more than a device may send back.
 */
export function enforceAccountLimits(merged: ProgressSnapshot): AccountLimitResult {
  let s = merged;
  if (
    s.words.length > ACCOUNT_LIMITS.compactWordsAbove ||
    wordTextBytes(s.words) > ACCOUNT_LIMITS.maxWordBytes
  ) {
    s = compactWords(s);
  }
  const liveWords = s.words.filter((w) => isLive(w, s.wordsClearedAt)).length;
  if (liveWords > ACCOUNT_LIMITS.maxLiveWords) {
    return {
      ok: false,
      code: "WORD_BANK_FULL",
      message: `the word bank has more than ${ACCOUNT_LIMITS.maxLiveWords} words`,
    };
  }
  if (wordTextBytes(s.words) > ACCOUNT_LIMITS.maxWordBytes) {
    return {
      ok: false,
      code: "WORD_BANK_FULL",
      message: `the word bank holds more than ${ACCOUNT_LIMITS.maxWordBytes} bytes of text`,
    };
  }
  if (s.learned.length > ACCOUNT_LIMITS.maxLearned || s.scores.length > ACCOUNT_LIMITS.maxScores) {
    return { ok: false, code: "PROGRESS_TOO_LARGE", message: "too many learned kanji or scores" };
  }
  return { ok: true, snapshot: s };
}
