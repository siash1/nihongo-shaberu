import { v } from "convex/values";
import { internalMutation, query } from "./_generated/server";
import { components } from "./_generated/api";
import { getAuthUserId } from "@convex-dev/auth/server";
import { limitSignUp } from "./lib/rateLimits";

/**
 * Convex Auth's `createUser` callback: runs once per new account (sign-up),
 * inside the sign-up mutation, after the username and password were accepted.
 * Sign-ups are rate limited here: throwing rolls the whole sign-up back, and
 * the client gets `ConvexError({ code: "RATE_LIMITED", retryAfterMs })`.
 */
export const createUser = internalMutation({
  args: {
    method: v.object({
      name: v.literal("usernamePassword"),
      profile: v.object({}),
    }),
  },
  returns: v.id("users"),
  handler: async (ctx) => {
    await limitSignUp(ctx);
    return await ctx.db.insert("users", { createdAt: Date.now() });
  },
});

/** The signed-in user's username, or null when not signed in. */
export const me = query({
  args: {},
  returns: v.union(v.object({ username: v.string() }), v.null()),
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (userId === null) return null;
    const username = await ctx.runQuery(
      components.authUsername.public.getUsername,
      { userId },
    );
    return username === null ? null : { username };
  },
});
