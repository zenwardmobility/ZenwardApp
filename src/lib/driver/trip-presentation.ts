/**
 * Driver-facing presentation derivations for canonical Trip state and time
 * (P1-E3-S2, timezone-corrected P1-E3-S2C). Single source of truth so a
 * later screen (Active Trip, Trips) reuses the same derivation rather than
 * re-deriving it independently (work item §17/§42 of P1-E3-S2, matching
 * ZD-089's "one place to look" principle already applied to the backend's
 * own transition table).
 *
 * These are UI groupings only — never a new stored Trip state (work item
 * §16 of P1-E3-S2). Canonical states remain exactly the 9 in
 * lifecycle-model.md §C.
 */

const DRIVER_STATE_LABELS: Record<string, string> = {
  scheduled: "Assigned",
  en_route_to_pickup: "Heading to Pickup",
  arrived_at_pickup: "At Pickup",
  passenger_onboard: "Passenger Onboard",
  en_route_to_destination: "Heading to Destination",
  arrived_at_destination: "At Destination",
  completed: "Completed",
  cancelled: "Cancelled",
  no_show: "No Show",
};

/**
 * `state='scheduled'` reads as "Assigned" here (not "Scheduled") because a
 * Driver only ever sees Trips they currently hold an active assignment on —
 * the "unassigned" derivation never applies from this vantage point
 * (confirmed: ui-data-action-map.md §6). Unknown/unexpected values fall
 * back to the raw value rather than guessing.
 */
export function driverTripStateLabel(state: string): string {
  return DRIVER_STATE_LABELS[state] ?? state;
}

/**
 * P1-E3-S2C: every function below takes an explicit IANA `timezone`
 * parameter — there is deliberately no default, no optional parameter, and
 * no fallback to the runtime's own local timezone. `trips.scheduled_pickup_at`/
 * `appointment_at` are `timestamptz` (absolute UTC-normalized instants);
 * "what time is this locally" and "what calendar day is this" both depend
 * entirely on WHERE the organization operates, never on where the Node
 * process happens to be running (P1-E3-S1's original implementation used
 * `Intl` with no `timeZone` override, which is correct only by coincidence
 * when server and organization share a timezone — see decision-register.md
 * ZD-11x and docs/product/operational-timezone.md). A caller that has no
 * timezone to pass has a bug to fix at the call site, not a default to
 * reach for here — TypeScript enforces this by making the parameter
 * required, not optional.
 */

/** "8:30 AM" style formatting, in the given IANA timezone — never a raw ISO string. */
export function formatTripTime(iso: string | null, timezone: string): string {
  if (!iso) return "Time TBD";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "Time TBD";
  return new Intl.DateTimeFormat("en-US", { hour: "numeric", minute: "2-digit", timeZone: timezone }).format(date);
}

/** "Saturday, August 29" style formatting, in the given IANA timezone. */
export function formatLongDate(date: Date, timezone: string): string {
  return new Intl.DateTimeFormat("en-US", { weekday: "long", month: "long", day: "numeric", timeZone: timezone }).format(date);
}

/**
 * The organization-local calendar date (`YYYY-MM-DD`) a given instant falls
 * on, in the given IANA timezone — the standards-based way to answer "what
 * day is this, there" without hand-rolling any DST/offset arithmetic
 * (work item §11). `en-CA` is used purely as a locale that happens to
 * format as `YYYY-MM-DD`, a directly comparable sortable string — not
 * because Canada is relevant here.
 */
function operationalDateKey(date: Date, timezone: string): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

/** Same organization-local calendar day, in the given IANA timezone — never the runtime's own local day. */
export function isSameOperationalDay(a: Date, b: Date, timezone: string): boolean {
  return operationalDateKey(a, timezone) === operationalDateKey(b, timezone);
}
