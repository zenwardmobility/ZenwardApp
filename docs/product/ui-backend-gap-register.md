# Zenward Platform — UI/Backend Gap Register

**Work item:** P1-E3-S0 — Stitch UI Ingestion & Implementation Mapping, amended by P1-E3-S0A — Controlled Internal Trip Creation Boundary (GAP-1 and GAP-2 resolved)
**Status:** Planning/documentation only, except GAP-1/GAP-2 below, which P1-E3-S0A closed with real migrations and tests — see docs/reports/P1-E3-S0A-controlled-trip-creation-report.txt.
**Last updated:** 2026-08-31

Every UI requirement from the 7 Stitch references that the current backend does not support, classified `BLOCKS P1-E3-S1` / `BLOCKS SPECIFIC SCREEN` / `DEFERRED` / `OPTIONAL`. Only gaps actually found by the reference analysis in [ui-data-action-map.md](./ui-data-action-map.md) are listed — nothing speculative.

---

## BLOCKS SPECIFIC SCREEN

### GAP-1 — Controlled internal Trip creation — **RESOLVED (P1-E3-S0A)**

- **Screen:** Internal New Trip (05)
- **Finding:** `trips` INSERT is granted to `authenticated` **without column restriction** (`grant select, insert, update on public.trips to authenticated;`, `supabase/migrations/20260830131700_rls_policies.sql`), gated only by `trips_insert_org_operations` (an org-role check). Unlike UPDATE — which was later revoked and re-granted only for specific planning columns — INSERT was never narrowed. A client-side direct INSERT could set `state` to any value at creation (bypassing the entire lifecycle model this project has otherwise carefully enforced), or set terminal timestamps at creation time.
- **Severity:** High — this is a real, currently-exploitable gap in the existing schema, not merely a missing feature. It predates this phase (created in P1-E2-S1) but was not caught by any prior audit because no prior phase built a Trip-creation UI to exercise it.
- **Resolution:** `create_trip` (SECURITY DEFINER RPC, `supabase/migrations/20260831120000_controlled_trip_creation.sql`) is now the sole creation path — `state` is not a parameter at all (structurally impossible to override, not merely rejected at runtime), hard-coded `'scheduled'`. The raw `trips` INSERT grant to `authenticated` is revoked (`20260831120100_retire_direct_trip_insert.sql`, ZD-101), mirroring ZD-092's treatment of `trip_assignments`. Verified: 27 SQL assertions + a forced-failure atomicity test + 6 real-HTTP checks, zero failures, full prior regression (204 total SQL assertions) remains green. See docs/reports/P1-E3-S0A-controlled-trip-creation-report.txt.
- **Blocks:** Nothing, as of P1-E3-S0A — `/operations/trips/new` can now be safely implemented once P1-E3-S1's auth plumbing exists.

### GAP-2 — Request-to-Trip conversion / acceptance — **RESOLVED (P1-E3-S0A)**

- **Screen:** Internal New Trip (05) — "Import request details"
- **Finding:** Reading a `transportation_requests` row to pre-fill a form is already possible (existing RLS SELECT). Nothing currently transitions a Request's `state` from `pending` to `accepted` when a Trip is created from it, despite the schema's own comment describing this as intended ("system-driven, triggered by first Trip creation"). No atomic create-Trip-and-accept-Request operation exists.
- **Severity:** Medium — depended on GAP-1.
- **Resolution:** Folded into `create_trip` exactly as recommended — an optional `p_request_id`, validated for tenant consistency and a usable state (`pending`/`accepted`; `declined`/`cancelled` rejected), atomically transitions a `pending` request to `accepted` in the same transaction as the Trip INSERT. Correctly preserves 1:N (an already-`accepted` request — e.g. producing a return-leg Trip — is left untouched, not treated as an error). A `decline_request`-style RPC for the request queue remains unbuilt — not evidenced by any reference in the P1-E3-S0 batch, so not proposed or built here.
- **Blocks:** Nothing, as of P1-E3-S0A.

### GAP-3 — Missing reference images: Driver History and Driver Profile screens — **History built (P1-E3-S3), Profile still open**

- **Screen:** Driver History, Driver Profile (both present in the bottom tab bar on every Driver reference, neither has its own screenshot)
- **Finding:** Both routes already exist and both have a ready backend source (`driver_list_trip_history`, `driver_get_profile`), but no visual reference was provided to design against.
- **Severity:** Low — backend-ready, visual-design gap only.
- **Resolution (History, P1-E3-S3):** Built as a minimal, functional screen directly against the existing design system, per this gap's own original recommendation — see ZD-128, docs/product/driver-active-trip-data-map.md. Rows show exactly what `driver_list_trip_history`'s deliberately-redacted contract returns (date/time/outcome), no passenger name or route.
- **Driver Profile: still open, unchanged.** Not addressed this phase — remains a stub.
- **Blocks:** Nothing — Driver Profile is simply not ready to build with full design fidelity yet.

