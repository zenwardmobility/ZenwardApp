-- P1-E3-S7A — Driver Location & Live Dispatch Tracking.
--
-- The first LIVE operational capability this product collects. Driver
-- location is operational Trip data, scoped narrowly to the window a
-- transportation execution is actually in progress — never a generic
-- employee tracker, never indefinite, never broadly readable.
--
-- ── DATA MODEL DECISION (work item §7) ─────────────────────────────────────
-- ONE append-oriented history table, `driver_location_updates` — no
-- separate "latest location" projection table. This directly extends
-- ZD-051's own established reasoning ("TripAssignment is the sole
-- assignment source of truth — no redundant current_driver_id pointer
-- that can drift out of sync") to this new domain: a denormalized
-- "latest" row per Trip/Driver would need to be kept in lockstep with the
-- history on every insert, reintroducing exactly the synchronization risk
-- ZD-051 rejected. "Latest location" is always DERIVED — `DISTINCT ON
-- (trip_id) ... ORDER BY trip_id, recorded_at DESC` against the one
-- history table, backed by the index below — never a second table that
-- could disagree with it.
--
-- ── WRITE PATH DECISION (work item §12) ────────────────────────────────────
-- A single controlled RPC, `driver_record_location`, not a direct RLS
-- INSERT grant. The write's real authorization condition — currently
-- ACTIVE assignment (not merely "ever assigned"), AND the Trip's
-- lifecycle state currently inside the eligible tracking window — is
-- exactly the kind of multi-condition, easy-to-drift check this
-- project's own established convention already routes through an RPC
-- rather than a WITH CHECK clause (mirrors _driver_execute_trip_transition
-- and every other Driver mutation; trips/trip_assignments already have
-- zero direct mutation grant to authenticated for the same reason). No
-- authenticated INSERT/UPDATE/DELETE grant exists on this table at all —
-- matches trip_events' own established zero-grant precedent for an
-- append-oriented history table.
--
-- ── TIMESTAMP AUTHORITY (work item §13) ────────────────────────────────────
-- `recorded_at` is ALWAYS the server's own `now()` at insert time — the
-- RPC accepts no client-supplied timestamp parameter at all. This is a
-- deliberate simplification beyond "validate it's not absurdly future-
-- dated": it eliminates an entire class of clock-skew/spoofing concern
-- outright, and the small (sub-second to low-single-digit-second) gap
-- between the browser's own `position.timestamp` and server receipt is
-- immaterial at this product's freshness-threshold granularity (tens of
-- seconds to minutes — see live-dispatch-location-data-map.md).
--
-- ── READ PATH DECISION (work item §23/§42) ─────────────────────────────────
-- Operations reads directly via RLS-scoped SELECT (`has_org_role`,
-- organization_admin/dispatcher) — the same convention every other
-- Operations-read table already uses (trips, trip_assignments, etc.), not
-- a second RPC; the read's authorization condition (org-scoped role
-- check) is simple and already well-precedented as a plain policy. Driver
-- gets ZERO SELECT grant on this table, including their own location —
-- no genuine product need was found (the Driver-side UI reflects local
-- `watchPosition` state, never a DB read-back), and work item §42 is
-- explicit: "Driver does not need the other Drivers' locations. Do not
-- grant it." — extended here to "does not need to read this table at
-- all."
--
-- ── RETENTION (work item §11) ───────────────────────────────────────────
-- Documented policy: 30 days from `recorded_at`. NOT implemented as an
-- automated cleanup job this phase — this project has no existing
-- scheduled-job infrastructure (no pg_cron, no edge function scheduler)
-- to build one safely against, and inventing one now would be new,
-- unproven infrastructure introduced as a side effect of this phase's own
-- primary mandate. See docs/product/driver-location-architecture.md for
-- the full retention policy and the explicit future cleanup-job
-- requirement this leaves open.

