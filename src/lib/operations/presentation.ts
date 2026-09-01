/**
 * Operations-facing presentation derivations for Today's Operations
 * (P1-E3-S4). Parallels src/lib/driver/trip-presentation.ts's role for the
 * Driver surface — a single place to look for how a canonical Trip state
 * becomes a screen label, not logic re-derived per component. Kept as its
 * own module rather than imported from the Driver module: the two are
 * different bounded contexts (Operations sees every Trip in the
 * organization and needs an "unassigned" concept the Driver surface never
 * encounters — a Driver only ever sees Trips they hold an assignment on),
 * and the small time-formatting helpers below are deliberately duplicated
 * rather than reached-into from `driver/` to keep that boundary clean (see
 * ZD-129). Neither module is a stored Trip state — see lifecycle-model.md
 * §C; both remain UI groupings over the same 9 canonical states.
 */

/**
 * The exact label strings TRIP_STATUS_MAP (src/components/ui/TripStatus.tsx)
 * already anticipates for Operations surfaces — component-inventory.md
 * confirmed this mapping exists before any of this phase's code was
 * written, not coincidentally matching it after the fact. `state='scheduled'`
 * is genuinely ambiguous without assignment context (unlike the Driver
 * surface, where it always means "Assigned" — a Driver never sees an
 * unassigned Trip) — hence the second `hasActiveAssignment` parameter.
 *
 * This is the plain lifecycle status (matches the reference's Upcoming
 * Trips STATUS column: an assigned-but-not-started Trip reads "Assigned",
 * an unassigned one reads "Scheduled") — distinct from the "Needs
 * Assignment" ISSUE label used only in the Needs Attention panel
 * (`needsAssignmentIssueLabel` below). Conflating the two into one column
 * would duplicate a warning badge as the primary status everywhere a Trip
 * appears; the reference itself keeps them visually and lexically separate.
 */
export function operationsTripStatusLabel(state: string, hasActiveAssignment: boolean): string {
  if (state === "scheduled") return hasActiveAssignment ? "Assigned" : "Scheduled";
  if (state === "en_route_to_pickup" || state === "en_route_to_destination") return "En Route";
  if (state === "arrived_at_pickup" || state === "arrived_at_destination") return "Arrived";
  if (state === "passenger_onboard") return "Passenger Onboard";
  if (state === "completed") return "Completed";
  if (state === "cancelled") return "Cancelled";
  if (state === "no_show") return "No Show";
  return state;
}

/** The 5 non-terminal, non-"scheduled" states — a Trip in one of these is, by construction, structurally guaranteed to carry an active assignment (lifecycle-model.md §C: nothing progresses past `scheduled` without one). */
const ACTIVE_STATES = new Set([
  "en_route_to_pickup",
  "arrived_at_pickup",
  "passenger_onboard",
  "en_route_to_destination",
  "arrived_at_destination",
]);

export function isActiveTripState(state: string): boolean {
  return ACTIVE_STATES.has(state);
}

/** "8:30 AM" style formatting, in the given IANA timezone. Deliberately duplicated from src/lib/driver/trip-presentation.ts — see this module's own doc comment. */
export function formatOperationsTime(iso: string | null, timezone: string): string {
  if (!iso) return "Time TBD";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "Time TBD";
  return new Intl.DateTimeFormat("en-US", { hour: "numeric", minute: "2-digit", timeZone: timezone }).format(date);
}

/** "Saturday, August 29" style formatting, in the given IANA timezone. */
export function formatOperationsLongDate(date: Date, timezone: string): string {
  return new Intl.DateTimeFormat("en-US", { weekday: "long", month: "long", day: "numeric", timeZone: timezone }).format(date);
}

/**
 * Humanized Activity Log label for a `trip_events.event_type` value — the
 * exact allow-listed vocabulary from the trip_events CHECK constraint
 * (supabase/migrations/20260830131200_trip_events.sql), not a guessed or
 * partial set. An unrecognized value falls back to the raw string rather
 * than guessing, matching the same convention as driverTripStateLabel.
 */
const EVENT_TYPE_LABELS: Record<string, string> = {
  trip_scheduled: "Trip scheduled",
  en_route_to_pickup: "Driver en route to pickup",
  arrived_at_pickup: "Driver arrived at pickup",
  passenger_onboard: "Passenger onboard",
  en_route_to_destination: "Driver en route to destination",
  arrived_at_destination: "Driver arrived at destination",
  trip_completed: "Trip completed",
  trip_cancelled: "Trip cancelled",
  no_show_recorded: "No-show recorded",
  driver_assigned: "Driver assigned",
  driver_reassigned: "Driver reassigned",
  assignment_ended: "Assignment ended",
  note_added: "Note added",
  exception_flagged: "Exception flagged",
  exception_resolved: "Exception resolved",
  request_converted_to_trip: "Request converted to trip",
};

export function operationsEventLabel(eventType: string): string {
  return EVENT_TYPE_LABELS[eventType] ?? eventType;
}
