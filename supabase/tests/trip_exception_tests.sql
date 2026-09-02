-- Zenward Platform — TripException mutation tests (P1-E3-S8).
--
-- Covers report_trip_exception (Operations + Driver actor populations)
-- and resolve_trip_exception (Operations only): positive paths, anon
-- denial, foreign-org denial, never-assigned-Driver denial, Driver
-- resolve denial, inactive-Membership denial, invalid-input validation,
-- the idempotent stale-resolution no-op, resolving a nonexistent
-- exception, and a forced-failure atomicity proof. Same SET ROLE/
-- request.jwt.claim.sub methodology as every other suite in this
-- repository.
--
-- Fixtures: dedicated trips under this file's own 96000000-...-eN
-- namespace, never used by supabase/seed.sql or any other test file.
-- Designed to run ONCE against freshly-seeded data (supabase db reset).
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/trip_exception_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres, bypasses RLS)
-- ---------------------------------------------------------------------------
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('96000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Exception test E1', 'Exception test E1'),
  ('96000000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Exception test E2', 'Exception test E2'),
  ('96000000-0000-0000-0000-0000000000e3', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'en_route_to_pickup', 'Exception test E3 (Org B)', 'Exception test E3'),
  ('96000000-0000-0000-0000-0000000000e4', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Exception test E4', 'Exception test E4'),
  ('96000000-0000-0000-0000-0000000000e5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Exception test E5', 'Exception test E5');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '96000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '96000000-0000-0000-0000-0000000000e4', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2');
-- E2, E5: no assignment (Driver A1 was never assigned to these).

-- =============================================================================
-- TEST EXC-A: Operations (dispatcher) reports an exception on an own-org
-- Trip -> PASS, created_by/status forced correctly.
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  v_r := public.report_trip_exception('96000000-0000-0000-0000-0000000000e1', 'vehicle_issue', 'Fictional flat tire, waiting for backup vehicle');
  if v_r.exception_id is not null and v_r.status = 'open' and v_r.created_by = '20000000-0000-0000-0000-0000000000a2' then
    raise notice 'TEST EXC-A: PASS (Operations reported a real open exception, created_by correctly forced)';
  else
    raise notice 'TEST EXC-A: FAIL (id=%, status=%, created_by=%)', v_r.exception_id, v_r.status, v_r.created_by;
  end if;
end $$;
reset role;

do $$
declare v_count int; v_event_count int;
begin
  select count(*) into v_count from public.trip_exceptions where trip_id = '96000000-0000-0000-0000-0000000000e1' and status = 'open';
  select count(*) into v_event_count from public.trip_events where trip_id = '96000000-0000-0000-0000-0000000000e1' and event_type = 'exception_flagged';
  if v_count = 1 and v_event_count = 1 then
    raise notice 'TEST EXC-A-DB: PASS (real trip_exceptions row + real exception_flagged trip_events row both independently confirmed)';
  else
    raise notice 'TEST EXC-A-DB: FAIL (exceptions=%, events=%)', v_count, v_event_count;
  end if;
end $$;

-- =============================================================================
-- TEST EXC-B: Driver (currently assigned) reports an exception on their
-- own Trip -> PASS.
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.report_trip_exception('96000000-0000-0000-0000-0000000000e4', 'passenger_not_ready', 'Fictional passenger needs a few more minutes');
  if v_r.exception_id is not null and v_r.created_by = '20000000-0000-0000-0000-0000000000a3' then
    raise notice 'TEST EXC-B: PASS (Driver reported a real exception on their own trip)';
  else
    raise notice 'TEST EXC-B: FAIL (id=%, created_by=%)', v_r.exception_id, v_r.created_by;
  end if;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-C: anon cannot report.