### GAP-4 — Sign-in / auth screen

- **Screen:** No reference provided for any unauthenticated state
- **Finding:** No Stitch reference shows sign-in, sign-up, or password-reset.
- **Severity:** Low (design gap) but **functionally required** for P1-E3-S1 regardless.
- **Recommendation:** Build a minimal functional sign-in view directly against the existing design system for S1 — do not block the auth-plumbing work on a missing mockup.
- **Blocks:** Nothing structural; noted so it isn't forgotten.

---

## BLOCKS P1-E3-S1 (cross-cutting, not screen-specific)

### GAP-5 — No Supabase client/session wiring exists yet

- **Finding:** `grep -rl "supabase" src/` returns nothing. No browser client, no server client, no session retrieval, no role-guard middleware exists anywhere in the application code, despite `.env.local` already carrying the right variable names (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `NEXT_PUBLIC_APP_URL`).
- **Severity:** Structural — this is exactly what P1-E3-S1 exists to build, not a surprise, but recorded here for completeness since it blocks every screen equally.
- **Recommendation:** See [application-implementation-plan.md](./application-implementation-plan.md).
- **Blocks:** Every screen, equally — this is the literal definition of P1-E3-S1's scope.

---

## DEFERRED (previously deferred, reconfirmed here — not newly discovered)

### GAP-6 — Driver Availability system

