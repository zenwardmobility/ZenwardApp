import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { organizationDayBoundsUtc } from "./day-bounds";
import { isActiveTripState, operationsTripStatusLabel, operationsEventLabel } from "./presentation";

/**
 * Server-side data access boundary for Today's Operations (P1-E3-S4, work
 * item §51) — organization-scoped, explicit columns (never `select("*")`),
 * timezone-aware grouping, no service role, no presentation JSX. Every
 * query below is additionally filtered by `organization_id` explicitly,
 * not left to RLS alone to narrow — the same defense-in-depth convention
 * `getActiveMemberships()` (src/lib/auth/membership.ts) already follows.
 *
 * Three real queries, not one aggregate RPC (GAP-8 in
 * ui-backend-gap-register.md explicitly recommends against building one
 * speculatively — this data volume does not need it):
 *   1. Today's trips (by `scheduled_pickup_at`, org-local day bounds) —
 *      feeds Needs Assignment, Upcoming Trips, and the Completed-Today
 *      subset.
 *   2. Active trips (any of the 5 non-terminal in-progress states,
 *      DELIBERATELY NOT bounded to today's window) — an in-progress Trip
 *      is happening right now by definition; bounding it to "scheduled for
 *      today" would incorrectly hide a running-late Trip whose
 *      `scheduled_pickup_at` technically fell on the prior org-local day.
 *   3. Today's `trip_events` (by `occurred_at`, org-local day bounds) —
 *      feeds the Activity Log.
 */

const TRIP_COLUMNS =
  "id, state, scheduled_pickup_at, pickup_description, destination_description, " +
  "passengers!trips_passenger_id_organization_id_fkey(display_name), " +
  "trip_assignments!trip_assignments_trip_id_organization_id_fkey(ended_at, " +
  "drivers!trip_assignments_driver_id_organization_id_fkey(display_name), " +
  "vehicles!trip_assignments_vehicle_id_organization_id_fkey(label))";

interface NameEmbed {
  display_name: string;
}
type NameRelation = NameEmbed | NameEmbed[] | null;

interface LabelEmbed {
  label: string;
}
type LabelRelation = LabelEmbed | LabelEmbed[] | null;

interface TripAssignmentEmbed {
  ended_at: string | null;
  drivers: NameRelation;
  vehicles: LabelRelation;
}

interface TripRow {
  id: string;
  state: string;
  scheduled_pickup_at: string | null;
  pickup_description: string;
  destination_description: string;
  passengers: NameRelation;
  trip_assignments: TripAssignmentEmbed[] | null;
}

/**
 * A single embedded resource can come back as an object OR a one-element
 * array depending on how PostgREST/supabase-js's type inference resolves a
 * given composite-FK relationship — the same defensive unwrap
 * `getActiveMemberships()` already uses for the `organizations` embed.
 */
function unwrapOne<T>(relation: T | T[] | null | undefined): T | null {
  if (!relation) return null;
  return Array.isArray(relation) ? (relation[0] ?? null) : relation;
}

export interface TodaysOperationsTrip {
  id: string;
  state: string;
  statusLabel: string;
  scheduledPickupAt: string | null;
  passengerName: string;
  pickupDescription: string;
  destinationDescription: string;
  driverName: string | null;
  vehicleLabel: string | null;
}

function mapTripRow(row: TripRow): TodaysOperationsTrip {
  const activeAssignment = (row.trip_assignments ?? []).find((assignment) => assignment.ended_at === null) ?? null;
  const driver = unwrapOne(activeAssignment?.drivers);
  const vehicle = unwrapOne(activeAssignment?.vehicles);
  const passenger = unwrapOne(row.passengers);

  return {
    id: row.id,
    state: row.state,
    statusLabel: operationsTripStatusLabel(row.state, activeAssignment !== null),
    scheduledPickupAt: row.scheduled_pickup_at,
    passengerName: passenger?.display_name ?? "Unknown Passenger",
    pickupDescription: row.pickup_description,
    destinationDescription: row.destination_description,
    driverName: driver?.display_name ?? null,
    vehicleLabel: vehicle?.label ?? null,
  };
}

interface TripEventTripEmbedRow {
  passengers: NameRelation;
}
type TripEventTripRelation = TripEventTripEmbedRow | TripEventTripEmbedRow[] | null;

