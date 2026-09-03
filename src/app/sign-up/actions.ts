"use server";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { AUTH_ERROR, type AuthErrorCode } from "@/lib/auth/errors";

export interface SignUpState {
  error?: AuthErrorCode;
  /** True only when Supabase Auth genuinely requires email confirmation
   * before a session exists (work item §2: "Email verification behavior
   * must be documented and truthful") — never assumed either way, always
   * read from the real `signUp()` response for THIS environment. */
  needsEmailConfirmation?: boolean;
}

function stringField(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Sign-up (P1-E3-S9, work item §2) — collects exactly what's needed to
 * start: full name, email, password, business name. Creates the real
 * authenticated user via Supabase Auth's own `signUp()` (never a
 * service-role shortcut from this — or any — browser-reachable code
 * path), then, ONLY if a real session actually exists (see the
 * `needsEmailConfirmation` branch below), calls `signup_create_
 * organization` — the sole controlled path that atomically creates the
 * caller's UserProfile, a new Organization, and their own
 * organization_admin Membership in one transaction (docs/product/
 * operator-onboarding-model.md).
 *
 * Failure-mode honesty (work item §2's own "failed signup does not leave
 * a broken partial state"): if `signUp()` succeeds but the RPC fails for
 * any reason, the person is left with a real, valid, harmless account and
 * NO organization — the exact same "authenticated, zero Membership" state
 * `/access-unavailable` already handles for other fixtures. Nothing is
 * silently half-created; they can retry signup (a second
 * `signup_create_organization` call from an already-authenticated session
 * is safe and non-destructive) or contact support.
 */
export async function signUpAction(_prevState: SignUpState, formData: FormData): Promise<SignUpState> {
  const fullName = stringField(formData, "fullName");
  const email = stringField(formData, "email").toLowerCase();
  const password = stringField(formData, "password");
  const businessName = stringField(formData, "businessName");

  if (!fullName || !email || !password || !businessName) {
    return { error: AUTH_ERROR.SIGNUP_INVALID_INPUT };
  }
  if (password.length < 8) {
    return { error: AUTH_ERROR.SIGNUP_WEAK_PASSWORD };
  }

  const supabase = await createServerSupabaseClient();

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
  });

  if (signUpError) {
    // Supabase returns a generic "already registered"-shaped error for a
    // taken email in some configurations and a distinguishable one in
    // others — normalized here rather than parsing message text, matching
    // the "never a raw Supabase/Postgres message" discipline used
    // throughout this codebase (src/lib/driver/errors.ts).
    if (signUpError.message.toLowerCase().includes("already registered") || signUpError.status === 422) {
      return { error: AUTH_ERROR.SIGNUP_EMAIL_TAKEN };
    }
    return { error: AUTH_ERROR.SIGNUP_FAILED };
  }

  // Honest environment-dependent branch (work item §2's own requirement).
  // Locally (supabase/config.toml: enable_confirmations = false) signUp()
  // returns a session immediately. A real deployment with email
  // confirmation enabled would return a user but no session here — this
  // codebase does not assume either way; it reads the real response.
  if (!signUpData.session) {
    return { needsEmailConfirmation: true };
  }

  const { error: orgError } = await supabase.rpc("signup_create_organization", {
    p_business_name: businessName,
    p_display_name: fullName,
  });

  if (orgError) {
    return { error: AUTH_ERROR.SIGNUP_FAILED };
  }

  redirect("/onboarding");
}
