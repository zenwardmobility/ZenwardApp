/**
 * Narrow ZW-code → tracker-status mapping for `driver_record_location`
 * (P1-E3-S7A) — mirrors `src/lib/driver/errors.ts`'s established pattern.
 * Deliberately not a scary "error" vocabulary: a failed location post is
 * an expected, ordinary event most of the time (the Trip progressed past
 * the eligible window, or was reassigned) — the tracker degrades quietly
 * (work item §21), it never surfaces a raw ZW code, SQLSTATE, or Postgres
 * message, and it never blocks Trip lifecycle actions.
 */
export type DriverLocationErrorCode = "INELIGIBLE" | "REVOKED" | "NOT_FOUND" | "INVALID" | "UNKNOWN";

/** Maps a real ZW code (driver_record_location's own errcode contract) to a narrow, safe category — never inferred, every branch corresponds to a code the RPC actually raises. */
export function mapDriverLocationError(code: string | undefined): DriverLocationErrorCode {
  switch (code) {
    case "ZW001":
      return "REVOKED"; // reassigned away, or no active assignment right now
    case "ZW002":
      return "NOT_FOUND"; // never assigned, foreign org, inactive Membership/Driver
    case "ZW004":
      return "INELIGIBLE"; // Trip's current lifecycle state is outside the tracking window
    case "ZW006":
      return "INVALID"; // malformed coordinates (should not happen from real browser geolocation)
    default:
      return "UNKNOWN";
  }
}

/** Whether this error means tracking should stop entirely for this Trip (vs. a transient failure worth retrying on the next tick). */
export function isTerminalLocationError(code: DriverLocationErrorCode): boolean {
  return code === "INELIGIBLE" || code === "REVOKED" || code === "NOT_FOUND";
}
