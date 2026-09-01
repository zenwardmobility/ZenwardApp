# Zenward Platform — Application Auth Boundary

**Work item:** P1-E3-S1 — Authentication, Session & Role Routing Foundation
**Status:** Implemented and verified. Complements every database-layer security document this project has produced (rls-model.md, mutation-authorization.md, driver-data-minimization.md) — this document is specifically about the application layer sitting in front of them.
**Last updated:** 2026-09-01

## Authentication ≠ authorization

A valid Supabase Auth session proves *who* someone is. It proves nothing about *what* they may do — that is resolved fresh, every request, from live `memberships`/`drivers` state, exactly as every prior database-security phase established. This layer does not weaken that principle; it is the first layer that actually *exercises* it from real application code instead of a SQL-simulation harness.

Concretely: `requireUser()` only confirms a session exists. `requireOperationsAccess()`/`requireDriverAccess()` are separate, subsequent steps that resolve Membership/role/Driver-linkage independently — a signed-in user with no Membership anywhere reaches `/access-unavailable`, not a default surface.

## Browser vs. server Supabase clients

Two client constructors, never a third variant scattered elsewhere:

- `src/lib/supabase/client.ts` — browser, publishable key.
- `src/lib/supabase/server.ts` — server (Server Components/Actions/Route Handlers), publishable key + the request's own session cookie.

Both use `@supabase/ssr`'s current, supported cookie-based pattern — no deprecated `auth-helpers` package, no hand-rolled token storage.

## No service-role use (work item §6/§17/§47)

`SUPABASE_SECRET_KEY` (or any service-role/secret key) is never referenced anywhere in `src/`. Every read/write in this layer — `getActiveMemberships()`, the Driver-linkage RPC call, the sign-in/sign-out calls — runs under the caller's own authenticated session and is subject to the exact same RLS/RPC authorization the database layer already enforces and has tested exhaustively. If a legitimately-authorized read were ever unexpectedly denied, the correct response is to report a backend contract mismatch, never to reach for a service-role shortcut — this principle held throughout implementation; no such mismatch was found.

## A real gap found and fixed during this phase

`getActiveMemberships()`'s first implementation queried `memberships` filtered only by `status='active'`, relying on RLS to scope the result to "my own rows." This is **not** what `memberships`' RLS actually guarantees: a second policy, `memberships_select_org_admin`, legitimately lets an `organization_admin` see every membership row in their own organization (their team) — additively alongside `memberships_select_self`, since RLS policies OR together rather than narrowing each other. The unfiltered query therefore returned every active Membership in any organization the caller administers, not just their own, for an org_admin caller specifically — which meant an Org A admin with no other Membership was incorrectly resolved as a *multi-org* user and routed to `/select-organization`.

Found by this phase's own integration testing (`ROLE-1` initially failed against real data, not a mock), not assumed safe from RLS alone — exactly the caution work item §17 calls for, applied to a subtler case than a simple access denial. Fixed by adding an explicit `.eq("user_id", user.id)` filter; RLS remains the enforcing layer underneath, this filter is what makes the *query's own intent* ("my organizations") match what it actually asks for.

## Cookie/session model

- **Auth session**: managed entirely by `@supabase/ssr` via `sb-*` cookies — never manually constructed, never stored in `localStorage`, never placed in a URL query parameter outside the one-time OAuth-style callback pattern (not used in this phase — email/password needs no callback route at all).
- **Organization context**: `zw_org_context`, httpOnly, `sameSite=lax`. Names a REQUESTED organization only — see "Organization context" in [auth-session-routing.md](../product/auth-session-routing.md) for why this is never trusted as authorization by itself.

## Live Membership requirement

Every protected request re-resolves Membership/role/Driver-linkage from the database. Nothing is cached in a session claim, a cookie, or module-level state across requests. Verified with the mandatory same-session revocation tests (work item §35/§36/§55) — see [application-auth-test-matrix.md](./application-auth-test-matrix.md).

## Role-change behavior

A role change takes effect on the resolving user's very next request, using the same session — no sign-out/sign-in required. A user moved from `dispatcher` to `driver` loses Operations access immediately and is routed to the surface their new role actually grants (`/driver`, or the account-setup state if no Driver row exists yet) rather than a bare denial.

## Redirect safety

`isSafeRedirectPath()` (`src/lib/auth/redirect.ts`) is an **allowlist**, not a denylist: only a single-leading-slash path built from `[A-Za-z0-9\-_/]` (plus a simple `?key=value&...` query segment) is accepted. This rejects, by construction rather than by enumerating attacks: protocol-relative URLs (`//evil.example`), any absolute URL of any scheme (`https://…`, `javascript:…`, `data:…`), and backslash tricks. Every `next`/`returnTo` value — the `/sign-in?next=` query parameter, the hidden form field it becomes, the value `selectOrganizationAction` reads — is validated through this single function before ever being passed to `redirect()`. Verified with real malicious values submitted through both the query string and a real POST to the actual sign-in Server Action (`REDIRECT-SAFETY`, `SIGNINFORM-4`).

## Route guard philosophy

`requireOperationsAccess()`/`requireDriverAccess()` (`src/lib/auth/authorization.ts`) are narrow, single-purpose functions — not a generic `authorizeEverything()` (work item §29). They exist to **improve navigation UX and prevent obviously invalid routing** (send a Driver to `/driver` instead of a confusing Operations 403, resolve `/` to the right landing page without a client-side flash). They are explicitly **not** a reimplementation of the database's RLS/RPC authorization, and never attempted to become one (work item §30) — every data read or mutation this application will eventually perform remains independently enforced by the exact same database layer every prior phase built, tested, and hardened. If this layer had a bug that let someone reach `/operations/trips/new`, the database's own `create_trip` RPC would still refuse an unauthorized caller — this layer being wrong would be a UX defect, not a security breach, by design.

## Redirect-loop prevention

The one case with real loop potential — a `driver` Membership with no linked Driver row — is handled by returning a discriminated result and rendering an inline state, never by redirecting back into the same guard (work item §60). Every other redirect target (`/sign-in`, `/select-organization`, `/access-unavailable`, `/operations`, `/driver`) is a strict, one-directional destination from any given denial reason — verified structurally (no test in the 41-check integration suite ever needed more than 2 redirect hops to reach a terminal `200`).
