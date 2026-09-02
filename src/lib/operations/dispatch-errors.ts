/**
 * Narrow ZW-code → user-facing message mapping for Dispatch assignment
 * mutations (P1-E3-S5, work item §27) — mirrors src/lib/driver/errors.ts's
 * established pattern. Never exposes a ZW code, SQLSTATE, or raw
 * PostgREST error text to an Operations user.
 */
export type DispatchErrorCode =
  | "UNAUTHORIZED"
  | "NOT_FOUND"
  | "ILLEGAL_STATE"
  | "ASSIGNMENT_CONFLICT"
  | "INVALID_DRIVER_OR_VEHICLE"
  | "UNKNOWN";

const DISPATCH_ERROR_MESSAGE: Record<DispatchErrorCode, string> = {
  UNAUTHORIZED: "Your session is no longer valid. Sign in again.",
  NOT_FOUND: "This trip is no longer available.",
  ILLEGAL_STATE: "This trip can no longer be assigned or reassigned.",
  ASSIGNMENT_CONFLICT:
    "This trip's assignment just changed. The board has been refreshed with the current assignment.",
  INVALID_DRIVER_OR_VEHICLE: "That driver or vehicle is no longer available. Choose another.",
  UNKNOWN: "Something went wrong. Try again.",
};

/**
 * Maps a real ZW code (assign_trip/reassign_trip's own errcode contract —
 * see supabase/migrations/20260831100200_controlled_trip_mutations.sql)
 * to a narrow, user-safe category. Never inferred/guessed — every branch
 * corresponds to a code the RPCs actually raise.
 */
export function mapDispatchError(code: string | undefined): DispatchErrorCode {
  switch (code) {
    case "ZW001":
      return "UNAUTHORIZED";
    case "ZW002":
      return "NOT_FOUND";
    case "ZW004":
      return "ILLEGAL_STATE";
    case "ZW005":
      return "ASSIGNMENT_CONFLICT";
    case "ZW006":
      return "INVALID_DRIVER_OR_VEHICLE";
    default:
      return "UNKNOWN";
  }
}

export function dispatchErrorMessage(code: DispatchErrorCode): string {
  return DISPATCH_ERROR_MESSAGE[code];
}
