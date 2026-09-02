# Trip Assurance — Data Map

**Phase:** P1-E3-S8 — Trip Assurance & Operational Exceptions
**Model reference:** [trip-assurance-model.md](./trip-assurance-model.md) — read that first for the vocabulary/priority/derivation rules; this document is the field-level/mutation-contract companion, matching the established pattern of `dispatch-board-data-map.md`/`live-dispatch-location-data-map.md`.

---

## 1. Assurance evaluator input facts

| Fact | Source | Notes |
|---|---|---|
| `state` | `trips.state` | Never re-derived — the real canonical value |
| `hasActiveAssignment` | `trip_assignments` row with `ended_at IS NULL` exists | Same derivation every other surface already uses |
| `isEligibleTrackingState` | `ELIGIBLE_LOCATION_TRACKING_STATES.has(state)` | The exact P1-E3-S7A set, never re-derived independently |
| `latestLocationRecordedAt` | `getLatestLocationsByTrip()`, assignment-scoped | Null unless the latest row's `assignment_id` matches the CURRENT active assignment |
| `openExceptionCount` | `trip_exceptions` rows with `status='open'` for this Trip | A real count, never inferred |

## 2. Today's Operations integration

`getTodaysOperations()` (`src/lib/operations/todays-operations.ts`):
1. Runs the existing 3 parallel queries (today's trips / active trips /
   today's events) unchanged.
2. Builds the candidate Trip set = today's trips ∪ active trips
   (deduplicated by id).
3. Runs a SECOND parallel phase: open exceptions for exactly that
   candidate id list (`id, trip_id, exception_type, created_at` —
   work item §42 minimization, no verbose `description` pulled into the
   list surface), and `getLatestLocationsByTrip()` for the subset of
   candidate ids already in an eligible tracking state.
4. Evaluates `evaluateTripAssurance()` once per candidate Trip, against
   one shared `now` (work item §38).
5. `attentionItems` = every Trip whose code is not `TERMINAL`/`ON_TRACK`,
   sorted by the documented priority (§4 of the model doc), with a
   stable secondary sort (earliest `scheduledPickupAt` first) — never an
   arbitrary/database-row-order pick.

No N+1: this is 5 total queries (3 original + 2 new), regardless of how
many Trips exist.

## 3. Dispatch Board integration

`getDispatchBoardData()` gained one more parallel query: open exception
trip ids for the board's own existing candidate Trip set (today's
non-terminal trips). `DispatchTrip.hasOpenException: boolean` — a small,
restrained marker (a `warning`-colored dot) on `AssignmentGrid`'s trip
blocks only, never a second full assurance panel (work item §31's own
"use restraint").

## 4. Trip Detail integration

`TripExceptionsPanel` — real open exceptions, "Report Issue" opens
`ReportIssueDialog`, each row's "Resolve" opens `ResolveExceptionDialog`.
No full assurance-code display added to Trip Detail this phase (work
item §26 only asks for the exceptions panel upgrade, not a full
assurance badge) — the real exception list and real assignment/location
data already visible elsewhere on the page ARE the "secondary
conditions" (work item §29).

## 5. TripException mutation contract

### `report_trip_exception(p_trip_id uuid, p_exception_type text default null, p_description text default null) returns trip_exception_result`

Callable by Organization Admin/Dispatcher (any Trip in their org) OR the
Trip's own **currently**-assigned Driver (tightened from "ever assigned"
to "currently assigned" in P1-E3-S8A — reassignment/terminal transitions
revoke a Driver's reporting authority immediately, same session, no
re-login). Always forces `created_by = auth.uid()` and `status = 'open'`.
As of P1-E3-S8A this is the ONLY way any actor creates a TripException —
the pre-existing direct-INSERT policies were retired (not merely
bypassed by convention) once inspection found them insufficiently narrow
for the Operations population. See
`supabase/migrations/20260902160000_exception_mutation_boundary_hardening.sql`
for the retirement and the Driver-authorization tightening.

### `resolve_trip_exception(p_exception_id uuid, p_resolution_note text default null) returns trip_exception_result`

Organization Admin/Dispatcher only — Driver never resolves (matches the
schema's own original comment). Idempotent: resolving an already-
resolved exception is a safe no-op (`changed: false`), returning the
REAL first resolution untouched — a stale/duplicate resolve attempt
never overwrites it (documented explicitly in the migration, distinct
from `reassign_trip`'s fail-closed staleness contract for a real
product reason — see that file's own comment).

## 6. Exception-type MVP list (ZD-1xx)

`exception_type` remains genuinely free text at the schema layer (no
CHECK constraint — "taxonomy not yet finalized"). The application layer
(`ReportIssueDialog`) offers a restrained, explicit 7-value list —
`driver_issue`, `vehicle_issue`, `passenger_not_ready`, `pickup_issue`,
`facility_delay`, `route_issue`, `other` — chosen deliberately after
inspecting the actual schema/product need, not blindly copied from the
work item's own illustrative list without review. A future value outside
this set is not blocked by the database; only the current UI's own
`<select>` constrains it.

## 7. Read minimization

Attention-queue reads: `id, trip_id, exception_type, created_at` only
(no `description`) — matches work item §42 exactly. Trip Detail's own
existing exceptions query (unchanged, P1-E3-S6) already fetches the full
row including `description`, appropriate for its own single-Trip,
full-detail context.

## 8. TripEvent behavior

Both RPCs write a real, structured `trip_events` row —
`exception_flagged` (on report) / `exception_resolved` (on resolve) —
both already allow-listed in the `event_type` CHECK constraint since the
very first schema migration, exercised for the first time by this phase.
No event is written on the idempotent no-op resolve path (nothing
actually changed).

## 9. AuditEvent behavior

Neither RPC writes an `AuditEvent` — see the model doc §10 for the exact
reasoning (does not materially change Trip responsibility or reach a
terminal disposition of the Trip itself, matching ZD-087's own test and
the identical precedent already set for `trip_notes`).
