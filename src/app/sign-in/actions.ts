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
