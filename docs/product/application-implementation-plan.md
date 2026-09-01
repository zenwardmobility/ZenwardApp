# Zenward Platform — Application Implementation Plan

**Work item:** P1-E3-S0 — Stitch UI Ingestion & Implementation Mapping, amended by P1-E3-S1 — Authentication, Session & Role Routing Foundation and P1-E3-S2 — Driver Application Shell & Driver Today (**P1-E3-S1 and P1-E3-S2 complete** — see status below)
**Status:** P1-E3-S0 itself was planning/documentation only. P1-E3-S1 (auth/session/routing), P1-E3-S2 (Driver shell + Driver Today), and P1-E3-S3 (Driver Trips + Trip Detail/Active Trip + Driver History) are implemented and verified — see [auth-session-routing.md](./auth-session-routing.md), [driver-today-data-map.md](./driver-today-data-map.md), [driver-trips-data-map.md](./driver-trips-data-map.md), [driver-active-trip-data-map.md](./driver-active-trip-data-map.md), and `docs/reports/P1-E3-S3-completion-report.txt`. The Driver surface (Today/Trips/Active Trip/History) is now complete; Driver Profile remains a stub (GAP-3, unaddressed). Every step from P1-E3-S4 onward remains exactly as planned, not marked complete prematurely (work item §71 of P1-E3-S0 explicit instruction).

Recommended build order after S0, the frontend architecture it should follow, and the screen-by-screen implementability matrix that order is derived from.

## Screen implementability matrix (work item §51)

| Screen | Visual ready? | Backend read ready? | Backend mutation ready? | Auth ready? | Can implement next? | Blocker |
|---|---|---|---|---|---|---|
| Today's Operations (01) | Yes | Yes (existing RLS tables) | N/A (read screen) | **Yes** (P1-E3-S1) | **Yes** | None |
| Trip Detail (02) | Yes | Yes, except Reference/Companion/Trip-Type-for-request-less-Trips | Yes (Edit Trip = direct UPDATE; Cancel/No-show/Add Note/Report Issue all exist) | **Yes** | **Yes** | Minor field gaps are non-blocking |
| Dispatch Board (03) | Yes | Yes | Yes (`assign_trip`/`reassign_trip` exist) | **Yes** | **Yes** | Drag-drop UX is a separate, later refinement — a click-to-assign version is implementable without it |
| Driver Active Trip (04) | Yes | Yes (`driver_get_trip_detail`) | Yes (all 6 `driver_*` RPCs exist) | **Yes** | **IMPLEMENTED (P1-E3-S3)** | Report Issue/Trip Details deferred (ZD-125) |
| Internal New Trip (05) | Yes (partially — full field set not shown) | Yes (reading a request) | Yes (`create_trip`, resolved P1-E3-S0A) | **Yes** | **Yes** | None remaining; not yet built |
| Driver Today (06) | Yes | Yes (`driver_list_active_trips`) | N/A (read screen; actions delegate to 04) | **Yes** | **IMPLEMENTED (P1-E3-S2)** | "Completed Today" omitted — GAP-10 |
| Driver Trips (07) | Yes | Yes (`driver_list_active_trips`) | N/A | **Yes** | **IMPLEMENTED (P1-E3-S3)** | None |

**Reading this matrix (updated after P1-E3-S1):** every one of the 7 screens is now backend-ready, auth-ready, and implementable — the two blockers this table originally tracked (GAP-1/GAP-2, resolved P1-E3-S0A; auth/session plumbing, resolved P1-E3-S1) are both closed. The recommended order below is about sequencing risk and dependency structure among ready screens, not about waiting on any remaining blocker.

## Recommended implementation order

The work item's own suggested P1-E3-S1→S7 skeleton is a reasonable starting shape, but reordered here based on actual backend readiness, reference completeness, and risk — not followed blindly (work item §52 explicit instruction):

