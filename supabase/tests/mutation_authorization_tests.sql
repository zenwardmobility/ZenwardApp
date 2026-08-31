-- Zenward Platform — cross-cutting mutation authorization tests (P1-E2-S2).
--
-- mutation_lifecycle_tests.sql and mutation_assignment_tests.sql already
-- exercise per-RPC-family authorization (right actor succeeds, wrong actor
-- denied, anon denied, direct-table regression). This file covers the
-- authorization properties that cut ACROSS every RPC family and are easy
-- to get wrong precisely because they are cross-cutting: Platform Admin is
-- explicitly NOT a universal mutation bypass (work item §80), an inactive
-- Membership loses mutation ability immediately (live-checked, never
-- cached), and a multi-org user's role is scoped per-organization, not
-- global. Same SET ROLE/request.jwt.claim.sub methodology as the other
-- suites.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/mutation_authorization_tests.sql

\set ON_ERROR_STOP off
\pset pager off

insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('90000000-0000-0000-0000-0000000000d1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Authorization test D1', 'Authorization test D1'),
  ('90000000-0000-0000-0000-0000000000d2', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Authorization test D2', 'Authorization test D2'),
  ('90000000-0000-0000-0000-0000000000d3', '10000000-0000-0000-0000-0000000000b1', '40000000-0000-0000-0000-0000000000b1', 'scheduled', 'Authorization test D3 (Org B)', 'Authorization test D3 (Org B)');

-- =============================================================================
-- D1. Platform Admin holds NO Membership anywhere (seed: user ...d1) and
-- must NOT be able to call any mutation RPC, on any organization's Trip,
-- through Membership-derived authorization — is_platform_admin() is never
-- consulted by has_org_role()/is_org_member(), by design (work item §80:
-- no "is_platform_admin() OR ..." bypass exists anywhere in this layer).
-- =============================================================================
do $$
declare v_denied int := 0;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000d1'; -- platform admin, zero memberships
  begin perform public.cancel_trip('90000000-0000-0000-0000-0000000000d1', 'attempted platform-admin cancel'); exception when sqlstate 'ZW002' then v_denied := v_denied + 1; end;
  begin perform public.assign_trip('90000000-0000-0000-0000-0000000000d1', '30000000-0000-0000-0000-0000000000a1'); exception when sqlstate 'ZW002' then v_denied := v_denied + 1; end;
  begin perform public.record_no_show('90000000-0000-0000-0000-0000000000d1', 'attempted platform-admin no-show'); exception when sqlstate 'ZW002' then v_denied := v_denied + 1; end;
  if v_denied = 3 then
    raise notice 'TEST D1: PASS (Platform Admin without a Membership is denied on all 3 ops RPCs -- not a universal bypass)';
  else
    raise notice 'TEST D1: FAIL (only % of 3 denied)', v_denied;
  end if;
end $$;
reset role;

-- =============================================================================
-- D2. Inactive Membership (seed: org-a-inactive, user ...a5, dispatcher
-- role but status=inactive) must be denied exactly as if they held no
-- Membership at all -- has_org_role()/is_org_member() check status live.
-- =============================================================================
do $$
declare v_r public.trip_assignment_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a5';
  begin
    v_r := public.assign_trip('90000000-0000-0000-0000-0000000000d2', '30000000-0000-0000-0000-0000000000a1');
    raise notice 'TEST D2: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST D2: PASS (inactive Dispatcher Membership correctly denied as not_found, same as no Membership)';
  when others then
    raise notice 'TEST D2: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- D3. Multi-org scoping: user ...c1 is organization_admin in Org A and
-- driver in Org B (seed). Their Org A admin role must NOT extend to an Org
-- B Trip -- has_org_role evaluates per organization_id parameter, never
-- "does this user hold this role ANYWHERE".
-- =============================================================================
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1';
  begin
    v_r := public.cancel_trip('90000000-0000-0000-0000-0000000000d3', 'attempted cross-org cancel using Org A admin identity');
    raise notice 'TEST D3: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST D3: PASS (Org A organization_admin role does not extend to an Org B Trip)';
  when others then
    raise notice 'TEST D3: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- Same user, same Trip, using their (real, Org-B-scoped) Driver identity
-- instead -- also correctly denied, since they hold no assignment on it
-- (a Driver relationship requires an actual trip_assignments row, not
-- merely being A driver somewhere in the right org).
do $$
declare v_r public.trip_transition_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1';
  begin
    v_r := public.driver_start_to_pickup('90000000-0000-0000-0000-0000000000d3', 'scheduled');
    raise notice 'TEST D4: FAIL (expected rejection, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST D4: PASS (multi-org user''s Org B Driver identity still requires an actual assignment on this Trip)';
  when others then
    raise notice 'TEST D4: FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$ begin raise notice '=== Cross-cutting mutation authorization test suite complete ==='; end $$;
