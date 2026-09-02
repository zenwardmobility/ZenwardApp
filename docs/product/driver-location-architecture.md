# Driver Location & Live Dispatch Tracking — Architecture

**Phase:** P1-E3-S7A
**Status:** Implemented and verified — see `docs/reports/P1-E3-S7A-driver-location-live-dispatch-report.txt`.

This document is the canonical reference for Zenward's first live operational
capability: Driver location. It exists to be read BEFORE any future change
to this system — the collection purpose, eligibility rules, authorization
chain, retention policy, and browser limitations below are deliberate
product/engineering decisions, not incidental implementation detail.

---

## 1. Collection purpose

Driver location is **operational Trip data** — collected only while it
serves an active transportation execution, never as a general employee
tracker, permanent staff-surveillance feature, or social location feature
(work item §3). Zenward does not collect a Driver's location:

- before a Trip is dispatched (`scheduled` state)
- after a Trip reaches any terminal state (`completed`/`cancelled`/`no_show`)
- outside of an active, currently-assigned TripAssignment
- for any purpose other than giving Operations/Dispatch visibility into an
  in-progress transportation execution

## 2. Eligible tracking states

Location may be recorded only while `trips.state` is one of:

```
en_route_to_pickup
arrived_at_pickup
passenger_onboard
en_route_to_destination
arrived_at_destination
```

