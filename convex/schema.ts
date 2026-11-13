import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // App users. Usernames, password hashes and sessions live in the Convex Auth
  // components (authUsername, authPassword, auth); they key them by this id.
  users: defineTable({
    createdAt: v.number(),
  }),

  // One row per user once progress has been synced. `version` increases each
  // time a sync changes the user's data (devices poll it via progress:status).
  syncStates: defineTable({
    userId: v.id("users"),
    kanjiResetAt: v.number(),
    wordsClearedAt: v.number(),
    version: v.number(),
    updatedAt: v.number(),
  }).index("by_userId", ["userId"]),

  learnedKanji: defineTable({
    userId: v.id("users"),
    kanji: v.string(),
    learnedAt: v.number(),
  }).index("by_userId_kanji", ["userId", "kanji"]),

  // Score frontier: usually one row per key, see convex/lib/merge.ts.
  kanjiScores: defineTable({
    userId: v.id("users"),
    key: v.string(),
    percent: v.number(),
    recordedAt: v.number(),
  }).index("by_userId_key", ["userId", "key"]),

  // Word bank entries, live words and tombstones (see isLive in lib/merge.ts).
  savedWords: defineTable({
    userId: v.id("users"),
    key: v.string(),
    word: v.string(),
    romaji: v.string(),
    meaning: v.string(),
    level: v.string(),
    addedAt: v.number(),
    deletedAt: v.number(),
  }).index("by_userId_key", ["userId", "key"]),
});
