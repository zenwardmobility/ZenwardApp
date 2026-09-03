# Zenward Platform — Owner-Operator Mode

**Work item:** P1-E3-S9 — Operator Signup & Business Setup, §4
**Status:** Implemented — `link_self_as_driver`, the relaxed `/driver/*` route guard, the sidebar's conditional "Drive" item.
**Last updated:** 2026-09-03

Supports the reality that one person may genuinely be Owner + Dispatcher + Driver — without collapsing roles insecurely.

## 1. The two identity layers stay fully separate

Exactly as `docs/product/authorization-model.md` §B already established, before this phase existed:

```
Membership.role     — governs Operations authorization (organization_admin/dispatcher/driver)
drivers table        — governs Driver-execution authorization (a linked, active Driver row)
```

**"A Driver row existing does not imply an active Membership. An active Membership does not imply a linked Driver row."** This phase adds a THIRD legitimate combination to that existing principle: an active `organization_admin`/`dispatcher` Membership **plus** a linked, active Driver row, both for the same person, in the same organization. Membership.role is **never** changed by any part of this feature — an owner who links themselves as a driver is, for every Operations-authorization purpose, still exactly the `organization_admin` they were before.

## 2. `link_self_as_driver` — the controlled mutation

`link_self_as_driver(p_organization_id, p_display_name, p_phone)` — SECURITY DEFINER, requires an active Membership (any of the 3 roles) in the target org, and **only ever links `auth.uid()` to a Driver row for themselves** — there is no parameter that could target a different person. Idempotent: a repeat call for the same person+org reuses the existing Driver row rather than creating a duplicate.

This is deliberately separate from the driver-invite/redemption flow (`docs/product/driver-invite-linkage-model.md`) — self-linking is a same-person, self-service action; inviting is an admin-acting-on-someone-else's-behalf action, and carries the correspondingly heavier verification (email match, token, admin-only creation).

## 3. The real gap this phase found and fixed: `current_driver_id()`

**Before this phase**, `current_driver_id()` (the function every Driver-scoped RLS policy and RPC ultimately calls) required the caller's Membership to have `role = 'driver'` specifically — a deliberate fix from an earlier phase (P1-E2-S3, ZD-100) that closed a real vulnerability: an inactive Membership retaining Driver access through a stale `drivers.status = 'active'` row.

That fix, while correct at the time, made Owner-Operator Mode structurally impossible: an `organization_admin` who self-links a Driver row keeps `role = 'organization_admin'` (by design, §1) — so `role = 'driver'` could never be true for them, and every driver-scoped check would deny them regardless of a real, active, correctly-linked Driver row. Found via direct live testing while building this feature, not assumed.

**The fix** (`20260903100700_current_driver_id_owner_operator_mode.sql`) relaxes the check from `m.role = 'driver'` to simply `m.status = 'active'` (any role) — preserving ZD-100's actual security property exactly (an inactive Membership, of ANY role, still denies Driver access, verified via a re-run of the original DETAIL-6 test plus a new dedicated test in `operator_onboarding_tests.sql`), while correctly allowing the one new case this phase deliberately introduces. See ZD-194.

## 4. Route guard relaxation — navigation only, never a new security boundary

`requireDriverAccess` (`src/lib/auth/authorization.ts`) previously redirected any non-`driver`-role Membership straight to `/operations` before ever checking for a linked Driver row. It now also lets `organization_admin`/`dispatcher` roles through to the SAME `driver_get_profile` RPC check every Driver already goes through — if it resolves (a real linked Driver row exists), they see `/driver/*`; if not, they're redirected to `/operations` exactly as before. **This changes navigation only** — the actual data access `/driver/*` performs is, and always was, gated entirely by `current_driver_id()`/`driver_get_profile` resolving from the real `drivers` table, never by Membership.role.

## 5. The "Drive" sidebar item

`OperationsSidebar` renders one additional nav item, "Drive" (linking to `/driver`), **only** when `current_driver_id()` genuinely resolves for the signed-in person in the current org — a real, live check (`src/app/operations/layout.tsx`), never inferred from `business_stage` or any other proxy. Appended to the existing 7-item nav, never replacing anything (work item §12: "Same platform, progressive emphasis").

## 6. Returning to Operations from the Driver view

A dual-hat person's `/driver/*` header shows a "Back to Operations" icon (in addition to the ordinary Sign Out) — shown only when `Membership.role !== 'driver'` for the resolved org (i.e., only for someone who reached `/driver` via the relaxed guard as their SECOND hat, not an ordinary Driver-only account, who has no "Operations" to go back to).

## 7. Verified live

`docs/reports/P1-E3-S9-operator-signup-business-setup-report.txt` — a real signup → business stage → business basics → vehicle → "yes, I also drive" → the owner reaching `/driver` and seeing the real Driver Today screen → the "Back to Operations" link working → their Membership role confirmed unchanged in the database throughout.
