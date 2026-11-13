# KanaFlashcard backend (Convex)

Accounts (Convex Auth 2.0, username + password) and progress sync for the app. The Swift client
lives in `KanaFlashcard/Services/Backend/`; the merge rules are in `lib/merge.ts` and, identically,
`KanaFlashcard/Models/ProgressSnapshot.swift`.

| File | What it holds |
|---|---|
| `auth.ts`, `auth.config.ts` | Convex Auth setup (sessions, username + password) |
| `users.ts` | `createUser` callback (sign-up rate limit), `users:me` |
| `progress.ts` | `progress:sync`, `progress:status` |
| `account.ts` | `account:deleteAccount` |
| `lib/merge.ts` | the CRDT merge, request validation, account limits, word compaction (pure, no imports) |
| `lib/rateLimits.ts` | sign-up and sync rate limits (`@convex-dev/rate-limiter`) |

## Local development and tests

First point `.env.local` at the local backend (see "Pushing to the cloud deployment" below);
as checked out here it targets the cloud deployment, and these commands would push there.

```sh
CONVEX_AGENT_MODE=anonymous npx convex dev          # local backend at http://127.0.0.1:3210
# Sign-ups are limited to 10 an hour per IP; the tests sign up many accounts:
CONVEX_AGENT_MODE=anonymous npx convex env set SIGNUP_LIMIT_PER_IP 100000
CONVEX_AGENT_MODE=anonymous npx convex env set SIGNUP_LIMIT_GLOBAL 100000

npm run typecheck
npm test                                             # merge rules + fixtures
BASE_URL=http://127.0.0.1:3210 npm run test:e2e      # HTTP API end to end
BASE_URL=http://127.0.0.1:3210 tests/AppFlow/run.sh  # the app's Swift code, two devices
```

To run the app against the local backend, set `KANA_BACKEND_URL=http://127.0.0.1:3210` in the
scheme's environment (Debug builds only). Every other build uses the cloud deployment in
`KanaFlashcard/Services/Backend/BackendConfig.swift`.

## Pushing to the cloud deployment

The app talks to `https://brave-vole-856.eu-west-1.convex.cloud`, the **Development** deployment
of the Convex project `kanaflashcard` (team `ashish-bisht-2b423`). Push function changes there
before installing a build that depends on them.

`.env.local` (git-ignored) links this folder to it:

```sh
CONVEX_DEPLOYMENT=dev:brave-vole-856
CONVEX_URL=https://brave-vole-856.eu-west-1.convex.cloud
CONVEX_SITE_URL=https://brave-vole-856.eu-west-1.convex.site
```

With the CLI logged in (`npx convex login`), push with `npx convex dev --once` (or keep
`npx convex dev` running). Do **not** use `npm run deploy` / `convex deploy` for this: it pushes to
the project's Production deployment, which the app does not use.

To run the local test backend instead, set `.env.local` to
`CONVEX_DEPLOYMENT=anonymous:anonymous-agent`, `CONVEX_URL=http://127.0.0.1:3210` and
`CONVEX_SITE_URL=http://127.0.0.1:3211` while testing, then switch it back.

Smoke test against the cloud (signs up a throwaway account, syncs, deletes it; 49 checks):

```sh
swiftc KanaFlashcard/Models/ProgressSnapshot.swift KanaFlashcard/Services/Backend/ConvexClient.swift \
  tests/SyncCLI/main.swift -o /tmp/synccli
BASE_URL=https://brave-vole-856.eu-west-1.convex.cloud /tmp/synccli
```

Do not run `npm run test:e2e` against the cloud: it signs up more accounts than the cloud's sign-up
limit (10 an hour per IP) allows.

Quick check of the push (expects `{"status":"success","value":null}`):

```sh
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"path":"users:me","args":{},"format":"json"}' \
  https://brave-vole-856.eu-west-1.convex.cloud/api/query
```

Optionally set usage alerts and spend limits on the deployment in the dashboard.

## Limits

- Requests (`SNAPSHOT_LIMITS` in `lib/merge.ts`): 2000 learned kanji, 2000 scores, 8000 word
  entries (live + tombstones, under Convex's 8192-element arrays), 4 MiB of word text, 300
  characters per field.
- Per account (`ACCOUNT_LIMITS`): 5000 live words (the app stops saving new words there), 2 MiB of
  word text. Above 6000 word entries the server compacts the tombstones of deleted words away
  (`compactWords`: like a Clear All at the latest delete with the live words added back), so a
  device always has room to send its edits.
- Rate limits (`lib/rateLimits.ts`): `progress:sync` 30 at once then 1 a second per account;
  sign-ups `SIGNUP_LIMIT_PER_IP` (default 10/hour) and `SIGNUP_LIMIT_GLOBAL` (default 200/hour),
  set with `npx convex env set`. Password checks are limited by Convex Auth per account (5, then
  1 a minute); anyone who knows a username can keep that bucket empty and block new sign-ins to it
  (devices already signed in keep syncing). With no email there is no other way in; accepted.

## Mac Catalyst signing (keychain)

The session is stored in the data-protection keychain, which on the Mac needs an App ID. The
Catalyst build gets one from `KanaFlashcard-Catalyst.entitlements` (Keychain Sharing with the app's
own group, `CODE_SIGN_ENTITLEMENTS[sdk=macosx*]`), so the Mac build now needs a Mac Catalyst
development profile: build it with `-allowProvisioningUpdates` (Xcode registers the Mac and creates
the profile; the app then runs only on Macs in that profile). Check the result:

```sh
codesign -d --entitlements - KanaFlashcard.app   # must list com.apple.application-identifier
ls KanaFlashcard.app/Contents/embedded.provisionprofile
```

Then sign in, quit, relaunch: the app must still be signed in. Without the App ID every keychain
call fails with -34018 and the Account sheet says the sign-in could not be saved.
