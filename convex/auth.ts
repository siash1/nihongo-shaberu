import { setupConvexAuth } from "@convex-dev/auth/server";
import { setupUsernamePassword } from "@convex-dev/auth/methods/username-password/server";
import { components, internal } from "./_generated/api";

const DAY = 24 * 60 * 60;

const auth = setupConvexAuth({
  component: components.auth,
  // Access tokens (JWT, `exp` claim) live one hour, the most Convex signs.
  accessTokenTtlSeconds: 3600,
  // A device may stay away 90 days and still resume its session...
  refreshInactivityTimeoutSeconds: 90 * DAY,
  // ...and a session lasts at most a year before signing in again.
  sessionMaxLifetimeSeconds: 365 * DAY,
});

export const { signOut, refreshSession, isAuthenticated } = auth;

// Sign-ups are rate limited in users.createUser (convex/lib/rateLimits.ts).
// Password checks (sign-in, changePassword) are rate limited by Convex Auth per
// account: 5, then one a minute. Accepted risk: anyone who knows a username can
// keep that bucket empty and so block new sign-ins to that account (devices
// already signed in keep syncing). There is no email, so no other way in.

export const {
  signUpWithUsernamePassword,
  signInWithUsernamePassword,
  changePassword,
} = setupUsernamePassword(auth, {
  component: components.authPassword,
  usernameComponent: components.authUsername,
}).attachUserCallbacks({ createUser: internal.users.createUser });
