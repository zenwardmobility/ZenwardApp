-- Zenward Platform — Driver read API authorization tests (P1-E2-S3).
--
-- Covers the required Driver Trip Detail test matrix (work item §51),
-- active-assignment revocation (§30), Membership/Driver-status live
-- checks (§31/§32), multi-org scoping (§33), never-assigned/foreign-org
-- denial (§34/§35), nonexistent-Trip handling (§36), and the active-list
-- scoping matrix (§57). Same SET ROLE/request.jwt.claim.sub methodology
-- as the other suites.
--
-- Fixtures: dedicated trips under this file's own 91000000-...-aN/-bN
-- namespace, created below as postgres. Designed to run ONCE against
-- freshly-seeded data (supabase db reset) — one test (reassignment)
-- performs a real mutation via reassign_trip.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/driver_read_authorization_tests.sql

\set ON_ERROR_STOP off
\pset pager off

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('91000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Read-auth test A1', 'Read-auth test A1'),
  ('91000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Read-auth test A2', 'Read-auth test A2'),
  ('91000000-0000-0000-0000-0000000000a3', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Read-auth test A3', 'Read-auth test A3'),
  ('91000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'scheduled', 'Read-auth test B1 (Org B)', 'Read-auth test B1 (Org B)');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000a1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000a2', '30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-0000000000a2'), -- Driver A2
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000a3', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'), -- Driver A1 (will be reassigned)
  ('10000000-0000-0000-0000-0000000000b1', '91000000-0000-0000-0000-0000000000b1', '30000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b2'); -- Driver B1

-- =============================================================================
-- Detail test matrix (work item §51)
-- =============================================================================

-- Assigned Driver -> ALLOW
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
  reset role;
  if v_r.trip_id = '91000000-0000-0000-0000-0000000000a1' and v_r.passenger_display_name = 'Fictional Passenger A1' then
    raise notice 'TEST DETAIL-1 (assigned Driver): PASS (ALLOW)';
  else
    raise notice 'TEST DETAIL-1 (assigned Driver): FAIL (trip_id=%, passenger=%)', v_r.trip_id, v_r.passenger_display_name;
  end if;
end $$;

-- Wrong Driver, same org -> DENY
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, not assigned to A2
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a2');
    raise notice 'TEST DETAIL-2 (wrong Driver same org): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-2 (wrong Driver same org): PASS (DENY)';
  when others then
    raise notice 'TEST DETAIL-2 (wrong Driver same org): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Formerly assigned Driver after reassignment -> DENY (revocation, §30);
-- new Driver gains access immediately, no JWT refresh.
do $$
declare v_ar public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- dispatcher
  v_ar := public.reassign_trip('91000000-0000-0000-0000-0000000000a3', '30000000-0000-0000-0000-0000000000a2', null, 'test setup: reassign A3 to Driver A2');
  reset role;
  if not v_ar.changed then
    raise notice 'TEST DETAIL-3-setup: FAIL (reassignment did not happen)';
  end if;
end $$;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, reassigned away
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a3');
    raise notice 'TEST DETAIL-3 (formerly assigned after reassignment): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-3 (formerly assigned after reassignment): PASS (DENY, immediate revocation, no JWT refresh needed)';
  when others then
    raise notice 'TEST DETAIL-3 (formerly assigned after reassignment): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, newly assigned
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a3');
  reset role;
  if v_r.trip_id = '91000000-0000-0000-0000-0000000000a3' then
    raise notice 'TEST DETAIL-3B (new Driver gains access immediately): PASS';
  else
    raise notice 'TEST DETAIL-3B (new Driver gains access immediately): FAIL (trip_id=%)', v_r.trip_id;
  end if;
end $$;

-- Never-assigned same-org Driver -> DENY (§34, even knowing the real UUID)
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, never assigned to A1
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-4 (never-assigned same-org): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-4 (never-assigned same-org): PASS (DENY)';
  when others then
    raise notice 'TEST DETAIL-4 (never-assigned same-org): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Foreign-org Driver -> DENY, no existence/PII disclosure (§35)
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- Driver B1, Org B
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1'); -- Org A trip
    raise notice 'TEST DETAIL-5 (foreign-org Driver): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-5 (foreign-org Driver): PASS (DENY, no existence disclosure)';
  when others then
    raise notice 'TEST DETAIL-5 (foreign-org Driver): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Inactive Membership -> DENY (§31, live-checked). Temporarily toggle
-- Driver A1's membership to inactive, test, then restore it — no new
-- fixture rows needed.
do $$
begin
  update public.memberships set status = 'inactive'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a3';
end $$;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, now inactive membership
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-6 (inactive Membership): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-6 (inactive Membership): PASS (DENY, live-checked, same active session/token)';
  when others then
    raise notice 'TEST DETAIL-6 (inactive Membership): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  update public.memberships set status = 'active'
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id = '20000000-0000-0000-0000-0000000000a3';
end $$;

-- Inactive Driver row (Membership itself still active) -> DENY (§32).
-- Temporarily toggle, test, restore.
do $$
begin
  update public.drivers set status = 'inactive' where id = '30000000-0000-0000-0000-0000000000a1';
