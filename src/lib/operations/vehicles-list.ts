import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface VehiclesListRow {
  id: string;
  label: string;
  status: string;
  currentDriverName: string | null;
}

/**
 * The canonical Fleet directory (P1-E3-S8B1, work item §20-§21).
 * Read-only this phase — `vehicles_insert_org_admin`/`_update_org_admin`
 * are already Organization-Admin-scoped and column-narrowed (label/
 * status only), so a future Add/Edit Vehicle flow is straightforward,
 * but a read-only list is judged sufficient for pilot operations now.
 * No wheelchair-accessible/ambulatory/stretcher-capable claims — the
 * `vehicles` schema has no such columns, and none is fabricated (work
 * item §20's own explicit prohibition).
 */
export async function getVehiclesList(organizationId: string): Promise<VehiclesListRow[]> {
  const supabase = await createServerSupabaseClient();
  const { data: vehicles, error } = await supabase
    .from("vehicles")
    .select("id, label, status")
    .eq("organization_id", organizationId)
    .order("label", { ascending: true })
    .limit(100);

  if (error || !vehicles) return [];

  const vehicleIds = vehicles.map((v) => v.id);
  const { data: activeAssignments } =
    vehicleIds.length > 0
      ? await supabase
          .from("trip_assignments")
          .select("vehicle_id, drivers(display_name)")
          .eq("organization_id", organizationId)
          .in("vehicle_id", vehicleIds)
          .is("ended_at", null)
      : { data: [] as { vehicle_id: string | null; drivers: { display_name: string } | null }[] };

  const currentDriverByVehicle = new Map<string, string>();
  for (const row of activeAssignments ?? []) {
    const vehicleId = (row as { vehicle_id: string | null }).vehicle_id;
    const driverName = (row as { drivers: { display_name: string } | null }).drivers?.display_name;
    if (vehicleId && driverName) currentDriverByVehicle.set(vehicleId, driverName);
  }

  return vehicles.map((v) => ({
    id: v.id,
    label: v.label,
    status: v.status,
    currentDriverName: currentDriverByVehicle.get(v.id) ?? null,
  }));
}
