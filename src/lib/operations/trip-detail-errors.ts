/**
 * Narrow ZW-code → user-facing message mapping for Operations Trip Detail
 * mutations (P1-E3-S6, work item §26) — mirrors `dispatch-errors.ts`'s
 * established pattern. Never exposes a ZW code, SQLSTATE, or raw
 * PostgREST error text to an Operations user.
 */
export type TripDetailErrorCode =
  | "UNAUTHORIZED"
  | "NOT_FOUND"
  | "ILLEGAL_STATE"
  | "INVALID_INPUT"
  | "UNKNOWN";

const TRIP_DETAIL_ERROR_MESSAGE: Record<TripDetailErrorCode, string> = {
  UNAUTHORIZED: "Your session is no longer valid. Sign in again.",
  NOT_FOUND: "This trip is no longer available.",
  ILLEGAL_STATE: "This action is no longer available — the trip's state has changed.",
  INVALID_INPUT: "Please provide the required information and try again.",
  UNKNOWN: "Something went wrong. Try again.",
};

/**
 * Maps a real ZW code — `cancel_trip`/`record_no_show`'s own errcode
 * contract (see supabase/migrations/20260831100200_controlled_trip_
 * mutations.sql) — to a narrow, user-safe category. Every branch
 * corresponds to a code these RPCs actually raise; none is guessed.
 */
export function mapTripDetailError(code: string | undefined): TripDetailErrorCode {
  switch (code) {
    case "ZW001":
      return "UNAUTHORIZED";
    case "ZW002":
      return "NOT_FOUND";
    case "ZW004":
      return "ILLEGAL_STATE";
    case "ZW006":
      return "INVALID_INPUT";
    default:
      return "UNKNOWN";
  }
}

export function tripDetailErrorMessage(code: TripDetailErrorCode): string {
  return TRIP_DETAIL_ERROR_MESSAGE[code];
}
