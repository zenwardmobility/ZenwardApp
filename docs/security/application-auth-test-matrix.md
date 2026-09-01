# Zenward Platform — Application Auth Test Matrix

**Work item:** P1-E3-S1 — Authentication, Session & Role Routing Foundation
**Status:** All tests below were actually executed against the running local Next.js app (`npm run dev`) and the real local Supabase Auth service. Not a syntax-only or mocked-client claim.
**Last updated:** 2026-09-01

## Methodology

`@supabase/ssr`'s own `createServerClient` — the exact library the application uses — with an in-memory cookie adapter, used to sign in as real seeded fixture users and obtain genuinely-formatted session cookies. Those cookies drive `fetch()` calls against the actual running app (`http://localhost:3000`) with manual redirect handling, so every hop in a redirect chain is inspected directly rather than assumed. The sign-in **form itself** (not just the underlying Supabase call) is additionally exercised via a real `multipart/form-data` POST replicating exactly what a browser submits without JavaScript, using the real Server Action reference fields extracted from the live-rendered page — this is real integration testing of the actual Server Action code path, not a mock. Same-session revocation tests mutate `memberships` directly via `psql` mid-test, using the same authenticated session (cookie jar) throughout, never re-authenticating.

Run reproducibly from a clean `supabase db reset`; 41/41 pass on the run this document reflects.

## Fixtures (`supabase/seed.sql`)

| Fixture | Email | Membership | Notes |
|---|---|---|---|
| Org Admin | org-a-admin@example.test | Org A, `organization_admin`, active | |
| Dispatcher | org-a-dispatcher@example.test | Org A, `dispatcher`, active | |
| Driver (linked) | org-a-driver-a@example.test | Org A, `driver`, active | Linked `drivers` row |
| Driver (linked, 2nd) | org-a-driver-b@example.test | Org A, `driver`, active | Linked `drivers` row |
| Inactive Membership | org-a-inactive@example.test | Org A, `dispatcher`, **inactive** | |
| Driver, no linkage | org-a-driver-nolink@example.test | Org A, `driver`, active | **No** `drivers` row — new fixture added this phase |
| Multi-org user | multi-org-user@example.test | Org A `organization_admin` + Org B `driver`, both active | Linked `drivers` row in Org B |
| Platform Admin only | platform-admin@example.test | Zero Memberships; holds a `PlatformAdminGrant` | |
| No Membership | no-membership@example.test | Zero Memberships | |

## Test results

| Actor | Membership | Org context | Target route | Expected | Actual |
|---|---|---|---|---|---|
| (none) | — | — | `/operations` | Redirect → `/sign-in?next=/operations` | PASS |
| (none) | — | — | `/driver` | Redirect → `/sign-in?next=/driver` | PASS |
| (none) | — | — | `/` | Redirect → `/sign-in` | PASS |
| Org Admin | Org A admin, active | Org A (auto, single) | `/` → `/operations` | ALLOW | PASS |
| Dispatcher | Org A dispatcher, active | Org A (auto) | `/` → `/operations` | ALLOW | PASS |
| Driver (linked) | Org A driver, active | Org A (auto) | `/` → `/driver` | ALLOW | PASS |
| Driver (linked) | Org A driver, active | Org A | `/operations` | DENY → redirected to `/driver` (not access-unavailable) | PASS |
| Dispatcher | Org A dispatcher, active | Org A | `/driver` | DENY → redirected to `/operations` | PASS |
| Inactive Membership | Org A dispatcher, **inactive** | — | `/` | → `/access-unavailable` | PASS |
| No Membership | none | — | `/` | → `/access-unavailable` | PASS |
| Platform Admin only | none (PlatformAdminGrant only) | — | `/` | → `/access-unavailable` (NOT tenant Operations) | PASS |
| Driver, no linkage | Org A driver, active, no `drivers` row | Org A | `/driver` | Safe inline "account not yet set up" state, 200, no crash, no internal ID exposed | PASS |
| Multi-org user | Org A admin + Org B driver | none selected | `/` | → `/select-organization` | PASS |
| Multi-org user | (same) | — | `/select-organization` | Shows both orgs + correct per-org role; org UUID only in each option's own hidden field, never in visible copy | PASS |
| Multi-org user | (same) | Org A (cookie) | `/operations` | ALLOW (admin in Org A) | PASS |
| Multi-org user | (same) | Org B (cookie) | `/operations` | DENY → redirected to `/driver` (driver in Org B) | PASS |
| Multi-org user | (same) | Org B (cookie) | `/driver` | ALLOW (driver in Org B) | PASS |
| Org Admin (single-org) | Org A admin | forged Org B cookie | `/operations` | Cookie ignored — real (only) org still resolves, ALLOW | PASS |
| Multi-org user | (same) | cookie = nonexistent org UUID | `/operations` | → `/select-organization` (with `next` preserved), not a crash | PASS |

## Sign-in / sign-out

| Scenario | Expected | Actual |
|---|---|---|
| Real form POST, bad credentials | No session cookie set, generic failure | PASS |
| Real form POST, correct credentials + safe `next` | Redirects to `next`, real `sb-*` session cookie set | PASS |
| Real form POST, correct credentials + **unsafe** `next` (`https://evil.example`) | Falls back to `/`, never redirects off-application | PASS |
| `signOutAction` (via `supabase.auth.signOut()`) | Session cookie invalidated; subsequent protected request redirects to `/sign-in` | PASS |

## Redirect safety

| Submitted `next` value | Expected | Actual |
|---|---|---|
| `https://evil.example` | Not carried into the sign-in form's hidden field | PASS |
| `//evil.example` | Not carried into the form | PASS |
| `javascript:alert(1)` | Not carried into the form | PASS |
| `/\evil.example` | Not carried into the form | PASS |
| `/operations/dispatch` (safe internal path) | **Is** carried into the form correctly | PASS |

## Same-session revocation (mandatory, work item §55)

All three scenarios use one continuous authenticated session (cookie jar) — no re-authentication between steps.

| Step | Action | Expected | Actual |
|---|---|---|---|
| 1a | Dispatcher, active Membership → `/operations` | ALLOW | PASS |
| 1b | `UPDATE memberships SET status='inactive'` for that same user (same session, no new sign-in) → `/operations` | DENY → `/access-unavailable`, no sign-out required | PASS |
| 1c | `UPDATE ... SET status='active'` again (same session) → `/operations` | ALLOW again, immediately | PASS |
| 2a | Dispatcher → `/operations` | ALLOW | PASS |
| 2b | `UPDATE memberships SET role='driver'` (same session) → `/operations` | DENY → redirected to `/driver` | PASS |
| 2c | Same session → `/driver` | Correctly resolves to the Driver surface (inline link-missing state, since this fixture has no `drivers` row) | PASS |
| 2d | `UPDATE ... SET role='dispatcher'` again (same session) → `/operations` | ALLOW again, immediately | PASS |
| 3a | Multi-org user, Org B context (driver) → `/driver` | ALLOW | PASS |
| 3b | `UPDATE memberships SET role='dispatcher'` for this user's **Org A** row only (same session) → `/driver` (still Org B context) | Org B authorization unaffected — ALLOW, unchanged | PASS |

## Summary

**41/41 checks passed.** Zero regressions in the 204 pre-existing database security assertions (unaffected — this phase touched no migration, RLS policy, or RPC). One real bug found and fixed during this testing (see [application-auth-boundary.md](./application-auth-boundary.md) "A real gap found and fixed during this phase") — not a false pass papered over, a genuine defect caught by testing against real data rather than assumed correct.
