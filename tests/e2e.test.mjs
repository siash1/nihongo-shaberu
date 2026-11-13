// End-to-end test of the backend over the public HTTP API, the way the Swift
// client calls it (plain fetch, `format: "json"`).
//
// Needs a running deployment:
//   CONVEX_AGENT_MODE=anonymous npx convex dev        (local backend, http://127.0.0.1:3210)
//   BASE_URL=http://127.0.0.1:3210 npm run test:e2e
//
// Every run signs up fresh random usernames, so it can run repeatedly against
// the same deployment. Sign-ups are rate limited per IP address (10 an hour by
// default, see convex/lib/rateLimits.ts); raise the limits on a local test
// backend first:
//   npx convex env set SIGNUP_LIMIT_PER_IP 100000
//   npx convex env set SIGNUP_LIMIT_GLOBAL 100000

import { test, describe, before } from "node:test";
import assert from "node:assert/strict";
import { merge, emptySnapshot, encodeSnapshot, isLive, ACCOUNT_LIMITS, SNAPSHOT_LIMITS } from "../convex/lib/merge.ts";

const BASE_URL = (process.env.BASE_URL ?? "http://127.0.0.1:3210").replace(/\/+$/, "");
const RUN = Math.random().toString(36).slice(2, 8);
const PASSWORD = "kana flashcards 2026";

let counter = 0;
function uniqueUsername(label) {
  counter += 1;
  return `e2e-${RUN}-${label}-${counter}`;
}

/** POST /api/{kind} and return the raw HTTP status and parsed body. */
async function raw(kind, path, args, token) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(`${BASE_URL}/api/${kind}`, {
    method: "POST",
    headers,
    body: JSON.stringify({ path, args, format: "json" }),
  });
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }
  return { http: response.status, body };
}

class CallError extends Error {
  constructor(http, body) {
    super(`HTTP ${http}: ${typeof body === "string" ? body : JSON.stringify(body)}`);
    this.http = http;
    this.body = body;
    this.errorData = typeof body === "object" && body !== null ? body.errorData : undefined;
  }
}

/** Call a function; return its value or throw CallError (function error or rejected request). */
async function call(kind, path, args, token) {
  const { http, body } = await raw(kind, path, args, token);
  if ((http === 200 || http === 560) && body?.status === "success") return body.value;
  throw new CallError(http, body);
}
const query = (path, args, token) => call("query", path, args, token);
const mutation = (path, args, token) => call("mutation", path, args, token);

async function rejectsWithCode(promise, code) {
  await assert.rejects(promise, (error) => {
    assert.ok(error instanceof CallError, String(error));
    assert.equal(error.errorData?.code, code, error.message);
    return true;
  });
}

function decodeJwt(token) {
  const [header, payload] = token.split(".").slice(0, 2).map((part) =>
    JSON.parse(Buffer.from(part, "base64url").toString("utf8")),
  );
  return { header, payload };
}

async function signUp(username, password = PASSWORD) {
  return await mutation("auth:signUpWithUsernamePassword", { username, password });
}
async function signIn(username, password = PASSWORD) {
  return await mutation("auth:signInWithUsernamePassword", { username, password });
}
async function newAccount(label) {
  const username = uniqueUsername(label);
  const result = await signUp(username);
  assert.equal(result.status, "complete", JSON.stringify(result));
  return { username, tokens: result.tokens };
}

const sync = (snapshot, token) => mutation("progress:sync", { snapshot }, token);
const status = (token) => query("progress:status", {}, token);

function sameSnapshot(actual, expected, message) {
  assert.equal(encodeSnapshot(actual), encodeSnapshot(expected), message);
}

function word(w, level, addedAt, deletedAt = 0, meaning = `${w} meaning`) {
  return { key: `${w}|${level}`, word: w, romaji: `${w}-romaji`, meaning, level, addedAt, deletedAt };
}

// ---------------------------------------------------------------------------

