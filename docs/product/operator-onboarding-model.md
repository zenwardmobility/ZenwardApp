# Zenward Platform — Operator Onboarding Model

**Work item:** P1-E3-S9 — Operator Signup & Business Setup
**Status:** Implemented — `/sign-up`, `/onboarding/*`, `signup_create_organization`, the onboarding checklist.
**Last updated:** 2026-09-03

Zenward's self-service path from "I run a transportation business" to "I have a usable, real Zenward organization" — for a 1–2 vehicle owner-operator, a growing 3–10 vehicle fleet, or an established 10+ vehicle operator alike. This document is the durable record of that design; see `docs/reports/P1-E3-S9-operator-signup-business-setup-report.txt` for the phase's verification evidence.

## 1. The flow

```
Sign Up
  → (email confirmation, only if the environment requires it — see §4)
  → Business Stage        /onboarding
  → Business Basics       /onboarding/basics
  → First Vehicle         /onboarding/vehicle          (skippable)
  → Owner-Driver choice   /onboarding/driver           (skippable)
  → First Facility        /onboarding/facility         (skippable)
  → First Passenger       /onboarding/passenger        (skippable)
  → First Trip            /operations/trips/new        (the real, existing New Trip screen — never duplicated)
  → Operations            /operations
```

Every step after Sign Up can be skipped ("Skip for now" / "Not right now") — nothing beyond the 4 fields collected at signup is mandatory. A skipped step simply leaves that item incomplete on the onboarding checklist (§3); the operator returns to it whenever they're ready, through the checklist's own links or by using the real Operations screens (Fleet/Facilities/Passengers/Drivers) directly.

## 2. Sign-up — what's collected and how it's created

**Collected:** full name, email, password, business name — exactly the 4 fields the work item specifies, nothing more.

