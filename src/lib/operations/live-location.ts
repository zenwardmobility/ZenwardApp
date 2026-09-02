import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { DispatchTripLocation } from "./live-location-shared";

export type { DispatchTripLocation } from "./live-location-shared";

/**
 * Server-side read boundary for live Driver location on the Dispatch
 * Board (P1-E3-S7A, work item §44) — organization-scoped, explicit
 * columns, no `select("*")`, no service role, no generic location
 * repository. Reads directly via the existing RLS SELECT policy
 * (`driver_location_updates_select_org_operations`) — the same
 * convention every other Operations-read table already uses, not a
 * second RPC (the read's own authorization condition is a simple
 * org-role check, already well-precedented as a plain policy).
 */

const LOCATION_COLUMNS = "trip_id, assignment_id, latitude, longitude, accuracy_meters, recorded_at";

/**
 * Latest location per Trip, for every Trip id given — derived from the
 * one append-only history table (no separate "latest" table, ZD-1xx),
 * ordered by `recorded_at desc` per trip and reduced to the first row
 * seen per `trip_id` in TypeScript. Explicitly does NOT trust that the
 * latest row's `assignment_id` still matches the Trip's CURRENT active
 * assignment — the caller (`getDispatchBoardData`) cross-checks that
 * against its own already-loaded `activeAssignmentId` before ever
 * displaying a position as live (work item §51 — a stale former
 * Driver's last-known position must never be shown as the current
 * assigned Driver's live location, even in the brief window before the
 * new Driver's first update arrives).
 */
export async function getLatestLocationsByTrip(
  organizationId: string,
  tripIds: string[],
): Promise<Map<string, DispatchTripLocation>> {
  const result = new Map<string, DispatchTripLocation>();
  if (tripIds.length === 0) return result;

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("driver_location_updates")
    .select(LOCATION_COLUMNS)
    .eq("organization_id", organizationId)
    .in("trip_id", tripIds)
    .order("recorded_at", { ascending: false });

  if (error) {
    throw new Error(`Failed to load dispatch location data: ${error.message}`);
  }

  for (const row of data ?? []) {
    if (!result.has(row.trip_id)) {
      result.set(row.trip_id, {
        latitude: row.latitude,
        longitude: row.longitude,
        accuracyMeters: row.accuracy_meters,
        recordedAt: row.recorded_at,
        assignmentId: row.assignment_id,
      });
    }
  }
  return result;
}
