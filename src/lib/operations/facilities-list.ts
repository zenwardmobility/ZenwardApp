import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface FacilitiesListRow {
  id: string;
  name: string;
  city: string | null;
  state: string | null;
  status: string;
}

/**
 * The canonical Facility directory (P1-E3-S8B1, work item §16-§17).
 * Read-only this phase — `facilities_insert_org_operations`/
 * `_update_org_operations` are already org+role-scoped and column-
 * narrowed (name/address/status only), so a future Add/Edit Facility
 * flow is straightforward to add without any RLS change, but is
 * deliberately deferred: a read-only directory is judged sufficient for
 * pilot operations this phase (work item §39's own explicit fallback —
 * "if mutation intentionally deferred: prove real existing Facilities
 * render correctly"). See docs/product/operations-surface-map.md.
 */
export async function getFacilitiesList(organizationId: string): Promise<FacilitiesListRow[]> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("facilities")
    .select("id, name, city, state, status")
    .eq("organization_id", organizationId)
    .order("name", { ascending: true })
    .limit(100);

  if (error || !data) return [];
  return data;
}
