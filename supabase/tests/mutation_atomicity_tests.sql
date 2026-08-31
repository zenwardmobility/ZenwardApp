-- Zenward Platform — mutation atomicity / forced-failure rollback test
-- (P1-E2-S2, work item §44). Run as postgres.
--
-- Proves that a multi-statement mutation function (close old assignment,
-- insert new assignment, insert TripEvent, insert AuditEvent) rolls back
-- as a single unit when a LATE statement fails — not merely "no error was
-- observed", but a positive check that every earlier write within that
-- same function call was undone too.
--
-- Mechanism: a temporary trigger on audit_events raises an exception for
-- one specific sentinel `reason` value. reassign_trip's audit_events
-- INSERT is its LAST write, after the trip_assignments close+insert and
-- the trip_events insert — so forcing failure there is the strongest
-- available proof that PL/pgSQL's implicit whole-function transaction
-- (no exception handler inside reassign_trip itself) really does undo
-- everything, not just the statement that errored. The trigger is
-- installed and removed by this script; it is not a permanent object.
--
-- See supabase/tests/mutation_concurrency_test.sh (companion script, run
-- separately — see the docstring there) for the concurrent-mutation test,
-- which genuinely needs two OS processes and so cannot live in one
-- sequential .sql file the way this one can.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/mutation_atomicity_tests.sql

\set ON_ERROR_STOP off
\pset pager off

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('90000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Atomicity test E1', 'Atomicity test E1');

insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2');

-- ---------------------------------------------------------------------------
-- Install the forced-failure trigger.
-- ---------------------------------------------------------------------------
create or replace function public._test_force_audit_failure()
returns trigger
language plpgsql
as $$
begin
  if new.reason = '__ATOMICITY_TEST_FORCED_FAILURE__' then
    raise exception 'forced failure for atomicity test' using errcode = 'ZW999';
  end if;
  return new;
end;
$$;

create trigger _test_force_audit_failure_trigger
  before insert on public.audit_events
  for each row execute function public._test_force_audit_failure();

-- ---------------------------------------------------------------------------
-- E1. Attempt a reassignment whose AuditEvent insert is forced to fail.
-- Expect: the whole call fails, and NOTHING it did persists.
-- ---------------------------------------------------------------------------
do $$
declare
  v_before_driver uuid; v_before_ended timestamptz;
  v_events_before int; v_assignments_before int;
begin
  select driver_id, ended_at into v_before_driver, v_before_ended
    from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000e1' and ended_at is null;
  select count(*) into v_events_before from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000e1';
  select count(*) into v_assignments_before from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000e1';

  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  begin
    perform public.reassign_trip('90000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000a2', null, '__ATOMICITY_TEST_FORCED_FAILURE__');
    raise notice 'TEST E1: FAIL (expected the forced failure to propagate, but the call succeeded)';
  exception when sqlstate 'ZW999' then
    -- Expected. Check nothing done before the forced failure persisted.
    -- Still running as the dispatcher (SET LOCAL is still in effect) —
    -- that role already has org-scoped SELECT on both tables, so no role
    -- switch is needed (RESET ROLE mid-block is not valid PL/pgSQL syntax
    -- here; it is only used between top-level DO statements elsewhere).
    declare
      v_after_driver uuid; v_after_ended timestamptz;
      v_events_after int; v_assignments_after int;
    begin
      select driver_id, ended_at into v_after_driver, v_after_ended
        from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000e1' and ended_at is null;
      select count(*) into v_events_after from public.trip_events where trip_id = '90000000-0000-0000-0000-0000000000e1';
      select count(*) into v_assignments_after from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000e1';

      if v_after_driver = v_before_driver
         and v_after_ended is null
         and v_events_after = v_events_before
         and v_assignments_after = v_assignments_before then
        raise notice 'TEST E1: PASS (forced late failure rolled back everything: original assignment still active with original driver, no new trip_assignments row, no new trip_events row)';
      else
        raise notice 'TEST E1: FAIL (partial write survived — before: driver=%, ended=%, events=%, rows=% / after: driver=%, ended=%, events=%, rows=%)',
          v_before_driver, v_before_ended, v_events_before, v_assignments_before,
          v_after_driver, v_after_ended, v_events_after, v_assignments_after;
      end if;
    end;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------------
-- Independently confirm no audit_events row leaked through either (the
-- trigger raises BEFORE the row would have been visible to this session
-- regardless, but this checks the durable end state directly).
-- ---------------------------------------------------------------------------
do $$
declare v_count int;
begin
  select count(*) into v_count from public.audit_events where reason = '__ATOMICITY_TEST_FORCED_FAILURE__';
  if v_count = 0 then
    raise notice 'TEST E2: PASS (no audit_events row with the forced-failure sentinel was ever committed)';
  else
    raise notice 'TEST E2: FAIL (% sentinel audit_events row(s) persisted)', v_count;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Remove the test-only trigger and function — never a permanent object.
-- ---------------------------------------------------------------------------
drop trigger _test_force_audit_failure_trigger on public.audit_events;
drop function public._test_force_audit_failure();

do $$ begin raise notice '=== Mutation atomicity (forced-failure) test suite complete ==='; end $$;