end $$;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, Driver row now inactive
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-7 (inactive Driver row): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-7 (inactive Driver row): PASS (DENY, current_driver_id fails closed on Driver status)';
  when others then
    raise notice 'TEST DETAIL-7 (inactive Driver row): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
begin
  update public.drivers set status = 'active' where id = '30000000-0000-0000-0000-0000000000a1';
end $$;

-- Random authenticated user, zero memberships anywhere -> DENY (§51)
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000e1'; -- no-membership user
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-8 (random authenticated user): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-8 (random authenticated user): PASS (DENY)';
  when others then
    raise notice 'TEST DETAIL-8 (random authenticated user): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Platform Admin without Driver context -> DENY (§43, not a bypass)
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000d1'; -- platform admin, zero memberships
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-9 (Platform Admin, no Driver context): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-9 (Platform Admin, no Driver context): PASS (DENY, not a universal bypass)';
  when others then
    raise notice 'TEST DETAIL-9 (Platform Admin, no Driver context): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- anon -> DENY outright (privilege layer, before any auth-chain logic)
do $$
begin
  set local role anon;
  begin
    perform public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST DETAIL-10 (anon): FAIL (expected denial, got success)';
  exception when insufficient_privilege then
    raise notice 'TEST DETAIL-10 (anon): PASS (DENY at the privilege layer)';
  end;
end $$;
reset role;

-- Nonexistent Trip id -> safe inaccessible result, same shape as a real
-- foreign/never-assigned Trip (§36, no existence oracle)
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_get_trip_detail('99999999-9999-9999-9999-999999999999');
    raise notice 'TEST DETAIL-11 (nonexistent Trip): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST DETAIL-11 (nonexistent Trip): PASS (same ZW002 not_found as a real inaccessible Trip — no existence oracle)';
  when others then
    raise notice 'TEST DETAIL-11 (nonexistent Trip): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- Multi-org Driver scoping (§33)
-- =============================================================================
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1'; -- org_admin in A, driver in B, not assigned to A1
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000a1'); -- Org A trip
    raise notice 'TEST MULTIORG-1: FAIL (expected denial, got success — stronger Org A role must not grant Driver data access)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST MULTIORG-1: PASS (Org A organization_admin role grants no Driver-read authority; multi-org user still requires a real Driver assignment)';
  when others then
    raise notice 'TEST MULTIORG-1: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.driver_profile_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1';
  begin
    v_r := public.driver_get_profile('10000000-0000-0000-0000-0000000000a1'::uuid); -- Org A: this user has NO Driver row there
    raise notice 'TEST MULTIORG-2: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST MULTIORG-2: PASS (multi-org user has no Driver row in Org A, correctly denied there despite being org_admin)';
  when others then
    raise notice 'TEST MULTIORG-2: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.driver_profile_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1';
  v_r := public.driver_get_profile('10000000-0000-0000-0000-0000000000b1'::uuid); -- Org B: real Driver row
  reset role;
  if v_r.driver_id = '30000000-0000-0000-0000-0000000000c1' then
    raise notice 'TEST MULTIORG-3: PASS (same user correctly resolves their real Org B Driver profile)';
  else
    raise notice 'TEST MULTIORG-3: FAIL (driver_id=%)', v_r.driver_id;
  end if;
end $$;

-- =============================================================================
-- Active-list scoping matrix (§57)
-- =============================================================================
do $$
declare v_count int; v_foreign int; v_unassigned_seen boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  select count(*) into v_count from public.driver_list_active_trips('10000000-0000-0000-0000-0000000000a1'::uuid)
    where trip_id = '91000000-0000-0000-0000-0000000000a1';
  select count(*) into v_foreign from public.driver_list_active_trips('10000000-0000-0000-0000-0000000000a1'::uuid)
    where trip_id in ('91000000-0000-0000-0000-0000000000a2', '91000000-0000-0000-0000-0000000000a3', '91000000-0000-0000-0000-0000000000b1');
  reset role;
  if v_count = 1 and v_foreign = 0 then
    raise notice 'TEST ACTIVE-LIST-1: PASS (Driver A1''s active list contains their own active assignment (A1) and none of: another Driver''s trip (A2), their own now-reassigned-away trip (A3), or a foreign-org trip (B1))';
  else
    raise notice 'TEST ACTIVE-LIST-1: FAIL (own=%, unexpected=%)', v_count, v_foreign;
  end if;
end $$;

do $$
declare v_r public.driver_profile_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  begin
    v_r := public.driver_get_profile('10000000-0000-0000-0000-0000000000b1'::uuid); -- Org B: Driver A1 has no relationship there
    raise notice 'TEST ORG-CONTEXT-1: FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST ORG-CONTEXT-1: PASS (an organization_id parameter does not grant authority over that org — caller still validated live)';
  when others then
    raise notice 'TEST ORG-CONTEXT-1: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$ begin raise notice '=== Driver read authorization test suite complete ==='; end $$;