interface TripEventRow {
  id: string;
  event_type: string;
  occurred_at: string;
  trips: TripEventTripRelation;
}

export interface TodaysOperationsActivityEvent {
  id: string;
  label: string;
  occurredAt: string;
  passengerName: string | null;
}

function mapEventRow(row: TripEventRow): TodaysOperationsActivityEvent {
  const trip = unwrapOne(row.trips);
  const passenger = unwrapOne(trip?.passengers);
  return {
    id: row.id,
    label: operationsEventLabel(row.event_type),
    occurredAt: row.occurred_at,
    passengerName: passenger?.display_name ?? null,
  };
}

export interface TodaysOperationsData {
  dayBoundsUtc: { startUtc: string; endUtc: string };
  todayTrips: TodaysOperationsTrip[];
  needsAssignmentTrips: TodaysOperationsTrip[];
  completedTodayTrips: TodaysOperationsTrip[];
  activeTrips: TodaysOperationsTrip[];
  activityLog: TodaysOperationsActivityEvent[];
  summary: {
    todayCount: number;
    activeCount: number;
    needsAssignmentCount: number;
    completedTodayCount: number;
  };
}

const ACTIVE_TRIP_STATES = [
  "en_route_to_pickup",
  "arrived_at_pickup",
  "passenger_onboard",
  "en_route_to_destination",
  "arrived_at_destination",
];

const ACTIVITY_LOG_LIMIT = 20;

export async function getTodaysOperations(organizationId: string, timezone: string): Promise<TodaysOperationsData> {
  const { startUtc, endUtc } = organizationDayBoundsUtc(new Date(), timezone);
  const startIso = startUtc.toISOString();
  const endIso = endUtc.toISOString();

  const supabase = await createServerSupabaseClient();

  const [todayResult, activeResult, eventsResult] = await Promise.all([
    supabase
      .from("trips")
      .select(TRIP_COLUMNS)
      .eq("organization_id", organizationId)
      .gte("scheduled_pickup_at", startIso)
      .lt("scheduled_pickup_at", endIso)
      .order("scheduled_pickup_at", { ascending: true })
      .returns<TripRow[]>(),
    supabase
      .from("trips")
      .select(TRIP_COLUMNS)
      .eq("organization_id", organizationId)
      .in("state", ACTIVE_TRIP_STATES)
      .order("scheduled_pickup_at", { ascending: true, nullsFirst: false })
      .returns<TripRow[]>(),
    supabase
      .from("trip_events")
      .select(
        "id, event_type, occurred_at, trips!trip_events_trip_id_organization_id_fkey(passengers!trips_passenger_id_organization_id_fkey(display_name))",
      )
      .eq("organization_id", organizationId)
      .gte("occurred_at", startIso)
      .lt("occurred_at", endIso)
      .order("occurred_at", { ascending: false })
      .limit(ACTIVITY_LOG_LIMIT)
      .returns<TripEventRow[]>(),
  ]);

  if (todayResult.error) {
    throw new Error(`Failed to load today's trips: ${todayResult.error.message}`);
  }
  if (activeResult.error) {
    throw new Error(`Failed to load active trips: ${activeResult.error.message}`);
  }
  if (eventsResult.error) {
    throw new Error(`Failed to load today's activity log: ${eventsResult.error.message}`);
  }

  const todayTrips = (todayResult.data ?? []).map(mapTripRow);
  const activeTrips = (activeResult.data ?? []).map(mapTripRow);
  const activityLog = (eventsResult.data ?? []).map(mapEventRow);

  const needsAssignmentTrips = todayTrips.filter((trip) => trip.state === "scheduled" && trip.driverName === null);
  const completedTodayTrips = todayTrips.filter((trip) => trip.state === "completed");

  return {
    dayBoundsUtc: { startUtc: startIso, endUtc: endIso },
    todayTrips,
    needsAssignmentTrips,
    completedTodayTrips,
    activeTrips,
    activityLog,
    summary: {
      todayCount: todayTrips.length,
      activeCount: activeTrips.length,
      needsAssignmentCount: needsAssignmentTrips.length,
      completedTodayCount: completedTodayTrips.length,
    },
  };
}

/** Re-exported for callers that only need the state-membership check (e.g. a future Dispatch Board), not the full query. */
export { isActiveTripState };
