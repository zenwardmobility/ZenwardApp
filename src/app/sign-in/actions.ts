"use server";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { safeRedirectPath } from "@/lib/auth/redirect";
import { AUTH_ERROR, type AuthErrorCode } from "@/lib/auth/errors";

export interface SignInState {
  error?: AuthErrorCode;
}

/**
 * Email + password only for MVP (work item §11). Never distinguishes "no
 * such account" from "wrong password" in the returned error — both
 * collapse to the same generic code (work item §13). `next` is
 * re-validated here (never trusted just because it round-tripped through
 * a hidden field) before being used as the post-sign-in destination.
 *
 * Deliberately does NOT itself call `complete_pending_signup()` (an
 * earlier version of this fix did, then P1-E4-S0A1 centralized it): the
 * real cloud reproduction showed a person can reach a live session
 * WITHOUT ever submitting this form at all — Supabase's own confirmation
 * link can establish a session directly. A check placed only here would
 * never fire for that path. `/` (src/app/page.tsx) is the one place ALL
 * authenticated traffic already passes through to resolve a destination,
 * so the pending-signup/invite continuation lives there instead (routing
 * a zero-Membership visitor to `/complete-signup`), not duplicated here.
 */
export async function signInAction(_prevState: SignInState, formData: FormData): Promise<SignInState> {
  const emailRaw = formData.get("email");
  const passwordRaw = formData.get("password");
  const nextRaw = formData.get("next");

  const email = typeof emailRaw === "string" ? emailRaw.trim().toLowerCase() : "";
  const password = typeof passwordRaw === "string" ? passwordRaw : "";

  if (!email || !password) {
    return { error: AUTH_ERROR.INVALID_CREDENTIALS };
  }

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return { error: AUTH_ERROR.INVALID_CREDENTIALS };
  }

  redirect(safeRedirectPath(nextRaw, "/"));
}
