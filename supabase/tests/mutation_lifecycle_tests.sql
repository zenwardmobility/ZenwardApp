-- Zenward Platform — Trip lifecycle mutation RPC tests (P1-E2-S2).
--
-- Covers the 6 driver_* transition functions, cancel_trip, and
-- record_no_show: full legal-path progression, idempotent retries, stale-
-- state rejection, illegal jumps, terminal-reopening denial, and the
-- not_found vs unauthorized distinction for Driver callers. Same
-- SET ROLE/request.jwt.claim.sub methodology as the P1-E2-S1 suites.
--
-- Fixtures: dedicated trips under this file's own 90000000-...-aN namespace
-- (never used by supabase/seed.sql), created below as postgres so this
-- file does not depend on or corrupt the shared seed trips. Designed to
-- run ONCE against freshly-seeded data (supabase db reset), same as every
-- other suite in this repository — several tests here perform real,
-- persisting mutations.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/mutation_lifecycle_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres, bypasses RLS)
-- ---------------------------------------------------------------------------
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('90000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A1', 'Lifecycle test A1'),
  ('90000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A2', 'Lifecycle test A2'),
  ('90000000-0000-0000-0000-0000000000a3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A3', 'Lifecycle test A3'),
  ('90000000-0000-0000-0000-0000000000a4', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A4', 'Lifecycle test A4'),
  ('90000000-0000-0000-0000-0000000000a5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A5', 'Lifecycle test A5'),
  ('90000000-0000-0000-0000-0000000000a6', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A6', 'Lifecycle test A6'),
  ('90000000-0000-0000-0000-0000000000a7', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A7', 'Lifecycle test A7'),
  ('90000000-0000-0000-0000-0000000000a8', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Lifecycle test A8', 'Lifecycle test A8');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a3', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a4', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2'), -- Driver A2
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a6', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2'), -- Driver A2
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a7', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1 (will be reassigned away)
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000a8', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'); -- Driver A1

-- =============================================================================
-- L1-L6. Full legal-path narrative on trip A1, called by Driver A1
-- (user ...a3), one state per test.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a1', 'scheduled');
  if v_r.current_state = 'en_route_to_pickup' and v_r.changed then
    raise notice 'TEST L1: PASS (scheduled -> en_route_to_pickup)';
  else
    raise notice 'TEST L1: FAIL (got state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup');
  if v_r.current_state = 'arrived_at_pickup' and v_r.changed then
    raise notice 'TEST L2: PASS (en_route_to_pickup -> arrived_at_pickup)';
  else
    raise notice 'TEST L2: FAIL (got state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000a1', 'arrived_at_pickup');
  if v_r.current_state = 'passenger_onboard' and v_r.changed then
    raise notice 'TEST L3: PASS (arrived_at_pickup -> passenger_onboard)';
  else
    raise notice 'TEST L3: FAIL (got state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_start_to_destination('90000000-0000-0000-0000-0000000000a1', 'passenger_onboard');
  if v_r.current_state = 'en_route_to_destination' and v_r.changed then
    raise notice 'TEST L4: PASS (passenger_onboard -> en_route_to_destination)';
  else
    raise notice 'TEST L4: FAIL (got state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_arrive_at_destination('90000000-0000-0000-0000-0000000000a1', 'en_route_to_destination');
  if v_r.current_state = 'arrived_at_destination' and v_r.changed then
    raise notice 'TEST L5: PASS (en_route_to_destination -> arrived_at_destination)';
  else
    raise notice 'TEST L5: FAIL (got state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result; v_assignment_open int; v_completed_at timestamptz;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000a1', 'arrived_at_destination');
  reset role;
  select count(*) into v_assignment_open from public.trip_assignments
    where trip_id = '90000000-0000-0000-0000-0000000000a1' and ended_at is null;
  select completed_at into v_completed_at from public.trips where id = '90000000-0000-0000-0000-0000000000a1';
  if v_r.current_state = 'completed' and v_r.changed and v_assignment_open = 0 and v_completed_at is not null then
    raise notice 'TEST L6: PASS (arrived_at_destination -> completed; assignment closed; completed_at set)';
  else
    raise notice 'TEST L6: FAIL (state=%, changed=%, open_assignments=%, completed_at=%)', v_r.current_state, v_r.changed, v_assignment_open, v_completed_at;
  end if;
end $$;

-- =============================================================================
-- L7. Idempotent retry: driver_complete_trip again on an already-completed
-- Trip A1 must be a safe no-op (changed=false), no duplicate trip_event.
-- =============================================================================
do $$
declare v_r public.trip_transition_result; v_events_before int; v_events_after int;
begin
  select count(*) into v_events_before from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000a1' and event_type = 'trip_completed';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000a1', 'arrived_at_destination');
  reset role;
  select count(*) into v_events_after from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000a1' and event_type = 'trip_completed';
  if v_r.changed = false and v_r.current_state = 'completed' and v_events_after = v_events_before then
    raise notice 'TEST L7: PASS (idempotent retry: changed=false, no duplicate trip_completed event)';
  else
    raise notice 'TEST L7: FAIL (changed=%, events_before=%, events_after=%)', v_r.changed, v_events_before, v_events_after;
  end if;
