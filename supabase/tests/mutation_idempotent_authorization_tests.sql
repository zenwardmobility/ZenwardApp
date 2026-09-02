-- Zenward Platform — idempotent authorization edge-case audit (P1-E2-S2A).
--
-- Targeted tests A-F for the interaction between idempotent no-op handling
-- and Driver assignment authorization: proves that "the Trip is already at
-- my target state" alone is never sufficient for a Driver RPC to return
-- success — the caller must also be verifiably the actor who performed
-- that exact transition (trip_events.actor_user_id), or still hold the
-- Trip's active assignment. A formerly/never-assigned Driver merely
-- observing an already-achieved state must be denied, not handed a false
-- idempotent success. Same SET ROLE/request.jwt.claim.sub methodology as
-- the other suites.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/mutation_idempotent_authorization_tests.sql

\set ON_ERROR_STOP off
\pset pager off

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('90000000-0000-0000-0000-0000000000b2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G1', 'Idempotent-auth test G1'),
  ('90000000-0000-0000-0000-0000000000b3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G2', 'Idempotent-auth test G2'),
  ('90000000-0000-0000-0000-0000000000b4', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G3', 'Idempotent-auth test G3'),
  ('90000000-0000-0000-0000-0000000000b5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G4', 'Idempotent-auth test G4'),
  ('90000000-0000-0000-0000-0000000000b6', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G5', 'Idempotent-auth test G5'),
  ('90000000-0000-0000-0000-0000000000b7', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Idempotent-auth test G6', 'Idempotent-auth test G6');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b2', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b3', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b4', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b5', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b6', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000b7', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'); -- Driver A1

-- =============================================================================
-- A. Driver A1 performs the transition themselves, is then reassigned away
-- to Driver A2, and retries the SAME action. Expected: idempotent success
-- -- this IS Driver A1's own prior action, so this is a legitimate retry
-- even though they are no longer actively assigned.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b2', 'scheduled');
  reset role;
  if v_r.current_state <> 'en_route_to_pickup' then
    raise notice 'TEST G-A-setup: FAIL (Driver A1 could not perform the initial transition, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_ar public.trip_assignment_result; v_expected uuid;
begin
  select id into v_expected from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000b2' and ended_at is null;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_ar := public.reassign_trip('90000000-0000-0000-0000-0000000000b2', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign to Driver A2', v_expected);
  reset role;
  if not v_ar.changed then
    raise notice 'TEST G-A-setup: FAIL (reassignment to Driver A2 did not happen)';
  end if;
end $$;

do $$
declare v_r public.trip_transition_result; v_events int;
begin
  select count(*) into v_events from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b2' and event_type = 'en_route_to_pickup';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, now reassigned away, retrying THEIR OWN action
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b2', 'scheduled');
  reset role;
  if v_r.changed = false and v_r.current_state = 'en_route_to_pickup' and v_events = 1 then
    raise notice 'TEST A: PASS (Driver A1 retrying their OWN prior action gets idempotent success even after being reassigned away, no duplicate TripEvent)';
  else
    raise notice 'TEST A: FAIL (changed=%, state=%, prior_event_count=%)', v_r.changed, v_r.current_state, v_events;
  end if;
end $$;

-- =============================================================================
-- B. Driver A1 is reassigned away BEFORE performing any transition; Driver
-- A2 performs en_route_to_pickup -> arrived_at_pickup. Driver A1 then
-- calls driver_arrive_at_pickup. Expected: DENY (ZW001) -- A1 never
-- performed this transition; A2 did.
-- =============================================================================
do $$
declare v_ar public.trip_assignment_result; v_expected uuid;
begin
  select id into v_expected from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000b3' and ended_at is null;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_ar := public.reassign_trip('90000000-0000-0000-0000-0000000000b3', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign to Driver A2 before any progress', v_expected);
  reset role;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b3', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000b3', 'en_route_to_pickup');
  reset role;
  if v_r.current_state <> 'arrived_at_pickup' then
    raise notice 'TEST G-B-setup: FAIL (Driver A2 could not progress Trip G2, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result; v_events_before int; v_events_after int;
begin
  select count(*) into v_events_before from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b3' and event_type = 'arrived_at_pickup';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, formerly assigned, never performed this
  begin
    v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000b3', null);
    raise notice 'TEST B: FAIL (expected denial, got success changed=%, state=%)', v_r.changed, v_r.current_state;
  exception when sqlstate 'ZW001' then
    reset role;
    select count(*) into v_events_after from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b3' and event_type = 'arrived_at_pickup';
    if v_events_after = v_events_before then
      raise notice 'TEST B: PASS (Driver A1 denied unauthorized -- A2 performed this transition, not A1 -- no duplicate TripEvent, count remains %)', v_events_after;
    else
      raise notice 'TEST B: FAIL (denied correctly but event count changed: before=%, after=%)', v_events_before, v_events_after;
    end if;
  when others then
    raise notice 'TEST B: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C. A same-org Driver who was NEVER assigned to this Trip at all calls a
