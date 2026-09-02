# New Trip — Data Map

**Phase:** P1-E3-S7 — Internal New Trip
**Route:** `/operations/trips/new`
**Reference:** [docs/design/stitch/references/05-internal-new-trip.png](../design/stitch/references/05-internal-new-trip.png) — the reference's own composition covers only the "Request Source" and "Passenger" sections (see [stitch-reference-index.md](../design/stitch/stitch-reference-index.md)'s own note: "the form's own remaining sections ... are not shown"). The Schedule/Pickup/Destination/Instructions & Assistance sections below extend the reference's established card-panel visual language (icon + bold title header, established by its own Passenger/Request Source panels) to the backend-required fields it doesn't visually specify.

This document supersedes nothing — it is new for this phase. See
[operations-trip-detail-data-map.md](./operations-trip-detail-data-map.md),
[dispatch-board-data-map.md](./dispatch-board-data-map.md), and
[todays-operations-data-map.md](./todays-operations-data-map.md) for the
sibling Operations screens.

---

## 1. Form fields

| UI Field | Source / Input | `create_trip` Parameter | Required / Optional | Timezone Transformation | Validation | Security Note |
|---|---|---|---|---|---|---|
| Passenger | `<select>`, real same-org active Passengers | `p_passenger_id` | **Required** | — | Native `required`; RPC re-validates tenant + `status='active'` | Selector sourced from `passengers_select_org_operations` RLS — never a foreign-org row |
| Pickup Date + Pickup Time | Two `<input type="date">`/`<input type="time">`, organization-local wall clock | `p_scheduled_pickup_at` | **Required by this form** (nullable at the RPC layer, but a Trip with no scheduled pickup cannot appear on any day-scoped Operations surface — a deliberate UI-level requirement beyond the RPC's bare minimum, work item §21 note) | `organizationLocalToUtc()` — the one explicit local→UTC conversion boundary (`src/lib/operations/local-time.ts`), run server-side in `createTripAction` using the organization's own resolved timezone | Native `required`; server rejects a `"nonexistent"`/`"ambiguous"` DST result before ever calling the RPC | Timezone is re-derived server-side from `requireOperationsAccess()`, never trusted from the client |
| Appointment Date + Appointment Time | Same pair, optional | `p_appointment_at` | Optional (both-or-neither; a lone date or lone time is rejected client- and server-side) | Same conversion boundary | A non-blocking client-side hint compares wall-clock strings if the appointment is before pickup; the server independently re-checks the actual converted UTC instants before calling the RPC; the RPC checks a third time | Same |
| Pickup Facility | `<select>`, real same-org active Facilities, optional | `p_pickup_facility_id` | Optional | — | RPC re-validates tenant + `status='active'` | Same RLS source as Facility read elsewhere |
| Pickup Address | `<textarea>`, auto-filled from the selected Facility's canonical address (still freely editable) or typed manually | `p_pickup_description` | **Required** | — | Native `required`; RPC rejects blank/>2000 chars | The Trip's own immutable execution snapshot — never replaced by a live Facility read later (work item §16) |
| Destination Facility | Same pattern | `p_destination_facility_id` | Optional | — | Same | Same |
| Destination Address | Same pattern | `p_destination_description` | **Required** | — | Same | Same |
| Instructions | `<textarea>`, optional | `p_instructions` | Optional | — | — | Trip-level only — never conflated with `assistance_notes` or `trip_notes` |
| Assistance Requirements | `<textarea>`, optional | `p_assistance_notes` | Optional | — | — | This Trip's own execution-time snapshot — deliberately never auto-imported from the Passenger's own saved `passengers.assistance_notes` (work item §29; matches ZD-149's identical Trip Detail precedent) |
| Transportation Request | `<select>`, real same-org `pending`/`accepted` Requests, optional | `p_request_id` | Optional | — | RPC re-validates tenant + eligible state (`pending`/`accepted`) | Selector sourced from `transportation_requests_select_org_operations` RLS |
| (no field — backend-owned) | — | `p_organization_id` | Always sent | — | Re-derived server-side from `requireOperationsAccess()` on every submission — never a hidden form field, never client-suppliable | The RPC re-validates this against the caller's live Membership regardless |
| (no field — backend-owned) | — | Trip `state` | Always `'scheduled'` | — | Hard-coded inside `create_trip` itself — structurally impossible for any parameter to override (work item §8/§9) | — |

**Not present as parameters, and not fabricated as form fields:** Trip Type, Companion, a human-readable Trip reference code, Driver/Vehicle assignment, return-trip fields, recurrence fields — see §5-§9 below.

---

## 2. Selectors

| Selector | Query Source | Selected Columns | Org Scope | Eligibility Filter | Empty Behavior |
|---|---|---|---|---|---|
| Passenger | `getNewTripFormData()` → `passengers` | `id, display_name, phone` | `.eq("organization_id", organizationId)` | `status = 'active'` | Placeholder reads "No passengers yet — add one"; "Add New Passenger" always available |
| Pickup/Destination Facility (same list, used twice) | `getNewTripFormData()` → `facilities` | `id, name, address_line1, address_line2, city, state, postal_code` | `.eq("organization_id", organizationId)` | `status = 'active'` | Placeholder "No facility — manual address"; manual entry remains fully supported |
| Transportation Request | `getNewTripFormData()` → `transportation_requests` | `id, requester_name, requester_relationship, passenger_id, pickup_description, destination_description, preferred_date, preferred_time, assistance_notes` | `.eq("organization_id", organizationId)` | `state in ('pending', 'accepted')` — the exact same states `create_trip`'s own `p_request_id` validation accepts | Placeholder "No linked request"; Trip is created with no Request link |

All three queries run in parallel (`Promise.all`) in `src/lib/operations/new-trip.ts`, explicit columns only, no `select("*")`, no service role — same convention as `getDispatchBoardData`'s Driver/Vehicle option queries.

---

## 3. Facility auto-fill behavior (work item §18/§20)

Selecting a Facility in either Pickup or Destination immediately overwrites that
side's address `<textarea>` with the Facility's own canonical address,
formatted as `"{name}, {address_line1}, {address_line2}, {city}, {state}
{postal_code}"` (blank parts omitted). The textarea remains a normal,
freely-editable field afterward — a Dispatcher can append a note ("use the
side door") or replace the text entirely. **Both the Facility id and the
(possibly-edited) address text are submitted together** to `create_trip`;
the RPC's own validation is the sole authority (it validates the Facility id's
tenant/active status, and separately validates the address text is
non-blank/within length — it never cross-checks one against the other), so a
deliberately-edited snapshot is never silently discarded in favor of the
Facility's own address, and vice versa. Re-selecting a different Facility
re-populates the field (overwriting whatever was there), on the reasoning
that changing the Facility selection is itself a signal the address should
follow it; selecting "No facility — manual address" does not clear an
already-typed address.

---

## 4. "Import request details" behavior (work item §13/§14/§15)

The reference's own "Import request details" affordance is implemented using
only real `transportation_requests` fields — never the fabricated
Ref/Organization/Facility/requester-editor fields the mockup's "Request
Source" panel shows (see §7 below for why those are omitted entirely). The
"Import request details" button is disabled until a Request is selected in
the "Transportation Request" dropdown; clicking it copies, from that Request's
own real row, into the form's existing fields:

- `pickup_description` → Pickup Address
- `destination_description` → Destination Address
- `preferred_date` / `preferred_time` → Pickup Date / Pickup Time (both
  already organization-local wall-clock values with no timezone tag, since
  neither column is `timestamptz` — copied as-is, no conversion needed)
- `assistance_notes` → Assistance Requirements
- `passenger_id`, only if it references a Passenger that is ALSO present in
  this form's own (active-only) Passenger option list — auto-selects it in
  the Passenger dropdown. A Request with no linked Passenger, or one linked
  to a Passenger that is no longer active, leaves the Passenger selection
  untouched (never silently substitutes a different Passenger).

Import is a manual, explicit action (never automatic on selecting a Request)
so an already-in-progress form is never silently overwritten by selecting a
Request the Dispatcher was only browsing (work item §46). The Requester's own
identity (`requester_name`/`requester_relationship`/`requester_phone`/
`requester_email`) is never imported into or treated as Passenger identity —
Passenger remains an independent selection per the real `create_trip`
contract (work item §15).

---

## 5. Return-trip decision

Not built. A return ride is architecturally a **separate** Trip, optionally
sharing the same `TransportationRequest` (`request_id`, 1:N) — there is no
`return_time`/`round_trip` field on `create_trip`, and none is fabricated
here. Creating a return leg is simply creating a second Trip through this
same form, linking it to the same (now-`accepted`) Request if desired. The
reference itself has no return-trip UI in its own actual composition to
begin with (its visible fields don't include one).

## 6. Recurring-trip decision

Not built. No recurrence engine exists in the schema or anywhere in this
codebase; this phase creates exactly one Trip per submission, matching
`create_trip`'s own non-batched contract. Recorded as a future workflow, not
fabricated.

## 7. Fabricated/unsupported fields — explicitly omitted

| Concept | Reason omitted |
|---|---|
| Trip Type ("One way"/"Round Trip") | No schema field exists (ui-backend-gap-register.md, unresolved) |
| Companion | No schema field exists (same register) |
| Human-readable Trip reference code | None exists; the created Trip's real UUID is used for routing only, never displayed as a fabricated code (work item §32) |
| Requester Name/Organization/Phone/Email as EDITABLE New Trip fields | `create_trip` has no parameter for any of these — they belong to `transportation_requests`, a different table/mutation entirely. Building an inline "create a new inbound Request" flow within New Trip would be a second, materially larger feature (its own INSERT, its own validation, its own requester-identity concept) outside `create_trip`'s actual contract — deferred, not built. The Request SELECTOR (linking to an EXISTING Request) is fully built; creating a new one is not. |
| "Ref: ZR-240829-104" style reference codes on a Request | Fabricated in the mockup; no such column exists on `transportation_requests` |
| "Needs Attention — Driver not assigned" advisory (pre-creation) | Nothing to flag before a Trip exists; replaced with a calm, honest, forward-looking info note ("Assign a driver after creating this trip") instead of a pre-emptive warning about a state that doesn't exist yet |

## 8. Passenger creation decision

`passengers_insert_org_operations` RLS already grants Organization
Admin/Dispatcher a safe, org-scoped INSERT (`display_name`, `phone` — the
same two fields this screen's own Passenger selector already shows,
work item §12's minimization). ui-data-action-map.md had already
independently concluded "direct table access is adequate here — Passenger
has no lifecycle machine to protect, unlike Trip." Implemented as
`addPassengerAction` (`src/app/operations/trips/new/actions.ts`) — a small,
real, RLS-protected write, mirroring `addNoteAction`'s established
direct-table pattern (P1-E3-S6). Does not materially expand this phase's
scope (one table, two columns, the exact "Add New Passenger" affordance the
reference itself shows) — matches work item §11's own "you MAY implement it
only if it does not materially expand this phase" allowance.

## 9. Assignment decision

Driver/Vehicle assignment is never part of this form (work item §33) —
`create_trip` has no such parameter, and none was added. After creation, the
page redirects to the real Trip Detail for the newly-created Trip; a calm
info panel on New Trip itself ("Assign a driver after creating this trip")
sets the expectation before submission. The actual assignment step remains
exclusively Dispatch's (`assign_trip`), unchanged.

## 10. Non-idempotency & double-submit handling (work item §38/§39/ZD-102)

`create_trip` is deliberately non-idempotent — no duplicate-submission
heuristic exists at the database layer (ZD-102). Two layers guard against an
accidental double-submission in the client:

1. `disabled={pending}` on the Create Trip button — the standard pattern
   every other mutation dialog in this app already uses.
2. A `useRef` boolean guard on the form's own `onSubmit` handler, checked
   and set synchronously before React's `pending` state has necessarily
   committed — closes the narrow race where a very fast repeated click
   could fire a second native form submission before the button visually
   disables. Reset only on an error response (so a genuine retry after a
   validation failure is not permanently blocked); never reset on success,
   since the page navigates away immediately after.

Verified via a real 5-rapid-synchronous-click reproduction (P1-E3-S7
completion report §47): exactly one `createTripAction` invocation reached the
server, and exactly one Trip row was created.

## 11. Error mapping

`src/lib/operations/new-trip-errors.ts` — `create_trip` itself only ever
raises 3 distinct codes (ZW001 unauthorized, ZW002 not an Organization
Admin/Dispatcher for this organization, ZW006 every other validation
failure, all collapsed into one code by the function itself). The mapping
does not invent finer-grained categories the RPC doesn't actually
distinguish. One additional code, `SCHEDULE_UNRESOLVABLE`, is added on top
for a local-time conversion failure (DST nonexistent/ambiguous) caught
before `create_trip` is ever called — never returned by the RPC itself. No
ZW code, SQLSTATE, or raw Postgres/PostgREST text ever reaches the rendered
UI.