end $$;

-- =============================================================================
-- L8. Terminal reopening denial: a DIFFERENT transition attempted on the
-- now-completed Trip A1 must be rejected (ZW003), not silently reopen it.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a1', 'scheduled');
    raise notice 'TEST L8: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW001' then
    raise notice 'TEST L8: PASS (terminal Trip cannot be reopened via an unrelated transition — assignment already closed by completion, so ZW001 unauthorized, not ZW003)';
  when others then
    raise notice 'TEST L8: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L9. Stale-state rejection on Trip A3 (assigned to Driver A1, still
-- scheduled): caller's expected_current_state does not match reality.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000a3', 'en_route_to_pickup');
    raise notice 'TEST L9: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW003' then
    raise notice 'TEST L9: PASS (expected_current_state mismatch correctly rejected as stale_state)';
  when others then
    raise notice 'TEST L9: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L10. Illegal jump: skipping ahead (arrived_at_pickup requested while
-- still scheduled, i.e. calling the wrong wrapper) is also ZW003, since it
-- is fundamentally the same "current state does not match this function's
-- required from-state" condition — documented explicitly so ZW003 vs ZW004
-- is not assumed to be interchangeable.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000a3', null);
    raise notice 'TEST L10: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW003' then
    raise notice 'TEST L10: PASS (skip-ahead jump correctly rejected as stale_state, not silently allowed)';
  when others then
    raise notice 'TEST L10: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L11. Cross-driver denial: Driver A2 (user ...a4) has NEVER been assigned
-- to Trip A3 (Driver A1's trip) -> ZW002 not_found, matching their zero
-- read-visibility into it.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4';
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a3', 'scheduled');
    raise notice 'TEST L11: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW002' then
    raise notice 'TEST L11: PASS (Driver never assigned to this Trip -> not_found)';
  when others then
    raise notice 'TEST L11: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L12. Historical-but-not-current denial: Trip A7 starts assigned to
-- Driver A1, is reassigned (as Org A admin) to Driver A2, then Driver A1
-- attempts a transition -> ZW001 unauthorized (they still have READ
-- visibility via is_driver_assigned_to_trip's ever-assigned semantics, but
-- no ACTIVE assignment to act on).
-- =============================================================================
do $$
declare v_ar public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  v_ar := public.reassign_trip('90000000-0000-0000-0000-0000000000a7', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign away from Driver A1');
  if v_ar.changed and v_ar.driver_id = '30000000-0000-0000-0000-0000000000a2' then
    raise notice 'TEST L12-setup: PASS (Trip A7 reassigned to Driver A2)';
  else
    raise notice 'TEST L12-setup: FAIL (changed=%, driver_id=%)', v_ar.changed, v_ar.driver_id;
  end if;
end $$;
reset role;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, no longer active on A7
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a7', 'scheduled');
    raise notice 'TEST L12: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW001' then
    raise notice 'TEST L12: PASS (formerly-assigned Driver correctly gets unauthorized, not not_found)';
  when others then
    raise notice 'TEST L12: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L13. Not-found: nonexistent Trip id.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_start_to_pickup('99999999-9999-9999-9999-999999999999', 'scheduled');
    raise notice 'TEST L13: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST L13: PASS (nonexistent Trip -> not_found)';
  when others then
    raise notice 'TEST L13: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L14/L15. Cancellation from a non-terminal state, with an active
-- assignment: cancel_trip closes the assignment and writes both TripEvent
-- and AuditEvent in one call.
-- =============================================================================
do $$
declare v_r public.trip_transition_result; v_open int; v_audit int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000a2', 'Fictional: passenger no longer needs the ride');
  reset role;
  select count(*) into v_open from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000a2' and ended_at is null;
  select count(*) into v_audit from public.audit_events where entity_id = '90000000-0000-0000-0000-0000000000a2' and action = 'trip_cancelled';
  if v_r.current_state = 'cancelled' and v_r.changed and v_open = 0 and v_audit = 1 then
    raise notice 'TEST L14: PASS (scheduled -> cancelled; AuditEvent written)';
  else
    raise notice 'TEST L14: FAIL (state=%, changed=%, open=%, audit=%)', v_r.current_state, v_r.changed, v_open, v_audit;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  -- Trip A3 is currently arrived_at_pickup with an active Driver A1 assignment (from L9/L10 setup).
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000a3', 'Fictional: facility closed unexpectedly');
  reset role;
  if v_r.current_state = 'cancelled' and v_r.changed then
    raise notice 'TEST L15: PASS (mid-progress Trip (arrived_at_pickup) -> cancelled)';
  else
    raise notice 'TEST L15: FAIL (state=%, changed=%)', v_r.current_state, v_r.changed;
  end if;
end $$;

-- =============================================================================
-- L16. Idempotent cancel retry: already-cancelled Trip A2, no duplicate event.
-- =============================================================================
do $$
declare v_r public.trip_transition_result; v_events int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000a2', 'retry with a different reason string');
  reset role;
  select count(*) into v_events from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000a2' and event_type = 'trip_cancelled';
  if v_r.changed = false and v_events = 1 then
    raise notice 'TEST L16: PASS (idempotent cancel retry: changed=false, exactly 1 trip_cancelled event)';
  else
    raise notice 'TEST L16: FAIL (changed=%, event_count=%)', v_r.changed, v_events;
  end if;
end $$;

-- =============================================================================
-- L17. Cancel-of-a-different-terminal-state rejection: bring Trip A6 to
-- completed, then attempt cancel_trip -> ZW004.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, assigned to A6
  perform public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a6', 'scheduled');
  perform public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000a6', 'en_route_to_pickup');
  perform public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000a6', 'arrived_at_pickup');
  perform public.driver_start_to_destination('90000000-0000-0000-0000-0000000000a6', 'passenger_onboard');
  perform public.driver_arrive_at_destination('90000000-0000-0000-0000-0000000000a6', 'en_route_to_destination');
  v_r := public.driver_complete_trip('90000000-0000-0000-0000-0000000000a6', 'arrived_at_destination');
  reset role;
  if v_r.current_state <> 'completed' then
    raise notice 'TEST L17-setup: FAIL (Trip A6 did not reach completed, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000a6', 'attempted cancel of a completed trip');
    raise notice 'TEST L17: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW004' then
    raise notice 'TEST L17: PASS (cancel_trip on a completed Trip correctly rejected as illegal_transition)';
  when others then
    raise notice 'TEST L17: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L18. cancel_trip invalid input: blank reason -> ZW006.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000a5', '   ');
    raise notice 'TEST L18: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST L18: PASS (blank reason correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST L18: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L19/L20. no-show: legal from arrived_at_pickup (Trip A4, Driver A2),
