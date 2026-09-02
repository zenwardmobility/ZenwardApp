# Operations Trip Detail — Data Map

**Work item:** P1-E3-S6 — Operations Trip Detail
**Reference:** [docs/design/stitch/references/02-trip-detail.png](../design/stitch/references/02-trip-detail.png) — canonical visual specification.
**Status:** Implemented — `src/app/operations/trips/[tripId]/page.tsx`, `src/app/operations/trips/[tripId]/actions.ts`, `src/lib/operations/trip-detail.ts`, `src/lib/operations/trip-detail-errors.ts`, `src/components/operations/trip-detail/*`.

## Visible fields

| UI FIELD | SOURCE | COLUMN | RELATIONSHIP | TRANSFORMATION | EMPTY BEHAVIOR | SECURITY NOTE |
|---|---|---|---|---|---|---|
| Passenger name (title) | `passengers` | `display_name` | `trips.passenger_id` → `passengers.id` (composite FK) | none | "Unknown Passenger" (should not occur under RLS) | Org-scoped via `trips_select_org_operations` + explicit `organization_id` filter |
| Trip status badge | `trips` | `state` | — | `operationsTripStatusLabel(state, hasActiveAssignment)` — same function Today's Operations/Dispatch already use | n/a (always one of 9 canonical states) | — |
| Pickup time | `trips` | `scheduled_pickup_at` | — | `formatOperationsTime`, org timezone | "Time TBD" | — |
| Appointment time | `trips` | `appointment_at` | — | `formatOperationsTime`, org timezone | "—" | — |
| Pickup / Destination address | `trips` | `pickup_description` / `destination_description` | — | none — the Trip's own immutable execution snapshot (work item §15), never replaced by a Facility record | always present (`not null`) | — |
| Pickup / Destination facility annotation | `facilities` | `name, city, state` | `trips.pickup_facility_id` / `destination_facility_id` → `facilities.id` (optional) | `"{name} · {city}, {state}"` | omitted entirely when unset (most Trips have no linked Facility) | Org-scoped via the same composite FK/RLS |
| Trip Instructions callout | `trips` | `instructions` | — | shown as a callout under Pickup, matching the reference's own "Call passenger on arrival" placement | omitted entirely when null — never a placeholder box | — |
| Assistance Requirements | `trips` | `assistance_notes` | — | none | "None recorded" | The Trip's own execution-time snapshot — deliberately NOT `passengers.assistance_notes` (a separate, potentially-divergent profile-level field); see "Assistance notes: Trip vs. Passenger" below |
| Passenger phone | `passengers` | `phone` | same as passenger name | `tel:` link | "—" | Operations-legitimate contact field (work item §13) |
| Requested By | `transportation_requests` | `requester_name`, `requester_relationship` | `trips.request_id` → `transportation_requests.id` (nullable — internally-created Trips have none) | `"{name} ({relationship})"` | row omitted entirely when `request_id` is null | Requester ≠ Passenger (work item §14) — never attributed to the Passenger record |
| Current assignment (Driver/Vehicle) | `trip_assignments` → `drivers`/`vehicles` | `drivers.display_name`/`phone`, `vehicles.label` | the row where `ended_at IS NULL` for this Trip | none | "Unassigned" / "—" | `TripAssignment` is the sole source of truth (work item §16) — never derived from `trips.*` (no such columns exist) or from `AuthUser` |
| Current Status / Last Update | `trip_events` (most recent) or `trips.updated_at` | `occurred_at` / `updated_at` | `trip_events.trip_id` | `formatOperationsTime` | falls back to `trips.updated_at` if no events exist yet | — |
| Next Action (Driver) | derived from `trips.state` | — | — | `DRIVER_NEXT_ACTION_LABEL[state]` (read-only text, never a button — work item §20) | omitted once terminal | Informational only — Operations cannot trigger this |
| Trip Exceptions | `trip_exceptions` | `exception_type`, `description`, `created_at` | `trip_exceptions.trip_id`, filtered `status='open'` | `humanizeExceptionType()` (generic snake_case → Title Case — `exception_type` is deliberately unconstrained free text, no fixed vocabulary to map) | "No open exceptions" | Org-scoped via `trip_exceptions_select_operations` |
| Trip Notes | `trip_notes` | `body`, `visibility`, `created_at` | `trip_notes.trip_id` | none | "No notes yet" | Both `operations_only` and `driver_visible` shown (RLS already scopes Operations to both) — author identity deliberately NOT resolved (see below) |
| Terminal-state banner | `trips` | `cancelled_at`/`cancellation_reason`, `no_show_at`, `completed_at` | — | `formatOperationsTime` | banner omitted entirely for non-terminal Trips | — |

