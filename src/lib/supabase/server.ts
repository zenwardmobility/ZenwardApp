import "server-only";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { getSupabaseUrl, getSupabasePublishableKey } from "./env";
import type { Database } from "./database.types";

/**
 * Server Supabase client for Server Components, Server Actions, and Route
 * Handlers — reads/writes the auth session via Next.js's cookie store.
 * Publishable key only, same as the browser client; the session cookie
 * (not a service key) is what grants the caller's own authenticated
 * identity, and RLS/RPC authorization is what actually decides what they
 * can do with it. See docs/security/application-auth-boundary.md.
 *
 * `cookies()` is async in this Next.js version (16.3.3) — awaited here so
 * every call site gets a plain client, not a Promise to unwrap themselves.
 *
 * The set() no-op guard exists because Server Components are read-only
 * with respect to cookies (only Server Actions/Route Handlers/the root
 * proxy.ts may write them) — calling this from a Server Component during
 * a Supabase auth refresh would otherwise throw. proxy.ts (renamed from
 * middleware.ts in P1-E3-S1A — Next.js 16 deprecated that file
 * convention) is what actually keeps the session cookie fresh via
 * src/lib/supabase/proxy.ts; this client's own writes are a no-op
 * fallback for the contexts where Next.js does not permit a write, not a
 * missing feature.
 */
export async function createServerSupabaseClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(getSupabaseUrl(), getSupabasePublishableKey(), {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Called from a Server Component (read-only cookie context) —
          // safe to ignore here because middleware refreshes the session
          // on every request that needs it (see middleware.ts).
        }
      },
    },
  });
}
