import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface DriversListRow {
  id: string;
  displayName: string;
  phone: string | null;
  status: string;
  /** A real, currently-active assignment's Passenger name — never a fabricated Availability status (work item §18: "Do NOT show Available unless a canonical Driver Availability model exists"). Null means "not currently on a trip," not "available." */
  currentTripPassengerName: string | null;
}

/**
 * The canonical Driver directory (P1-E3-S8B1, work item §18-§19).
 * Read-only — Driver is not AuthUser/Membership, and no safe Driver +
 * Membership + user-invite contract exists yet in this product to back
 * a real "Add Driver" flow (inviting a new authenticated user, creating
 * their Membership, then linking a Drivers row — three different tables
 * this phase does not touch). Building that casually would either
 * fabricate a fake invite flow or silently create orphaned auth users —
 * recorded as explicit future (P1-E3-S9) work, not built here.
 */
export async function getDriversList(organizationId: string): Promise<DriversListRow[]> {
  const supabase = await createServerSupabaseClient();
  const { data: drivers, error } = await supabase
    .from("drivers")
    .select("id, display_name, phone, status")
    .eq("organization_id", organizationId)
    .order("display_name", { ascending: true })
    .limit(100);

  if (error || !drivers) return [];

  const driverIds = drivers.map((d) => d.id);
  const { data: activeAssignments } =
    driverIds.length > 0
      ? await supabase
          .from("trip_assignments")
          .select("driver_id, trips(passengers(display_name))")
          .eq("organization_id", organizationId)
          .in("driver_id", driverIds)
          .is("ended_at", null)
      : { data: [] as { driver_id: string; trips: { passengers: { display_name: string } | null } | null }[] };

  const currentTripByDriver = new Map<string, string>();
  for (const row of activeAssignments ?? []) {
    const passengerName = (row as { trips: { passengers: { display_name: string } | null } | null }).trips?.passengers
      ?.display_name;
    if (passengerName) currentTripByDriver.set((row as { driver_id: string }).driver_id, passengerName);
  }

  return drivers.map((d) => ({
    id: d.id,
    displayName: d.display_name,
    phone: d.phone,
    status: d.status,
    currentTripPassengerName: currentTripByDriver.get(d.id) ?? null,
  }));
}
