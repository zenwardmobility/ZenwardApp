# Zenward Platform — Driver Trips Data Map

**Work item:** P1-E3-S3 — Driver Trips & Active Trip Experience
**Status:** Implemented and verified against the actual running Next.js app and local Supabase — real HTTP/headless-Chrome checks, the full 217-assertion database regression suite, and a genuine end-to-end lifecycle walk, all passing.
**Last updated:** 2026-09-01

Every field the Driver Trips screen (`src/app/driver/trips/page.tsx`, docs/design/stitch/references/07-driver-trips.png) renders, mapped to its actual source.

## Field mapping

| UI field | Source RPC | Source field | Display transformation | Empty behavior | Security note |
|---|---|---|---|---|---|
| Header driver name/avatar | `driver_get_profile` (via `requireDriverAccess`, reused — ZD-111) | `display_name` | initials via `Avatar` | — | Own row only |
| "Trips" heading | — | — | static | — | — |
| Date-group labels ("Today"/"Tomorrow"/"Tuesday, September 2") | — | derived from each row's `scheduled_pickup_at` | `operationalDayLabel()` — organization-local calendar day (P1-E3-S2C) | — | — |
| Featured card time / compact row time | `driver_list_active_trips` | `scheduled_pickup_at` | `formatTripTime()`, organization timezone | "Time TBD" for a null-time row (routed to the "Unscheduled" group instead — see below) | Timestamp only |
| Status badge | `driver_list_active_trips` | `state` | `driverTripStateLabel()` (same centralized mapping as Driver Today) | — | Presentation label, never a new stored state |
| Passenger name | `driver_list_active_trips` | `passenger_display_name` | none | "Passenger" fallback | Same minimum-necessary field as Driver Today — no phone/notes here |
| Pickup / Destination | `driver_list_active_trips` | `pickup_description` / `destination_description` | none | fallback text | Trip's own snapshot fields |
| Appointment label | `driver_list_active_trips` | `appointment_at` | "Appt: " + `formatTripTime()` | omitted if null | Timestamp only |
| "View Trip" / row tap target | — | `driver_list_active_trips.trip_id` | routes to `/driver/trips/[tripId]` | — | RLS/RPC re-validates on that screen regardless |
| Empty state ("No active assignments") | — | — | shown when the list is empty | — | No fabricated schedule data |
| Error state | — | — | shown only on an RPC error | — | No raw error ever rendered |

## What's different from Driver Today

Driver Today filters `driver_list_active_trips` to the organization-local "today" only (P1-E3-S2/S2C). **Driver Trips shows every currently-active assignment, unfiltered by date** — the same single RPC call, the same field set, grouped by organization-local calendar day into labeled sections rather than restricted to one day. This is exactly what `ui-data-action-map.md` §6 anticipated for this screen and confirmed live: the seeded fixture set includes a trip from an earlier phase's own test data (`80000000-...-a1`, scheduled for "tomorrow") that Driver Today correctly never shows (it isn't today) and Driver Trips correctly does show under a "Tomorrow" section — real, incidental proof the two screens' filtering logic is correctly differentiated, not a hardcoded example.

Only the single **soonest** trip overall (across every date) gets the featured `DriverNextTripCard` treatment, exactly matching docs/design/stitch/references/07-driver-trips.png — every other trip, including the first trip of a later date group, is a compact `DriverTripCard` row. This was confirmed by direct visual inspection of the reference before implementation, not assumed from the general Driver Today pattern.

## Unscheduled trips

A trip with a null `scheduled_pickup_at` (permitted at creation — `create_trip`'s `p_scheduled_pickup_at` is optional) has no calendar day to group under. Rather than hiding it (Driver Today's approach, appropriate there since that screen is inherently date-scoped) or guessing a date, Driver Trips places it in a dedicated trailing "Unscheduled" section — visible, honestly labeled, never silently dropped.

## Related documents

[driver-today-data-map.md](./driver-today-data-map.md) (the sibling screen, same RPC, different filter) · [driver-active-trip-data-map.md](./driver-active-trip-data-map.md) · [operational-timezone.md](./operational-timezone.md) · [decision-register.md](./decision-register.md) (ZD-124 onward).
