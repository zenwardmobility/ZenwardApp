-- Zenward Platform — Trip assignment mutation RPC tests (P1-E2-S2).
--
-- Covers assign_trip and reassign_trip: positive paths, idempotent
-- retries, the assignment-eligible-states rule (ZD-088), driver/vehicle
-- validation, the assign_trip-vs-reassign_trip conflict boundary, anon
-- denial, and the trip_assignments direct-table-write regression. Same
-- SET ROLE/request.jwt.claim.sub methodology as the other suites.
--
-- Fixtures: dedicated trips under this file's own 90000000-...-cN
-- namespace, plus one additional inactive Driver fixture, created below as
-- postgres. Designed to run ONCE against freshly-seeded data.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/mutation_assignment_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
insert into public.drivers (id, organization_id, user_id, display_name, status) values
  ('30000000-0000-0000-0000-0000000000a9', '10000000-0000-0000-0000-0000000000a1', null, 'Fictional Inactive Driver A9', 'inactive');

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('90000000-0000-0000-0000-0000000000c1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C1', 'Assignment test C1'),
  ('90000000-0000-0000-0000-0000000000c2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C2', 'Assignment test C2'),
  ('90000000-0000-0000-0000-0000000000c3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C3', 'Assignment test C3'),
  ('90000000-0000-0000-0000-0000000000c4', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C4', 'Assignment test C4'),
  ('90000000-0000-0000-0000-0000000000c5', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C5', 'Assignment test C5'),
  ('90000000-0000-0000-0000-0000000000c6', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C6', 'Assignment test C6'),
  ('90000000-0000-0000-0000-0000000000c7', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C7', 'Assignment test C7'),
  ('90000000-0000-0000-0000-0000000000c8', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Assignment test C8', 'Assignment test C8');

insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c2', '30000000-0000-0000-0000-0000000000a1', null, '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c3', '30000000-0000-0000-0000-0000000000a2', null, '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c5', '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c6', '30000000-0000-0000-0000-0000000000a1', null, '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c7', '30000000-0000-0000-0000-0000000000a2', null, '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c8', '30000000-0000-0000-0000-0000000000a1', null, '20000000-0000-0000-0000-0000000000a2');

-- =============================================================================
-- C1/C2. assign_trip positive + idempotent retry (fresh unassigned trip).
-- =============================================================================
do $$
declare v_r public.trip_assignment_result; v_audit int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c1', '30000000-0000-0000-0000-0000000000a2', '50000000-0000-0000-0000-0000000000a1');
  reset role;
  select count(*) into v_audit from public.audit_events where entity_id = '90000000-0000-0000-0000-0000000000c1' and action = 'driver_assigned';
  if v_r.changed and v_r.driver_id = '30000000-0000-0000-0000-0000000000a2' and v_r.assignment_id is not null and v_audit = 1 then
    raise notice 'TEST C1: PASS (assign_trip creates the first assignment; AuditEvent written)';
  else
    raise notice 'TEST C1: FAIL (changed=%, driver_id=%, assignment_id=%, audit=%)', v_r.changed, v_r.driver_id, v_r.assignment_id, v_audit;
  end if;
end $$;

do $$
declare v_r public.trip_assignment_result; v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c1', '30000000-0000-0000-0000-0000000000a2', '50000000-0000-0000-0000-0000000000a1');
  reset role;
  select count(*) into v_count from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000c1';
  if v_r.changed = false and v_count = 1 then
    raise notice 'TEST C2: PASS (identical assign_trip retry is a safe no-op, no second row created)';
  else
    raise notice 'TEST C2: FAIL (changed=%, row_count=%)', v_r.changed, v_count;
  end if;
end $$;

-- =============================================================================
-- C3. assign_trip conflict: Trip C2 already has an active assignment
-- (Driver A1) — attempting assign_trip with a DIFFERENT driver is ZW005,
-- not a silent overwrite. reassign_trip is the correct function for that.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c2', '30000000-0000-0000-0000-0000000000a2');
    raise notice 'TEST C3: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW005' then
    raise notice 'TEST C3: PASS (assign_trip on an already-assigned Trip with a different driver -> assignment_conflict)';
  when others then
    raise notice 'TEST C3: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C4. assign_trip called again with the SAME driver+vehicle already active
-- on seed Trip A1 (Driver A1 + Van A1) is also an idempotent no-op — this
-- exercises assign_trip's own match branch, distinct from C2's "just
-- created it" case. Read-safe: the match branch performs no write, so
-- seed data is untouched for any other suite.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.assign_trip('80000000-0000-0000-0000-0000000000a1', '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1');
  reset role;
  if v_r.changed = false and v_r.driver_id = '30000000-0000-0000-0000-0000000000a1' then
    raise notice 'TEST C4: PASS (assign_trip matching the already-active assignment is idempotent, no write)';
  else
    raise notice 'TEST C4: FAIL (changed=%, driver_id=%)', v_r.changed, v_r.driver_id;
  end if;
end $$;

-- =============================================================================
-- C5. Driver/vehicle validation: Org B's driver cannot be assigned to an
-- Org A trip (application-level ZW006, independent of the composite-FK
-- backstop already covered by RLS test W).
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c4', '30000000-0000-0000-0000-0000000000b1');
    raise notice 'TEST C5: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST C5: PASS (cross-org driver correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST C5: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C6. Driver validation: inactive Driver cannot be assigned.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c4', '30000000-0000-0000-0000-0000000000a9');
    raise notice 'TEST C6: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST C6: PASS (inactive Driver correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST C6: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C7. Assignment-eligible states (ZD-088): assign_trip is illegal once a
-- Trip has progressed to passenger_onboard.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, assigned to C3
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000c3', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000c3', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000c3', 'arrived_at_pickup');
  reset role;
  if v_r.current_state <> 'passenger_onboard' then
    raise notice 'TEST C7-setup: FAIL (Trip C3 not at passenger_onboard, got %)', v_r.current_state;
  end if;
end $$;

do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c3', '30000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST C7: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW004' then
    raise notice 'TEST C7: PASS (assign_trip past arrived_at_pickup correctly rejected as illegal_transition — ZD-088)';
  when others then
    raise notice 'TEST C7: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C8. Authorization: Driver (not Organization Admin/Dispatcher) cannot
-- call assign_trip at all.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c4', '30000000-0000-0000-0000-0000000000a2');
    raise notice 'TEST C8: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST C8: PASS (Driver calling assign_trip correctly rejected as not_found — mirrors zero ops visibility)';
  when others then
    raise notice 'TEST C8: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C9. assign_trip invalid input: null driver id.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000c4', null);
    raise notice 'TEST C9: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST C9: PASS (null driver_id correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST C9: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C10. reassign_trip requires an EXISTING active assignment: Trip C4 was
-- never successfully assigned by any of the tests above (every attempt on
-- it failed before writing) -> ZW005, not a silent create.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result; v_count int;
begin
  select count(*) into v_count from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000c4';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.reassign_trip('90000000-0000-0000-0000-0000000000c4', '30000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST C10: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW005' then
    raise notice 'TEST C10: PASS (reassign_trip with nothing to reassign (existing rows=%) -> assignment_conflict, use assign_trip instead)', v_count;
  when others then
    raise notice 'TEST C10: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C11/C12. reassign_trip positive path + idempotent retry (Trip C5,
-- currently Driver A1 + Van A1).
-- =============================================================================
do $$
declare v_r public.trip_assignment_result; v_old_closed int; v_audit int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.reassign_trip('90000000-0000-0000-0000-0000000000c5', '30000000-0000-0000-0000-0000000000a2', null, 'Fictional: original driver called in sick');
  reset role;
  select count(*) into v_old_closed from public.trip_assignments
    where trip_id = '90000000-0000-0000-0000-0000000000c5' and driver_id = '30000000-0000-0000-0000-0000000000a1' and ended_at is not null;
  select count(*) into v_audit from public.audit_events where entity_id = '90000000-0000-0000-0000-0000000000c5' and action = 'driver_reassigned';
  if v_r.changed and v_r.driver_id = '30000000-0000-0000-0000-0000000000a2' and v_old_closed = 1 and v_audit = 1 then
    raise notice 'TEST C11: PASS (reassign_trip closes old row, creates new one, writes AuditEvent)';
  else
    raise notice 'TEST C11: FAIL (changed=%, driver_id=%, old_closed=%, audit=%)', v_r.changed, v_r.driver_id, v_old_closed, v_audit;
  end if;
end $$;

do $$
declare v_r public.trip_assignment_result; v_active_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  v_r := public.reassign_trip('90000000-0000-0000-0000-0000000000c5', '30000000-0000-0000-0000-0000000000a2', null);
  reset role;
  select count(*) into v_active_count from public.trip_assignments where trip_id = '90000000-0000-0000-0000-0000000000c5' and ended_at is null;
  if v_r.changed = false and v_active_count = 1 then
    raise notice 'TEST C12: PASS (identical reassign_trip retry is a safe no-op, exactly 1 active row remains)';
  else
    raise notice 'TEST C12: FAIL (changed=%, active_count=%)', v_r.changed, v_active_count;
  end if;
end $$;

-- =============================================================================
-- C13. reassign_trip driver/vehicle validation: cross-org vehicle.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.reassign_trip('90000000-0000-0000-0000-0000000000c6', '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000b1');
    raise notice 'TEST C13: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW006' then
    raise notice 'TEST C13: PASS (cross-org vehicle correctly rejected as invalid_input)';
  when others then
    raise notice 'TEST C13: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C14. reassign_trip eligible-states rule, same boundary as C7.
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, assigned to C7
  v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000c7', 'scheduled');
  v_r := public.driver_arrive_at_pickup('90000000-0000-0000-0000-0000000000c7', 'en_route_to_pickup');
  v_r := public.driver_mark_passenger_onboard('90000000-0000-0000-0000-0000000000c7', 'arrived_at_pickup');
  reset role;
end $$;

do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  begin
    v_r := public.reassign_trip('90000000-0000-0000-0000-0000000000c7', '30000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST C14: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW004' then
    raise notice 'TEST C14: PASS (reassign_trip past arrived_at_pickup correctly rejected as illegal_transition)';
  when others then
    raise notice 'TEST C14: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- C15. anon denial on both assignment RPCs.
-- =============================================================================
do $$
declare v_denied int := 0;
begin
  set local role anon;
  begin perform public.assign_trip('90000000-0000-0000-0000-0000000000c8', '30000000-0000-0000-0000-0000000000a1'); exception when insufficient_privilege then v_denied := v_denied + 1; end;
  begin perform public.reassign_trip('90000000-0000-0000-0000-0000000000c8', '30000000-0000-0000-0000-0000000000a2'); exception when insufficient_privilege then v_denied := v_denied + 1; end;
  if v_denied = 2 then
    raise notice 'TEST C15: PASS (anon denied on both assign_trip and reassign_trip)';
  else
    raise notice 'TEST C15: FAIL (only % of 2 denied)', v_denied;
  end if;
end $$;
reset role;

-- =============================================================================
-- C16. Direct-table-mutation regression: Dispatcher can no longer INSERT
-- or UPDATE trip_assignments directly — assign_trip/reassign_trip are the
-- sole path (20260831100000_trip_assignment_privilege_tightening.sql).
-- =============================================================================
do $$
declare v_insert_denied boolean := false; v_update_denied boolean := false;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher, the role that HELD this grant before P1-E2-S2
  begin
    insert into public.trip_assignments (organization_id, trip_id, driver_id)
      values ('10000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-0000000000c8', '30000000-0000-0000-0000-0000000000a2');
  exception when insufficient_privilege then v_insert_denied := true;
  end;
  begin
    update public.trip_assignments set ended_at = now() where trip_id = '90000000-0000-0000-0000-0000000000c8';
  exception when insufficient_privilege then v_update_denied := true;
  end;
  if v_insert_denied and v_update_denied then
    raise notice 'TEST C16: PASS (direct INSERT and UPDATE on trip_assignments both denied for Dispatcher)';
  else
    raise notice 'TEST C16: FAIL (insert_denied=%, update_denied=%)', v_insert_denied, v_update_denied;
  end if;
end $$;
reset role;

do $$ begin raise notice '=== Trip assignment mutation test suite complete ==='; end $$;