before(async () => {
  try {
    await fetch(`${BASE_URL}/version`);
  } catch (error) {
    throw new Error(
      `No Convex deployment at ${BASE_URL}. Start one with ` +
        "`CONVEX_AGENT_MODE=anonymous npx convex dev` or set BASE_URL. (" + error + ")",
    );
  }
});

describe("accounts", () => {
  test("sign up returns a token bundle with a one-hour JWT", async () => {
    const username = uniqueUsername("Signup");
    const startedAt = Date.now();
    const result = await signUp(username);
    assert.equal(result.status, "complete");
    const { tokens } = result;
    assert.deepEqual(Object.keys(tokens).sort(), ["accessToken", "refreshToken", "refreshTokenExpiresAt", "userId"]);
    assert.equal(typeof tokens.refreshToken, "string");
    assert.equal(typeof tokens.userId, "string");
    // Refresh tokens expire after 90 days of inactivity.
    const ninetyDays = 90 * 24 * 3600 * 1000;
    assert.ok(Math.abs(tokens.refreshTokenExpiresAt - (startedAt + ninetyDays)) < 60_000, String(tokens.refreshTokenExpiresAt));
    const { header, payload } = decodeJwt(tokens.accessToken);
    assert.equal(header.alg, "ES256");
    assert.equal(payload.aud, "convex-auth");
    assert.equal(payload.exp - payload.iat, 3600);
    assert.ok(payload.iss.endsWith("/components/auth"), payload.iss);

    const me = await query("users:me", {}, tokens.accessToken);
    assert.deepEqual(me, { username });
  });

  test("duplicate sign-up is USERNAME_TAKEN, case-insensitively", async () => {
    const { username } = await newAccount("Dup");
    const again = await signUp(username);
    assert.deepEqual(again, { status: "error", userError: { error: "USERNAME_TAKEN" } });
    const upper = await signUp(username.toUpperCase());
    assert.deepEqual(upper, { status: "error", userError: { error: "USERNAME_TAKEN" } });
  });

  test("sign-in errors: INVALID_CREDENTIALS and USER_NOT_FOUND", async () => {
    const { username } = await newAccount("creds");
    assert.deepEqual(await signIn(username, "not the right password"), {
      status: "error",
      userError: { error: "INVALID_CREDENTIALS" },
    });
    assert.deepEqual(await signIn(uniqueUsername("nobody")), {
      status: "error",
      userError: { error: "USER_NOT_FOUND" },
    });
    // Sign-in is case-insensitive on the username.
    const ok = await signIn(username.toUpperCase());
    assert.equal(ok.status, "complete");
  });

  test("password and username rules", async () => {
    assert.deepEqual(await signUp(uniqueUsername("pw"), "short"), {
      status: "error",
      userError: { error: "PASSWORD_TOO_SHORT", minimumLength: 10 },
    });
    assert.deepEqual(await signUp(uniqueUsername("pw"), "password123"), {
      status: "error",
      userError: { error: "PASSWORD_TOO_COMMON" },
    });
    assert.deepEqual(await signUp(uniqueUsername("pw"), " leading space pw"), {
      status: "error",
      userError: { error: "PASSWORD_HAS_SURROUNDING_WHITESPACE" },
    });
    assert.deepEqual(await signUp(" " + uniqueUsername("name"), PASSWORD), {
      status: "error",
      userError: { error: "USERNAME_HAS_SURROUNDING_WHITESPACE" },
    });
    assert.deepEqual(await signUp("x".repeat(101), PASSWORD), {
      status: "error",
      userError: { error: "USERNAME_TOO_LONG", maximumLength: 100 },
    });
  });

  test("users:me is null without a token", async () => {
    assert.equal(await query("users:me", {}), null);
  });
});