- **Screens:** Today's Operations (Driver Availability panel), Dispatch Board (Driver Capacity: Available/Break/Unavailable statuses)
- **Finding:** `On Trip` is derivable from an active `trip_assignments` row; `Available`/`Break`/`Unavailable` require a genuine driver-operational-availability concept that has no schema representation and was explicitly deferred as its own system in prior phases (P1-E2-S3's own report references this same deferral).
- **Severity:** Medium — visible on 2 of 7 screens, but not blocking (each screen degrades gracefully to showing only "On Trip" vs. an unlabeled/omitted status).
- **Recommendation:** A dedicated future work item (schema + RLS + read/mutation surface for Driver-set or dispatcher-set availability), scoped and reviewed on its own — not designed here.
- **Blocks:** Full fidelity of the Driver Availability/Capacity panels only; both screens remain otherwise implementable.
- **Resolution this phase (Today's Operations, P1-E3-S4):** Confirmed still open — the Driver Availability panel is omitted from Today's Operations entirely (not degraded to a partial "On Trip only" version), since Today's Operations' own summary strip already reports the "active" trip count elsewhere; a partial panel here would have added visual clutter without adding information not already shown. Dispatch Board (not built this phase) remains the screen where "On Trip only" degradation, per the original recommendation, is the more natural fit.
- **Resolution (Dispatch Board, P1-E3-S5):** Built exactly as the original recommendation anticipated — `DriverCapacityPanel` shows real Driver names and an "On Trip" badge only when a genuine active-state assignment exists right now; no badge at all otherwise. AVAILABLE/BREAK/CONFLICT pills and the "Potential timing conflict"/"BREAK UNTIL..." grid annotations from the reference are not built (ZD-140). Still fully open as its own future work item.

### GAP-7 — TripException Driver-facing status view

- **Finding:** Reconfirms ZD-096's own deferral (P1-E2-S3) — the existing `trip_exceptions_select_assigned_driver` policy is retained but no projection surfaces it to Driver UI. No reference in this batch showed a Driver-facing exception LIST (only "Report Issue," a write action, which is already backend-ready via direct INSERT).
- **Severity:** Low.
- **Blocks:** Nothing in this reference set.

### GAP-10 — Driver Today "Completed Today" section — not implementable at full Stitch fidelity *(found P1-E3-S2)*

- **Screen:** Driver Today (06)
- **Finding:** `driver_list_active_trips` excludes a completed trip entirely — its active assignment closes in the same transaction as `driver_complete_trip`, so a finished trip has no active assignment left to be listed under, by construction, not an oversight. `driver_list_trip_history` is the only RPC covering ended assignments, but ZD-099 deliberately redacts passenger identity and pickup/destination text from history (a past assignment is lower-need than an active one). No combination of the two approved RPCs can produce Stitch's "8:15 AM · Brenda Scott · Home → Northside Clinic · Completed" row.
- **Severity:** Low — cosmetic completeness of one section on one screen; no security or correctness issue, and the information is not lost (it remains visible, appropriately redacted, on the deferred History tab).
- **Recommendation:** Do not widen `driver_list_trip_history`'s existing redaction to work around this — that would undermine ZD-099's stated privacy rationale for a single section's visual completeness. If full fidelity is ever wanted, it needs its own deliberately-reviewed, narrowly-scoped "recently completed, minimally identifying" projection — a new decision, not assumed here.
- **Resolution this phase:** Omitted from Driver Today. Not implemented, not faked. See docs/product/driver-today-data-map.md "Omitted from this phase".
- **Blocks:** Full Stitch-reference parity on Driver Today only.

---

## OPTIONAL (would improve the product but nothing in this reference set requires it)

### GAP-8 — Operations Overview aggregate read RPC

- **Finding:** Summary metrics (24 trips today, 6 active, etc.) are derivable client-side from the same day-scoped `trips` query the tables below them already need — no new RPC is required to implement the screen (see ui-data-action-map.md §8).
- **Severity:** None currently — purely a future query-cost optimization if data volume grows.
- **Recommendation:** Do not build speculatively; revisit if real usage shows the client-side aggregation is a performance problem.
- **Resolution (Today's Operations, P1-E3-S4):** Confirmed as recommended — `getTodaysOperations()` (`src/lib/operations/todays-operations.ts`) derives every summary count server-side from the same three real queries the panels below already need. No aggregate RPC was built.

### GAP-9 — "Export Day Sheet"

- **Finding:** No backend export/report-generation capability exists in any phase to date.
- **Severity:** Low — a single button on one screen, not core trip-management functionality.
- **Recommendation:** Scope as its own small feature when prioritized; not designed here.
- **Resolution (Today's Operations, P1-E3-S4):** The button is rendered, real, and `disabled` — not hidden, not a fake working control. Still fully open as a future feature.

### GAP-11 — No Trip duration / expected-dropoff field — found P1-E3-S5

- **Screen:** Dispatch Board (03) — "Today's Assignments" time-axis grid
- **Finding:** `trips` has only `scheduled_pickup_at`/`appointment_at` (both single instants) — no field represents how long a Trip is expected to take, or when it's expected to end. The reference's own grid renders each Trip block with a visible WIDTH suggesting a duration.
- **Severity:** Low — cosmetic precision of one visual element on one screen; no correctness or security issue, and nothing is hidden (every block still shows its real start time and status).
- **Recommendation:** Do not invent an estimated-duration heuristic (e.g. "assume 45 minutes") to fill this gap — that would be fabricated data presented as if real. If duration-proportional grid blocks are ever wanted, this needs its own deliberately-reviewed schema decision (a stored duration? computed from historical Trip data? facility-specific defaults?), not assumed here.
- **Resolution this phase:** `AssignmentGrid` renders every Trip block at the same fixed width, positioned only by its real start time (`src/lib/operations/dispatch-grid.ts`, ZD-136). Not implemented as duration-proportional, not faked.
- **Blocks:** Full Stitch-reference visual parity of the grid's block sizing only — the grid is otherwise fully functional.

---

## PRODUCT DECISIONS REQUIRED (not backend gaps per se — need product input, not engineering, before either can be built)

These block full fidelity of specific UI concepts but are not "missing backend capability" in the RPC/schema sense — they need a defined business rule before any implementation, backend or frontend:

| Concept | Screens | What's missing |
|---|---|---|
| **Running Late threshold** | 01, 03 | Inputs exist (`scheduled_pickup_at`, state, `now()`); the minutes-past-schedule threshold is undefined |
| **"Potential timing conflict" / CONFLICT** | 03 | No formula defined for what makes two assignments "conflicting" |
| **"Pending Confirmation"** | 01, 03 | No domain concept matches this at all — needs a product definition before it can even be assigned a data source |
| **"Pickup updated from X" change tracking** | 06, 07 | Needs a decision on whether/how field-level change history should be tracked and to whom it's visible, before any schema work |
| **Companion field** | 02, 04 | Needs a decision on whether this becomes a real schema field (and on which entity — Trip snapshot, matching `assistance_notes`'s pattern, is the natural fit) |
| **Human-readable Trip/Request reference codes** ("ZW-240829-018", "ZR-240829-104", "FAC-23981") | 02, 05 | No such field exists; needs a decision on format and generation (stored vs. computed) before implementation |
| **Trip Type / structured pickup-destination fields** | 02 | Whether `pickup_description`/`destination_description` remain single free-text fields (display-formatted) or become structured (name + address) is a product/schema decision, not just a display one |
| **"Organization/Facility" requester field** | 05 | No dedicated column exists on `transportation_requests` for this — decide whether it's free text (reuse `requester_name`/`additional_notes`) or a real `facilities` link |
| **Multi-org UX (org switcher)** | none directly, but implied by Membership architecture | See application-route-map.md — smallest-safe-approach recommended, not decided |

None of these are proposed to be resolved in this phase, per explicit instruction (work item §50).
