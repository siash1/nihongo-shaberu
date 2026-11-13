import { ConvexError, v } from "convex/values";
import { mutation, query } from "./_generated/server";
import type { Doc } from "./_generated/dataModel";
import { requireUserId } from "./lib/session";
import { limitSync } from "./lib/rateLimits";
import {
  enforceAccountLimits,
  merge,
  sanitizeSnapshot,
  type LearnedEntry,
  type ProgressSnapshot,
  type ScoreEntry,
  type WordEntry,
} from "./lib/merge";

/** Wire format of a progress snapshot (see convex/lib/merge.ts). */
const vSnapshot = v.object({
  kanjiResetAt: v.number(),
  learned: v.array(v.object({ kanji: v.string(), learnedAt: v.number() })),
  scores: v.array(
    v.object({ key: v.string(), percent: v.number(), recordedAt: v.number() }),
  ),
  wordsClearedAt: v.number(),
  words: v.array(
    v.object({
      key: v.string(),
      word: v.string(),
      romaji: v.string(),
      meaning: v.string(),
      level: v.string(),
      addedAt: v.number(),
      deletedAt: v.number(),
    }),
  ),
});

/**
 * Merge the device's snapshot into the user's synced progress and return the
 * merged state. The device merges the result into its local stores (its data
 * may have changed meanwhile) and syncs again when that differs.
 *
 * `version` increases only when this call changed the stored data.
 * `serverTime` is the clock every client timestamp was clamped to.
 *
 * Errors (`ConvexError({ code, message })`): `UNAUTHENTICATED`;
 * `RATE_LIMITED` (also `retryAfterMs`); `INVALID_INPUT` for a malformed
 * snapshot; `WORD_BANK_FULL` when the word bank is over its limits, before or
 * after merging (see `ACCOUNT_LIMITS`); `PROGRESS_TOO_LARGE` for other limits.
 * The server compacts word tombstones of a large bank, so the state it stores
 * and returns always fits what a device may send back.
 */
export const sync = mutation({
  args: { snapshot: vSnapshot },
  returns: v.object({
    snapshot: vSnapshot,
    version: v.number(),
    serverTime: v.number(),
  }),
  handler: async (ctx, args) => {
    const userId = await requireUserId(ctx);
    await limitSync(ctx, userId);
    const now = Date.now();

    const sanitized = sanitizeSnapshot(args.snapshot, now);
    if (!sanitized.ok) {
      throw new ConvexError({ code: sanitized.code, message: sanitized.message });
    }

    const state = await ctx.db
      .query("syncStates")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .unique();
    const learnedRows = await ctx.db
      .query("learnedKanji")
      .withIndex("by_userId_kanji", (q) => q.eq("userId", userId))
      .collect();
    const scoreRows = await ctx.db
      .query("kanjiScores")
      .withIndex("by_userId_key", (q) => q.eq("userId", userId))
      .collect();
    const wordRows = await ctx.db
      .query("savedWords")
      .withIndex("by_userId_key", (q) => q.eq("userId", userId))
      .collect();

    const server: ProgressSnapshot = {
      kanjiResetAt: state?.kanjiResetAt ?? 0,
      learned: learnedRows.map(toLearned),
      scores: scoreRows.map(toScore),
      wordsClearedAt: state?.wordsClearedAt ?? 0,
      words: wordRows.map(toWord),
    };
    const limited = enforceAccountLimits(merge(server, sanitized.snapshot));
    if (!limited.ok) {
      throw new ConvexError({ code: limited.code, message: limited.message });
    }
    const merged = limited.snapshot;

    let changed =
      merged.kanjiResetAt !== server.kanjiResetAt ||
      merged.wordsClearedAt !== server.wordsClearedAt;

    const learnedChanged = await writeDiff(learnedRows, merged.learned, {
      rowKey: (r) => r.kanji,
      entryKey: (e) => e.kanji,
      same: (r, e) => r.learnedAt === e.learnedAt,
      insert: (e) => ctx.db.insert("learnedKanji", { userId, ...e }),
      patch: (r, e) => ctx.db.patch("learnedKanji", r._id, { ...e }),
      remove: (r) => ctx.db.delete("learnedKanji", r._id),
    });
    // A key can hold several frontier entries, one per recordedAt.
    const scoresChanged = await writeDiff(scoreRows, merged.scores, {
      rowKey: (r) => `${r.key}\u0000${r.recordedAt}`,
      entryKey: (e) => `${e.key}\u0000${e.recordedAt}`,
      same: (r, e) => r.percent === e.percent,
      insert: (e) => ctx.db.insert("kanjiScores", { userId, ...e }),
      patch: (r, e) => ctx.db.patch("kanjiScores", r._id, { ...e }),
      remove: (r) => ctx.db.delete("kanjiScores", r._id),
    });
    const wordsChanged = await writeDiff(wordRows, merged.words, {
      rowKey: (r) => r.key,
      entryKey: (e) => e.key,
      same: (r, e) =>
        r.word === e.word &&
        r.romaji === e.romaji &&
        r.meaning === e.meaning &&
        r.level === e.level &&
        r.addedAt === e.addedAt &&
        r.deletedAt === e.deletedAt,
      insert: (e) => ctx.db.insert("savedWords", { userId, ...e }),
      patch: (r, e) => ctx.db.patch("savedWords", r._id, { ...e }),
      remove: (r) => ctx.db.delete("savedWords", r._id),
    });
    changed = changed || learnedChanged || scoresChanged || wordsChanged;

    let version = state?.version ?? 0;
    if (changed) {
      version += 1;
      const fields = {
        kanjiResetAt: merged.kanjiResetAt,
        wordsClearedAt: merged.wordsClearedAt,
        version,
        updatedAt: now,
      };
      if (state === null) {
        await ctx.db.insert("syncStates", { userId, ...fields });
      } else {
        await ctx.db.patch("syncStates", state._id, fields);
      }
    }

    return { snapshot: merged, version, serverTime: now };
  },
});

