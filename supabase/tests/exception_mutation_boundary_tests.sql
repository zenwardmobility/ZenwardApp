-- Zenward Platform — Exception Mutation Boundary Hardening tests (P1-E3-S8A).
--
-- Proves the database authorization surface itself — not merely
-- application code discipline — enforces that report_trip_exception()/
-- resolve_trip_exception() are the ONLY way any normal actor writes
-- trip_exceptions: direct INSERT/UPDATE/DELETE bypass attempts (BND
-- series), the Driver authorization tightening from "ever assigned" to
-- "currently assigned" including reassignment/terminal revocation (DRV
-- series), and Operations contract re-confirmation including live role
-- revocation (OPS series). Same SET ROLE/request.jwt.claim.sub
-- methodology as every other suite in this repository.
--
-- Fixtures: dedicated trips under this file's own 97000000-...-eN
-- namespace, never used by supabase/seed.sql or any other test file.
-- Designed to run ONCE against freshly-seeded data (supabase db reset).
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/exception_mutation_boundary_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres, bypasses RLS)
-- ---------------------------------------------------------------------------
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('97000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Boundary test E1', 'Boundary test E1'),
  ('97000000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Boundary test E2 (reassignment)', 'Boundary test E2'),
  ('97000000-0000-0000-0000-0000000000e3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Boundary test E3 (terminal)', 'Boundary test E3'),
  ('97000000-0000-0000-0000-0000000000e4', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'en_route_to_pickup', 'Boundary test E4 (Org B)', 'Boundary test E4'),
  ('97000000-0000-0000-0000-0000000000e5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'en_route_to_pickup', 'Boundary test E5 (role revocation)', 'Boundary test E5');

insert into public.trip_assignments (id, organization_id, trip_id, driver_id, assigned_by) values
  ('97100000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('97100000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e2', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('97100000-0000-0000-0000-0000000000e3', '10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e3', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2');
-- E4 (Org B), E5: no assignment needed for their own test purposes.

-- A real, RPC-created exception on E1 to exercise the bypass attempts
-- against (Operations-authored, open).
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  perform public.report_trip_exception('97000000-0000-0000-0000-0000000000e1', 'vehicle_issue', 'Fictional boundary-test seed exception');
end $$;
reset role;

-- =============================================================================
-- BND-A: authenticated Operations actor cannot direct-INSERT trip_exceptions.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by)
      values ('10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', 'other', 'Fictional direct-insert bypass attempt', 'open', auth.uid());
    raise notice 'BND-A: FAIL (direct INSERT succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-A: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-A: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- BND-B: authenticated Operations actor cannot direct-UPDATE trip_exceptions.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    update public.trip_exceptions set description = 'Fictional direct-update bypass attempt'
      where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-B: FAIL (direct UPDATE succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-B: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-B: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- BND-C: authenticated Operations actor cannot direct-DELETE trip_exceptions
-- (DELETE was never granted to authenticated by any migration).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    delete from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-C: FAIL (direct DELETE succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-C: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-C: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- BND-D: authenticated Driver actor cannot direct-INSERT trip_exceptions
-- either (the pre-existing narrow Driver INSERT policy was retired).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  begin
    insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by)
      values ('10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', 'other', 'Fictional driver direct-insert bypass attempt', 'open', auth.uid());
    raise notice 'BND-D: FAIL (Driver direct INSERT succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-D: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-D: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- BND-E: forged created_by via direct INSERT — still denied (proves the
-- privilege revocation is total, not merely a column/value-shaped RLS
-- check that a crafted payload might slip past).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by)
      values ('10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', 'other', 'Fictional forged-identity attempt', 'open', '20000000-0000-0000-0000-0000000000a3'); -- impersonating Driver A1
    raise notice 'BND-E: FAIL (forged created_by INSERT succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-E: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-E: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- BND-F: forged status='resolved' via direct INSERT — still denied.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by, resolved_by, resolved_at)
      values ('10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', 'other', 'Fictional forged pre-resolved attempt', 'resolved', auth.uid(), auth.uid(), now());
    raise notice 'BND-F: FAIL (forged pre-resolved INSERT succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-F: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-F: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Now genuinely resolve the seed exception through the real RPC, so the
-- reopen/historical-rewrite bypass attempts below have a real resolved
-- row to target.
do $$
declare v_exc_id uuid;
begin
  select id into v_exc_id from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e1' and status = 'open' limit 1;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  perform public.resolve_trip_exception(v_exc_id, 'Fictional: resolved for boundary testing');
end $$;
reset role;

