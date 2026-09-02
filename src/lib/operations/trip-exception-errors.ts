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
