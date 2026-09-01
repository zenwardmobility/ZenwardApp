/**
 * Redirect-safety allowlist (work item §51). `next`/`returnTo` values are
 * user-influenced (a query param on /sign-in, a hidden form field) and
 * must never be usable to send a signed-in user off-application.
 *
 * Allowlist-based, not denylist-based: only an internal, single-leading-
 * slash path built from a restrictive character set is accepted. Rejects
 * protocol-relative (`//evil.example`), absolute URLs of any scheme
 * (`https://…`, `javascript:…`, `data:…`), backslash tricks, and anything
 * containing a colon at all — deliberately broader rejection than the
 * minimum needed, since the safe set of real internal paths this
 * application redirects to is small and well-known.
 */
const SAFE_REDIRECT_PATTERN = /^\/[A-Za-z0-9\-_/]*(?:\?[A-Za-z0-9\-_=&]*)?$/;

export function isSafeRedirectPath(path: unknown): path is string {
  if (typeof path !== "string" || path.length === 0) return false;
  if (path.startsWith("//")) return false;
  if (path.includes("\\")) return false;
  return SAFE_REDIRECT_PATTERN.test(path);
}

/** Returns `path` if safe, otherwise the given fallback (default `/`). */
export function safeRedirectPath(path: unknown, fallback = "/"): string {
  return isSafeRedirectPath(path) ? path : fallback;
}