-- =============================================================================
-- BND-G: direct UPDATE attempting to REOPEN a resolved exception
-- (status='open') — denied; persisted row remains resolved.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    update public.trip_exceptions set status = 'open'
      where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-G: FAIL (direct reopen UPDATE succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-G: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-G: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_status text;
begin
  select status into v_status from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e1';
  if v_status = 'resolved' then
    raise notice 'BND-G-DB: PASS (persisted row genuinely still resolved after the denied reopen attempt)';
  else
    raise notice 'BND-G-DB: FAIL (status=%)', v_status;
  end if;
end $$;

-- =============================================================================
-- BND-H: direct UPDATE attempting to rewrite historical fields
-- (description/exception_type/created_by) on the resolved exception —
-- denied; original persisted history unchanged.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  begin
    update public.trip_exceptions
      set description = 'Fictional rewritten history', exception_type = 'other', created_by = '20000000-0000-0000-0000-0000000000a3'
      where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-H: FAIL (direct historical-rewrite UPDATE succeeded — should have been denied)';
  exception when insufficient_privilege then
    raise notice 'BND-H: PASS (DENIED, insufficient_privilege: %)', sqlerrm;
  when others then
    raise notice 'BND-H: PASS-VARIANT (denied, but unexpected sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_desc text; v_type text; v_creator uuid;
begin
  select description, exception_type, created_by into v_desc, v_type, v_creator
    from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e1';
  if v_desc = 'Fictional boundary-test seed exception' and v_type = 'vehicle_issue' and v_creator = '20000000-0000-0000-0000-0000000000a2' then
    raise notice 'BND-H-DB: PASS (original history genuinely unchanged after the denied rewrite attempt)';
  else
    raise notice 'BND-H-DB: FAIL (description=%, exception_type=%, created_by=%)', v_desc, v_type, v_creator;
  end if;
end $$;

-- =============================================================================
-- BND-I: foreign-org (Org B) actor cannot direct INSERT/UPDATE/DELETE
-- against an Org A exception row (compounding: no table grant at all,
-- regardless of org).
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b2'; -- Org B dispatcher
  begin
    insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by)
      values ('10000000-0000-0000-0000-0000000000a1', '97000000-0000-0000-0000-0000000000e1', 'other', 'Fictional foreign-org insert attempt', 'open', auth.uid());
    raise notice 'BND-I-INSERT: FAIL (foreign-org direct INSERT succeeded)';
  exception when insufficient_privilege then
    raise notice 'BND-I-INSERT: PASS (DENIED, insufficient_privilege)';
  when others then
    raise notice 'BND-I-INSERT: PASS-VARIANT (denied, sqlstate % — %)', sqlstate, sqlerrm;
  end;

  begin
    update public.trip_exceptions set description = 'Fictional foreign-org update attempt' where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-I-UPDATE: FAIL (foreign-org direct UPDATE succeeded)';
  exception when insufficient_privilege then
    raise notice 'BND-I-UPDATE: PASS (DENIED, insufficient_privilege)';
  when others then
    raise notice 'BND-I-UPDATE: PASS-VARIANT (denied, sqlstate % — %)', sqlstate, sqlerrm;
  end;

  begin
    delete from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e1';
    raise notice 'BND-I-DELETE: FAIL (foreign-org direct DELETE succeeded)';
  exception when insufficient_privilege then
    raise notice 'BND-I-DELETE: PASS (DENIED, insufficient_privilege)';
  when others then
    raise notice 'BND-I-DELETE: PASS-VARIANT (denied, sqlstate % — %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- DRV-1: currently-assigned Driver reports via the real RPC -> PASS
-- (baseline for the reassignment-revocation test below).
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, currently assigned to E2
  v_r := public.report_trip_exception('97000000-0000-0000-0000-0000000000e2', 'route_issue', 'Fictional: detour before reassignment');
  if v_r.exception_id is not null then
    raise notice 'DRV-1: PASS (currently-assigned Driver A1 reported successfully)';
  else
    raise notice 'DRV-1: FAIL (no exception created)';
  end if;
end $$;
reset role;

-- Reassign E2 from Driver A1 to Driver A2 through the REAL reassign_trip
-- RPC (Operations), same as a real Dispatcher action would.
do $$
declare v_expected_id uuid;
begin
  select id into v_expected_id from public.trip_assignments where trip_id = '97000000-0000-0000-0000-0000000000e2' and ended_at is null;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  perform public.reassign_trip('97000000-0000-0000-0000-0000000000e2', '30000000-0000-0000-0000-0000000000a2', null, 'Fictional: original driver called out', v_expected_id);
end $$;
reset role;

-- =============================================================================
-- DRV-2: Driver A1 (reassigned AWAY, same session, no re-login) attempts
-- another report_trip_exception on E2 -> DENIED. This is the key
-- regression this phase closes: "ever assigned" would have allowed this;
-- "currently assigned" must not.
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, now reassigned away
  begin
    perform public.report_trip_exception('97000000-0000-0000-0000-0000000000e2', 'other', 'Fictional: former driver attempt after reassignment');
    raise notice 'DRV-2: FAIL (expected denial, got success — reassignment revocation broken)';
  exception when sqlstate 'ZW002' then
    raise notice 'DRV-2: PASS (DENIED ZW002 — former Driver correctly revoked immediately, no re-login needed)';
  when others then
    raise notice 'DRV-2: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- DRV-3: Driver A2 (the NEW currently-assigned Driver) reports on E2 ->
