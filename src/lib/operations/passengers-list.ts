import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface PassengersListRow {
  id: string;
  displayName: string;
  phone: string | null;
  status: string;
}

export interface PassengersListResult {
  rows: PassengersListRow[];
  totalCount: number;
}

export const PASSENGERS_LIST_LIMIT = 100;

/**
 * The canonical Passenger directory (P1-E3-S8B1, work item §13) —
 * minimized real fields only (display name, phone, status): no
 * assistance/medical text here, matching the same data-minimization
 * discipline already established for every other Passenger-facing read
 * in this codebase (ZD-080 and its own descendants). A single bounded
 * query (LIMIT 100) — Passenger counts for a pilot-sized operator (work
 * item §4: 3-25 vehicles) are nowhere near large enough to need real
 * pagination yet; documented here rather than silently assumed.
 */
export async function getPassengersList(organizationId: string, search?: string): Promise<PassengersListResult> {
  const supabase = await createServerSupabaseClient();

  let query = supabase
    .from("passengers")
    .select("id, display_name, phone, status", { count: "exact" })
    .eq("organization_id", organizationId)
    .order("display_name", { ascending: true })
    .limit(PASSENGERS_LIST_LIMIT);

  const trimmed = search?.trim();
  if (trimmed) {
    query = query.or(`display_name.ilike.%${trimmed}%,phone.ilike.%${trimmed}%`);
  }

  const { data, error, count } = await query;
  if (error || !data) {
    return { rows: [], totalCount: 0 };
  }

  return {
    rows: data.map((row) => ({
      id: row.id,
      displayName: row.display_name,
      phone: row.phone,
      status: row.status,
    })),
    totalCount: count ?? data.length,
  };
}
