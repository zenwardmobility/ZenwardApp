/**
 * Narrow ZW-code → user-facing message mapping for `report_trip_exception`/
 * `resolve_trip_exception` (P1-E3-S8) — mirrors every other error-mapping
 * module in this codebase (dispatch-errors.ts, trip-detail-errors.ts,
 * new-trip-errors.ts). Never exposes a ZW code, SQLSTATE, or raw
 * Postgres/PostgREST message.
 */
export type TripExceptionErrorCode = "UNAUTHORIZED" | "NOT_FOUND" | "INVALID_INPUT" | "UNKNOWN";

const TRIP_EXCEPTION_ERROR_MESSAGE: Record<TripExceptionErrorCode, string> = {
  UNAUTHORIZED: "Your session is no longer valid. Sign in again.",
  NOT_FOUND: "This trip or issue is no longer available.",
  INVALID_INPUT: "Check the details entered and try again.",
  UNKNOWN: "Something went wrong. Try again.",
};

/** Maps a real ZW code (report_trip_exception's/resolve_trip_exception's own errcode contract) to a narrow, user-safe category. */
export function mapTripExceptionError(code: string | undefined): TripExceptionErrorCode {
  switch (code) {
    case "ZW001":
      return "UNAUTHORIZED";
    case "ZW002":
      return "NOT_FOUND";
    case "ZW006":
      return "INVALID_INPUT";
    default:
      return "UNKNOWN";
  }
}

export function tripExceptionErrorMessage(code: TripExceptionErrorCode): string {
  return TRIP_EXCEPTION_ERROR_MESSAGE[code];
}

/**
 * A restrained, explicit MVP exception-type list (P1-E3-S8, work item
 * §20/ZD-1xx) — `exception_type` remains genuinely free text at the
 * schema layer (no CHECK constraint, "taxonomy not yet finalized"); this
 * is an APPLICATION-layer convenience only, chosen deliberately after
 * inspecting the actual schema and product need, not merely copied from
 * the work item's own illustrative list without review. A future value
 * outside this set is not blocked by the database.
 *
 * P1-E3-S8B: moved here (from being defined locally inside
 * ReportIssueDialog.tsx, and separately re-listed as a bare Set in the
 * Operations Server Action file) so both the Operations dialog and the
 * new Driver-facing one (§37) share exactly one list — never two
 * independently-maintained copies of the same categories.
 */
export const EXCEPTION_TYPE_OPTIONS = [
  { value: "driver_issue", label: "Driver issue" },
  { value: "vehicle_issue", label: "Vehicle issue" },
  { value: "passenger_not_ready", label: "Passenger not ready" },
  { value: "pickup_issue", label: "Pickup issue" },
  { value: "facility_delay", label: "Facility delay" },
  { value: "route_issue", label: "Route issue" },
  { value: "other", label: "Other" },
];

export const EXCEPTION_TYPE_VALUES = new Set(EXCEPTION_TYPE_OPTIONS.map((o) => o.value));
