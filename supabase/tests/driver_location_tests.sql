-- Zenward Platform — Driver location tracking tests (P1-E3-S7A).
--
-- Covers driver_record_location: eligible-Driver write, wrong-Driver
-- denial, foreign-org denial, inactive-Membership denial, inactive-Driver
-- denial, reassignment revocation, terminal-state revocation, the
-- pre-dispatch "scheduled" state denial, coordinate/accuracy validation,
-- anon denial, the movement/second-update case, and Operations'
-- own-org-only SELECT (including the explicit absence of any Driver SELECT
-- grant on this table at all). Same SET ROLE/request.jwt.claim.sub
-- methodology as every other suite in this repository.
--
-- Fixtures: dedicated trips under this file's own 95000000-...-eN
-- namespace, never used by supabase/seed.sql or any other test file.
-- Designed to run ONCE against freshly-seeded data (supabase db reset).
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/driver_location_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres, bypasses RLS)
-- ---------------------------------------------------------------------------
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('95000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Location test L1', 'Location test L1'),
  ('95000000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Location test L2', 'Location test L2'),
  ('95000000-0000-0000-0000-0000000000e3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Location test L3', 'Location test L3'),
  ('95000000-0000-0000-0000-0000000000e4', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Location test L4', 'Location test L4'),
  ('95000000-0000-0000-0000-0000000000e5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'completed', 'Location test L5', 'Location test L5'),
  ('95000000-0000-0000-0000-0000000000e6', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Location test L6', 'Location test L6'),
  ('95000000-0000-0000-0000-0000000000e7', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Location test L7 (not yet dispatched)', 'Location test L7'),
  ('95000000-0000-0000-0000-0000000000e8', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'en_route_to_pickup', 'Location test L8 (Org B)', 'Location test L8');

-- L1/L2/L6/L7: active assignment, Driver A1. L3: active assignment, Driver
-- A2 (so Driver A1 attempting to post against L3 is the "wrong Driver"
-- case). L4: active assignment, Driver A1 (will be reassigned to Driver
-- A2 mid-test). L5 (terminal): a CLOSED (historical) assignment for
-- Driver A1 — mirrors a real completed Trip, where completion closes the
-- assignment as a normal side effect. L8: active assignment, Org B Driver.
insert into public.trip_assignments (id, organization_id, trip_id, driver_id, assigned_by, ended_at, end_reason) values
  ('95100000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e2', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e3', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e3', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e4', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e4', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e5', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e5', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', now(), 'trip_completed'),
  ('95100000-0000-0000-0000-0000000000e6', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e6', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e7', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e7', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', null, null),
  ('95100000-0000-0000-0000-0000000000e8', '10000000-0000-0000-0000-0000000000b1', '95000000-0000-0000-0000-0000000000e8', '30000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b2', null, null);

-- =============================================================================
-- TEST LOC-A: eligible Driver, active assignment, eligible state -> PASS
-- Driver A1 (user ...a3) posts against L1.
-- =============================================================================
do $$
declare v_r public.driver_location_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_record_location('95000000-0000-0000-0000-0000000000e1', 33.7490, -84.3880, 12.5);
  if v_r.location_id is not null and v_r.trip_id = '95000000-0000-0000-0000-0000000000e1'
     and v_r.assignment_id = '95100000-0000-0000-0000-0000000000e1' then
    raise notice 'TEST LOC-A: PASS (eligible Driver wrote a real location row, correct trip/assignment)';
  else
    raise notice 'TEST LOC-A: FAIL (got location_id=%, trip_id=%, assignment_id=%)', v_r.location_id, v_r.trip_id, v_r.assignment_id;
  end if;
end $$;
reset role;

-- Independent DB verification (as postgres) — not trusting the RPC's own return value alone.
do $$
declare v_count int;
begin
  select count(*) into v_count from public.driver_location_updates
    where trip_id = '95000000-0000-0000-0000-0000000000e1'
      and organization_id = '10000000-0000-0000-0000-0000000000a1'
      and driver_id = '30000000-0000-0000-0000-0000000000a1'
      and assignment_id = '95100000-0000-0000-0000-0000000000e1'
      and latitude = 33.7490 and longitude = -84.3880 and accuracy_meters = 12.5;
  if v_count = 1 then
    raise notice 'TEST LOC-A-DB: PASS (row independently confirmed with correct org/driver/trip/assignment/coordinates)';
  else
    raise notice 'TEST LOC-A-DB: FAIL (expected 1 matching row, got %)', v_count;
  end if;
end $$;

-- =============================================================================
-- TEST LOC-B: movement — a second, distinct coordinate from the same
-- Driver on the same Trip becomes the new authoritative latest position.
-- =============================================================================
do $$
begin
  perform pg_sleep(1.1); -- ensure a distinct, later recorded_at
end $$;

do $$
declare v_r public.driver_location_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_record_location('95000000-0000-0000-0000-0000000000e1', 33.7520, -84.3910, 8.0);
  if v_r.location_id is not null then
    raise notice 'TEST LOC-B: PASS (second update accepted)';
  else
    raise notice 'TEST LOC-B: FAIL (second update rejected)';
  end if;
end $$;
reset role;

do $$
declare v_lat double precision; v_count int;
begin
  select count(*) into v_count from public.driver_location_updates where trip_id = '95000000-0000-0000-0000-0000000000e1';
  select latitude into v_lat from public.driver_location_updates
    where trip_id = '95000000-0000-0000-0000-0000000000e1'
    order by recorded_at desc limit 1;
  if v_count = 2 and v_lat = 33.7520 then
    raise notice 'TEST LOC-B-DB: PASS (2 history rows exist; DISTINCT-ON-style latest query returns the second, later coordinate)';
  else
    raise notice 'TEST LOC-B-DB: FAIL (count=%, latest lat=%)', v_count, v_lat;
  end if;
end $$;

-- =============================================================================
-- TEST LOC-C: wrong Driver — Driver A2 (assigned to L3, not L1) attempts
-- to post against L1 (Driver A1's own active assignment). L1 has an
-- historical relationship for A1 only, so this is the same "not_found"
-- (never assigned) category the driver_* mutation RPCs already establish.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e1', 33.75, -84.39, null);
    raise notice 'TEST LOC-C: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST LOC-C: PASS (DENY ZW002, Driver A2 has no relationship to L1)';
  when others then
    raise notice 'TEST LOC-C: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-D: foreign-org Driver — Org B Driver attempts to post against
-- an Org A Trip. Must be indistinguishable from "never assigned" (no
-- existence oracle).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Org B Driver
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e1', 33.75, -84.39, null);
    raise notice 'TEST LOC-D: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST LOC-D: PASS (DENY ZW002, foreign-org Driver, no existence disclosure)';
  when others then
    raise notice 'TEST LOC-D: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-E: inactive Membership -> DENY. Temporarily toggle Driver A1's
-- membership to inactive against a dedicated fixture trip (L6), test,
-- restore.
-- =============================================================================
do $$
begin
  update public.memberships set status = 'inactive'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a3';
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, now inactive membership
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e6', 33.75, -84.39, null);
    raise notice 'TEST LOC-E: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST LOC-E: PASS (DENY ZW002, inactive Membership, live-checked)';
  when others then
    raise notice 'TEST LOC-E: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  update public.memberships set status = 'active'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a3';
end $$;

-- =============================================================================
-- TEST LOC-F: inactive Driver row (Membership itself still active) -> DENY.
-- Same toggle/restore pattern, same fixture trip L6.
-- =============================================================================
do $$
begin
  update public.drivers set status = 'inactive' where id = '30000000-0000-0000-0000-0000000000a1';
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, Driver row now inactive
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e6', 33.75, -84.39, null);
    raise notice 'TEST LOC-F: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST LOC-F: PASS (DENY ZW002, inactive Driver row, current_driver_id fails closed)';
  when others then
    raise notice 'TEST LOC-F: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  update public.drivers set status = 'active' where id = '30000000-0000-0000-0000-0000000000a1';
end $$;

-- =============================================================================
-- TEST LOC-G / LOC-H: reassignment revocation (work item §14, the
-- mandatory scenario). Driver A1 posts successfully against L4. Trip is
-- then reassigned to Driver A2 (closing A1's assignment, opening a new
-- active one for A2 — exactly what reassign_trip itself does). Driver A1's
-- next post is DENIED; Driver A2's is ALLOWED.
-- =============================================================================
do $$
declare v_r public.driver_location_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_record_location('95000000-0000-0000-0000-0000000000e4', 33.70, -84.30, null);
  if v_r.location_id is not null then
    raise notice 'TEST LOC-G-setup: PASS (Driver A1 posted successfully before reassignment)';
  else
    raise notice 'TEST LOC-G-setup: FAIL (initial post failed)';
  end if;
end $$;
reset role;

-- Reassign L4 from Driver A1 to Driver A2 — same append-oriented pattern
-- reassign_trip itself uses (close current active row, insert a new one).
do $$
begin
  update public.trip_assignments set ended_at = now(), end_reason = 'reassigned'
    where id = '95100000-0000-0000-0000-0000000000e4';
  insert into public.trip_assignments (id, organization_id, trip_id, driver_id, assigned_by)
    values ('95100000-0000-0000-0000-0000000000e9', '10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000e4', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2');
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, now reassigned away
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e4', 33.71, -84.31, null);
    raise notice 'TEST LOC-G: FAIL (former Driver A1 posted successfully after reassignment — should have been denied)';
  exception when sqlstate 'ZW001' then
    raise notice 'TEST LOC-G: PASS (DENY ZW001, former Driver correctly revoked same-session, same active token)';
  when others then
    raise notice 'TEST LOC-G: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.driver_location_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, newly assigned
  v_r := public.driver_record_location('95000000-0000-0000-0000-0000000000e4', 33.72, -84.32, null);
  if v_r.location_id is not null and v_r.assignment_id = '95100000-0000-0000-0000-0000000000e9' then
    raise notice 'TEST LOC-H: PASS (new Driver A2 can post immediately, tied to the NEW assignment id)';
  else
    raise notice 'TEST LOC-H: FAIL (new Driver post failed or wrong assignment_id=%)', v_r.assignment_id;
  end if;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-I: terminal-state revocation. L5 is `completed`, with a CLOSED
-- assignment for Driver A1 (mirrors real completion — the assignment ends
-- as a normal side effect). Driver A1's post is DENIED even though they
-- once genuinely held this Trip.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e5', 33.75, -84.39, null);
    raise notice 'TEST LOC-I: FAIL (expected denial on completed Trip, got success)';
  exception when sqlstate 'ZW001' then
    raise notice 'TEST LOC-I: PASS (DENY ZW001 — no active assignment on a terminal Trip, assignment already closed)';
  when others then
    raise notice 'TEST LOC-I: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-J: pre-dispatch `scheduled` state — NOT an eligible tracking
-- window (work item §5's explicit "do not track a merely scheduled
-- Driver" rule), even with a genuine active assignment in place (L7).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e7', 33.75, -84.39, null);
    raise notice 'TEST LOC-J: FAIL (expected denial on scheduled Trip, got success)';
  exception when sqlstate 'ZW004' then
    raise notice 'TEST LOC-J: PASS (DENY ZW004 — scheduled is outside the eligible tracking window, despite a genuine active assignment)';
  when others then
    raise notice 'TEST LOC-J: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-K/L/M: coordinate/accuracy validation (work item §13) — a
-- genuinely eligible Driver+Trip+state (L2), invalid input only.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e2', 95.0, -84.39, null); -- latitude out of range
    raise notice 'TEST LOC-K: FAIL (expected denial on invalid latitude, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST LOC-K: PASS (DENY ZW006 — latitude 95.0 out of [-90,90] range)';
  when others then
    raise notice 'TEST LOC-K: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e2', 33.75, -200.0, null); -- longitude out of range
    raise notice 'TEST LOC-L: FAIL (expected denial on invalid longitude, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST LOC-L: PASS (DENY ZW006 — longitude -200.0 out of [-180,180] range)';
  when others then
    raise notice 'TEST LOC-L: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e2', 33.75, -84.39, -5.0); -- negative accuracy
    raise notice 'TEST LOC-M: FAIL (expected denial on negative accuracy, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST LOC-M: PASS (DENY ZW006 — accuracy_meters -5.0 is negative)';
  when others then
    raise notice 'TEST LOC-M: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-N: anon cannot write.
-- =============================================================================
do $$
begin
  set local role anon;
  begin
    perform public.driver_record_location('95000000-0000-0000-0000-0000000000e2', 33.75, -84.39, null);
    raise notice 'TEST LOC-N: FAIL (anon call succeeded — should have been denied)';
  exception when others then
    raise notice 'TEST LOC-N: PASS (denied: %)', sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-O/P: Operations read path — own-org SELECT works, foreign-org
-- SELECT returns zero rows (RLS, not an error — matches the established
-- convention for every other Operations-read table).
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  select count(*) into v_count from public.driver_location_updates where organization_id = '10000000-0000-0000-0000-0000000000a1';
  if v_count > 0 then
    raise notice 'TEST LOC-O: PASS (Org A dispatcher reads % own-org location row(s))', v_count;
  else
    raise notice 'TEST LOC-O: FAIL (expected > 0 own-org rows, got %)', v_count;
  end if;
end $$;
reset role;

do $$
declare v_r public.driver_location_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Org B Driver, eligible on their own org's Trip
  v_r := public.driver_record_location('95000000-0000-0000-0000-0000000000e8', 32.08, -81.09, null);
end $$;
reset role;

do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  select count(*) into v_count from public.driver_location_updates where organization_id = '10000000-0000-0000-0000-0000000000b1';
  if v_count = 0 then
    raise notice 'TEST LOC-P: PASS (Org A dispatcher sees ZERO Org B location rows, despite a real Org B row existing)';
  else
    raise notice 'TEST LOC-P: FAIL (expected 0, got % — cross-tenant location leak)', v_count;
  end if;
end $$;
reset role;

-- =============================================================================
-- TEST LOC-Q: Driver cannot broadly read location data at all — no SELECT
-- POLICY exists for Driver on this table (work item §42), only the org-
-- operations policy. The table-level `grant select ... to authenticated`
-- is broad (same shape as `passengers`' own grant, ZD-080) — RLS is what
-- actually restricts it: a Driver's query does not error, it correctly
-- returns ZERO rows, exactly the established pattern rls_adversarial_
-- tests.sql's own TEST E already uses for the identical "no Driver
-- policy exists" situation on `passengers`.
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  select count(*) into v_count from public.driver_location_updates;
  if v_count = 0 then
    raise notice 'TEST LOC-Q: PASS (Driver sees ZERO location rows via RLS — no Driver SELECT policy exists on this table, despite real rows existing)';
  else
    raise notice 'TEST LOC-Q: FAIL (expected 0, got % — Driver can read location data)', v_count;
  end if;
end $$;
reset role;

do $$ begin raise notice '=== Driver location test suite complete — review PASS/FAIL lines above ==='; end $$;