-- =============================================================================
do $$
begin
  set local role anon;
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e1', 'other', 'Fictional anon attempt');
    raise notice 'TEST EXC-C: FAIL (anon call succeeded — should have been denied)';
  exception when others then
    raise notice 'TEST EXC-C: PASS (denied: %)', sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-D: foreign-org Operations cannot report against an Org A Trip.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b2'; -- Org B dispatcher
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e1', 'other', 'Fictional foreign-org attempt');
    raise notice 'TEST EXC-D: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-D: PASS (DENY ZW002, foreign-org Operations, no existence disclosure)';
  when others then
    raise notice 'TEST EXC-D: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-E: never-assigned Driver cannot report against a Trip they
-- have no relationship to.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, never assigned to E2
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e2', 'other', 'Fictional never-assigned attempt');
    raise notice 'TEST EXC-E: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-E: PASS (DENY ZW002, Driver A2 has no relationship to E2)';
  when others then
    raise notice 'TEST EXC-E: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-F: invalid input — blank description.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e1', 'other', '   ');
    raise notice 'TEST EXC-F: FAIL (expected denial on blank description, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST EXC-F: PASS (DENY ZW006 — blank/whitespace-only description)';
  when others then
    raise notice 'TEST EXC-F: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-G: inactive Membership cannot report (live-checked).
-- =============================================================================
do $$
begin
  update public.memberships set status = 'inactive'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a2';
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e1', 'other', 'Fictional inactive membership attempt');
    raise notice 'TEST EXC-G: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-G: PASS (DENY ZW002, inactive Membership, live-checked)';
  when others then
    raise notice 'TEST EXC-G: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  update public.memberships set status = 'active'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a2';
end $$;

-- =============================================================================
-- TEST EXC-H/I: Operations resolves the real exception created in EXC-A ->
-- PASS. Driver can NEVER resolve, even their own reported exception.
-- =============================================================================
do $$
declare v_exception_id uuid;
begin
  select id into v_exception_id from public.trip_exceptions where trip_id = '96000000-0000-0000-0000-0000000000e1' and status = 'open' limit 1;
  perform set_config('zenward.test_exception_id', v_exception_id::text, false);
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1 — must be denied
  begin
    perform public.resolve_trip_exception(current_setting('zenward.test_exception_id')::uuid, 'Fictional driver attempt to resolve');
    raise notice 'TEST EXC-H: FAIL (Driver resolved successfully — should have been denied)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-H: PASS (DENY ZW002 — Driver can never resolve, matches schema''s own established rule)';
  when others then
    raise notice 'TEST EXC-H: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- Org A admin
  v_r := public.resolve_trip_exception(current_setting('zenward.test_exception_id')::uuid, 'Fictional backup vehicle arrived, trip continued');
  if v_r.status = 'resolved' and v_r.resolved_by = '20000000-0000-0000-0000-0000000000a1' and v_r.changed then
    raise notice 'TEST EXC-I: PASS (Operations resolved the real exception, resolved_by/resolved_at correctly set)';
  else
    raise notice 'TEST EXC-I: FAIL (status=%, resolved_by=%, changed=%)', v_r.status, v_r.resolved_by, v_r.changed;
  end if;
end $$;
reset role;

do $$
declare v_count int; v_event_count int;
begin
  select count(*) into v_count from public.trip_exceptions where id = current_setting('zenward.test_exception_id')::uuid and status = 'resolved' and resolved_at is not null;
  select count(*) into v_event_count from public.trip_events where trip_id = '96000000-0000-0000-0000-0000000000e1' and event_type = 'exception_resolved';
  if v_count = 1 and v_event_count = 1 then
    raise notice 'TEST EXC-I-DB: PASS (row genuinely resolved + real exception_resolved trip_events row, both independently confirmed)';
  else
    raise notice 'TEST EXC-I-DB: FAIL (resolved-rows=%, events=%)', v_count, v_event_count;
  end if;
end $$;