-- =============================================================================
-- Composite-FK support: trip_assignments gains the same (id,
-- organization_id) uniqueness every other org-scoped table already has,
-- so driver_location_updates can reference it with a genuinely
-- schema-enforced org-consistent composite FK (work item §9) rather than
-- a bare `id` FK that trusts organization_id to independently line up.
-- Purely additive — no existing column, grant, policy, or query changes.
-- =============================================================================
alter table public.trip_assignments
  add constraint trip_assignments_id_organization_id_key unique (id, organization_id);

-- =============================================================================
-- driver_location_updates
-- =============================================================================
create table public.driver_location_updates (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  driver_id uuid not null,
  trip_id uuid not null,
  assignment_id uuid not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_meters double precision check (accuracy_meters is null or accuracy_meters >= 0),
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  foreign key (driver_id, organization_id) references public.drivers (id, organization_id),
  foreign key (trip_id, organization_id) references public.trips (id, organization_id),
  foreign key (assignment_id, organization_id) references public.trip_assignments (id, organization_id)
);

comment on table public.driver_location_updates is
  'TENANT-OWNED, HIGH RLS RISK — sensitive operational location data (domain-model.md-style classification, P1-E3-S7A). Append-oriented history, deliberately no separate "latest" projection table (see this migration''s own header comment, extends ZD-051). No Passenger data of any kind is ever stored here (work item §37) — trip_id is sufficient relationship context. No authenticated INSERT/UPDATE/DELETE grant exists — driver_record_location() (SECURITY DEFINER) is the sole write path. Retention: 30 days from recorded_at (documented policy, no automated cleanup job exists yet — see docs/product/driver-location-architecture.md).';

comment on column public.driver_location_updates.assignment_id is
  'The SPECIFIC TripAssignment this update was recorded under — not merely "this driver, this trip". Ties every row to the exact assignment in force at write time, so a stale former Driver''s pre-reassignment rows are never confusable with the current assignment''s own history (work item §8/§51).';

comment on column public.driver_location_updates.recorded_at is
  'Server-authoritative instant (RPC-set to now(), never client-supplied) — see this migration''s own header comment on timestamp authority (work item §13).';

-- Efficient "latest location per Trip" derivation (DISTINCT ON / window
-- query) and efficient organization-scoped freshness reads.
create index driver_location_updates_trip_recorded_idx
  on public.driver_location_updates (trip_id, recorded_at desc);

create index driver_location_updates_org_recorded_idx
  on public.driver_location_updates (organization_id, recorded_at desc);

create index driver_location_updates_assignment_idx
  on public.driver_location_updates (assignment_id);

alter table public.driver_location_updates enable row level security;

-- Operations: SELECT only, own-org, admin/dispatcher — same convention as
-- every other Operations-read table (trips, trip_assignments, etc.). No
-- Driver policy of any kind exists (work item §42) — Driver's location UI
-- reflects local watchPosition state only, never a read-back from this
-- table. No anon grant, no anon policy.
grant select on public.driver_location_updates to authenticated;

create policy driver_location_updates_select_org_operations
  on public.driver_location_updates for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- =============================================================================
-- driver_record_location — the sole write path
-- =============================================================================
create type public.driver_location_result as (
  location_id uuid,
  trip_id uuid,
  assignment_id uuid,
  recorded_at timestamptz
);

comment on type public.driver_location_result is
  'Return shape for driver_record_location. Deliberately minimal — no lat/lng echoed back (the caller already knows what it sent; nothing here needs the value round-tripped), matching this project''s general preference for narrow, purpose-built result types over convenience.';

create or replace function public.driver_record_location(
  p_trip_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_meters double precision default null
)
returns public.driver_location_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_assignment public.trip_assignments;
  v_location_id uuid;
  v_recorded_at timestamptz;
  v_result public.driver_location_result;
