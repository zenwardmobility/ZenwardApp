# Dispatch Board — Data Map

**Work item:** P1-E3-S5 — Dispatch Board, amended by P1-E3-S5A — Reassignment Concurrency Hardening and P1-E3-S5B — Strict Reassignment Stale-Precondition Ordering
**Reference:** [docs/design/stitch/references/03-dispatch-board.png](../design/stitch/references/03-dispatch-board.png) — canonical visual specification.
**Status:** Implemented — `src/app/operations/dispatch/page.tsx`, `src/app/operations/dispatch/actions.ts`, `src/lib/operations/dispatch-board.ts`, `src/lib/operations/dispatch-grid.ts`, `src/lib/operations/dispatch-errors.ts`, `src/components/operations/dispatch/*`. `reassign_trip`'s optimistic-concurrency precondition (P1-E3-S5A, `p_expected_assignment_id`) is live, checked BEFORE the idempotent driver/vehicle match (ordering corrected P1-E3-S5B — a stale expected id is always rejected, even when the request coincidentally matches the current assignment) — see "Concurrency behavior" below and `docs/reports/P1-E3-S5B-strict-stale-precondition-report.txt`.

## Visible fields and their sources

| Screen element | Source | Notes |
|---|---|---|
| "5 open trips today" | `trips.length` (today's non-terminal trips) | **P1-E3-S8C1 (work item §3):** label changed from "trips today" to "open trips today" — the underlying count already excluded completed/cancelled/no-show trips (only `NON_TERMINAL_STATES`), which is the correct scope for a board about what still needs dispatch attention, but the OLD label was identical to Today's Operations' own "trips today" (a different, full-day scope), which read as two contradictory numbers for the same-sounding thing. The operational logic itself is unchanged — only the label, to make the existing, already-correct scope self-evident without a salesperson's explanation. See `todays-operations-data-map.md`'s matching note. |
| "1 unassigned" | `unassignedTrips.length` | `state='scheduled'` AND no active `trip_assignments` row |
| "1 active" | count of trips in one of the 5 non-terminal in-progress states | |
| Needs Assignment cards | `unassignedTrips` | Passenger name, time (+ appointment), pickup→destination (free-text snapshot fields), `Needs Assignment` badge, `Assign` action |
| Today's Assignments grid rows | one row per `status='active'` Driver in the org (`driverRows`) | Includes a Driver with zero Trips today — visibility into who has no work, not just who does |
| Grid blocks | `assignedTrips`, positioned by real `scheduled_pickup_at` (org-local hour/minute) | See "Grid block width" below for why width is fixed, not duration-proportional |
| Driver Capacity cards | `driverRows` | Avatar/initials, name, `On Trip` badge only when a real active-state assignment exists right now, else no badge |
| "Dispatch" / date | `AppHeader` title/description, `OperationsLayoutClient` | Same persistent-header-owns-the-title pattern as Today's Operations (ZD-132) |

## Active assignment derivation

Every Trip query embeds `trip_assignments` and finds the row where `ended_at IS NULL` — never derives "current driver" from any other source (never from a Trip column, never from auth identity). `TripAssignment` remains the sole source of truth, exactly as lifecycle-model.md §F/§G establishes. `driverId`/`vehicleId`/`driverName`/`vehicleLabel` on a `DispatchTrip` are all `null` when no active assignment exists — this null-ness IS the "unassigned" signal (`unassignedTrips` filters on it), never a separate persisted "Needs Assignment" status.

## Driver option query

`drivers` filtered by `organization_id` and `status='active'` — the same, and only, filter `assign_trip`/`reassign_trip` themselves enforce server-side (confirmed by reading their actual SQL). No `Available`/`On Shift`/`Break`/`Offline` filtering exists or is invented — Driver Availability has no schema representation (GAP-6). The assignment dialog's Driver `<select>` is populated from this exact list.

## Vehicle option query

`vehicles` filtered by `organization_id` and `status='active'` — same principle. Vehicle is genuinely OPTIONAL in both RPC contracts (`p_vehicle_id uuid default null`, confirmed by inspecting `assign_trip`/`reassign_trip`'s actual signatures in `database.types.ts` and their SQL bodies) — the dialog's Vehicle field is never `required`, and both RPC calls omit `p_vehicle_id` entirely when none is chosen (not an empty string).

## Assignment mutation (`assign_trip`)

Called only via the `assignmentAction` Server Action (`src/app/operations/dispatch/actions.ts`) with `mode="assign"`. Real signature: `assign_trip(p_trip_id uuid, p_driver_id uuid, p_vehicle_id uuid default null)`. UI never calls this when a Trip already has an active assignment (the "Assign" affordance only ever appears on `unassignedTrips` rows) — but the backend remains authoritative regardless (work item §11): a genuinely concurrent assignment by another dispatcher is independently caught by the RPC's own row lock + existing-assignment check, not merely prevented by the UI's own state.

## Reassignment mutation (`reassign_trip`)

Called via the same Server Action with `mode="reassign"`. Real signature (as of P1-E3-S5A, ordering hardened P1-E3-S5B): `reassign_trip(p_trip_id uuid, p_driver_id uuid, p_vehicle_id uuid default null, p_reason text default null, p_expected_assignment_id uuid default null)`. Requires an existing active assignment (enforced by the RPC itself, not just the UI only showing this action on assigned Trips), **and — checked FIRST, before anything else, once an active assignment is confirmed to exist — that `p_expected_assignment_id` still matches the active assignment's own id.** A mismatch is `ASSIGNMENT_CONFLICT` unconditionally, even when the requested driver/vehicle happen to already equal the CURRENT assignment (see "Concurrency behavior" below). Only once the expected id is confirmed current does the RPC evaluate whether the requested driver+vehicle already match it (idempotent no-op) or require a real change. Closes the old row and inserts a new one atomically, in the same transaction — the client never ends an assignment or inserts a replacement itself; `trip_assignments` has zero direct INSERT/UPDATE grant to `authenticated` (confirmed: `revoke insert, update on public.trip_assignments from authenticated`, `supabase/migrations/20260831100000_trip_assignment_privilege_tightening.sql`).

`AssignmentDialog` submits the Trip's real `activeAssignmentId` (`src/lib/operations/dispatch-board.ts`) as a hidden form field — never rendered/shown to the Dispatcher. The Server Action forwards it as-is to `p_expected_assignment_id`; it does not itself compare anything — the RPC, under its own row lock, is the sole authority on whether it still matches.

## Mutation result handling

Both RPCs return `trip_assignment_result { trip_id, assignment_id, driver_id, vehicle_id, changed }`. `changed=false` (the requested driver+vehicle already exactly match the active assignment) is treated as a normal, successful outcome — the dialog closes exactly as it would for `changed=true`, no special-cased error. This is deliberate idempotency, not a failure to detect.

## Error mapping

`src/lib/operations/dispatch-errors.ts` maps the real ZW-code contract (confirmed from `assign_trip`/`reassign_trip`'s own SQL) to five narrow, user-safe categories — no ZW code, SQLSTATE, or PostgREST detail ever reaches the UI:

| ZW code | Category | User-facing message |
|---|---|---|
| `ZW001` | `UNAUTHORIZED` | "Your session is no longer valid. Sign in again." |
| `ZW002` | `NOT_FOUND` | "This trip is no longer available." |
| `ZW004` | `ILLEGAL_STATE` | "This trip can no longer be assigned or reassigned." |
| `ZW005` | `ASSIGNMENT_CONFLICT` | "This trip's assignment just changed. The board has been refreshed with the current assignment." |
| `ZW006` | `INVALID_DRIVER_OR_VEHICLE` | "That driver or vehicle is no longer available. Choose another." |
| (anything else) | `UNKNOWN` | "Something went wrong. Try again." |

## Concurrency behavior — verified, not assumed

- **Stale assign** (work item §64): a second, real `assign_trip` call from another dispatcher session, made while the first dialog is still open, is detected — the first dispatcher's later submit surfaces `ASSIGNMENT_CONFLICT`, and `router.refresh()` (called on every non-idle action state, success or error) pulls the real current assignment onto the board. Verified end-to-end: real UI + a real concurrent RPC call from an independent session, with independent DB verification (exactly one active assignment, owned by whichever dispatcher's call actually committed first).
- **Stale reassign — HARDENED (P1-E3-S5A, ZD-145) — ordering corrected (P1-E3-S5B, ZD-146).** P1-E3-S5's own live-application testing found that `reassign_trip` had no precondition tying a reassignment to the specific assignment a Dispatcher actually reviewed — it atomically closed whatever assignment was currently active, so a Dispatcher's stale form could silently overwrite a different Dispatcher's newer decision. Transactionally safe (never two active assignments), but operationally undesirable. `reassign_trip` now requires `p_expected_assignment_id` to match the active assignment's own id — a mismatch (including a null/omitted value) fails closed with the existing `ASSIGNMENT_CONFLICT` category, never a new error code.
  - **The check order matters, and was itself found wrong once.** P1-E3-S5A's first implementation checked the idempotent driver/vehicle match BEFORE the expected-id check — which meant a STALE expected id could still be silently accepted as `changed:false` whenever the requested driver/vehicle happened to already equal the CURRENT (not the caller's expected) assignment. P1-E3-S5B corrected this: the expected-id check now runs FIRST, unconditionally, the moment an active assignment is confirmed to exist — a stale expected id is `ASSIGNMENT_CONFLICT` **even when the request coincidentally matches the current state.** Verified end-to-end through the real UI for exactly this case: Dispatcher A loads a Trip (assignment X, Driver 1); Dispatcher B, via an independent real RPC call, reassigns it to Driver 2 (assignment Y); Dispatcher A's stale form — still referencing X — independently also picks Driver 2 (the SAME driver Y already represents) and submits; still DENIED. Exactly one active assignment exists throughout; no additional row is ever created by the stale request; the board, once refreshed, shows Y unchanged. See decision-register.md ZD-146 (which further tightens ZD-145) and `docs/reports/P1-E3-S5B-strict-stale-precondition-report.txt`.
  - **Retry-safety is narrower than it was under P1-E3-S5A, deliberately.** The idempotent-match check is now reached ONLY once `p_expected_assignment_id` is confirmed current — a genuine retry of a caller's own already-applied change (whose expected id necessarily points at the now-closed PRIOR row, not the one that same call just created) is therefore now also rejected as `ASSIGNMENT_CONFLICT`, a real, explicit narrowing of what P1-E3-S5A originally preserved. This is an intentional P1-E3-S5B product decision — "staleness is staleness," full stop — not an oversight; it does not touch ZD-093's own guarantee, which is a different mechanism (`p_expected_current_state` on the `driver_*` transition RPCs, checked against Trip state) that this change never modifies. In this application specifically, the cost is low: `AssignmentDialog` always captures a fresh expected id on every dialog open, so a true raw-HTTP-retry-with-a-stale-id scenario is not how a Dispatcher's own repeated submission would normally occur.
- **Row-level serialization**: `supabase/tests/mutation_concurrency_test.sh` (re-run this phase, unchanged) proves via real two-OS-process wall-clock timing that a concurrent `assign_trip` call genuinely blocks on the Trip row lock rather than racing past it — the mechanism underneath both scenarios above, and the same row lock `reassign_trip`'s own `p_expected_assignment_id` check now runs under.

## Timezone handling

Identical mechanism to Today's Operations: `organizationDayBoundsUtc()` (`src/lib/operations/day-bounds.ts`) computes the organization's local "today" as a UTC range from `access.organization.organizationTimezone` — never server-local, never browser-local. The grid's own hour axis is a fixed 6 AM–8 PM org-local window (see below); block positions are computed via `orgLocalHourMinute()`, which reads `scheduled_pickup_at` through the SAME organization timezone, never the runtime's own.

## Grid block width — a documented content simplification, not a fabrication

`trips` has no duration or expected-dropoff field (`scheduled_pickup_at`/`appointment_at` only — confirmed against `database.types.ts`). Every grid block is therefore rendered at the same fixed pixel width, positioned only by its real start time — never a fabricated or guessed duration. See `src/lib/operations/dispatch-grid.ts`'s own doc comment and decision-register.md.

## Deliberately omitted from the reference

- **Driver Availability status pills** (AVAILABLE / BREAK / CONFLICT on the reference's Driver Capacity cards) — only `On Trip` is derivable (an active-state assignment right now); the rest depend on a Driver Availability taxonomy with no schema representation (GAP-6). A Driver with nothing in progress shows no status pill at all.
- **"Potential timing conflict" warning** — no formula for Trip-to-Trip conflict is defined anywhere in this project (ui-backend-gap-register.md "PRODUCT DECISIONS REQUIRED").
- **"REVIEW" / "Return trip confirmation pending" queue cards** — "Pending Confirmation" has no domain concept at all (same gap register entry). The Needs Assignment queue shows real Needs-Assignment cards only, matching Today's Operations' own established precedent (ZD-130).
- **"BREAK UNTIL 10:30 AM" grid block** — depends on the same undefined availability/break scheduling concept.
- **Day navigator (‹ Today ›)** — rendered, real, disabled. The board only ever queries the organization's own "today"; no other-day query was built this phase, so a live navigator would be a fake affordance.
- **"Dispatch Settings"** — rendered, real, disabled. No defined behavior exists for it anywhere in this project.
- **Drag-and-drop assignment** — not built (work item §22's own explicit default). The reference's spatial grid visually suggests it, but no interaction contract confirms it; a deliberate click → dialog → confirm flow is used instead, avoiding the accessibility and accidental-mutation risk drag-and-drop would introduce.
- **No embedded map / no GPS / no live location** — out of scope for this phase entirely (work item §34/§35), deferred to a dedicated future location phase.
- **No Supabase Realtime** — the board is authoritative on navigation and on every mutation's own `revalidatePath`/`router.refresh()`, never a live subscription (work item §38).

**Related documents:** [todays-operations-data-map.md](./todays-operations-data-map.md) · [ui-backend-gap-register.md](./ui-backend-gap-register.md) · [decision-register.md](./decision-register.md) · [component-inventory.md](../design/component-inventory.md)