-- Driver RPC whose target state already holds. Expected: ZW002 not_found
-- (already denied at the ever-assigned gate, before idempotency is even
-- considered).
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b4', 'scheduled');
  reset role;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, never assigned to G3 at all
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b4', null);
    raise notice 'TEST C: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST C: PASS (never-assigned same-org Driver denied as not_found, before idempotency is even considered)';
  when others then
    raise notice 'TEST C: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- D. A foreign-org Driver calls a Driver RPC whose target state already
-- holds. Expected: ZW002 not_found, no existence disclosure.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b5', 'scheduled');
  reset role;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Driver B1, Org B, no relationship to Org A's Trip G4
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b5', null);
    raise notice 'TEST D: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST D: PASS (foreign-org Driver denied as not_found, no existence disclosure)';
  when others then
    raise notice 'TEST D: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- E. REQUIRED EXISTING BEHAVIOR: the Driver who actually performed
-- driver_complete_trip retries the exact call after their assignment has
-- been closed. Expected: idempotent success, no duplicate TripEvent.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b6', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000b6', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000b6', 'arrived_at_pickup');
  v_r := public.driver_start_to_destination('90000000-0000-0000-0000-0000000000b6', 'passenger_onboard');
  v_r := public.driver_arrive_at_destination('90000000-0000-0000-0000-0000000000b6', 'en_route_to_destination');
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000b6', 'arrived_at_destination');
  reset role;
  if v_r.current_state <> 'completed' then
    raise notice 'TEST G-E-setup: FAIL (Driver A1 could not complete Trip G5, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result; v_events int;
begin
  select count(*) into v_events from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b6' and event_type = 'trip_completed';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, the actual completer, retrying
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000b6', 'arrived_at_destination');
  reset role;
  if v_r.changed = false and v_r.current_state = 'completed' and v_events = 1 then
    raise notice 'TEST E: PASS (the actual completer retrying driver_complete_trip still gets idempotent success — required behavior preserved, no duplicate TripEvent)';
  else
    raise notice 'TEST E: FAIL (changed=%, state=%, event_count=%)', v_r.changed, v_r.current_state, v_events;
  end if;
end $$;

-- =============================================================================
-- F. A formerly assigned Driver who did NOT perform completion calls
-- driver_complete_trip after another Driver completed it. Expected: DENY,
-- not treated as the legitimate idempotent retry actor.
-- =============================================================================
do $$
declare v_ar public.trip_assignment_result; v_r public.trip_transition_result; v_expected uuid;
begin
  select id into v_expected from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000b7' and ended_at is null;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_ar := public.reassign_trip('90000000-0000-0000-0000-0000000000b7', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign to Driver A2 before any progress', v_expected);
  reset role;

  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000b7', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000b7', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000b7', 'arrived_at_pickup');
  v_r := public.driver_start_to_destination('90000000-0000-0000-0000-0000000000b7', 'passenger_onboard');
  v_r := public.driver_arrive_at_destination('90000000-0000-0000-0000-0000000000b7', 'en_route_to_destination');
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000b7', 'arrived_at_destination');
  reset role;
  if v_r.current_state <> 'completed' then
    raise notice 'TEST G-F-setup: FAIL (Driver A2 could not complete Trip G6, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result; v_events_before int; v_events_after int;
begin
  select count(*) into v_events_before from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b7' and event_type = 'trip_completed';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, formerly assigned, never performed completion
  begin
    v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000b7', null);
    raise notice 'TEST F: FAIL (expected denial, got success changed=%, state=%)', v_r.changed, v_r.current_state;
  exception when sqlstate 'ZW001' then
    reset role;
    select count(*) into v_events_after from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000b7' and event_type = 'trip_completed';
    if v_events_after = v_events_before then
      raise notice 'TEST F: PASS (Driver A1 correctly NOT treated as the legitimate idempotent retry actor -- A2 completed it, not A1 -- no duplicate TripEvent, count remains %)', v_events_after;
    else
      raise notice 'TEST F: FAIL (denied correctly but event count changed: before=%, after=%)', v_events_before, v_events_after;
    end if;
  when others then
    raise notice 'TEST F: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$ begin raise notice '=== Idempotent authorization edge-case audit test suite complete ==='; end $$;
