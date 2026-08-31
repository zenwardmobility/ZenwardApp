-- Zenward Platform — Driver read API history tests (P1-E2-S3).
--
-- Covers the required history test matrix (§55): own ended assignment
-- visible, another Driver's absent, foreign-org absent, phone/notes/
-- requester absent (structural, cross-checked with
-- driver_read_minimization_tests.sql), invalid/oversized range rejected.
-- Also covers history-after-reassignment (§56): a formerly-assigned
-- Driver appears in their own limited history but does not regain current
-- detailed access. Same SET ROLE/request.jwt.claim.sub methodology as the
-- other suites.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/driver_read_history_tests.sql

\set ON_ERROR_STOP off
\pset pager off

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('91000000-0000-0000-0000-0000000000d1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'History test D1 (reassigned away)', 'History test D1'),
  ('91000000-0000-0000-0000-0000000000d2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'History test D2 (completed by A1)', 'History test D2'),
  ('91000000-0000-0000-0000-0000000000d3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'History test D3 (Driver A2 only)', 'History test D3'),
  ('91000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'scheduled', 'History test E1 (Org B, Driver B1)', 'History test E1');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000d1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1, will be reassigned
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000d2', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1, will complete
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000d3', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2'), -- Driver A2 only
  ('10000000-0000-0000-0000-0000000000b1', '91000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b2'); -- Org B, Driver B1

-- Advance D1: reassign Driver A1 away (ended_at set, end_reason='reassigned', Trip NOT terminal).
do $$
declare v_ar public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_ar := public.reassign_trip('91000000-0000-0000-0000-0000000000d1', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign D1 to Driver A2');
  reset role;
end $$;

-- Advance D2: Driver A1 completes it (ended_at set, end_reason='trip_completed', Trip IS terminal).
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_start_to_pickup('91000000-0000-0000-0000-0000000000d2', 'scheduled');
  v_r := public.driver_arrive_at_pickup('91000000-0000-0000-0000-0000000000d2', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('91000000-0000-0000-0000-0000000000d2', 'arrived_at_pickup');
  v_r := public.driver_start_to_destination('91000000-0000-0000-0000-0000000000d2', 'passenger_onboard');
  v_r := public.driver_arrive_at_destination('91000000-0000-0000-0000-0000000000d2', 'en_route_to_destination');
  v_r := public.driver_complete_trip('91000000-0000-0000-0000-0000000000d2', 'arrived_at_destination');
  reset role;
  if v_r.current_state <> 'completed' then
    raise notice 'TEST HISTORY-setup: FAIL (Trip D2 did not reach completed, got %)', v_r.current_state;
  end if;
end $$;

-- Advance D3: Driver A2 completes it (Driver A1 has zero involvement).
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2
  v_r := public.driver_start_to_pickup('91000000-0000-0000-0000-0000000000d3', 'scheduled');
  v_r := public.driver_arrive_at_pickup('91000000-0000-0000-0000-0000000000d3', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('91000000-0000-0000-0000-0000000000d3', 'arrived_at_pickup');
  v_r := public.driver_start_to_destination('91000000-0000-0000-0000-0000000000d3', 'passenger_onboard');
  v_r := public.driver_arrive_at_destination('91000000-0000-0000-0000-0000000000d3', 'en_route_to_destination');
  v_r := public.driver_complete_trip('91000000-0000-0000-0000-0000000000d3', 'arrived_at_destination');
  reset role;
end $$;

-- Advance E1 (Org B): Driver B1 completes it.
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Driver B1
  v_r := public.driver_start_to_pickup('91000000-0000-0000-0000-0000000000e1', 'scheduled');
  v_r := public.driver_arrive_at_pickup('91000000-0000-0000-0000-0000000000e1', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('91000000-0000-0000-0000-0000000000e1', 'arrived_at_pickup');
  v_r := public.driver_start_to_destination('91000000-0000-0000-0000-0000000000e1', 'passenger_onboard');
  v_r := public.driver_arrive_at_destination('91000000-0000-0000-0000-0000000000e1', 'en_route_to_destination');
  v_r := public.driver_complete_trip('91000000-0000-0000-0000-0000000000e1', 'arrived_at_destination');
  reset role;
end $$;

-- =============================================================================
-- Own ended assignment (both D1-reassigned and D2-completed) visible;
-- trip_outcome reflects the actual distinction (§56: reassignment !=
-- current authority, so D1 shows a NULL outcome — Trip continued past
-- Driver A1's involvement and is not terminal — while D2 correctly shows
-- 'completed').
-- =============================================================================
do $$
declare v_d1_outcome text; v_d1_end_reason text; v_d2_outcome text; v_d2_end_reason text; v_found_d1 boolean; v_found_d2 boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  select true, trip_outcome, end_reason into v_found_d1, v_d1_outcome, v_d1_end_reason
    from public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, null, null)
    where trip_id = '91000000-0000-0000-0000-0000000000d1';
  select true, trip_outcome, end_reason into v_found_d2, v_d2_outcome, v_d2_end_reason
    from public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, null, null)
    where trip_id = '91000000-0000-0000-0000-0000000000d2';
  reset role;
  if coalesce(v_found_d1, false) and v_d1_outcome is null and coalesce(v_found_d2, false) and v_d2_outcome = 'completed' then
    raise notice 'TEST HISTORY-1 (own ended assignments): PASS (D1 visible with NULL outcome — reassigned away, Trip not terminal, later Driver''s progress not revealed; D2 visible with outcome=completed; end_reasons: D1=%, D2=%)', v_d1_end_reason, v_d2_end_reason;
  else
    raise notice 'TEST HISTORY-1: FAIL (found_d1=%, d1_outcome=%, found_d2=%, d2_outcome=%)', v_found_d1, v_d1_outcome, v_found_d2, v_d2_outcome;
  end if;
end $$;

-- =============================================================================
-- Another Driver's ended assignment -> absent.
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  select count(*) into v_count from public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, null, null)
    where trip_id = '91000000-0000-0000-0000-0000000000d3'; -- Driver A2's own trip, A1 never touched it
  reset role;
  if v_count = 0 then
    raise notice 'TEST HISTORY-2 (another Driver''s assignment): PASS (absent from Driver A1''s history)';
  else
    raise notice 'TEST HISTORY-2 (another Driver''s assignment): FAIL (expected 0, got %)', v_count;
  end if;
end $$;

-- =============================================================================
-- Foreign-org history -> absent (calling with Org A context never returns
-- Org B rows regardless).
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, null, null)
    where trip_id = '91000000-0000-0000-0000-0000000000e1';
  reset role;
  if v_count = 0 then
    raise notice 'TEST HISTORY-3 (foreign-org history): PASS (Org B trip absent from an Org A history query)';
  else
    raise notice 'TEST HISTORY-3 (foreign-org history): FAIL (expected 0, got %)', v_count;
  end if;
end $$;

-- Driver B1 querying their OWN org's history correctly sees their own completed Trip.
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Driver B1
  select count(*) into v_count from public.driver_list_trip_history('10000000-0000-0000-0000-0000000000b1'::uuid, null, null)
    where trip_id = '91000000-0000-0000-0000-0000000000e1';
  reset role;
  if v_count = 1 then
    raise notice 'TEST HISTORY-3B (own-org history): PASS (Driver B1 sees their own completed Org B Trip in their own org''s history)';
  else
    raise notice 'TEST HISTORY-3B (own-org history): FAIL (expected 1, got %)', v_count;
  end if;
end $$;

-- =============================================================================
-- Structural absence of phone/notes/requester/passenger-identity fields in
-- history (cross-checked with driver_read_minimization_tests.sql's exact
-- column-set assertion on driver_trip_history_entry).
-- =============================================================================
do $$
declare v_bad text;
begin
  select string_agg(attname, ',') into v_bad
  from pg_attribute
  where attrelid = 'public.driver_trip_history_entry'::regclass and attnum > 0 and not attisdropped
    and (attname ilike '%phone%' or attname ilike '%note%' or attname ilike '%requester%'
         or attname ilike '%passenger%' or attname ilike '%pickup_description%' or attname ilike '%destination_description%'
         or attname ilike '%instruction%' or attname ilike '%assistance%');
  if v_bad is null then
    raise notice 'TEST HISTORY-4 (materially redacted): PASS (driver_trip_history_entry has no phone/note/requester/passenger-identity/address/assistance column at all)';
  else
    raise notice 'TEST HISTORY-4 (materially redacted): FAIL (found: %)', v_bad;
  end if;
end $$;

-- =============================================================================
-- Invalid/oversized date range rejected (§29, §55) — a query-cost/privacy
-- safeguard, not a business retention rule.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, now(), now() - interval '1 day'); -- inverted range
    raise notice 'TEST HISTORY-5 (inverted range): FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST HISTORY-5 (inverted range): PASS (rejected as invalid_input)';
  when others then
    raise notice 'TEST HISTORY-5 (inverted range): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    perform public.driver_list_trip_history('10000000-0000-0000-0000-0000000000a1'::uuid, now() - interval '400 days', now()); -- exceeds 180-day cap
    raise notice 'TEST HISTORY-6 (oversized range): FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST HISTORY-6 (oversized range): PASS (rejected as invalid_input, exceeds the 180-day cap)';
  when others then
    raise notice 'TEST HISTORY-6 (oversized range): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- History-after-reassignment does NOT restore current detailed access
-- (§56, cross-checked against driver_read_authorization_tests.sql DETAIL-3).
-- =============================================================================
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, visible in D1's history, but no longer active there
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000d1');
    raise notice 'TEST HISTORY-7 (history visibility != current authority): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST HISTORY-7 (history visibility != current authority): PASS (Driver A1 appears in Trip D1''s history but is correctly denied current detailed access)';
  when others then
    raise notice 'TEST HISTORY-7 (history visibility != current authority): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$ begin raise notice '=== Driver read history test suite complete ==='; end $$;
