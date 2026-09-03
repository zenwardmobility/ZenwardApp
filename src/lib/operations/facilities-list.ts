import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface FacilitiesListRow {
  id: string;
  name: string;
  addressLine1: string | null;
  addressLine2: string | null;
  city: string | null;
  state: string | null;
  postalCode: string | null;
  status: string;
}

/**
 * The canonical Facility directory (P1-E3-S8B1, real Create/Edit added
 * P1-E3-S9 — closes GAP-13). `facilities_insert_org_operations`/
 * `_update_org_operations` were already org+role-scoped and column-
 * narrowed (name/address/status only) before either phase touched this
 * file. See docs/product/operations-surface-map.md.
 */
export async function getFacilitiesList(organizationId: string): Promise<FacilitiesListRow[]> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("facilities")
    .select("id, name, address_line1, address_line2, city, state, postal_code, status")
    .eq("organization_id", organizationId)
    .order("name", { ascending: true })
    .limit(100);

  if (error || !data) return [];
  return data.map((row) => ({
    id: row.id,
    name: row.name,
    addressLine1: row.address_line1,
    addressLine2: row.address_line2,
    city: row.city,
    state: row.state,
    postalCode: row.postal_code,
    status: row.status,
  }));
}