1. **P1-E3-S1 — Application shell + Auth + role routing. COMPLETE.** Unconditionally first: every other screen was blocked on this alone (GAP-5, now resolved). Built: Supabase browser/server clients (`@supabase/ssr`), session retrieval, a minimal/functional sign-in page (GAP-4, resolved — no Stitch reference existed for it), live-resolved organization-scoped role routing (`/operations` vs `/driver`), the smallest-safe multi-org resolution (`/select-organization`), server-side route guards (`requireOperationsAccess`/`requireDriverAccess`) wired onto the existing placeholder route scaffold, and the query/command separation convention every later phase will reuse. Verified with 41 real integration checks against the actual running app and local Supabase Auth, including the mandatory same-session revocation matrix — zero regressions in the 204 pre-existing database security assertions. One real bug found and fixed during implementation (an org-admin's own-Membership query accidentally returning their whole team's memberships — see application-auth-boundary.md). No Stitch screen was implemented — this phase is the doorway only, exactly as scoped.

2. **P1-E3-S2 — Driver Application Shell & Driver Today. COMPLETE** (Driver Today only — Driver Active Trip and Driver Trips deliberately deferred to step 3 below, per that phase's own explicit scope boundary). Recommended *before* the Operations screens, reordering the work item's own suggested sequence, because: (a) these screens have the fewest open gaps of the whole set — zero blocking gaps, only the deferred/optional items (GAP-6, GAP-7, GAP-10) which degrade gracefully; (b) they exercise the full, already-hardened S2/S2A/S3 RPC and read-model surface end-to-end, which is valuable to prove out early; (c) they are lower visual/interaction complexity than the Dispatch Board, reducing first-slice risk. Built: the shared Driver shell (header, bottom nav, responsive `max-w-md` cap), Driver Today (next/later-today trip cards, empty/error states, real `driver_list_active_trips` data) — see [driver-today-data-map.md](./driver-today-data-map.md) and `docs/reports/P1-E3-S2-completion-report.txt`.

3. **P1-E3-S3 — Driver Trips + Driver Active Trip. COMPLETE.** The Driver surface — the Trips list and the Active Trip lifecycle controls (the 6 `driver_*` mutation RPCs P1-E3-S2 deliberately left unwired) — before moving to Operations, continuing the same low-risk sequencing logic step 2 used. A full lifecycle walk (scheduled → completed, all 6 transitions) was verified through the actual application UI, not by direct SQL. Driver History also implemented (minimal, GAP-3 partially resolved — ZD-128); Driver Profile remains a stub.

4. **P1-E3-S4 — Operations Overview + Trip Detail.** Both fully backend-ready (Trip Detail's minor field gaps are non-blocking — display "Not available" for Reference/Companion/Trip-Type rather than blocking the whole screen). Establishes the Operations shell/data-table/panel composition pattern that Dispatch Board then reuses.

5. **P1-E3-S5 — Dispatch Board, click-to-assign first.** Fully backend-ready for a **click-to-assign** interaction (select a Trip, select a Driver, call `assign_trip`/`reassign_trip`) without drag-and-drop. Recommended to ship this simpler interaction model first and treat drag-and-drop as a deliberate, separately-scoped follow-up (work item §22/23) — the assignment-conflict handling, optimistic-UI, and rollback UX drag-and-drop needs are the same regardless of whether the trigger is a click or a drop, so nothing is lost by sequencing the simpler interaction first.

6. **P1-E3-S6 — Internal New Trip.** GAP-1/GAP-2's backend work is already resolved (P1-E3-S0A, `create_trip`) — this step is UI-only. Implements both the manual-creation and request-import paths shown in reference 05.

7. **P1-E3-S7 — Dispatch Board drag-and-drop.** The deliberate follow-up flagged in step 5 — optimistic UI, pending/conflict/stale-state/rollback handling, reusing the existing `ZW003`/`ZW004`/`ZW005` error contract exactly as documented in §Error-state mapping below. Not before the click-to-assign version has shipped and been used.

This order minimizes time-to-first-working-screen (Driver, steps 2-3, has zero blocking gaps), completes the Driver surface before starting Operations, and treats drag-and-drop as an enhancement, not a launch requirement.

## Frontend architecture recommendation (work item §46)

Built on top of the **existing** Next.js App Router structure (`src/app/operations/*`, `src/app/driver/*`, already scaffolded) — not a new architecture:

- **Server/client component boundary:** Route-level pages (`page.tsx`) as Server Components performing the initial authenticated data fetch (session + role-scoped query), passing data down to Client Components only where interactivity is needed (forms, the Dispatch grid, Driver action buttons). Matches the App Router default and needs no new convention beyond what Next.js already encourages.
- **Supabase browser client:** A single `createBrowserClient` instance (from `@supabase/ssr`, not yet a dependency — see below), used only from Client Components, using the **publishable key only** (never a secret key in the browser — work item §47).
- **Supabase server client:** A `createServerClient` instance reading cookies via Next.js's server APIs, used in Server Components and Route Handlers for the initial authenticated fetch and for any Server Action that calls a mutation RPC.
- **Auth session retrieval:** A single shared helper (e.g. `getSession()`/`getUser()`) wrapping the server client, used by every protected route's layout to redirect unauthenticated requests before rendering — this is the role-guard mechanism, not a separate middleware layer necessarily (Next.js middleware is also viable; the choice is an S1 implementation detail, not decided here).
- **Query/service layer:** One function per read need (e.g. `getActiveTripsForDriver(orgId)`, `getTripDetail(tripId)`), each a thin wrapper calling the corresponding Supabase RPC/`select` and returning a typed result — never inline Supabase calls scattered through components (work item §45, query/command separation).
- **Mutation/service layer:** Symmetric — one function per RPC call (`assignTrip(tripId, driverId, vehicleId)`, `driverArriveAtPickup(tripId, expectedState)`, etc.), each a thin wrapper around the actual RPC name from `docs/data/mutation-api.md`, never a raw table write.
- **Domain/view-model transformation:** A thin mapping layer between raw RPC/query results (already minimal per the secure read models) and what each component actually renders (e.g. formatting `scheduled_pickup_at` for display, computing the "Needs Assignment"/"Running Late" derived labels from §2 of the data-action map) — kept separate from both the service layer and the components themselves so the derivation formulas live in one place, matching how the backend itself centralizes its own transition table (ZD-089).
- **Error mapping:** One shared function translating the 6-code error contract (`ZW001`-`ZW006`) into UI-safe messages/behaviors — see the Error-state mapping section below. Never surface a raw SQLSTATE or PostgREST error body to a user.
- **Role guard:** Route-group-level (`(operations)`/`(driver)` or the existing `operations/`/`driver/` segments) — verify the resolved Membership role matches the route group before rendering, redirecting otherwise.
- **Org context:** A single resolved `organizationId` available to every Server Component in a request (from session + the multi-org resolution described in the route map), threaded explicitly into every query/mutation call — never inferred ad hoc per-component.

### Supabase client safety (work item §47)

Browser clients use the **publishable key** and rely entirely on RLS/RPC authorization — exactly the boundary every prior backend phase built and tested. No service-role key, and no service-role-shortcut pattern, is appropriate for either Operations or Driver at any point — Operations' broader access is achieved through its own RLS policies (already granting it broader legitimate reads), never through an elevated client.

### Environment plan (work item §48)

`.env.local` **already contains** the correct 3 variables (confirmed by inspection, not created by this phase):

```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
NEXT_PUBLIC_APP_URL
```

No secret/service-role value is needed for the browser or server-side rendering path described above (the server client also uses the publishable key + the user's own session cookie, not a service key — RLS still applies). No production configuration is touched in this phase.

## Query/command separation (work item §45)

| Layer | Source | Never |
|---|---|---|
| READ | `driver_get_profile`/`driver_list_active_trips`/`driver_get_trip_detail`/`driver_list_trip_history` (Driver); direct RLS-scoped `select` against `trips`/`passengers`/`trip_assignments`/etc. (Operations) | Read logic embedded inside a mutation call, or vice versa |
| COMMAND | `driver_start_to_pickup` … `driver_complete_trip`, `assign_trip`, `reassign_trip`, `cancel_trip`, `record_no_show` (all RPCs); direct INSERT for `trip_notes`/`trip_exceptions` (the two sanctioned direct-write exceptions); direct UPDATE for Trip's already-grantable planning columns | Any UI component issuing a raw `UPDATE`/`INSERT` against `trips.state`, `trip_assignments`, or `audit_events` |

## Error-state mapping (work item §42)

| Backend code | Meaning | Future UI behavior |
|---|---|---|
| `ZW001 unauthorized` | Caller can see the resource but can't act on it right now | Access-safe UI — hide/disable the action, do not explain why in detail |
| `ZW002 not_found` | Doesn't exist, or caller has no legitimate visibility | Generic "unavailable" state — never distinguish this from a real 404 |
| `ZW003 stale_state` | Caller's view of the Trip is out of date | Refresh/reload the Trip's current data, then let the user retry |
| `ZW004 illegal_transition` | Not a legal edge from the current state | Refresh current Trip state; the attempted action is no longer valid |
| `ZW005 assignment_conflict` | Someone else already changed the assignment | "Assignment changed elsewhere" — refresh the Dispatch Board/Trip data, do not silently retry |
| `ZW006 invalid_input` | Malformed input | Inline form validation message |

No raw SQLSTATE or PostgREST error body is ever shown to a user (work item §42 explicit instruction).

## Data-refresh strategy (work item §43) — recommended per screen, not implemented

| Screen | Recommended model |
|---|---|
| Today's Operations, Trip Detail | Initial server load + manual refresh action; client revalidation on navigation back to the screen |
| Dispatch Board | Initial server load + manual refresh; **realtime is a possible follow-up** (work item §44), not built now — the board is usable without it, refreshed manually or on an interval if that proves necessary in practice |
| Driver Active Trip, Today, Trips | Initial server load + revalidate after every action (each `driver_*` RPC call already returns the new state — use that response directly rather than a full re-fetch) |
| Driver Trip History | Initial server load only — historical data doesn't need refreshing |

No Supabase Realtime subscription is added in this phase or recommended as a first-implementation requirement anywhere (work item §44).

## Distinguishing visual characteristics to preserve (work item §54)

Specific, not generic, per the Stitch references actually reviewed:

- **Restrained content density** — Operations tables and panels pack real information (multi-column tables, definition-list grids) without feeling cluttered; whitespace is used between logical groups, not padded generically inside them.
- **Subtle borders over shadows** — panels are distinguished by a light border and background contrast, not drop shadows; `Panel`'s own existing default (`elevated=false`) already encodes this.
- **A calm, muted status palette** — status badges use restrained tones (soft teal/amber/gray backgrounds with darker text), never saturated "traffic light" colors; matches the existing `StatusBadge` category system already built.
- **Typography hierarchy is understated** — page titles are confidently sized but not oversized; body/table text stays compact and legible at real information density (a dispatcher scanning 24 rows, not a marketing page).
- **The operational timeline (Trip Route, Dispatch grid) uses a literal dot-and-line visual metaphor**, not icons or abstract progress bars — preserve this specific treatment rather than substituting a generic stepper component.
- **CTA emphasis is singular per screen** — one dominant teal action (New Trip, Create Trip, I'VE ARRIVED), everything else is secondary/outline — never multiple competing primary buttons.
- **Driver screens read as a focused single-task tool**, not a shrunken dashboard — one primary card, one dominant action, generous touch targets, matching `DriverPrimaryAction`'s existing "never pair two of these on one screen" rule.

## Next recommended phase

**P1-E3-S4 — Operations Application Shell & Today's Operations**, exactly as reasoned above (step 4): the Driver surface (Today/Trips/Active Trip/History) is now complete — see `docs/reports/P1-E3-S3-completion-report.txt` — so Operations is next, starting with its own shell and Overview screen before the Dispatch Board.
