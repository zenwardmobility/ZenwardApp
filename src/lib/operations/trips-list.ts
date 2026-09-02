import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { organizationDayBoundsUtc } from "./day-bounds";

export type TripsListDateFilter = "today" | "upcoming" | "past" | "all";
export type TripsListAssignmentFilter = "all" | "assigned" | "unassigned";

export interface TripsListFilters {
  search?: string;
  date?: TripsListDateFilter;
  assignment?: TripsListAssignmentFilter;
  page?: number;
}

export interface TripsListRow {
  id: string;
  passengerName: string;
  pickupDescription: string;
  destinationDescription: string;
  scheduledPickupAt: string | null;
  state: string;
  driverName: string | null;
}

export interface TripsListResult {
  rows: TripsListRow[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export const TRIPS_LIST_PAGE_SIZE = 25;

/**
 * The canonical Trip inventory query (P1-E3-S8B1, work item §9-§11) — find/
 * filter/inspect any Trip in the organization, not just "today's" narrow
 * slice Today's Operations/Dispatch already cover. Bounded, server-side
 * pagination (`TRIPS_LIST_PAGE_SIZE` rows per page via `range()`) — never
 * an unbounded historical load (work item §11).
 *
 * Every filter (search, assignment) is resolved to a real database
 * condition BEFORE pagination — never applied as a client-side re-filter
 * on an already-paginated page. That would be a real correctness bug, not
 * a style choice: a client-side filter after `range()` silently drops
 * matching rows that never made it into the current page and reports a
 * `totalCount` that doesn't match what's actually shown (found and fixed
 * during this module's own first draft, not assumed correct).
 */
export async function getTripsList(
  organizationId: string,
  timezone: string,
  filters: TripsListFilters,
): Promise<TripsListResult> {
  const supabase = await createServerSupabaseClient();
  const page = Math.max(1, filters.page ?? 1);
  const pageSize = TRIPS_LIST_PAGE_SIZE;
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  let query = supabase
    .from("trips")
    .select(
      "id, passenger_id, state, scheduled_pickup_at, pickup_description, destination_description, passengers(display_name)",
      { count: "exact" },
    )
    .eq("organization_id", organizationId);

  const dateFilter = filters.date ?? "all";
  if (dateFilter === "today") {
    const { startUtc, endUtc } = organizationDayBoundsUtc(new Date(), timezone);
    query = query.gte("scheduled_pickup_at", startUtc.toISOString()).lt("scheduled_pickup_at", endUtc.toISOString());
  } else if (dateFilter === "upcoming") {
    const { endUtc } = organizationDayBoundsUtc(new Date(), timezone);
    query = query.gte("scheduled_pickup_at", endUtc.toISOString());
  } else if (dateFilter === "past") {
    const { startUtc } = organizationDayBoundsUtc(new Date(), timezone);
    query = query.lt("scheduled_pickup_at", startUtc.toISOString());
  }

  // A search term may match the Trip's own pickup/destination text OR the
  // Passenger's name — two different tables. Resolving matching Passenger
  // ids first (one small, org-scoped, bounded query) and folding them into
  // the same server-side `.or()` filter as the address columns keeps this
  // one correct, correctly-paginated, correctly-counted query.
  const search = filters.search?.trim();
  if (search) {
    const { data: matchingPassengers } = await supabase
      .from("passengers")
      .select("id")
      .eq("organization_id", organizationId)
      .ilike("display_name", `%${search}%`);
    const passengerIds = (matchingPassengers ?? []).map((p) => p.id);

    const orParts = [`pickup_description.ilike.%${search}%`, `destination_description.ilike.%${search}%`];
    if (passengerIds.length > 0) {
      orParts.push(`passenger_id.in.(${passengerIds.join(",")})`);
    }
    query = query.or(orParts.join(","));
  }

  // Assignment status similarly requires a real pre-pagination condition —
  // resolved via the org's currently-active assignment trip-id set (small,
  // proportional to today's real dispatch load, not full Trip history).
  const assignmentFilter = filters.assignment ?? "all";
  if (assignmentFilter !== "all") {
    const { data: activeAssignments } = await supabase
      .from("trip_assignments")
      .select("trip_id")
      .eq("organization_id", organizationId)
      .is("ended_at", null);
    const assignedTripIds = (activeAssignments ?? []).map((a) => a.trip_id);

    if (assignmentFilter === "assigned") {
      if (assignedTripIds.length === 0) {
        return { rows: [], totalCount: 0, page, pageSize };
      }
      query = query.in("id", assignedTripIds);
    } else if (assignmentFilter === "unassigned") {
      if (assignedTripIds.length > 0) {
        query = query.not("id", "in", `(${assignedTripIds.join(",")})`);
      }
    }
  }

  query = query.order("scheduled_pickup_at", { ascending: dateFilter !== "past" }).range(from, to);

  const { data, error, count } = await query;
  if (error || !data) {
    return { rows: [], totalCount: 0, page, pageSize };
  }

  // Second phase, scoped to exactly this page's own Trip ids — the same
  // two-phase discipline dispatch-board.ts established, never a broader
  // per-org scan.
  const tripIds = data.map((row) => row.id);
  const { data: assignmentRows } =
    tripIds.length > 0
      ? await supabase
          .from("trip_assignments")
          .select("trip_id, drivers(display_name)")
          .eq("organization_id", organizationId)
          .in("trip_id", tripIds)
          .is("ended_at", null)
      : { data: [] as { trip_id: string; drivers: { display_name: string } | null }[] };

  const driverByTrip = new Map<string, string>();
  for (const row of assignmentRows ?? []) {
    const driverName = (row as { drivers: { display_name: string } | null }).drivers?.display_name;
    if (driverName) driverByTrip.set((row as { trip_id: string }).trip_id, driverName);
  }

  const rows: TripsListRow[] = data.map((row) => {
    const passenger = row.passengers as unknown as { display_name: string } | null;
    return {
      id: row.id,
      passengerName: passenger?.display_name ?? "Passenger",
      pickupDescription: row.pickup_description,
      destinationDescription: row.destination_description,
      scheduledPickupAt: row.scheduled_pickup_at,
      state: row.state,
      driverName: driverByTrip.get(row.id) ?? null,
    };
  });

  return { rows, totalCount: count ?? rows.length, page, pageSize };
}
