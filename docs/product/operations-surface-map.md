# Zenward Platform — Operations Surface Map

**Work item:** P1-E3-S8B1 — Operations Surface Completion & Navigation Closure
**Status:** Complete. Every route below is either REAL (functional, org-scoped, RLS-backed) or explicitly UNLINKED (route file exists on disk but carries no navigation path to it) — never a visible dead end.
**Last updated:** 2026-09-02

For every `/operations/*` route: purpose, data, authorization, actions, current maturity.

---

## `/operations` — Today's Operations
- **Purpose:** The all-day dispatcher workspace — what needs attention right now.
- **Data:** `getTodaysOperations()` (P1-E3-S4/S8) — today's Trips, the real Trip Assurance attention queue, Active Trips, Activity Log.
- **Authorization:** `requireOperationsAccess()` — `organization_admin`/`dispatcher`, active Membership.
- **Actions:** New Trip (link), Assign/Open Trip (attention rows).
- **Maturity:** REAL.

## `/operations/trips` — Trips
- **Purpose:** The canonical Trip inventory — find, filter, and open any Trip in the organization (not just today's).
- **Data:** `getTripsList()` (new, P1-E3-S8B1) — server-filtered (search, date, assignment), server-side paginated (`TRIPS_LIST_PAGE_SIZE` = 25 rows/page via `range()`), driver context via a second bounded query scoped to the current page's Trip ids.
- **Authorization:** `requireOperationsAccess()`.
- **Actions:** New Trip (link), open any row (link to Trip Detail).
- **Maturity:** REAL.

## `/operations/trips/[tripId]` — Trip Detail
- **Purpose:** Full detail and lifecycle actions for one Trip.
- **Data:** `getTripDetail()` (P1-E3-S6).
- **Authorization:** `requireOperationsAccess()`.
- **Actions:** Contact Driver, Manage Assignment, Report Issue, Resolve, Cancel Trip, Record No-Show, Add Note — all real. Edit Trip stays honestly disabled (no edit contract exists yet).
- **Maturity:** REAL (unchanged this phase).

## `/operations/trips/new` — New Trip
- **Purpose:** Controlled internal Trip creation.
- **Data/Actions:** `create_trip` RPC, real Passenger `Combobox`, real Facility/Request selection.
- **Authorization:** `requireOperationsAccess()`.
- **Maturity:** REAL (unchanged this phase).

## `/operations/dispatch` — Dispatch
- **Purpose:** Assign/reassign Trips, see live location freshness and Assurance indicators.
- **Maturity:** REAL (unchanged this phase).

## `/operations/passengers` — Passengers
- **Purpose:** The directory of people whose transportation the organization coordinates.
- **Data:** `getPassengersList()` (new) — `display_name`/`phone`/`status` only (data-minimized; no assistance/medical text browsed as a directory field — that stays scoped to Trip Detail, where it is operationally relevant to one specific Trip). Server-side search (name or phone), bounded to 100 rows (a pilot-sized operator, work item §4, is nowhere near that count).
- **Authorization:** `requireOperationsAccess()` — same `passengers_select_org_operations` RLS policy every other Passenger read in this codebase already uses.
- **Actions:** **Add Passenger** — reuses the exact `AddPassengerDialog`/`addPassengerAction` New Trip already established (P1-E3-S7), the same safe, org-scoped `passengers` INSERT; only the post-success behavior differs (`router.refresh()` here vs. an in-memory form append there — see the component's own comment).
- **Mutation decision:** Edit/Deactivate deliberately NOT built this phase. `passengers_update_org_operations` (RLS) plus the narrowed `display_name, phone, assistance_notes, status` column grant already exist and are already safe — a future edit flow needs no new RLS, only a form and action. Deferred because a list + Add is judged sufficient for pilot operations (work item §14's own explicit fallback: "a list/detail/read-only passenger page is preferable to an unsafe edit flow" — here the edit flow isn't unsafe, just not yet built, and building it added meaningful scope this phase's own breadth (5 surfaces + account menu + sign-out) did not have room for without diluting quality elsewhere).
- **Maturity:** REAL (list + create). Edit/Deactivate: NOT YET BUILT (documented, not silently missing).

## `/operations/facilities` — Facilities
- **Purpose:** The organization's referring clinics/dialysis centers/etc.
- **Data:** `getFacilitiesList()` (new) — `name`/`city`/`state`/`status`, bounded to 100 rows.
- **Authorization:** `requireOperationsAccess()`.
- **Actions:** None yet.
- **Mutation decision:** Read-only this phase. `facilities_insert_org_operations`/`_update_org_operations` (RLS) are already org+role-scoped and column-narrowed (`name, address_line1, address_line2, city, state, postal_code, status`) — a future Add/Edit Facility flow needs no new RLS. Deferred for the identical scope-discipline reason as Passenger edit above; work item §39's own explicit fallback ("if mutation intentionally deferred: prove real existing Facilities render correctly") was followed directly.
- **Maturity:** REAL (list, read-only). Create/Edit: NOT YET BUILT.

## `/operations/drivers` — Drivers
- **Purpose:** The organization's drivers and their real current-trip status.
- **Data:** `getDriversList()` (new) — `display_name`/`phone`/`status` plus a real current-trip fact (the Passenger name on any currently-active assignment) — **never** a fabricated "Available" status (GAP-6, still open).
- **Authorization:** `requireOperationsAccess()`.
- **Actions:** None.
- **Mutation decision:** Read-only, deliberately. Driver is not AuthUser/Membership — a real "Add Driver" flow would need to invite a new authenticated user, create their Membership, AND link a `drivers` row, three tables this phase does not touch. Building any part of that casually would either fabricate a fake invite flow or risk creating orphaned auth users. Recorded explicitly as future (P1-E3-S9) work — Driver onboarding is a real, separate product surface, not a checkbox to tick here.
- **Maturity:** REAL (list, read-only). Onboarding: NOT YET BUILT, explicitly deferred to a future phase.

## `/operations/fleet` — Fleet
- **Purpose:** The organization's vehicles and their real current assignment.
- **Data:** `getVehiclesList()` (new) — `label`/`status` plus the real current Driver name on any active assignment. No accessibility-capability claims (wheelchair/ambulatory/stretcher) — the schema has no such columns and none is fabricated.
- **Authorization:** `requireOperationsAccess()`.
- **Actions:** None yet.
- **Mutation decision:** Read-only this phase. `vehicles_insert_org_admin`/`_update_org_admin` (RLS, Organization-Admin-scoped, column-narrowed to `label, status`) already exist safely — same deferral reasoning as Facilities.
- **Maturity:** REAL (list, read-only). Create/Edit: NOT YET BUILT.

## `/operations/billing` — Billing
## `/operations/reports` — Reports
- **Purpose:** Not yet defined.
- **Maturity:** UNLINKED. The route files remain on disk (`OperationsRouteStub`, honestly labeled "is not yet implemented") for internal reachability, but carry **zero** navigation path from any real Operations UI as of this phase (removed from the sidebar — work item §26/§32). Restoring visible navigation to either requires a real screen first, not the reverse.

## `/operations/settings`
- **Purpose:** Not yet defined.
- **Maturity:** ABSENT. No route file exists at all (a genuine Next.js 404 if requested directly) — and, as of this phase, nothing in the visible product links to it either (the sidebar's own broken link was removed, work item §31). Building an empty page merely to avoid the 404 was explicitly rejected by the work item; the route simply does not exist yet, truthfully.

---

## Account menu & Sign Out

The top-right avatar (`AccountMenu`, new) is now a real, accessible menu — organization name, current role, an optional **Switch Organization** (only rendered when `getActiveMemberships()` genuinely returns more than one active Membership for the signed-in user — never shown merely because the UI has room for it), and **Sign Out** (reuses the pre-existing, already-correct `signOutAction`: real `supabase.auth.signOut()`, the `zw_org_context` cookie cleared, redirect to `/sign-in` — this action already existed and was already wired into the Driver header; it was simply never reachable from Operations until this phase). See `docs/product/operations-navigation-truthfulness-audit.md` for the full before/after audit and the live sign-out security test.

## Related documents
[operations-navigation-truthfulness-audit.md](./operations-navigation-truthfulness-audit.md) · [ui-backend-gap-register.md](./ui-backend-gap-register.md) · [application-route-map.md](./application-route-map.md) · [decision-register.md](./decision-register.md)
