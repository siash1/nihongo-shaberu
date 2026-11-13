import { v } from "convex/values";
import { mutation } from "./_generated/server";
import { components } from "./_generated/api";
import { requireUserId } from "./lib/session";

/**
 * Delete the signed-in user's account: synced progress, username, sessions
 * and the user document. The username can be signed up again afterwards.
 *
 * The password component has no delete API, so its row for this user cannot
 * be removed; instead its hash is overwritten with the hash of a random secret
 * that is never stored, so the real password hash does not outlive the
 * account. (Backups taken before the deletion still hold the old hash.)
 */
export const deleteAccount = mutation({
  args: {},
  returns: v.null(),
  handler: async (ctx) => {
    const userId = await requireUserId(ctx);

    // Destroy the password hash (only ever for the caller's own user id).
    const bytes = crypto.getRandomValues(new Uint8Array(32));
    const secret = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
    const scrubbed = await ctx.runMutation(
      components.authPassword.public._internal_dangerous_setPassword,
      { userId, password: secret, minimumLength: 10 },
    );
    if (!scrubbed.success) {
      // Throwing rolls the whole deletion back rather than leave the hash.
      throw new Error("Could not overwrite the password hash: " + scrubbed.userError.error);
    }

    for (const row of await ctx.db
      .query("syncStates")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .collect()) {
      await ctx.db.delete("syncStates", row._id);
    }
    for (const row of await ctx.db
      .query("learnedKanji")
      .withIndex("by_userId_kanji", (q) => q.eq("userId", userId))
      .collect()) {
      await ctx.db.delete("learnedKanji", row._id);
    }
    for (const row of await ctx.db
      .query("kanjiScores")
      .withIndex("by_userId_key", (q) => q.eq("userId", userId))
      .collect()) {
      await ctx.db.delete("kanjiScores", row._id);
    }
    for (const row of await ctx.db
      .query("savedWords")
      .withIndex("by_userId_key", (q) => q.eq("userId", userId))
      .collect()) {
      await ctx.db.delete("savedWords", row._id);
    }

    await ctx.runMutation(components.authUsername.public.deleteUsername, {
      userId,
    });

    const sessions = await ctx.runQuery(components.auth.public.listSessions, {
      userId,
    });
    if (sessions.length > 0) {
      await ctx.runMutation(components.auth.public.revokeSessions, {
        sessionIds: sessions.map((s) => s.sessionId),
      });
    }

    if ((await ctx.db.get("users", userId)) !== null) {
      await ctx.db.delete("users", userId);
    }
    return null;
  },
});
