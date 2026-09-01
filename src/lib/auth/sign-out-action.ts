"use server";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { ORG_CONTEXT_COOKIE } from "./organization";
import { cookies } from "next/headers";

/**
 * Signs out via Supabase's own session-invalidation call (work item §33 —
 * never just deleting a UI-level cookie while the Supabase session stays
 * valid), clears the organization-context cookie (it names no secret, but
 * carries no meaning without a session either), then redirects to
 * /sign-in.
 */
export async function signOutAction() {
  const supabase = await createServerSupabaseClient();
  await supabase.auth.signOut();

  const cookieStore = await cookies();
  cookieStore.delete(ORG_CONTEXT_COOKIE);

  redirect("/sign-in");
}
