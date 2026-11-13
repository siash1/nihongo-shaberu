import { ConvexError } from "convex/values";
import { getAuthUserId } from "@convex-dev/auth/server";
import type { QueryCtx } from "../_generated/server";
import type { Id } from "../_generated/dataModel";

/**
 * The signed-in user's id, or a `ConvexError({ code: "UNAUTHENTICATED" })`
 * when the caller has no token or its session was signed out, revoked or
 * expired.
 */
export async function requireUserId(
  ctx: Pick<QueryCtx, "auth" | "runQuery">,
): Promise<Id<"users">> {
  const userId = await getAuthUserId(ctx);
  if (userId === null) {
    throw new ConvexError({
      code: "UNAUTHENTICATED",
      message: "Sign in to sync your progress.",
    });
  }
  return userId;
}
