# Zenward Platform — Driver Today Data Map

**Work item:** P1-E3-S2 — Driver Application Shell & Driver Today, timezone-corrected P1-E3-S2C — Organization Operational Timezone Boundary
**Status:** Implemented and verified against the actual running Next.js app and local Supabase — real HTTP content checks (populated + empty states), a live same-session revocation check (inactive Membership, inactive Driver row), the full 217-assertion database regression suite, and (P1-E3-S2C) real DST/midnight-boundary/multi-org/server-timezone-independence tests, all passing.
**Last updated:** 2026-09-01

Every field the Driver Today screen (`src/app/driver/page.tsx`, docs/design/stitch/references/06-driver-today.png) renders, mapped to its actual source. No field here was inferred or hardcoded to resemble the Stitch reference — see "Omitted from this phase" below for what the reference shows that this document deliberately does not implement.

## Field mapping

| UI field | Source RPC | Source field | Display transformation | Empty behavior | Security note |
|---|---|---|---|---|---|
| Header driver name | `driver_get_profile` (via `requireDriverAccess`, reused — see ZD-111) | `display_name` | none | Header omits the subtitle line entirely if absent (never reached in practice — the layout redirects to the link-missing state first) | Own row only; RLS+RPC-scoped, never inferred from email/JWT/UserProfile (work item §12) |
| Header avatar | derived | `display_name` | initials via existing `Avatar` component | same as above | Initials only — no photo field exists anywhere in the Driver model |
| "Today" heading | — | — | static heading text | always shown | — |
| Date line | — | `new Date()` at render time | `formatLongDate()` — "Saturday, August 29" style, `Intl.DateTimeFormat` in the resolved **Organization's own IANA timezone** (P1-E3-S2C — `access.organization.organizationTimezone`, never the server's own timezone) | always shown | — |
| "N trips assigned" badge | `driver_list_active_trips` | count of rows after the today-date filter (see below) | pluralized count | hidden entirely when the count is 0 (the empty state below replaces the whole trip section) | Count only, no row content |
| Next Trip time / Later Today time | `driver_list_active_trips` | `scheduled_pickup_at` | `formatTripTime()` — "10:00 AM", in the resolved Organization's own IANA timezone (P1-E3-S2C), never a raw ISO string | "Time TBD" if null (trips with no `scheduled_pickup_at` never reach Today at all — see "Today" grouping below) | Timestamp only |
| Status badge | `driver_list_active_trips` | `state` | `driverTripStateLabel()` — canonical state → Driver-facing label (`src/lib/driver/trip-presentation.ts`), e.g. `scheduled`→"Assigned", `en_route_to_pickup`→"Heading to Pickup" | `state` is never null for a row this RPC returns | Presentation label only — never a new stored state (work item §16/§17) |
| Passenger name | `driver_list_active_trips` | `passenger_display_name` | none | "Passenger" fallback if null | The one Passenger field this list returns — no phone, no assistance notes, no other field (ZD-097, driver-data-minimization.md) |
| Pickup | `driver_list_active_trips` | `pickup_description` | none | "Pickup location not available" fallback | Trip's own immutable snapshot field — never a Facility/Passenger address join |
| Destination | `driver_list_active_trips` | `destination_description` | none | same fallback | same |
| Appointment label | `driver_list_active_trips` | `appointment_at` | "Appt: " + `formatTripTime()` | omitted entirely (not shown as "Appt: —") when null | Timestamp only |
| "View Trip" CTA (Next Trip card only) | — | `driver_list_active_trips.trip_id` | routes to `/driver/trips/[tripId]` — the existing canonical route (application-route-map.md), still a placeholder screen (work item §24) | — | The caller's own visible trip only — RLS/RPC re-validates on that next screen regardless of how it was reached |
| Later Today / Next Trip card tap target | — | same `trip_id` | whole card wrapped in a `Link` to the same route | — | same |
| Empty state ("You're clear for now") | — | — | shown when the today-filtered list is empty | — | No fabricated future-schedule data (work item §34) |
| Error state ("Couldn't load your trips") | — | — | shown only when the RPC call itself returns an error | — | No raw Postgres/PostgREST error, SQLSTATE, or internal detail ever rendered (work item §35) |

## "Today" grouping (work item §13 of P1-E3-S2, timezone-corrected P1-E3-S2C)

