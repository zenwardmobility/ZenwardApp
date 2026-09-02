import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { organizationDayBoundsUtc } from "./day-bounds";
import { isActiveTripState, operationsTripStatusLabel, operationsEventLabel } from "./presentation";
import { getLatestLocationsByTrip } from "./live-location";
import { evaluateTripAssurance, needsAttention, type TripAssuranceResult } from "./trip-assurance";

/**
 * Server-side data access boundary for Today's Operations (P1-E3-S4, work
 * item §51; extended P1-E3-S8 for the real attention queue). Organization-
 * scoped, explicit columns (never `select("*")`), timezone-aware
 * grouping, no service role, no presentation JSX. Every query below is
 * additionally filtered by `organization_id` explicitly, not left to RLS
 * alone to narrow — the same defense-in-depth convention
 * `getActiveMemberships()` (src/lib/auth/membership.ts) already follows.
 *
 * Query architecture (work item §40 of P1-E3-S8 — avoid N+1, no
 * `select("*")`): the original 3 queries (today's trips / active trips /
 * today's events) still run first, in parallel, unchanged. Their RESULT
 * (the deduplicated union of today's + active trip ids) then drives a
 * SECOND, small parallel phase — open-exception rows and assignment-
 * scoped latest locations, each scoped to exactly that candidate id list,
 * never a broader per-organization scan. This mirrors the exact two-phase
 * pattern P1-E3-S7A's own `getDispatchBoardData()` already established
 * (fetch trips, then fetch location only for the resulting eligible-state
 * ids) — reused, not reinvented.
 */

const TRIP_COLUMNS =
  "id, state, scheduled_pickup_at, pickup_description, destination_description, " +
  "passengers!trips_passenger_id_organization_id_fkey(display_name), " +
  "trip_assignments!trip_assignments_trip_id_organization_id_fkey(id, ended_at, " +
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
  id: string;
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

const ELIGIBLE_LOCATION_TRACKING_STATES = new Set([
  "en_route_to_pickup",
  "arrived_at_pickup",
  "passenger_onboard",
  "en_route_to_destination",
  "arrived_at_destination",
]);

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
  activeAssignmentId: string | null;
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
    activeAssignmentId: activeAssignment?.id ?? null,
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

/** One attention-queue row (work item §28) — the Trip's own real fields plus its single, deterministic primary assurance reason. */
export interface TodaysOperationsAttentionItem {
  trip: TodaysOperationsTrip;
  assurance: TripAssuranceResult;
}

export interface TodaysOperationsData {
  dayBoundsUtc: { startUtc: string; endUtc: string };
  todayTrips: TodaysOperationsTrip[];
  needsAssignmentTrips: TodaysOperationsTrip[];
  completedTodayTrips: TodaysOperationsTrip[];
  activeTrips: TodaysOperationsTrip[];
  activityLog: TodaysOperationsActivityEvent[];
  /** The real attention queue (P1-E3-S8, work item §27) — one row per Trip needing attention, deduplicated (work item §29), ordered by deterministic priority. */
  attentionItems: TodaysOperationsAttentionItem[];
  summary: {
    todayCount: number;
    activeCount: number;
    needsAssignmentCount: number;
    completedTodayCount: number;
    attentionCount: number;
    onTrackCount: number;
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

/** Deterministic queue ordering (work item §7) — mirrors evaluateTripAssurance's own priority exactly. */
const PRIORITY_RANK: Record<string, number> = {
  OPEN_EXCEPTION: 0,
  NEEDS_ASSIGNMENT: 1,
  LOCATION_STALE: 2,
  LOCATION_UNAVAILABLE: 3,
};

export async function getTodaysOperations(organizationId: string, timezone: string): Promise<TodaysOperationsData> {
  const now = new Date();
  const { startUtc, endUtc } = organizationDayBoundsUtc(now, timezone);
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

  // The candidate set for assurance evaluation — today's trips ∪ active
  // trips, deduplicated by id (a Trip can legitimately appear in both).
  const candidateTrips = new Map<string, TodaysOperationsTrip>();
  for (const trip of todayTrips) candidateTrips.set(trip.id, trip);
  for (const trip of activeTrips) candidateTrips.set(trip.id, trip);
  const candidateIds = [...candidateTrips.keys()];
  const eligibleTrackingIds = candidateIds.filter((id) => ELIGIBLE_LOCATION_TRACKING_STATES.has(candidateTrips.get(id)!.state));

  const [exceptionsResult, locationsByTrip] = await Promise.all([
    candidateIds.length > 0
      ? supabase
          .from("trip_exceptions")
          .select("id, trip_id, exception_type, created_at")
          .eq("organization_id", organizationId)
          .eq("status", "open")
          .in("trip_id", candidateIds)
      : Promise.resolve({ data: [], error: null }),
    getLatestLocationsByTrip(organizationId, eligibleTrackingIds),
  ]);

  if (exceptionsResult.error) {
    throw new Error(`Failed to load open exceptions: ${exceptionsResult.error.message}`);
  }

  const openExceptionCountByTrip = new Map<string, number>();
  for (const row of exceptionsResult.data ?? []) {
    openExceptionCountByTrip.set(row.trip_id, (openExceptionCountByTrip.get(row.trip_id) ?? 0) + 1);
  }

  const attentionItems: TodaysOperationsAttentionItem[] = [];
  let onTrackCount = 0;

  for (const trip of candidateTrips.values()) {
    // Assignment-scoped location (P1-E3-S7A discipline, work item §15): a
    // location row is only ever treated as current if its assignment_id
    // matches this Trip's own current active assignment — a former
    // Driver's fresh location must never make a new assignment look
    // healthy.
    const location = locationsByTrip.get(trip.id) ?? null;
    const latestLocationRecordedAt =
      location && trip.activeAssignmentId && location.assignmentId === trip.activeAssignmentId
        ? location.recordedAt
        : null;

    const assurance = evaluateTripAssurance(
      {
        state: trip.state,
        hasActiveAssignment: trip.activeAssignmentId !== null,
        isEligibleTrackingState: ELIGIBLE_LOCATION_TRACKING_STATES.has(trip.state),
        latestLocationRecordedAt,
        openExceptionCount: openExceptionCountByTrip.get(trip.id) ?? 0,
      },
      now,
    );

    if (needsAttention(assurance.code)) {
      attentionItems.push({ trip, assurance });
    } else if (assurance.code === "ON_TRACK") {
      onTrackCount++;
    }
  }

  attentionItems.sort((a, b) => {
    const rankDiff = (PRIORITY_RANK[a.assurance.code] ?? 99) - (PRIORITY_RANK[b.assurance.code] ?? 99);
    if (rankDiff !== 0) return rankDiff;
    // Stable secondary order: earliest scheduled pickup first, within the
    // same priority tier — never an arbitrary/database-row-order pick
    // (work item §7).
    return (a.trip.scheduledPickupAt ?? "").localeCompare(b.trip.scheduledPickupAt ?? "");
  });

  return {
    dayBoundsUtc: { startUtc: startIso, endUtc: endIso },
    todayTrips,
    needsAssignmentTrips,
    completedTodayTrips,
    activeTrips,
    activityLog,
    attentionItems,
    summary: {
      todayCount: todayTrips.length,
      activeCount: activeTrips.length,
      needsAssignmentCount: needsAssignmentTrips.length,
      completedTodayCount: completedTodayTrips.length,
      attentionCount: attentionItems.length,
      onTrackCount,
    },
  };
}

/** Re-exported for callers that only need the state-membership check (e.g. a future Dispatch Board), not the full query. */
export { isActiveTripState };
