# Live Dispatch Location — Data Map

**Phase:** P1-E3-S7A — Driver Location & Live Dispatch Tracking
**Route:** Integrated into `/operations/dispatch` (existing, P1-E3-S5) and `/driver/trips/[tripId]` (existing, P1-E3-S3)
**Architecture reference:** [driver-location-architecture.md](./driver-location-architecture.md) — read that first for the full authorization/retention/Realtime rationale; this document is the field-level/UI-integration companion, matching the established pattern of `dispatch-board-data-map.md`/`new-trip-data-map.md`.

---

## 1. Driver-side fields

| UI Field | Source | RPC Parameter | Required / Optional | Notes |
|---|---|---|---|---|
| Tracker status text | Local `watchPosition`/permission state (never a DB read) | — | — | "Location sharing off/on", "Requesting…", "Location permission needed", "Location unavailable", "Location sharing stopped" |
| Latitude | `GeolocationPosition.coords.latitude` | `p_latitude` | Required | Validated `[-90, 90]` server-side |
| Longitude | `GeolocationPosition.coords.longitude` | `p_longitude` | Required | Validated `[-180, 180]` server-side |
| Accuracy | `GeolocationPosition.coords.accuracy` | `p_accuracy_meters` | Optional | Validated `>= 0` when present |
| (no field) | — | `recorded_at` (not a parameter) | Always server `now()` | Never client-supplied — see architecture doc §9 |
| Trip id | The active-trip route param | `p_trip_id` | Required | Untrusted route input — the RPC is sole authority, no pre-validation "does this look accessible" check (matches Driver Trip Detail's own established convention) |

## 2. Operations-side fields (Dispatch Board)

| UI Field | Source | Notes |
|---|---|---|
| Freshness indicator (row label) | `getLatestLocationsByTrip()` → `classifyLocationFreshness()` | "Updated just now" / "Updated N min ago" / "Location stale" — real thresholds, `driver-location-architecture.md §12` |
| "View on map" link | `externalMapUrl(latitude, longitude)` | Plain OpenStreetMap URL, no API key, opens in a new tab |
| Which Trip's location shows per Driver row | `row.trips.find(t => t.driverLocation !== null)` | At most one of a Driver's Trips is genuinely in the tracking window at a time in practice |

## 3. Assignment-scoped latest-location derivation (work item §51)

`DispatchTrip.driverLocation` (`src/lib/operations/dispatch-board.ts`) is
set ONLY when:

```
latestLocation.assignmentId === trip.activeAssignment.id
```

A location row that exists but belongs to a SUPERSEDED assignment (the
Trip was reassigned since that row was written) is discarded — the field
is `null`, and no stale former-Driver position is ever displayed as
current. This is enforced in the query-merge layer
(`mapTripRow` in `dispatch-board.ts`), not in the database query itself
(which correctly has no way to know which assignment is "current" without
the same join Dispatch already performs for every other field).

## 4. Query architecture

`getDispatchBoardData()` (unchanged entry point) now additionally calls
`getLatestLocationsByTrip(organizationId, activeStateTripIds)` — a second,
focused query (`src/lib/operations/live-location.ts`), scoped to only the
Trip ids already known to be in `ACTIVE_STATES` (the same set
`driver_record_location` itself enforces — no other Trip could possibly
have a location row). Explicit columns only
(`trip_id, assignment_id, latitude, longitude, accuracy_meters,
recorded_at`), organization-scoped, ordered `recorded_at DESC`, reduced to
one row per `trip_id` in TypeScript (first-seen-wins after the DESC
order). No `select("*")`, no service role.

## 5. Realtime / polling

See architecture doc §11 for the full decision. Summary: `DispatchLiveRefresh`
(`src/components/operations/dispatch/DispatchLiveRefresh.tsx`) triggers
`router.refresh()` every 20 seconds — the Dispatch page's existing,
already-proven server re-fetch mechanism, not a new data path. Renders no
visible UI (deliberately no permanent "LIVE" badge — freshness is shown
per-row from real timestamps, never from polling activity itself).

## 6. Trip Detail integration

**Not built this phase.** Work item §34 explicitly marks a "Last Driver
Location" section on Operations Trip Detail as OPTIONAL ("acceptable... if
the data and visual hierarchy support it... Primary location workspace
remains Dispatch"). Given the volume of mandatory work already required
this phase (schema, RPC, RLS, Driver tracker with full permission/
throttle/cleanup lifecycle, Dispatch integration, ~20 SQL tests, ~10
application-level tests, two architecture documents, and 8 other
documentation updates), this optional enhancement is deliberately deferred
— not because it is unsafe or infeasible, but as a scope discipline
decision consistent with this project's own established pattern of not
padding a phase beyond its mandatory requirements. `getLatestLocationsByTrip`
already generalizes trivially to a single-trip lookup for a future phase
that wants to build this.

## 7. Today's Operations integration

**Not built**, per work item §33's own explicit instruction ("Do not
clutter Today's Operations yet... Dispatch Board is the primary location
surface").
