import { ConvexError } from "convex/values";
import { HOUR, MINUTE, RateLimiter } from "@convex-dev/rate-limiter";
import { components } from "../_generated/api";
import type { MutationCtx } from "../_generated/server";

// Convex functions see the deployment's environment variables (set with
// `npx convex env set NAME value`); the app has no Node types installed.
declare const process: { env: Record<string, string | undefined> };

/**
 * Application rate limits (the `@convex-dev/rate-limiter` component, mounted
 * in convex.config.ts). The deployment URL is public, so anyone can call the
 * functions: these keep one caller from filling the database or using up its
 * bandwidth.
 *
 * - `sync`: per account, bursts of 30 `progress:sync` calls, then one a second.
 *   The app debounces edits by 2 s and polls a cheap query, so it stays far
 *   below this.
 * - Sign-ups: per IP address (`SIGNUP_LIMIT_PER_IP`, default 10 an hour, in
 *   bursts of up to 10) and for the whole deployment (`SIGNUP_LIMIT_GLOBAL`,
 *   default 200 an hour). Raise them on a local test backend, which signs up
 *   many accounts: `npx convex env set SIGNUP_LIMIT_PER_IP 100000`.
 *
 * Password checks are limited separately by Convex Auth (per account: 5, then
 * one a minute). Anyone who knows a username can keep that bucket empty and so
 * stop new sign-ins to it (signed-in devices keep working); with no email there
 * is no other way in. That risk is accepted.
 */
const rateLimiter = new RateLimiter(components.rateLimiter, {
  sync: { kind: "token bucket", rate: 60, period: MINUTE, capacity: 30 },
});

function envLimit(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

/** Throws `ConvexError({ code: "RATE_LIMITED", message, retryAfterMs })`. */
function rateLimited(message: string, retryAfterMs: number): never {
  throw new ConvexError({ code: "RATE_LIMITED", message, retryAfterMs: Math.ceil(retryAfterMs) });
}

export async function limitSync(ctx: MutationCtx, userId: string): Promise<void> {
  const status = await rateLimiter.limit(ctx, "sync", { key: userId });
  if (!status.ok) rateLimited("Too many syncs. Try again in a moment.", status.retryAfter);
}

export async function limitSignUp(ctx: MutationCtx): Promise<void> {
  const { ip } = await ctx.meta.getRequestMetadata();
  const perIp = envLimit("SIGNUP_LIMIT_PER_IP", 10);
  const perIpStatus = await rateLimiter.limit(ctx, "signUpPerIp", {
    key: ip ?? "unknown",
    config: { kind: "token bucket", rate: perIp, period: HOUR, capacity: perIp },
  });
  if (!perIpStatus.ok) {
    rateLimited("Too many new accounts from this network. Try again later.", perIpStatus.retryAfter);
  }
  const global = envLimit("SIGNUP_LIMIT_GLOBAL", 200);
  const globalStatus = await rateLimiter.limit(ctx, "signUpGlobal", {
    config: { kind: "token bucket", rate: global, period: HOUR, capacity: Math.max(1, Math.ceil(global / 4)) },
  });
  if (!globalStatus.ok) {
    rateLimited("Too many new accounts right now. Try again later.", globalStatus.retryAfter);
  }
}