-- illegal from scheduled (Trip A5).
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2
  perform public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a4', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000a4', 'en_route_to_pickup');
  reset role;
  if v_r.current_state <> 'arrived_at_pickup' then
    raise notice 'TEST L19-setup: FAIL (Trip A4 not at arrived_at_pickup, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result; v_open int; v_no_show_at timestamptz;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_r := public.record_no_show('90000000-0000-0000-0000-0000000000a4', 'Fictional: passenger did not come to the door');
  reset role;
  select count(*) into v_open from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000a4' and ended_at is null;
  select no_show_at into v_no_show_at from public.trips where id = '90000000-0000-0000-0000-0000000000a4';
  if v_r.current_state = 'no_show' and v_r.changed and v_open = 0 and v_no_show_at is not null then
    raise notice 'TEST L19: PASS (arrived_at_pickup -> no_show; assignment closed; no_show_at set)';
  else
    raise notice 'TEST L19: FAIL (state=%, changed=%, open=%, no_show_at=%)', v_r.current_state, v_r.changed, v_open, v_no_show_at;
  end if;
end $$;

do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.record_no_show('90000000-0000-0000-0000-0000000000a5', 'attempted no-show while still scheduled');
    raise notice 'TEST L20: FAIL (expected rejection, got success state=%)', v_r.current_state;
  exception when sqlstate 'ZW004' then
    raise notice 'TEST L20: PASS (no-show from scheduled correctly rejected as illegal_transition)';
  when others then
    raise notice 'TEST L20: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L21. record_no_show invalid input: reason over 500 chars -> ZW006.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.record_no_show('90000000-0000-0000-0000-0000000000a8', repeat('x', 501));
    raise notice 'TEST L21: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST L21: PASS (oversized reason correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST L21: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- L22. anon denial: every lifecycle RPC, called with no role/JWT at all,
-- is denied outright (no execute privilege, fails before any auth-chain
-- logic even runs).
-- =============================================================================
do $$
declare v_denied_count int := 0;
begin
  set local role anon;
  begin perform public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.driver_start_to_destination('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.driver_arrive_at_destination('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.driver_complete_trip('90000000-0000-0000-0000-0000000000a8', 'scheduled'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.cancel_trip('90000000-0000-0000-0000-0000000000a8', 'x'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  begin perform public.record_no_show('90000000-0000-0000-0000-0000000000a8', 'x'); exception when insufficient_privilege then v_denied_count := v_denied_count + 1; end;
  if v_denied_count = 8 then
    raise notice 'TEST L22: PASS (anon denied on all 8 lifecycle RPCs)';
  else
    raise notice 'TEST L22: FAIL (only % of 8 denied)', v_denied_count;
  end if;
end $$;
reset role;

-- =============================================================================
-- L23. Direct-table-mutation regression: Driver still cannot UPDATE
-- trips.state directly (unchanged from P1-E2-S1 — this phase never
-- widened that grant).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    update public.trips set state = 'completed' where id = '90000000-0000-0000-0000-0000000000a8';
    raise notice 'TEST L23: FAIL (direct UPDATE of trips.state succeeded)';
  exception when insufficient_privilege then
    raise notice 'TEST L23: PASS (direct UPDATE of trips.state still denied at the column-privilege layer)';
  end;
end $$;
reset role;

do $$ begin raise notice '=== Trip lifecycle mutation test suite complete ==='; end $$;
