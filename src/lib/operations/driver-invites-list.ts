import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface DriverInviteRow {
  id: string;
  email: string;
  displayName: string;
  status: string;
  createdAt: string;
}

/**
 * Pending/recent Driver invites for the Drivers screen (P1-E3-S9, work
 * item §10). RLS-scoped via `driver_invites_select_org_admin` — a
 * Dispatcher calling this simply gets zero rows (no SELECT policy
 * grants them any), never an error, matching this codebase's own "RLS
 * returns zero rows for no access" convention.
 */
export async function getDriverInvitesList(organizationId: string): Promise<DriverInviteRow[]> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("driver_invites")
    .select("id, email, display_name, status, created_at")
    .eq("organization_id", organizationId)
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(50);

  if (error || !data) return [];
  return data.map((row) => ({
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    status: row.status,
    createdAt: row.created_at,
  }));
}
