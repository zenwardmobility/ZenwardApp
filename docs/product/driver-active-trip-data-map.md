# Zenward Platform — Driver Active Trip Data Map

**Work item:** P1-E3-S3 — Driver Trips & Active Trip Experience
**Status:** Implemented and verified — a real, complete lifecycle walk (scheduled → completed, all 6 transitions) executed through the actual application UI (real form submit → real Server Action → real RPC → real database), plus idempotent-retry, wrong-driver, reassignment-while-open, inactive-Membership, inactive-Driver, and multi-org tests, all against the real running app and local Supabase.
**Last updated:** 2026-09-01

Every field the Driver Trip Detail / Active Trip screen (`src/app/driver/trips/[tripId]/page.tsx`, docs/design/stitch/references/04-driver-active-trip.png) renders, mapped to its actual source.

## Field mapping

| UI field | Source | Display transformation | Empty behavior | Security note |
|---|---|---|---|---|
| Passenger name | `driver_get_trip_detail.passenger_display_name` | none | "Passenger" fallback | The one identity field this RPC returns |
| Status badge | `driver_get_trip_detail.state` | `driverTripStateLabel()` (centralized, shared with Today/Trips) | — | Presentation label only |
| Pickup time | `driver_get_trip_detail.scheduled_pickup_at` | `formatTripTime()`, organization timezone (P1-E3-S2C) | "Time TBD" | Timestamp only |
| Pickup address | `driver_get_trip_detail.pickup_description` | none | fallback text | Trip's own snapshot field |
| Drop-off appointment | `driver_get_trip_detail.appointment_at` | "Appt: " + `formatTripTime()` | omitted if null | Timestamp only |
| Drop-off address | `driver_get_trip_detail.destination_description` | none | fallback text | Trip's own snapshot field |
| Navigate action (either leg) | derived | `directionsUrl()` — a plain Google Maps web-search URL built from the leg's own address text | shown only for the currently-live leg (`currentLeg(state)`) | Sends only the address already visible on screen — no Passenger name/phone, no SDK, no API key |
| Call Passenger action | `driver_get_trip_detail.passenger_phone` | `tel:` link | omitted entirely if the field is null, or once the passenger is onboard (see "Design decisions" below) | The one phone field this RPC returns; never logged, never sent anywhere but the native dialer |
| Assistance | `driver_get_trip_detail.assistance_notes` | none | "None recorded" | Real field, own value |
| Instructions | `driver_get_trip_detail.instructions` | none | "None recorded" | Real field, own value |
| Driver notes (advisory) | `driver_get_trip_detail.driver_notes` (jsonb array) | rendered via `DriverInstruction`, one per note | section omitted entirely if the array is empty | `driver_visible` notes only — `operations_only` notes never appear under any condition (unchanged from P1-E2-S3, ZD-098) |
| Primary lifecycle action | derived | `DRIVER_NEXT_ACTION[state]` — see "State → action mapping" below | omitted if `state` has no mapped entry (should not occur for any state this RPC can legitimately return — see below) | The button submits to the RPC named in this table; nothing else |
| "Trip unavailable" state | — | shown whenever `driver_get_trip_detail` returns an error or no row | — | Identical presentation for every denial reason (malformed ID, nonexistent, foreign-org, never-assigned, reassigned-away, or a just-completed Trip whose assignment has already closed) — no existence oracle, matching ZD-095's established convention |

## State → action mapping

Verified against both `lifecycle-model.md` §N and `docs/data/mutation-api.md` before implementation — both agree exactly with the work item's own conceptual sketch:

| Current `state` | Button label | RPC | Resulting `state` |
|---|---|---|---|
| `scheduled` | Start to Pickup | `driver_start_to_pickup` | `en_route_to_pickup` |
| `en_route_to_pickup` | I'VE ARRIVED | `driver_arrive_at_pickup` | `arrived_at_pickup` |
| `arrived_at_pickup` | Passenger Onboard | `driver_mark_passenger_onboard` | `passenger_onboard` |
| `passenger_onboard` | Start to Destination | `driver_start_to_destination` | `en_route_to_destination` |
| `en_route_to_destination` | I'VE ARRIVED | `driver_arrive_at_destination` | `arrived_at_destination` |
| `arrived_at_destination` | Complete Trip | `driver_complete_trip` | `completed` |

