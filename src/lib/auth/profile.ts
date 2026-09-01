import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

/**
 * The caller's own display name, live-resolved from `user_profiles`
 * (RLS: `user_profiles_select_own`) — never the raw email leaked into a
 * "name" slot, which OperationsLayoutClient/OperationsSidebar did until
 * P1-E3-S4 (see decision-register.md ZD-129). No seed data currently
 * populates `user_profiles.display_name` for any fixture user (confirmed:
 * no `insert into public.user_profiles` exists in supabase/seed.sql, and
 * no `handle_new_user`-style auto-provisioning trigger exists either) — so
 * every fixture account genuinely exercises the `email` fallback below,
 * not a hypothetical path. That gap (no profile self-service/provisioning
 * flow yet) is out of scope for this phase; a real display name, once one
 * exists, flows through automatically without any further Operations-side
 * change.
 */
export async function getDisplayName(userId: string, email: string | null): Promise<string> {
  const supabase = await createServerSupabaseClient();
  const { data } = await supabase.from("user_profiles").select("display_name").eq("id", userId).maybeSingle();
  return data?.display_name ?? email ?? "Unknown User";
}
