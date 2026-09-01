/**
 * Stable application-level auth error vocabulary (work item §48) — never a
 * raw Supabase/Postgres message or SQLSTATE surfaced to a user. Mirrors
 * the same design principle as the database's own ZW001-ZW006 contract
 * (docs/data/mutation-api.md): a small, named, stable set a UI can branch
 * on, never sentence-parsed.
 */
export const AUTH_ERROR = {
  INVALID_CREDENTIALS: "INVALID_CREDENTIALS",
  SESSION_EXPIRED: "SESSION_EXPIRED",
  NO_ACTIVE_MEMBERSHIP: "NO_ACTIVE_MEMBERSHIP",
  ORG_CONTEXT_INVALID: "ORG_CONTEXT_INVALID",
  ROLE_FORBIDDEN: "ROLE_FORBIDDEN",
  DRIVER_LINK_MISSING: "DRIVER_LINK_MISSING",
} as const;

export type AuthErrorCode = (typeof AUTH_ERROR)[keyof typeof AUTH_ERROR];

/** Safe, generic, user-facing copy — never distinguishes "no such account" from "wrong password" (work item §13). */
export const AUTH_ERROR_MESSAGE: Record<AuthErrorCode, string> = {
  INVALID_CREDENTIALS: "That email and password combination doesn't match our records.",
  SESSION_EXPIRED: "Your session has expired. Please sign in again.",
  NO_ACTIVE_MEMBERSHIP: "Your account does not currently have access to a Zenward organization.",
  ORG_CONTEXT_INVALID: "That organization is not available for your account.",
  ROLE_FORBIDDEN: "Your account does not have access to this area.",
  DRIVER_LINK_MISSING: "Your account is not yet linked to a driver profile.",
};