**Created, atomically, in one transaction (`signup_create_organization`, a SECURITY DEFINER RPC — see `docs/product/onboarding-data-map.md` for the full mutation contract):**
1. The real Supabase Auth user, via `supabase.auth.signUp()` — the ordinary, already-tested auth path. Never a service-role-created account; no service-role credential is ever reachable from the browser (work item §2's own explicit requirement).
2. A `user_profiles` row (display name = the "full name" field).
3. A new `organizations` row (status `active`).
4. The signer-upper's own `memberships` row: `organization_admin`, `active`.

**Atomicity (work item §2 — "failed signup does not leave a broken partial organization/user state"):** the Postgres function body is one implicit transaction — if any step fails, all of it rolls back. The one thing that CANNOT be rolled back by this RPC is the auth user itself, since that's created by a separate, prior `signUp()` call — but that's by design, not a gap: an auth user with no organization yet is the exact same "authenticated, zero Membership" state the platform already handles safely (`/access-unavailable`), not a broken row. See ZD-193.

## 3. Business Stage — emphasis only, never security or schema

"How are you operating today?" (Starting / Growing / Established) is stored on `organizations.business_stage` — a plain, nullable, CHECK-constrained text column. It is:
- **Never** read by any RLS policy or mutation-authorization check (verified: `grep`-checked across every migration).
- **Never** a pricing input — no price is hard-coded anywhere in the application (work item §3's explicit prohibition; see `founding-operator-program.md` from P1-E3-S8C for the separate, business-side pricing conversation).
- **Never** a schema fork — STARTING/GROWING/ESTABLISHED operators use the identical tables, RLS policies, and RPCs. The only place this value currently shapes anything is the sidebar's own progressive-complexity discussion (§5) and, potentially, future presentation tuning — not built this phase beyond the "Drive" nav item (which itself derives from a real linked Driver row, not from `business_stage`).

## 4. Email verification — documented truthfully

Locally (`supabase/config.toml`, `enable_confirmations = false`), `signUp()` returns a real session immediately — no verification gate exists in this environment. The sign-up action does not assume this either way: it checks the actual `signUp()` response, and only proceeds to create the organization if a real `session` came back. If a deployment ever enables email confirmation, the same code path correctly shows "check your email to confirm your account" instead, and the organization is created on the person's NEXT successful sign-in with a session (not here) — this is the honest, environment-independent behavior, not a claim that doesn't hold locally.

## 5. Progressive complexity (work item §12)

A STARTING (1–2 vehicle) operator is not shown a forked, simplified application — "same platform, progressive emphasis," per the work item's own explicit instruction. What this phase actually built toward that goal:
- The **onboarding checklist** (§3 below is misnamed — see actual §7) itself is the same for every business stage; nothing is hidden based on `business_stage`.
- The **"Drive" sidebar item** (§6, Owner-Operator Mode) is the one genuinely adaptive nav element — it appears only for a person who has a real, linked Driver capability, which is naturally far more common for a 1–2 vehicle owner-operator than a 10+ vehicle established fleet (where the owner is rarely also driving). This is a real, derived fact, not a `business_stage`-keyed toggle.
- **Deliberately not built this phase:** a `business_stage`-driven nav reordering (e.g., promoting "My Trips"/"Drive" above "Dispatch"/"Fleet" for STARTING operators specifically). The 7-item Operations nav (Overview/Trips/Dispatch/Passengers/Facilities/Drivers/Fleet) is identical for every business stage. This is recorded as a deliberate, honest deferral (not a silently-dropped requirement) — see GAP-16 in `docs/product/ui-backend-gap-register.md` — because a rushed nav-personalization change carried real risk of regressing the already-tested, already-working navigation for every OTHER operator size, for a refinement whose UX shape (exactly which items move where, and how) was not specified precisely enough to build safely in the time this phase had.

## 6. Owner-Operator Mode

See `docs/product/owner-operator-mode.md` for the full contract (Membership.role vs. linked Driver row, the security fix this phase required, the "Drive" nav item, and the /driver route-guard relaxation).

## 7. Driver invite/linkage

See `docs/product/driver-invite-linkage-model.md` for the full contract (the highest-risk part of this phase).

## 8. Onboarding checklist (work item §11)

`getOnboardingChecklist()` (`src/lib/operations/onboarding-checklist.ts`) derives 6 items from real, live counts — never a persisted "X% complete" value that could drift from reality:

| Item | Complete when |
|---|---|
| Business profile | Always true once an Organization exists (you cannot reach this screen without one) |
| First vehicle | `vehicles` count > 0 for this org |
| Driver setup | `drivers` count (status=active) > 0 for this org |
| First facility | `facilities` count > 0 for this org |
| First passenger | `passengers` count > 0 for this org |
| First trip | `trips` count > 0 for this org |

The banner (`OnboardingChecklistBanner`, shown on Today's Operations) renders only while incomplete — once every item is true, it stops rendering entirely, with no further persisted state to track or clear. No item is forced mandatory; every item's own link leads either to its dedicated onboarding step or (for "First trip") directly to the real New Trip screen.

## 9. First-Trip success condition (work item §13)

Verified live, end to end, with no manual database editing at any point (`docs/reports/P1-E3-S9-operator-signup-business-setup-report.txt`): sign up → business stage → business basics → add a vehicle → choose to also drive → add a facility → add a passenger → create the first Trip (the real New Trip screen) → land on Trip Detail (which is Operations) → the checklist banner disappears → assign a driver on Dispatch → execute the full lifecycle as that Driver (start → arrived → onboard → start to destination → arrived → complete), including a real reported-and-resolved issue and a real shared location update along the way.

## 10. What this phase deliberately did NOT build

Per the work item's own explicit exclusions: Request Hub, billing, broker integrations, Facility Portal, native Driver app, advanced analytics, geofencing/structured service-area data, a `business_stage`-driven nav reorder (§5), and a general `change_membership_role`/`deactivate_membership` UI (the underlying live-role-check property was verified via direct SQL testing — `docs/reports/...` §Role revocation — but no Operations screen to perform it was built this phase; an org_admin can still do so via a direct, already-safe `memberships` UPDATE, unchanged from before this phase).