## Explicitly omitted (fabricated concepts, no backend field)

- **Trip Type** ("One way") — no `trip_type` column exists; already an open "PRODUCT DECISIONS REQUIRED" item (ui-backend-gap-register.md).
- **Reference code** ("ZW-240829-018", "FAC-23981") — no human-readable reference field exists anywhere in the schema (same gap register entry, work item §45). Never fabricated, and the raw UUID is not shown as a substitute (no genuine operational need identified) — the breadcrumb/title use the Passenger's real name instead.
- **Companion** ("None recorded") — no schema field exists (work item §46, same gap register entry).
- **"Pickup updated from X"** — no field-level change-history tracking exists (work item §47).
- **Running Late** — no lateness threshold is defined anywhere in this project; never derived from client-side clock math (work item §48).
- **Driver Availability labels** (Available/On Shift/Break/Offline) — GAP-6, no schema representation (work item §49).

## Assistance notes: Trip vs. Passenger

`trips.assistance_notes` and `passengers.assistance_notes` are two distinct columns that can diverge (domain-model.md §J's hybrid snapshot strategy: Trip fields are immutable execution-time copies, Passenger fields are the live profile). This screen shows ONLY the Trip-level snapshot — the authoritative record of what was true for THIS specific execution — never falling back to or blending in the Passenger profile's own value, which would risk silently mixing two different points in time under one label.

## Assignment management navigation (work item §18)

No second `assign_trip`/`reassign_trip` implementation exists here. `CurrentStatusPanel` renders a single link to the canonical `/operations/dispatch` route — labeled "Assign Driver" when the Trip has no active assignment, "Manage Assignment" when it does. The link is generic, not deep-linked to this specific Trip (the Dispatch Board has no per-Trip deep-link parameter), matching the identical, already-documented limitation Today's Operations' own "Assign" action established. The Dispatch Board itself was NOT modified this phase — its existing assignment interaction is untouched (work item §53).

## Activity Timeline — not built as a separate panel

The canonical reference (`02-trip-detail.png`) does not show a distinct Activity Timeline/history panel in its own actual composition — "Current Status" surfaces only the most recent event as "Last Update". Work item §44 is explicit that "the screenshot is authoritative for layout" over its own conceptual composition list, which only offered a timeline as a possibility, not a requirement. `trip_events` is still queried and used (for "Last Update"), just not rendered as its own dedicated list section, matching what the reference actually shows rather than a conceptual superset of it.

## Trip Notes: author identity not resolved

Consistent with Today's Operations' Activity Log (todays-operations-data-map.md), the author of a `trip_notes` row is deliberately not resolved to a display name — `user_profiles` has no seed data anywhere in this project, and reliable actor-identity resolution would need a second, currently-unjustified lookup for informational value only. The reference's own "Facility coordinator" author label is a Stitch-mockup illustration, not a literal reflection of this schema's author-identity model (`trip_notes.author_user_id` always points at a Zenward staff account, never a requester) — showing it as if real would misrepresent the data. Notes instead show time + body + a real visibility badge.

## Actions

| ACTION | RPC | ELIGIBLE STATES | INPUTS | SUCCESS | ERROR | CROSS-SURFACE EFFECT |
|---|---|---|---|---|---|---|
| Cancel Trip | `cancel_trip(p_trip_id, p_reason)` | any non-terminal state (`ZW004` from `completed`/`no_show`; idempotent no-op if already `cancelled`) | reason (required, 1–500 chars) | Trip → `cancelled`, active assignment (if any) closed (`end_reason='trip_cancelled'`), `trip_events`/`audit_events` written | mapped via `trip-detail-errors.ts` — never raw ZW/SQLSTATE | Driver's `driver_get_trip_detail`/active-trip access fails closed immediately (the assignment that gated it is now ended) |
| Record No-Show | `record_no_show(p_trip_id, p_reason)` | `en_route_to_pickup` or `arrived_at_pickup` only (`ZW004` otherwise; idempotent no-op if already `no_show`) | reason (required, 1–500 chars) | Trip → `no_show`, active assignment closed (`end_reason='no_show'`) | same mapping | Same Driver revocation as Cancel |
| Add Note | direct `trip_notes` INSERT (RLS-protected, not an RPC — `trip_notes_insert_operations` policy, confirmed safe by inspection, work item §33) | any (notes are not lifecycle-gated) | body (required), visibility (`operations_only` \| `driver_visible`, required, no default) | new `trip_notes` row, `author_user_id` = the real caller | generic `UNKNOWN` (a raw table INSERT surfaces Postgres/PostgREST errors, not ZW codes; input is already validated before the query) | A `driver_visible` note becomes visible on the Driver's own Active Trip screen |
| Assign / Reassign | *(none — navigates to Dispatch)* | — | — | — | — | — |
| Report Issue | *(not implemented — disabled)* | — | — | — | — | — |
| Resolve Exception | *(not implemented — read-only display)* | — | — | — | — | — |

Every mutation re-derives Operations authorization fresh via `requireOperationsAccess()` on every call (never trusted from page render) — an inactive Membership, a role change, or a foreign-org attempt is caught on the very next action, by construction.

## Timezone handling

Every displayed timestamp — pickup, appointment, Last Update, terminal-state timestamps, exception/note timestamps — is formatted via `formatOperationsTime`/`formatOperationsLongDate`, both requiring an explicit IANA timezone parameter (`organization.organizationTimezone`, resolved server-side by `requireOperationsAccess`). No browser/server timezone fallback exists anywhere on this screen.

## Untrusted route parameter (work item §8)

`getTripDetail()` validates the `tripId` route parameter against a UUID regex BEFORE issuing any query — a malformed value never reaches Postgres (which would otherwise throw a distinguishable "invalid input syntax for type uuid" error). A well-formed but nonexistent or foreign-organization id is indistinguishable from "not found" — RLS returns zero rows for both, mapped to the identical `unavailable` result. The page renders one calm, generic "Trip unavailable" state for all three cases — no existence oracle, no leaked tenant information.

## Query efficiency (work item §50)

One query for the core Trip row (embedding Passenger, Requester, both Facility references, and the current-and-historical `trip_assignments` → Driver/Vehicle relationship in a single explicit-column select), plus three small parallel queries (`trip_events`, `trip_notes`, `trip_exceptions`, each filtered by `trip_id` + `organization_id`) run via `Promise.all`. No N+1 — Driver/Vehicle names come from the SAME embedded relationship as the Trip row, never a second per-row fetch.

## Service role / direct lifecycle-update audit

No service role is used anywhere in this module (`createServerSupabaseClient()`, the publishable-key client, exclusively). No direct `trips.state`/`cancelled_at`/`no_show_at`/`completed_at` write exists anywhere in this phase's code — `cancel_trip`/`record_no_show` (the existing controlled RPCs) are the only mutation path for lifecycle changes; the only direct table write is the RLS-protected `trip_notes` INSERT described above.

**Related documents:** [todays-operations-data-map.md](./todays-operations-data-map.md) · [dispatch-board-data-map.md](./dispatch-board-data-map.md) · [ui-backend-gap-register.md](./ui-backend-gap-register.md) · [decision-register.md](./decision-register.md) · [component-inventory.md](../design/component-inventory.md)