`driver_list_active_trips` returns every Trip the caller currently holds an active assignment on, in any organization-permitted timeframe — not scoped to today by the RPC itself (confirmed: docs/data/read-api.md §B). Driver Today derives its own "today" subset, exactly as `ui-data-action-map.md` §6 anticipated ("client-side grouping of `driver_list_active_trips` by `scheduled_pickup_at`"):

- A row is included only if `scheduled_pickup_at` is non-null **and** falls on the same **organization-local** calendar date as the render-time `now()` (`isSameOperationalDay()`, given the resolved `organizationTimezone` — P1-E3-S2C).
- A row with a null `scheduled_pickup_at` (permitted at creation — `create_trip`'s `p_scheduled_pickup_at` is optional) is excluded from Today — there is no unambiguous "is this today" answer for it. It is not hidden from the product: it remains visible on the Trips screen (not built this phase), which has no such filter.
- The earliest-by-time row becomes "Next Trip"; the rest become "Later Today", in ascending order.

## Timezone correctness (P1-E3-S2C — supersedes the original P1-E3-S2 simplification)

P1-E3-S2 originally used the runtime's own local timezone (no `Intl` `timeZone` override) — a documented simplification that was, in practice, a real operational-correctness defect the moment the server's timezone differed from the organization's own. **P1-E3-S2C closed this**: every date/time computation on this screen now takes the resolved Organization's IANA timezone (`organizations.timezone`, threaded through `OrganizationContext.organizationTimezone` — see [operational-timezone.md](./operational-timezone.md)) as a required parameter, with no fallback to the server's own zone. Verified server-timezone-independent by running the same logic under three different process `TZ` values (default, `UTC`, `Africa/Lagos`) with byte-identical output; verified DST-correct across a January/July `America/New_York` pair; verified at the exact 11:30 PM/12:30 AM local-midnight boundary the original defect was named after. Full record: docs/reports/P1-E3-S2C-operational-timezone-report.txt.

## Omitted from this phase (deliberately, not silently)

| Stitch concept | Why it's not here |
|---|---|
| **Completed Today** section | `driver_list_active_trips` excludes a completed trip entirely (its assignment closes on `driver_complete_trip`) — by construction, not a bug. `driver_list_trip_history` is the only RPC covering ended assignments, but ZD-099 deliberately redacts passenger identity and pickup/destination text from history. No combination of the two approved RPCs can produce Stitch's "8:15 AM · Brenda Scott · Home → Northside Clinic · Completed" row. Recorded as **GAP-10** (ui-backend-gap-register.md) rather than worked around by widening either RPC's projection, which this phase's own instructions forbid (work item §58) and would undermine ZD-099's stated privacy rationale. |
| Navigate / Call Passenger (on the Next Trip card) | `driver_list_active_trips` does not return `passenger_phone`, `assistance_notes`, or `driver_notes` — only `driver_get_trip_detail` does. Per the implementation plan's own framing ("actions delegate to 04"), these belong to the Active Trip screen, explicitly out of scope this phase (work item §1/§24/§25) — not duplicated here via an extra RPC call. See ZD-114. |
| "Call passenger on arrival" inline note | Same reason — `driver_notes` is a `driver_get_trip_detail`-only field. |
| "Pickup updated from X" change notice | No field-level change-tracking exists anywhere (`trip_events`/`audit_events` are both zero-exposure to Driver, ZD-096) — a pre-existing, already-recorded gap (ui-backend-gap-register.md "Pending Confirmation" table), not resolved or newly discovered here. |
| "On Shift" header status / notification bell | No Driver-availability concept exists in the schema (explicitly deferred, GAP-6) — fabricating a shift-status indicator was avoided per work item §14. The bell has no backing notification system anywhere in the product; omitted rather than rendered non-functional. |
| Assistance Requirements / Companion | Not shown on Today in the Stitch reference itself either — these belong to Trip Detail/Active Trip, consistent with the fields `driver_list_active_trips` doesn't return. |

## Related documents

[ui-data-action-map.md](./ui-data-action-map.md) §6/§7 (the original Driver read-model mapping this document extends with real implementation detail) · [driver-data-minimization.md](../security/driver-data-minimization.md) (the field-level security rationale behind every Passenger/Trip field above) · [read-api.md](../data/read-api.md) (the RPC contract) · [ui-backend-gap-register.md](./ui-backend-gap-register.md) (GAP-10) · [operational-timezone.md](./operational-timezone.md) (the full timezone model, P1-E3-S2C) · [decision-register.md](./decision-register.md) (ZD-111 through ZD-116, ZD-119 onward).
