import { defineApp } from "convex/server";
import auth from "@convex-dev/auth/convex.config.js";
import authPassword from "@convex-dev/auth/components/password/convex.config.js";
import authUsername from "@convex-dev/auth/components/username/convex.config.js";
import rateLimiter from "@convex-dev/rate-limiter/convex.config.js";

const app = defineApp();
// The core must stay unnamed: Convex Auth requires it at the path "auth".
app.use(auth);
app.use(authPassword);
app.use(authUsername);
// The app's own rate limits (convex/lib/rateLimits.ts).
app.use(rateLimiter);

export default app;