/** The user's sync version (0 when the user never synced data). */
export const status = query({
  args: {},
  returns: v.object({ version: v.number() }),
  handler: async (ctx) => {
    const userId = await requireUserId(ctx);
    const state = await ctx.db
      .query("syncStates")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .unique();
    return { version: state?.version ?? 0 };
  },
});

// ---------------------------------------------------------------------------

function toLearned(r: Doc<"learnedKanji">): LearnedEntry {
  return { kanji: r.kanji, learnedAt: r.learnedAt };
}

function toScore(r: Doc<"kanjiScores">): ScoreEntry {
  return { key: r.key, percent: r.percent, recordedAt: r.recordedAt };
}

function toWord(r: Doc<"savedWords">): WordEntry {
  return {
    key: r.key,
    word: r.word,
    romaji: r.romaji,
    meaning: r.meaning,
    level: r.level,
    addedAt: r.addedAt,
    deletedAt: r.deletedAt,
  };
}

/**
 * Make the stored rows hold exactly `entries`: patch rows whose entry changed,
 * insert new entries, delete rows the merge dropped (and duplicate rows).
 * Returns whether anything was written.
 */
async function writeDiff<Row, Entry>(
  rows: Row[],
  entries: Entry[],
  ops: {
    rowKey: (row: Row) => string;
    entryKey: (entry: Entry) => string;
    same: (row: Row, entry: Entry) => boolean;
    insert: (entry: Entry) => Promise<unknown>;
    patch: (row: Row, entry: Entry) => Promise<void>;
    remove: (row: Row) => Promise<void>;
  },
): Promise<boolean> {
  let changed = false;
  const existing = new Map<string, Row>();
  for (const row of rows) {
    const key = ops.rowKey(row);
    if (existing.has(key)) {
      await ops.remove(row);
      changed = true;
    } else {
      existing.set(key, row);
    }
  }
  for (const entry of entries) {
    const key = ops.entryKey(entry);
    const row = existing.get(key);
    if (row === undefined) {
      await ops.insert(entry);
      changed = true;
    } else {
      existing.delete(key);
      if (!ops.same(row, entry)) {
        await ops.patch(row, entry);
        changed = true;
      }
    }
  }
  for (const row of existing.values()) {
    await ops.remove(row);
    changed = true;
  }
  return changed;
}
