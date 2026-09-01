import "server-only";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";

/**
 * Resolves the current authenticated user from the session cookie via
 * Supabase Auth (`getUser()`, which re-validates the token against the
 * Auth server — not `getSession()`, which only decodes the local JWT).
 * Authentication only — this says nothing about what the user is
 * authorized to do; see src/lib/auth/authorization.ts for that.
 */
export async function getUser() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user;
}

/** Redirects to sign-in (preserving `next`) if unauthenticated. Server-side, resolved before any protected content renders (work item §9). */
export async function requireUser(redirectTo = "/sign-in") {
  const user = await getUser();
  if (!user) {
    redirect(redirectTo);
  }
  return user;
}
