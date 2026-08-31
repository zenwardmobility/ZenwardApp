# Zenward Platform — Driver Data Minimization

**Work item:** P1-E2-S3 — Secure Read Models & Driver Minimum-Necessary Projection
**Status:** Implemented and tested locally. Not deployed to any remote/production project.
**Last updated:** 2026-08-31

This document is the field-level security assessment behind the Driver read API ([read-api.md](../data/read-api.md)). It complements [rls-model.md](./rls-model.md) (base-table RLS posture) and [mutation-authorization.md](./mutation-authorization.md) (the mutation-side equivalent). ZD references are in [decision-register.md](../product/decision-register.md).

## The core problem (work item §4)

RLS controls **rows**, not **columns**. A policy like "Driver may SELECT the Passenger row on their assigned Trip" would still return every column on that row — including any column added in the future. This is why Driver has never had, and still does not have, any direct SELECT policy on `passengers` at all (ZD-080). This phase extends the same reasoning to every other Driver-readable base table: a table having a narrowly *row*-scoped Driver policy does not mean its *columns* were ever reviewed for necessity.

## Driver read-surface audit (work item §5)

Every table a Driver could reach, as of immediately before this phase (P1-E2-S2A baseline):

| Table | Driver direct SELECT? | Policy | Columns | Operationally necessary | Decision |
|---|---|---|---|---|---|
| `organizations` | Yes | `organizations_select_members` (any active member) | `id, name, status, created_at, updated_at` | `name` (own org display) | **Retained** — no over-exposure; own-membership org row only |
| `memberships` | Yes | `memberships_select_self` (own row only) | `id, organization_id, user_id, role, status, created_at, updated_at` | all, own data | **Retained** — own row only, not another user's |
| `user_profiles` | Yes | `user_profiles_select_own` (own row only) | (own profile fields) | own data | **Retained** — own row only |
| `platform_admin_grants` | No | — | — | — | Unaffected |
| `drivers` | Yes | `drivers_select_own` (own row only) | `id, organization_id, user_id, display_name, phone, status, created_at, updated_at` | `display_name, phone, status, organization_id` | **Retired** → `driver_get_profile`. Own data, so no minimization risk per se, but consolidated into the same controlled-projection architecture as everything else (`user_id`/timestamps dropped from the response) |
| `passengers` | **No** (ZD-080, unchanged) | — | `id, organization_id, display_name, phone, assistance_notes, status, created_at, updated_at` | `display_name, phone` (detail only) | **Hard rule unchanged** — no policy exists or will ever be added; see Passenger field matrix below |
| `facilities` | No | — | — | — | Unaffected — Trip's own `pickup_description`/`destination_description` snapshots are used instead of any Facility join (§19) |
| `vehicles` | Yes | `vehicles_select_assigned_driver` (current active assignment only) | `id, organization_id, label, status, created_at, updated_at` | `label, status` | **Retired** → embedded `vehicle_label`/`vehicle_status` in the read API |
| `transportation_requests` | No | — | — | — | Unaffected — never exposed to Driver (§22/§23) |
| `trips` | Yes | `trips_select_assigned_driver` (**ever** assigned — read-scope, includes historical) | `id, organization_id, request_id, passenger_id, state, scheduled_pickup_at, appointment_at, pickup_description, destination_description, pickup_facility_id, destination_facility_id, assistance_notes, instructions, completed_at, cancelled_at, cancellation_reason, no_show_at, created_at, updated_at` | `state, scheduled_pickup_at, appointment_at, pickup_description, destination_description, assistance_notes, instructions` (active only) | **Retired** → `driver_list_active_trips`/`driver_get_trip_detail`/`driver_list_trip_history`. The single largest over-exposure found: every column, indefinitely, even after reassignment |
| `trip_assignments` | Yes | `trip_assignments_select_own_driver` (own, any/historical) | `id, organization_id, trip_id, driver_id, vehicle_id, assigned_by, assigned_at, ended_at, end_reason, created_at` | `assigned_at, ended_at, end_reason` (as context) | **Retired** → active list (current only) + history (redacted). `assigned_by` (an admin's identity) never exposed |
| `trip_events` | Yes | `trip_events_select_assigned_driver` (ever assigned) | `id, organization_id, trip_id, event_type, actor_user_id, occurred_at, metadata` | none established this phase | **Retired**, no replacement (work item §24). `actor_user_id` — identifying which other person performed historical actions, indefinitely — was the specific over-exposure |
| `trip_notes` | Yes | `trip_notes_select_assigned_driver_visible` (driver_visible only, ever assigned) | `id, organization_id, trip_id, author_user_id, visibility, body, created_at, updated_at` | `body, created_at` (driver_visible, active only) | **Retired** → `driver_notes` embedded in detail (id/body/created_at only, ZD-098) |
| `trip_exceptions` | Yes | `trip_exceptions_select_assigned_driver` (ever assigned) | `id, organization_id, trip_id, exception_type, description, status, created_by, resolved_by, resolved_at, resolution_note, created_at` | not established this phase | **Retained, deliberately not retired** (ZD-096) — no replacement projection is built (work item §26 defers this), so retiring existing narrowly-scoped access with no successor was judged not clearly required or beneficial. Flagged for a future dedicated review if a Driver-facing exception/issue-status UI is ever built |
| `audit_events` | No | — | — | — | Unaffected — zero Driver access, unchanged |

Organization Admin / Dispatcher `_org_operations` policies on every table above are completely untouched (work item §42) — this audit and every retirement is scoped exclusively to the `_assigned_driver`/`_own_driver`/`_own` Driver policies.

## Passenger field matrix (mandatory, every field reviewed — work item §62)

| Field | Active list | Active detail | History | Returned? | Rationale |
|---|---|---|---|---|---|
| `id` | No | No | No | **Never** | Internal identifier; not needed by any Driver-facing UI concept |
| `organization_id` | No | No | No | **Never** | Internal/redundant — the caller already validated org context |
| `display_name` | **Yes** | **Yes** | No | List + detail only | Needed to identify who to pick up (§17); excluded from history as not operationally necessary for a past record (conservative default, "when uncertain, exclude" — no field explicitly required this in history) |
| `phone` | No | **Yes** | No | Detail only | §18: MAY be included in active detail if operationally necessary — is; explicitly excluded from list (§14) and history (§28) |
| `assistance_notes` | No | No | No | **Never** (from `passengers`) | The Driver-facing assistance/instruction fields come from `trips.assistance_notes`/`trips.instructions` instead — the existing per-Trip immutable snapshot (schema.md), not the Passenger's general profile field, to avoid two divergent sources of the same kind of fact |
| `status` | No | No | No | **Never** | Internal lifecycle field (active/inactive passenger record), not a Driver concern |
| `created_at` / `updated_at` | No | No | No | **Never** | Irrelevant record-keeping metadata |

No `passengers` field beyond `display_name`/`phone` is returned under any condition, in any of the 4 Driver read RPCs. Verified structurally (not just by inspection) — see `driver_read_minimization_tests.sql` MIN-KEYS-* assertions against `pg_attribute`, which prove the return types themselves cannot carry any other field.

## Trip / TripAssignment / Vehicle / TripNote field matrix

| Source | Field | Active list | Active detail | History | Rationale |
|---|---|---|---|---|---|
| Trip | `id` | trip_id | trip_id | trip_id | Primary reference |
| Trip | `state` | Yes | Yes | No (see `trip_outcome` below) | Live state relevant only while active |
| Trip | `scheduled_pickup_at` | Yes | Yes | Yes | Fixed at scheduling time — safe even historically |
| Trip | `appointment_at` | Yes | Yes | No | Operationally relevant only while active |
| Trip | `pickup_description` / `destination_description` | Yes | Yes | **No** | Full free-text addresses, not short labels — work item §28 explicitly prefers omitting full addresses from history when no short-label field exists; none does here |
| Trip | `assistance_notes` / `instructions` | No | Yes | No | Needed only to actually perform the currently-active Trip |
| Trip | `passenger_id`, `request_id`, `pickup_facility_id`, `destination_facility_id`, `completed_at`, `cancelled_at`, `cancellation_reason`, `no_show_at`, `created_at`, `updated_at` | No | No | No | Never operationally needed by Driver; terminal-timestamp fields are structurally always null for any Trip `driver_get_trip_detail` can return anyway, since a current active assignment implies a non-terminal state |
| TripAssignment | `id` | assignment_id | assignment_id | — | Reference only |
| TripAssignment | `assigned_at` | No | No | Yes (`assignment_started_at`) | Safe historical fact |
| TripAssignment | `ended_at` | — | — | Yes (`assignment_ended_at`) | Safe historical fact |
| TripAssignment | `end_reason` | No | No | Yes | Safe operational context ("why did my involvement end") |
| TripAssignment | `driver_id`, `vehicle_id`, `assigned_by` | No | No | No | `driver_id` is the caller's own, redundant; `assigned_by` is an admin's identity, never exposed |
| Vehicle | `label`, `status` | Yes | Yes | No | Minimal, needed to identify the vehicle while active; irrelevant historically |
| Vehicle | `id`, `organization_id`, `created_at`, `updated_at` | No | No | No | Never needed |
| TripNote (`driver_visible` only) | `id`, `body`, `created_at` | No | Yes | No | Exactly what's needed to read the note; `operations_only` notes never appear under any condition (ZD-098) |
| TripNote | `author_user_id`, `visibility`, `organization_id`, `trip_id` | No | No | No | Unnecessary administrative metadata / redundant with the surrounding response |

## Explicitly excluded categories (work item §22-§26, confirmed absent structurally)

- **Requester information** (`transportation_requests` snapshot fields) — never returned by any function; `transportation_requests` is not queried by any Driver read RPC at all.
- **TransportationRequest object** — never returned; Trip's own snapshot fields are the sole data source.
- **TripEvent history** — zero exposure, no replacement built this phase (§24).
- **AuditEvent** — zero exposure: no projection, no count, no metadata, no identifiers, in any function.
- **Facility administrative metadata** — never queried; Trip's `pickup_description`/`destination_description` snapshots are used instead (§19).
- **Billing/payment/insurance data** — no such fields exist anywhere in the current schema; nothing to exclude beyond confirming their absence (verified via `driver_read_minimization_tests.sql` MIN-EXCLUDED-CATEGORIES, an `ilike` sweep across all 4 return types for `%billing%`/`%payment%`/`%insurance%`/`%diagnos%`/`%medication%`/`%dob%`/`%birth%`).
- **TripException data** — the underlying table's Driver policy is retained (see audit table above), but no dedicated projection surfaces it through the read API this phase.

## Uncertain fields — deferred, not exposed "just in case" (work item §16)

- **Driver acknowledgement of an assignment** — no such field exists on `trip_assignments` (flagged as unresolved in lifecycle-model.md §F long before this phase); nothing to expose.
- **Wheelchair/mobility-device taxonomy** — no dedicated field exists beyond free-text `assistance_notes`/`instructions`, already included; no new field was invented for this phase (work item §20 explicit instruction).
- **TripException Driver-facing status** — see above; deferred pending a concrete need and a dedicated review, per work item §26.