describe("progress sync", () => {
  test("two devices converge: data, a word deletion and a reset", async () => {
    const { username, tokens: deviceA } = await newAccount("sync");
    assert.deepEqual(await status(deviceA.accessToken), { version: 0 });

    const t = Date.now() - 60_000;
    // Device A: local progress (as migrated / edited before signing in).
    let localA = {
      kanjiResetAt: 0,
      learned: [
        { kanji: "日", learnedAt: t + 1 },
        { kanji: "本", learnedAt: t + 2 },
      ],
      scores: [{ key: "1-quiz", percent: 80, recordedAt: t + 3 }],
      wordsClearedAt: 0,
      words: [word("ねこ", "N5", t + 4, 0, "cat"), word("いぬ", "N5", t + 5, 0, "dog")],
    };
    const first = await sync(localA, deviceA.accessToken);
    sameSnapshot(first.snapshot, merge(emptySnapshot(), localA));
    assert.equal(first.version, 1);
    assert.ok(Math.abs(first.serverTime - Date.now()) < 60_000);
    localA = merge(first.snapshot, localA);
    assert.deepEqual(await status(deviceA.accessToken), { version: 1 });

    // Device B signs in and pulls (an empty local store syncs as an empty snapshot).
    const signInB = await signIn(username);
    assert.equal(signInB.status, "complete");
    const deviceB = signInB.tokens;
    assert.equal(deviceB.userId, deviceA.userId);
    const pulled = await sync(emptySnapshot(), deviceB.accessToken);
    sameSnapshot(pulled.snapshot, first.snapshot);
    assert.equal(pulled.version, 1, "a pull that changes nothing does not bump the version");

    // Device B edits: reset kanji progress, learn 人 after it, a new score,
    // delete ねこ, add とり.
    let localB = pulled.snapshot;
    const tReset = t + 10;
    localB = {
      ...localB,
      kanjiResetAt: tReset,
      learned: [{ kanji: "人", learnedAt: t + 11 }],
      scores: [{ key: "2-quiz", percent: 70, recordedAt: t + 12 }],
      words: [
        ...localB.words.map((w) => (w.key === "ねこ|N5" ? { ...w, deletedAt: t + 13 } : w)),
        word("とり", "N4", t + 14, 0, "bird"),
      ],
    };
    // Meanwhile device A learns 京 after B's reset and records a better 1-quiz.
    localA = merge(localA, {
      ...emptySnapshot(),
      learned: [{ kanji: "京", learnedAt: t + 15 }],
      scores: [{ key: "1-quiz", percent: 95, recordedAt: t + 16 }],
    });

    const syncB = await sync(localB, deviceB.accessToken);
    assert.equal(syncB.version, 2);
    localB = merge(syncB.snapshot, localB);

    const syncA = await sync(localA, deviceA.accessToken);
    assert.equal(syncA.version, 3);
    localA = merge(syncA.snapshot, localA);

    // B polls status, sees a new version and syncs again.
    assert.deepEqual(await status(deviceB.accessToken), { version: 3 });
    const syncB2 = await sync(localB, deviceB.accessToken);
    localB = merge(syncB2.snapshot, localB);
    assert.equal(syncB2.version, 3, "B had nothing new");

    const expected = {
      kanjiResetAt: tReset,
      learned: [
        { kanji: "京", learnedAt: t + 15 }, // U+4EAC
        { kanji: "人", learnedAt: t + 11 }, // U+4EBA
      ],
      scores: [
        { key: "1-quiz", percent: 95, recordedAt: t + 16 },
        { key: "2-quiz", percent: 70, recordedAt: t + 12 },
      ],
      wordsClearedAt: 0,
      words: [
        word("いぬ", "N5", t + 5, 0, "dog"),
        word("とり", "N4", t + 14, 0, "bird"),
        { ...word("ねこ", "N5", 0, t + 13, "cat") }, // tombstone
      ].sort((x, y) => (Buffer.compare(Buffer.from(x.key), Buffer.from(y.key)))),
    };
    sameSnapshot(localA, expected, "device A");
    sameSnapshot(localB, expected, "device B");
    sameSnapshot(syncB2.snapshot, expected, "server");

    // Re-syncing identical data leaves the version unchanged.
    const again = await sync(localA, deviceA.accessToken);
    assert.equal(again.version, 3);
    sameSnapshot(again.snapshot, expected);
    assert.deepEqual(await status(deviceA.accessToken), { version: 3 });

    // Clear all words on A: tombstones and words go, version bumps once.
    const cleared = await sync({ ...localA, wordsClearedAt: Date.now() - 1000, words: [] }, deviceA.accessToken);
    assert.equal(cleared.version, 4);
    assert.deepEqual(cleared.snapshot.words, []);
    const pulledAfterClear = await sync(localB, deviceB.accessToken);
    assert.deepEqual(pulledAfterClear.snapshot.words, [], "B's older words are garbage-collected by the clear");
    assert.equal(pulledAfterClear.version, 4);
  });

  test("timestamps from the future are clamped to serverTime", async () => {
    const { tokens } = await newAccount("clock");
    const future = Date.now() + 365 * 24 * 3600 * 1000;
    const result = await sync(
      {
        kanjiResetAt: 0,
        learned: [{ kanji: "未", learnedAt: future }],
        scores: [{ key: "3-quiz", percent: 60, recordedAt: future }],
        wordsClearedAt: 0,
        words: [word("みらい", "N3", future, 0)],
      },
      tokens.accessToken,
    );
    assert.ok(result.serverTime <= Date.now() + 5_000);
    assert.equal(result.snapshot.learned[0].learnedAt, result.serverTime);
    assert.equal(result.snapshot.scores[0].recordedAt, result.serverTime);
    assert.equal(result.snapshot.words[0].addedAt, result.serverTime);
    // A later reset from a correct clock still wipes it.
    const reset = await sync({ ...emptySnapshot(), kanjiResetAt: Date.now() + 10 }, tokens.accessToken);
    assert.deepEqual(reset.snapshot.learned, []);
  });

  test("NFC: decomposed kana from a device merges with precomposed", async () => {
    const { tokens } = await newAccount("nfc");
    const t = Date.now() - 1000;
    await sync({ ...emptySnapshot(), learned: [{ kanji: "が", learnedAt: t }] }, tokens.accessToken);
    const result = await sync({ ...emptySnapshot(), learned: [{ kanji: "が", learnedAt: t + 1 }] }, tokens.accessToken);
    assert.deepEqual(result.snapshot.learned, [{ kanji: "が", learnedAt: t + 1 }]);
  });

  test("invalid input is ConvexError INVALID_INPUT", async () => {
    const { tokens } = await newAccount("invalid");
    await rejectsWithCode(
      sync({ ...emptySnapshot(), scores: [{ key: "1-quiz", percent: 150, recordedAt: 1 }] }, tokens.accessToken),
      "INVALID_INPUT",
    );
    await rejectsWithCode(sync({ ...emptySnapshot(), words: [word("a", "N9", 1)] }, tokens.accessToken), "INVALID_INPUT");
    await rejectsWithCode(
      sync({ ...emptySnapshot(), learned: [{ kanji: "日本語日本語日本語", learnedAt: 1 }] }, tokens.accessToken),
      "INVALID_INPUT",
    );
    const error = await sync(
      { ...emptySnapshot(), scores: [{ key: "1-quiz", percent: 1.5, recordedAt: 1 }] },
      tokens.accessToken,
    ).catch((e) => e);
    assert.equal(error.errorData.code, "INVALID_INPUT");
    assert.equal(typeof error.errorData.message, "string");
    // Nothing was stored.
    assert.deepEqual(await status(tokens.accessToken), { version: 0 });
  });

  test("args failing validation are a plain function error (no errorData)", async () => {
    const { tokens } = await newAccount("argval");
    const { http, body } = await raw("mutation", "progress:sync", { snapshot: { kanjiResetAt: "x" } }, tokens.accessToken);
    assert.ok(http === 200 || http === 560, String(http));
    assert.equal(body.status, "error");
    assert.equal(body.errorData, undefined);
    assert.match(body.errorMessage, /ArgumentValidationError/);
  });

  test("unauthenticated calls are ConvexError UNAUTHENTICATED", async () => {
    await rejectsWithCode(sync(emptySnapshot()), "UNAUTHENTICATED");
    await rejectsWithCode(status(), "UNAUTHENTICATED");
    await rejectsWithCode(mutation("account:deleteAccount", {}), "UNAUTHENTICATED");
  });

  test("a garbage bearer token is rejected before any function runs (HTTP 401)", async () => {
    for (const token of ["garbage", "a.b.c"]) {
      const { http, body } = await raw("query", "users:me", {}, token);
      assert.equal(http, 401);
      assert.equal(body.code, "InvalidAuthHeader");
    }
  });
});