The exact same set already established as `ACTIVE_STATES` in
`src/lib/operations/presentation.ts`/`dispatch-board.ts`, and duplicated as
`ELIGIBLE_LOCATION_TRACKING_STATES` in `src/lib/driver/trip-presentation.ts`
(this file's own header explains the deliberate duplication — matches this
codebase's established Operations/Driver boundary-keeping convention). Both
"arrived" states remain eligible: the Driver is still actively engaged in
trip execution (waiting/loading at pickup, or at the destination before
hand-off), and Dispatch benefits from confirming the Driver is genuinely
there. `scheduled` (before dispatch) and every terminal state are NOT
eligible. This set is enforced authoritatively inside `driver_record_location`
itself (hardcoded array literal, matching `_is_valid_trip_transition`'s own
single-source-of-truth philosophy) — the client-side constant only decides
whether the tracker UI mounts at all; it is never trusted as the actual
security boundary.

## 3. No automatic state transitions

GPS proximity never mutates canonical Trip state. There is no geofence
logic anywhere in this codebase. A Driver must always explicitly confirm
"Arrived at Pickup"/"Passenger Onboard"/"Arrived at Destination" etc.
through the existing `DriverLifecycleAction` control — location data is
read-only context for Dispatch, never a trigger.

## 4. Schema

### `driver_location_updates` (append-oriented history — see §5 for why)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `organization_id` | uuid, FK → `organizations` | Tenant root |
| `driver_id` | uuid, composite FK → `drivers(id, organization_id)` | |
| `trip_id` | uuid, composite FK → `trips(id, organization_id)` | |
| `assignment_id` | uuid, composite FK → `trip_assignments(id, organization_id)` | The SPECIFIC assignment in force at write time — see §8 |
| `latitude` | double precision, CHECK `[-90, 90]` | |
| `longitude` | double precision, CHECK `[-180, 180]` | |
| `accuracy_meters` | double precision, CHECK `>= 0` or null | Optional — from `GeolocationPosition.coords.accuracy` |
| `recorded_at` | timestamptz, default `now()` | Server-authoritative — see §9 |
| `created_at` | timestamptz, default `now()` | |

No `altitude`, `heading`, `speed`, or device identifiers — none has an
actual MVP requirement (work item §10). No Passenger data of any kind (§37,
below).

`trip_assignments` also gained `unique (id, organization_id)` (additive,
purely for this composite FK) — no existing behavior changed.

## 5. History vs. latest-projection decision

**One append-oriented history table. No separate "latest location"
projection table.** This directly extends ZD-051's own established
reasoning (TripAssignment is the sole assignment source of truth — no
redundant `current_driver_id` pointer that can drift out of sync) to this
new domain: a denormalized "latest" row per Trip/Driver would need to be
kept in lockstep with the history on every insert, reintroducing exactly
the synchronization risk ZD-051 rejected.

"Latest location" is always **derived**, never stored separately —
`getLatestLocationsByTrip()` (`src/lib/operations/live-location.ts`) reads
the history table `ORDER BY recorded_at DESC` per Trip, backed by the
`driver_location_updates_trip_recorded_idx` index (`trip_id, recorded_at
desc`), and reduces to the first row seen per `trip_id`.

## 6. Retention policy

**Documented policy: 30 days from `recorded_at`.** This phase does NOT
implement an automated cleanup job — this project has no existing
scheduled-job infrastructure (no `pg_cron`, no edge function scheduler) to
build one safely against, and inventing one now would be new, unproven
infrastructure introduced as a side effect of this phase's own primary
mandate (work item §11's own explicit caution: "Do not implement
destructive background cleanup infrastructure if unsupported"). **Future
requirement, left explicitly open:** a scheduled job (or a manual runbook
step, until one exists) that deletes `driver_location_updates` rows older
than 30 days. Until that exists, location history accumulates
unboundedly — a known, deliberate, and documented gap, not an oversight.

## 7. Write authorization chain

The sole write path is `driver_record_location(p_trip_id, p_latitude,
p_longitude, p_accuracy_meters)` (SECURITY DEFINER RPC). No authenticated
INSERT/UPDATE/DELETE grant exists on `driver_location_updates` at all —
matches `trip_events`' own established zero-grant precedent for an
append-oriented history table. Authorization chain, in order, mirroring
`_driver_execute_trip_transition`'s own established pattern exactly:

1. `auth.uid()` must be non-null → else `ZW001 unauthorized`.
2. The Trip must exist → else `ZW002 not_found`.
3. `is_driver_assigned_to_trip()` — the caller must have EVER had a
   relationship to this Trip → else `ZW002 not_found` (indistinguishable
   from foreign-org/nonexistent — no existence oracle).
4. `_lock_driver_active_assignment()` — the caller must hold a CURRENTLY
   active (`ended_at IS NULL`) assignment on this Trip right now → else
   `ZW001 unauthorized` (covers reassignment revocation, §8).
5. `trips.state` must be one of the 5 eligible states (§2) → else `ZW004
   illegal_transition` (reusing the same category `cancel_trip`/
   `record_no_show` already use for "not valid given current lifecycle
   state").
6. Coordinates validated (§9) → else `ZW006 invalid_input`.

`current_driver_id()` (used transitively by both #3 and #4) already
correctly requires BOTH an active `drivers` row AND an active Membership
with `role='driver'` (corrected in P1-E2-S3, ZD-100) — inactive Membership
and inactive Driver row are both caught automatically, with zero new code,
and both surface as `ZW002` (matching `driver_get_trip_detail`'s own
established convention for the identical situation).

## 8. Reassignment revocation

Every write is tied to the SPECIFIC `assignment_id` in force at write
time — not merely "this driver, this trip" (work item §8). When Operations
reassigns a Trip (`reassign_trip`, unchanged this phase), the former
Driver's assignment row is closed (`ended_at` set) and a new one opens for
the new Driver. `_lock_driver_active_assignment()` only ever finds a row
with `ended_at IS NULL` — so the former Driver's very next
`driver_record_location` call fails with `ZW001`, same-session, same
active token, no re-authentication required to observe the revocation
(verified live — report §34/§60). The new Driver can post immediately,
tied to the NEW assignment id.

## 9. Timestamp authority

`recorded_at` is **always** the server's own `now()` at insert time — the
RPC accepts no client-supplied timestamp parameter at all (work item §13:
"Prefer server timestamp authority... Do not blindly trust device time").
This is a deliberate simplification beyond "validate it's not absurdly
future-dated": it eliminates an entire class of clock-skew/spoofing
concern outright. The gap between the browser's own
`GeolocationPosition.timestamp` and server receipt (typically well under a
second on a healthy connection) is immaterial at this product's
freshness-threshold granularity (§14 below — tens of seconds to minutes).

## 10. Read authorization (Operations)

Operations reads directly via RLS-scoped `SELECT`
(`driver_location_updates_select_org_operations`,
`has_org_role(organization_id, ['organization_admin', 'dispatcher'])`) —
the same convention every other Operations-read table already uses, not a
second RPC. `getLatestLocationsByTrip()` (`src/lib/operations/
live-location.ts`) is the one focused, explicit-column read boundary — no
`select("*")`, no generic location repository, no service role.

**Driver gets ZERO read access to this table — including their own
location.** No Driver SELECT policy exists at all. A Driver's query
succeeds (the table-level `GRANT SELECT ... TO authenticated` is broad,
same shape as `passengers`' own grant, ZD-080) but RLS filters every row
out — the Driver-side tracker never reads back a stored location; its own
UI reflects local `watchPosition` state only.

## 11. Realtime decision

**Deferred.** Work item §30-§32 explicitly permits deferring Realtime if
it cannot be proven tenant-safe with real adversarial tests within this
phase: "Security beats animation." This local Supabase CLI version's
`postgres_changes` RLS-interaction behavior was not independently
adversarially re-proven this phase (distinct from, and not automatically
implied by, ordinary `SELECT` being RLS-safe — the work item's own
explicit warning). Rather than ship an unproven live-subscription security
surface under this phase's own time constraints, the fallback is used:
restrained client-side polling. `DispatchLiveRefresh`
(`src/components/operations/dispatch/DispatchLiveRefresh.tsx`) triggers
`router.refresh()` every 20 seconds — reusing the EXACT same
already-proven, already-RLS-scoped server re-fetch every other Dispatch
mutation already triggers on success, not a new data path. The initial
page render works fully without this component (a plain
`supabase db reset`-fresh page load already shows correct, current
location data — Realtime/polling only affects how quickly a SUBSEQUENT
update appears without a manual reload).

## 12. Freshness thresholds

Centralized in `src/lib/operations/location-freshness.ts`:

| Age of `recorded_at` | Classification | Label |
|---|---|---|
| ≤ 45 seconds | `live` | "Updated just now" |
| ≤ 5 minutes | `recent` | "Updated N min ago" |
| > 5 minutes | `stale` | "Location stale" |
| no location recorded at all | `none` | "No recent location" |

Never fabricates "Live" for an old timestamp (work item §29) — every label
is derived from comparing the real `recorded_at` against the current
instant at render time.

## 13. Map provider decision

**No SDK, no API key, no billing.** `externalMapUrl()`
(`src/lib/operations/live-location-shared.ts`) links to
`openstreetmap.org` with the coordinate pre-centered — no third-party
script loaded, no privacy-implicated embed, no provider account. This is
the explicitly-sanctioned MVP fallback (work item §25: "If no map provider
is already configured, acceptable first delivery is: live
coordinate-derived Driver location status + external map link"). No map
provider (Leaflet/Mapbox/Google Maps) was previously configured in this
project. An embedded Leaflet+OpenStreetMap map (work item §26's own stated
preference over Google/Mapbox if a lightweight option is built) remains a
clearly-flagged future enhancement, not built this phase — deliberately,
given the volume of other mandatory security/testing/documentation work
this phase already required, and because the explicit fallback this
work item itself sanctions was available and sufficient.

## 14. No ETA

No ETA is computed or displayed anywhere. No routing engine exists in this
product. A straight-line-distance-based estimate would not be a real
travel-time estimate and is not presented as one anywhere (work item §36).

## 15. Passenger-data minimization

`driver_location_updates` stores no Passenger data of any kind — no name,
no phone, no address. `trip_id` is sufficient relationship context; anyone
with legitimate access to a location row can already separately look up
the Trip's own (already access-controlled) Passenger data if genuinely
needed (work item §37).

## 16. Logging / analytics

No precise latitude/longitude is sent to any analytics platform, error-
tracking breadcrumb, or third-party logging service — none is integrated
in this project at all. Server-side, the RPC's own error paths never log
coordinate values (work item §38/§39). No client-side `console.log` of
coordinates exists in `DriverLocationTracker` — failures degrade silently
via the tracker's own status state, not the browser console.

## 17. Browser/PWA limitations (honest, not overclaimed)

- Foreground location works reasonably while the Driver's browser tab
  remains open and active.
- Mobile browsers may throttle `watchPosition` update frequency,
  especially on battery-saver modes.
- Locked-screen/backgrounded-tab tracking is **not reliable** in a plain
  web/PWA context — this is a genuine platform limitation, not a bug in
  this implementation.
- iOS Safari/WebKit-based browsers are especially constrained around
  background geolocation; no workaround exists at the web-platform level.
- This implementation makes **no claim** of "continuous background GPS."
  A native app (with genuine background location APIs) is the only path
  to that — explicitly out of scope this phase (work item §77).

## 18. Update cadence

`watchPosition()` is used (not a fixed `setInterval` poll of
`getCurrentPosition`) — the browser decides when a new reading is
available, and `DriverLocationTracker` accepts every reading but
**throttles actual server submission to at most once every 20 seconds**
(`SUBMIT_THROTTLE_MS`, the restrained middle of the work item's own
suggested 10-30s range) via a `lastSubmitAtRef` timestamp check inside the
position callback — not a separate timer. A reading that arrives before
the throttle window elapses is simply not submitted; there is no queueing
of skipped readings.

## 19. Multiple tabs

Not coordinated. Each open tab independently manages its own permission
state, `watchPosition` watch, and 20s throttle — two tabs on the same Trip
could each submit roughly every 20s, doubling write volume in that
scenario. Deliberately deferred (work item §49 explicitly permits this,
provided it's documented): a genuinely rare scenario for this MVP, and
the backend is correctness-safe regardless (each write is independently
authorized and simply adds another history row — no data corruption, no
security issue, only a modest volume increase).

## 20. Network failure / offline

A failed submission (network error, transient server error) is silently
dropped — the tracker does not crash, does not show an alarming error, and
does not queue unbounded history in `localStorage` (work item §21/§22).
The next `watchPosition` reading (whenever the browser next produces one)
simply tries again on its own schedule. No offline sync engine, no
background sync registration, exists this phase. Future native/offline
requirement: a real offline queue with bounded size and eventual-delivery
semantics, left explicitly open for a future native migration.

## 21. Permission UX

Permission is requested **only** from an explicit "Share My Location" tap
on the Active Trip screen itself — never at sign-in, app launch, or
automatically on page mount (work item §17). The tracker card explains
its purpose in the button's own visible label and the surrounding status
text; no separate modal/dialog interrupts the flow. Denial does not block
any Trip lifecycle action — `DriverLifecycleAction` renders independently
and remains fully usable regardless of tracker status (work item §18).

## 22. Future native migration

Documented, not built: a native (or Capacitor/React-Native-wrapped) Driver
app would remove every limitation in §17 (true background tracking,
reliable locked-screen updates) and could implement the §6/§20 retention-
cleanup and offline-queue requirements more robustly than a web/PWA
context allows. This document's own §2/§4/§7/§9/§11/§12 (eligibility,
schema, authorization, timestamp authority, freshness) all remain valid
unchanged for a native client — only the Driver-side collection mechanism
would differ.