-- =============================================================================
-- TEST EXC-J: stale resolution — a SECOND (redundant) resolve attempt is a
-- safe idempotent no-op, never overwriting the real, already-persisted
-- resolution with the stale caller's own note (work item §50).
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- a DIFFERENT dispatcher, resolving "again"
  v_r := public.resolve_trip_exception(current_setting('zenward.test_exception_id')::uuid, 'Fictional STALE note that must never overwrite the real one');
  if v_r.changed = false and v_r.resolution_note = 'Fictional backup vehicle arrived, trip continued' and v_r.resolved_by = '20000000-0000-0000-0000-0000000000a1' then
    raise notice 'TEST EXC-J: PASS (stale resolve is a safe no-op; the REAL first resolution/resolver is preserved, never overwritten)';
  else
    raise notice 'TEST EXC-J: FAIL (changed=%, resolution_note=%, resolved_by=%)', v_r.changed, v_r.resolution_note, v_r.resolved_by;
  end if;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-K: resolving a nonexistent exception id -> ZW002, no oracle.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  begin
    perform public.resolve_trip_exception('99999999-9999-9999-9999-999999999999', null);
    raise notice 'TEST EXC-K: FAIL (expected denial on nonexistent id, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-K: PASS (DENY ZW002, nonexistent exception id)';
  when others then
    raise notice 'TEST EXC-K: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-L: foreign-org Operations cannot resolve an Org B exception.
-- =============================================================================
do $$
declare v_org_b_exception_id uuid;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b2'; -- Org B dispatcher
  perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e3', 'other', 'Fictional Org B exception');
end $$;
reset role;

do $$
declare v_org_b_exception_id uuid;
begin
  select id into v_org_b_exception_id from public.trip_exceptions where trip_id = '96000000-0000-0000-0000-0000000000e3' limit 1;
  perform set_config('zenward.test_org_b_exception_id', v_org_b_exception_id::text, false);
end $$;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- Org A admin
  begin
    perform public.resolve_trip_exception(current_setting('zenward.test_org_b_exception_id')::uuid, 'Fictional cross-org attempt');
    raise notice 'TEST EXC-L: FAIL (Org A admin resolved an Org B exception — should have been denied)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST EXC-L: PASS (DENY ZW002, foreign-org exception, no existence disclosure)';
  when others then
    raise notice 'TEST EXC-L: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- TEST EXC-M: forced-failure atomicity — a late failure (on the
-- trip_events INSERT, each function's own LAST write) rolls back the
-- EARLIER trip_exceptions write within the same call too. Mirrors
-- mutation_atomicity_tests.sql's own established mechanism exactly: a
-- temporary trigger on trip_events, installed and removed by this script.
-- =============================================================================
create or replace function public._test_force_trip_events_failure()
returns trigger
language plpgsql
as $$
begin
  if new.trip_id = '96000000-0000-0000-0000-0000000000e5' then
    raise exception 'forced failure for atomicity test' using errcode = 'ZW999';
  end if;
  return new;
end;
$$;

create trigger _test_force_trip_events_failure_trigger
  before insert on public.trip_events
  for each row execute function public._test_force_trip_events_failure();

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    perform public.report_trip_exception('96000000-0000-0000-0000-0000000000e5', 'other', 'Fictional atomicity test — should never persist');
    raise notice 'TEST EXC-M: FAIL (report_trip_exception succeeded despite the forced trip_events failure)';
  exception when sqlstate 'ZW999' then
    raise notice 'TEST EXC-M: PASS (forced failure raised as expected)';
  when others then
    raise notice 'TEST EXC-M: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

drop trigger _test_force_trip_events_failure_trigger on public.trip_events;
drop function public._test_force_trip_events_failure();

do $$
declare v_count int;
begin
  select count(*) into v_count from public.trip_exceptions where trip_id = '96000000-0000-0000-0000-0000000000e5';
  if v_count = 0 then
    raise notice 'TEST EXC-M-DB: PASS (the earlier trip_exceptions INSERT was rolled back too — no partial write persisted)';
  else
    raise notice 'TEST EXC-M-DB: FAIL (expected 0 trip_exceptions rows for E5, got %)', v_count;
  end if;
end $$;

do $$ begin raise notice '=== TripException mutation test suite complete — review PASS/FAIL lines above ==='; end $$;