describe("sessions", () => {
  test("refreshSession rotates; the old token works until the new one is used; reuse after that revokes", async () => {
    const { tokens: t0 } = await newAccount("refresh");

    const r1 = await mutation("auth:refreshSession", { refreshToken: t0.refreshToken });
    assert.equal(r1.kind, "rotated");
    assert.notEqual(r1.tokens.refreshToken, t0.refreshToken);
    assert.equal(r1.tokens.userId, t0.userId);
    assert.ok((await query("users:me", {}, r1.tokens.accessToken)) !== null);

    // Lost response: the old token still works until its successor is used.
    const r1b = await mutation("auth:refreshSession", { refreshToken: t0.refreshToken });
    assert.equal(r1b.kind, "rotated");

    // The client keeps r1b and uses it: now t0 and r1 are superseded.
    const r2 = await mutation("auth:refreshSession", { refreshToken: r1b.tokens.refreshToken });
    assert.equal(r2.kind, "rotated");
    assert.ok((await query("users:me", {}, r2.tokens.accessToken)) !== null);

    // Presenting a superseded token looks like theft: the whole session ends.
    assert.deepEqual(await mutation("auth:refreshSession", { refreshToken: t0.refreshToken }), { kind: "noSession" });
    assert.deepEqual(await mutation("auth:refreshSession", { refreshToken: r2.tokens.refreshToken }), {
      kind: "noSession",
    });
    // Its (still unexpired) access tokens no longer resolve to a user.
    assert.equal(await query("users:me", {}, r2.tokens.accessToken), null);
    await rejectsWithCode(status(r2.tokens.accessToken), "UNAUTHENTICATED");
  });

  test("signOut ends the session: refresh is noSession, the access token is unauthenticated", async () => {
    const { tokens } = await newAccount("signout");
    assert.equal(await mutation("auth:signOut", { refreshToken: tokens.refreshToken }), null);
    assert.deepEqual(await mutation("auth:refreshSession", { refreshToken: tokens.refreshToken }), {
      kind: "noSession",
    });
    assert.equal(await query("users:me", {}, tokens.accessToken), null);
    await rejectsWithCode(status(tokens.accessToken), "UNAUTHENTICATED");
    // Signing out twice is fine.
    assert.equal(await mutation("auth:signOut", { refreshToken: tokens.refreshToken }), null);
    // An unknown refresh token is just noSession.
    assert.deepEqual(await mutation("auth:refreshSession", { refreshToken: "not-a-token" }), { kind: "noSession" });
  });

  test("deleteAccount removes data, frees the username and revokes every session", async () => {
    const { username, tokens: a } = await newAccount("delete");
    const b = (await signIn(username)).tokens;
    const t = Date.now() - 1000;
    const synced = await sync(
      {
        ...emptySnapshot(),
        learned: [{ kanji: "消", learnedAt: t }],
        words: [word("けす", "N4", t)],
      },
      a.accessToken,
    );
    assert.equal(synced.version, 1);

    assert.equal(await mutation("account:deleteAccount", {}, a.accessToken), null);

    // Both devices' sessions are gone.
    for (const tokens of [a, b]) {
      assert.equal(await query("users:me", {}, tokens.accessToken), null);
      await rejectsWithCode(status(tokens.accessToken), "UNAUTHENTICATED");
      await rejectsWithCode(sync(emptySnapshot(), tokens.accessToken), "UNAUTHENTICATED");
      assert.deepEqual(await mutation("auth:refreshSession", { refreshToken: tokens.refreshToken }), {
        kind: "noSession",
      });
    }
    // The username is free and the old password no longer signs in.
    assert.deepEqual(await signIn(username), { status: "error", userError: { error: "USER_NOT_FOUND" } });
    const again = await signUp(username, "a brand new password 1");
    assert.equal(again.status, "complete");
    assert.notEqual(again.tokens.userId, a.userId);
    // The new account starts empty.
    assert.deepEqual(await status(again.tokens.accessToken), { version: 0 });
    const fresh = await sync(emptySnapshot(), again.tokens.accessToken);
    sameSnapshot(fresh.snapshot, emptySnapshot());
  });
});

