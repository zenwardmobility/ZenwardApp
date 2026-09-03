"use server";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { AUTH_ERROR, type AuthErrorCode } from "@/lib/auth/errors";

export interface JoinActionState {
  error?: AuthErrorCode;
  needsEmailConfirmation?: boolean;
}

function stringField(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Join-invite sign-up (P1-E3-S9, work item §10) — the SAME normal
 * Supabase Auth `signUp()` as `/sign-up`, never a service-role-created
 * account. The email is fixed to the invite's own email (a hidden field,
 * re-validated server-side against the token below) — the invitee
 * cannot redeem someone else's invite by typing a different email here,
 * since `redeem_driver_invite` independently re-checks the caller's real
 * account email against the invite row regardless of what this form
 * submitted.
 */
export async function joinSignUpAction(_prevState: JoinActionState, formData: FormData): Promise<JoinActionState> {
  const token = stringField(formData, "token");
  const email = stringField(formData, "email").toLowerCase();
  const fullName = stringField(formData, "fullName");
  const password = stringField(formData, "password");

  if (!token || !email || !fullName || !password) {
    return { error: AUTH_ERROR.SIGNUP_INVALID_INPUT };
  }
  if (password.length < 8) {
    return { error: AUTH_ERROR.SIGNUP_WEAK_PASSWORD };
  }

  const supabase = await createServerSupabaseClient();

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({ email, password });
  if (signUpError) {
    if (signUpError.message.toLowerCase().includes("already registered") || signUpError.status === 422) {
      return { error: AUTH_ERROR.SIGNUP_EMAIL_TAKEN };
    }
    return { error: AUTH_ERROR.SIGNUP_FAILED };
  }

  if (signUpData.user) {
    await supabase.from("user_profiles").upsert({ id: signUpData.user.id, display_name: fullName });
  }

  if (!signUpData.session) {
    return { needsEmailConfirmation: true };
  }

  const { error: redeemError } = await supabase.rpc("redeem_driver_invite", { p_token: token });
  if (redeemError) {
    return { error: AUTH_ERROR.INVITE_INVALID };
  }

  redirect("/driver");
}

/** For an already-signed-in visitor whose account email matches the invite — one click to accept. */
export async function acceptInviteAction(_prevState: JoinActionState, formData: FormData): Promise<JoinActionState> {
  const token = stringField(formData, "token");
  if (!token) {
    return { error: AUTH_ERROR.INVITE_INVALID };
  }

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.rpc("redeem_driver_invite", { p_token: token });
  if (error) {
    return { error: AUTH_ERROR.INVITE_INVALID };
  }

  redirect("/driver");
}
