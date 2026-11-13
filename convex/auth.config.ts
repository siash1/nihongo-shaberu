import type { AuthConfig } from "convex/server";
import { convexAuthProvider } from "@convex-dev/auth/server";

// Access tokens are signed by the deployment itself (`ctx.auth.signJwt` in the
// auth component), so no JWT_PRIVATE_KEY / JWKS environment variables exist.
export default {
  providers: [convexAuthProvider()],
} satisfies AuthConfig;