describe("limits", () => {
  test("a large word bank is compacted: tombstones go, live words stay, no deleted word comes back", async () => {
    const { tokens } = await newAccount("compact");
    const t = Date.now() - 1_000_000;
    const words = [];
    for (let i = 0; i < 100; i++) words.push(word(`live${i}`, "N5", t + i));
    const tombstones = ACCOUNT_LIMITS.compactWordsAbove;
    for (let i = 0; i < tombstones; i++) words.push(word(`gone${i}`, "N4", t - 10, t + 1000 + i));
    const result = await sync({ ...emptySnapshot(), words }, tokens.accessToken);
    const s = result.snapshot;
    assert.equal(s.words.length, 100, "only the live words are kept");
    assert.ok(s.words.every((w) => isLive(w, s.wordsClearedAt)));
    assert.equal(s.wordsClearedAt, t + 1000 + tombstones - 1, "the clear is the latest delete");
    // A device still holding an old live copy of a deleted word does not bring it back.
    const stale = await sync({ ...emptySnapshot(), words: [word("gone0", "N4", t - 10)] }, tokens.accessToken);
    assert.equal(stale.snapshot.words.length, 100);
    assert.equal(stale.version, result.version, "nothing changed");
  });

  test("more live words than an account keeps is WORD_BANK_FULL, and nothing is stored", async () => {
    const { tokens } = await newAccount("full");
    const t = Date.now() - 1000;
    const words = Array.from({ length: ACCOUNT_LIMITS.maxLiveWords + 1 }, (_, i) => word(`w${i}`, "N5", t));
    await rejectsWithCode(sync({ ...emptySnapshot(), words }, tokens.accessToken), "WORD_BANK_FULL");
    assert.deepEqual(await status(tokens.accessToken), { version: 0 });
    const tooMany = Array.from({ length: SNAPSHOT_LIMITS.maxWords + 1 }, (_, i) => word(`x${i}`, "N5", t, t + 1));
    await rejectsWithCode(sync({ ...emptySnapshot(), words: tooMany }, tokens.accessToken), "WORD_BANK_FULL");
  });

  test("syncs are rate limited per account (RATE_LIMITED with retryAfterMs)", async () => {
    const { tokens } = await newAccount("ratelimit");
    let limited;
    for (let i = 0; i < 60 && limited === undefined; i++) {
      try {
        await sync(emptySnapshot(), tokens.accessToken);
      } catch (error) {
        limited = error;
      }
    }
    assert.ok(limited instanceof CallError, "rate limited within 60 calls");
    assert.equal(limited.errorData.code, "RATE_LIMITED");
    assert.ok(limited.errorData.retryAfterMs > 0, JSON.stringify(limited.errorData));
    // Other accounts are not affected.
    const other = await newAccount("ratelimit-other");
    assert.equal((await sync(emptySnapshot(), other.tokens.accessToken)).version, 0);
  });
});