begin
  -- ---------------------------------------------------------------------
  -- Authorization: live-checked, mirrors _driver_execute_trip_transition's
  -- own established chain exactly (work item's own explicit requirement
  -- to reuse existing helpers rather than inventing a parallel check).
  -- ---------------------------------------------------------------------
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- "Ever assigned" visibility check first (mirrors every driver_* RPC) —
  -- a Driver with zero historical relationship to this Trip gets the same
  -- not_found a foreign-org or nonexistent Trip would (no existence
  -- oracle).
  if not public.is_driver_assigned_to_trip(p_trip_id) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- Strict WRITE check: CURRENTLY active assignment only (work item §8/
  -- §14) — a driver who once held this Trip but was reassigned away (or
  -- never held an active assignment at all) fails here with ZW001, the
  -- same "you can see it, you can't act on it" category every other
  -- Driver mutation uses for this exact situation.
  v_assignment := public._lock_driver_active_assignment(p_trip_id, v_trip.organization_id);
  if v_assignment.id is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  -- ---------------------------------------------------------------------
  -- Eligible tracking window (work item §5, lifecycle-model.md §C): the
  -- 5 states between dispatch and arrival — exactly ACTIVE_STATES, the
  -- same set already established in src/lib/operations/presentation.ts
  -- and dispatch-board.ts. Both "arrived" states remain eligible
  -- (deliberate — the Driver is still actively engaged in trip execution:
  -- waiting/loading at pickup, or at the destination before hand-off; a
  -- Dispatcher benefits from confirming the Driver is genuinely there).
  -- `scheduled` (before dispatch) and every terminal state are NOT
  -- eligible — reusing the ZW004 category cancel_trip/record_no_show
  -- already established for "this action is not valid given the Trip's
  -- current lifecycle state" (not literally a rejected state
  -- transition, but the same semantic category).
  -- ---------------------------------------------------------------------
  if v_trip.state <> all (array[
    'en_route_to_pickup', 'arrived_at_pickup', 'passenger_onboard',
    'en_route_to_destination', 'arrived_at_destination'
  ]) then
    raise exception 'illegal_transition' using errcode = 'ZW004';
  end if;

  -- ---------------------------------------------------------------------
  -- Coordinate validation (work item §13) — the CHECK constraints below
  -- are the actual backstop; these mirror them explicitly so a violation
  -- raises this function's own clean ZW006 rather than a raw constraint-
  -- violation error leaking a Postgres message.
  -- ---------------------------------------------------------------------
  if p_latitude is null or p_longitude is null
     or p_latitude < -90 or p_latitude > 90
     or p_longitude < -180 or p_longitude > 180 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if p_accuracy_meters is not null and p_accuracy_meters < 0 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  -- Server-authoritative timestamp — never client-supplied (this
  -- migration's own header comment).
  v_recorded_at := now();

  insert into public.driver_location_updates (
    organization_id, driver_id, trip_id, assignment_id,
    latitude, longitude, accuracy_meters, recorded_at
  ) values (
    v_trip.organization_id, v_assignment.driver_id, p_trip_id, v_assignment.id,
    p_latitude, p_longitude, p_accuracy_meters, v_recorded_at
  )
  returning id into v_location_id;

  v_result.location_id := v_location_id;
  v_result.trip_id := p_trip_id;
  v_result.assignment_id := v_assignment.id;
  v_result.recorded_at := v_recorded_at;
  return v_result;
end;
$$;

comment on function public.driver_record_location(uuid, double precision, double precision, double precision) is
  'Driver-only. The sole controlled path to record a location update. Requires: a real session, live "ever assigned" visibility (ZW002 otherwise), a CURRENTLY active TripAssignment for the calling Driver on this Trip (ZW001 otherwise — covers reassignment revocation), and the Trip currently in one of the 5 eligible execution-window states (ZW004 otherwise — covers terminal-state revocation and pre-dispatch scheduled Trips). recorded_at is always the server''s own now(), never client-supplied. See docs/product/driver-location-architecture.md for the full contract.';

revoke all on function public.driver_record_location(uuid, double precision, double precision, double precision) from public;
grant execute on function public.driver_record_location(uuid, double precision, double precision, double precision) to authenticated;
