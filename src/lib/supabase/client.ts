"use client";

import { createBrowserClient } from "@supabase/ssr";
import { getSupabaseUrl, getSupabasePublishableKey } from "./env";
import type { Database } from "./database.types";

/**
 * Browser Supabase client — publishable key only, relies entirely on the
 * caller's own session + RLS/RPC authorization (docs/security/
 * application-auth-boundary.md "No service-role use"). Never a secret
 * key. Create a fresh instance per call site that needs one rather than a
 * shared singleton — this matches @supabase/ssr's own recommended pattern
 * and avoids cross-request state leaking between users in any context
 * where module state could be shared.
 */
export function createBrowserSupabaseClient() {
  return createBrowserClient<Database>(getSupabaseUrl(), getSupabasePublishableKey());
}