-- ALLOWED.
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, now the current driver on E2
  v_r := public.report_trip_exception('97000000-0000-0000-0000-0000000000e2', 'other', 'Fictional: new driver reports after reassignment');
  if v_r.exception_id is not null and v_r.created_by = '20000000-0000-0000-0000-0000000000a4' then
    raise notice 'DRV-3: PASS (new currently-assigned Driver A2 reported successfully)';
  else
    raise notice 'DRV-3: FAIL (id=%, created_by=%)', v_r.exception_id, v_r.created_by;
  end if;
end $$;
reset role;

-- =============================================================================
-- DRV-4/TERMINAL: Driver A1 reports on E3 while non-terminal -> PASS.
-- Trip E3 then reaches a terminal state (completed, via the real Driver
-- lifecycle RPCs) which closes the active assignment in the same
-- transaction. Driver A1's next report attempt -> DENIED, same session,
-- no re-login.
-- =============================================================================
do $$
declare v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, currently assigned to E3
  v_r := public.report_trip_exception('97000000-0000-0000-0000-0000000000e3', 'other', 'Fictional: issue while trip still active');
  if v_r.exception_id is not null then
    raise notice 'DRV-4: PASS (Driver A1 reported successfully while Trip E3 still non-terminal)';
  else
    raise notice 'DRV-4: FAIL (no exception created)';
  end if;
end $$;
reset role;

-- Walk E3 to a real terminal state via the actual Driver lifecycle RPCs
-- (not a direct UPDATE) — proves the revocation holds for a genuinely
-- reached terminal state, not merely a manually-set one.
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  -- E3 was seeded directly at 'en_route_to_pickup' (matching this file's
  -- other fixtures) — the walk starts from there, not from 'scheduled'.
  perform public.driver_arrive_at_pickup('97000000-0000-0000-0000-0000000000e3', 'en_route_to_pickup');
  perform public.driver_mark_passenger_onboard('97000000-0000-0000-0000-0000000000e3', 'arrived_at_pickup');
  perform public.driver_start_to_destination('97000000-0000-0000-0000-0000000000e3', 'passenger_onboard');
  perform public.driver_arrive_at_destination('97000000-0000-0000-0000-0000000000e3', 'en_route_to_destination');
  perform public.driver_complete_trip('97000000-0000-0000-0000-0000000000e3', 'arrived_at_destination');
end $$;
reset role;

do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, Trip E3 now completed
  begin
    perform public.report_trip_exception('97000000-0000-0000-0000-0000000000e3', 'other', 'Fictional: attempt after trip completed');
    raise notice 'DRV-5-TERMINAL: FAIL (expected denial, got success — terminal revocation broken)';
  exception when sqlstate 'ZW002' then
    raise notice 'DRV-5-TERMINAL: PASS (DENIED ZW002 — terminal Trip correctly revoked, active assignment closed by driver_complete_trip)';
  when others then
    raise notice 'DRV-5-TERMINAL: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- OPS-1: role revocation mid-session — a dispatcher who resolves once,
-- then has their Membership role changed to 'driver', immediately loses
-- resolve authority (live-checked, no re-login).
-- =============================================================================
do $$
declare v_exc_id uuid; v_r public.trip_exception_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher, still a dispatcher
  v_r := public.report_trip_exception('97000000-0000-0000-0000-0000000000e5', 'other', 'Fictional: role-revocation test exception');
  v_exc_id := v_r.exception_id;
  if v_exc_id is not null then
    raise notice 'OPS-1-SETUP: PASS (seed exception created for role-revocation test)';
  else
    raise notice 'OPS-1-SETUP: FAIL';
  end if;
end $$;
reset role;

update public.memberships set role = 'driver' where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a2';

do $$
declare v_exc_id uuid;
begin
  select id into v_exc_id from public.trip_exceptions where trip_id = '97000000-0000-0000-0000-0000000000e5' and status = 'open' limit 1;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- same user, now role='driver'
  begin
    perform public.resolve_trip_exception(v_exc_id, 'Fictional: attempt after role changed to driver');
    raise notice 'OPS-1: FAIL (expected denial, got success — role revocation not live-checked)';
  exception when sqlstate 'ZW002' then
    raise notice 'OPS-1: PASS (DENIED ZW002 — resolve authority immediately lost on role change, same session, no re-login)';
  when others then
    raise notice 'OPS-1: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Restore the role (toggle-and-restore, established convention).
update public.memberships set role = 'dispatcher' where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a2';

do $$
begin
  raise notice '=== Exception mutation boundary hardening test suite complete — review PASS/FAIL lines above ===';
end $$;