`completed`/`cancelled`/`no_show` have no entry — no progression action exists from a terminal state, for anyone. **In practice, `driver_get_trip_detail` never returns one of these three states to a Driver at all**: every mutation that reaches a terminal state (`driver_complete_trip`, and the Operations-only `cancel_trip`/`record_no_show`) closes the active `trip_assignments` row in the *same transaction* (docs/data/mutation-api.md) — so the instant a Trip becomes terminal, the calling Driver's assignment is no longer active, and `driver_get_trip_detail` correctly denies access (`ZW002`) on the very next call, rendering "Trip unavailable" instead. This was confirmed directly, not assumed: a real `driver_complete_trip` call in the end-to-end test immediately made the same Trip ID return "Trip unavailable" on reload.

## Design decisions (documented, not dictated by the reference)

The reference screenshot shows only one lifecycle state (`en_route_to_pickup`); every decision below fills a gap the single reference image doesn't resolve, made deliberately and recorded here rather than guessed silently:

- **Call Passenger only appears during the pickup-relevant leg** (`scheduled`/`en_route_to_pickup`/`arrived_at_pickup`) — once `passenger_onboard`, the passenger is physically in the vehicle, so a phone action no longer serves an operational purpose. Navigate follows whichever leg (`currentLeg()`) is actually live, pickup or destination.
- **Report Issue / Trip Details were deliberately deferred**, not built. `trip_exceptions_insert_assigned_driver` (the backend path "Report Issue" would use) genuinely exists and is ready, but adding it would be a real, separate write surface needing its own dedicated security/functional test coverage — out of proportion to this phase's primary mandate (open Trips → progress the lifecycle → completion). "Trip Details"' own destination was flagged ambiguous in `stitch-reference-index.md` at the time the reference was first reviewed, with no clear target to build toward. See decision-register.md.
- **No "Trip ZW-240829-018" reference code line** — no human-readable Trip reference field exists anywhere in the schema (a pre-existing, already-recorded product decision gap, not new to this phase); omitted rather than showing a raw UUID.
- **No "Companion" row** — no such field exists anywhere in the schema (confirmed again this phase; unchanged gap). The "Passenger Requirements" card shows exactly the two real fields the RPC returns: Assistance and Instructions.

## Server Action / mutation architecture

One shared Server Action, `progressTripAction` (`src/app/driver/trips/[tripId]/actions.ts`), backs every one of the 6 buttons — never a direct client-side RPC call, never a service-role key. `rpc` (which of the 6 functions to call) is validated against a fixed allowlist derived from the state→action table above, never passed through as an arbitrary client-supplied function name. Authorization is layered exactly as ZD-105 established: `requireDriverAccess()` is re-derived fresh on every single mutation attempt (never trusted from the page's own earlier render — this is what makes the inactive-Membership/inactive-Driver same-session tests pass), and the RPC itself remains the sole, final authority on whether *this* Driver may act on *this* Trip right now.

**A genuine architectural finding, not a hypothetical:** the first implementation had `driver_complete_trip`'s success handled by a client-side `useEffect` calling `router.push("/driver")`. A real end-to-end test caught a genuine race: Next.js automatically re-renders the current route's Server Component tree once any Server Action completes (to reflect its own `revalidatePath()` calls) — and that automatic re-render, fetching the now-inaccessible Trip, rendered "Trip unavailable" *before* the client `useEffect`'s `router.push()` ever got a chance to fire. Fixed by calling `redirect("/driver")` **server-side, from within the action itself**, for the completion case specifically — this pre-empts the race entirely rather than trying to win it client-side. Recorded as ZD-124.

## Related documents

[driver-trips-data-map.md](./driver-trips-data-map.md) · [driver-today-data-map.md](./driver-today-data-map.md) · [mutation-api.md](../data/mutation-api.md) (the 6 RPCs' own contract) · [read-api.md](../data/read-api.md) (`driver_get_trip_detail`'s contract) · [operational-timezone.md](./operational-timezone.md) · [decision-register.md](./decision-register.md) (ZD-124 onward).
