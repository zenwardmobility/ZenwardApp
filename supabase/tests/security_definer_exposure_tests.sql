-- Zenward Platform — SECURITY DEFINER / RPC exposure test suite
-- (P1-E2-S1A, deep pass). Run as postgres.
--
-- METHODOLOGY: identical to supabase/tests/rls_adversarial_tests.sql —
-- `SET LOCAL ROLE authenticated;` (or `anon`) plus
-- `SET LOCAL request.jwt.claim.sub = '<user-uuid>'` inside each test,
-- against the `postgres` superuser connection (which would otherwise
-- bypass everything via BYPASSRLS). This exercises the exact GUC
-- `auth.uid()` reads (confirmed via `\sf auth.uid` during P1-E2-S1) and is
-- the same mechanism a real PostgREST request produces — proven identical
-- to genuine GoTrue-issued-token HTTP calls during this same audit (see
-- docs/security/rls-test-matrix.md "Cross-validation against real
-- PostgREST/GoTrue"). Fixtures: supabase/seed.sql (fictional only).
--
-- Run:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/security_definer_exposure_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- Fixture UUIDs used throughout.
-- Org A = ...a1, Org B = ...b1
-- Users: a1=Org A admin, a2=Org A dispatcher, a3=Org A driver A (Driver id 30..a1),
--        a4=Org A driver B (Driver id 30..a2), a5=Org A dispatcher (INACTIVE),
--        b1=Org B admin, b2=Org B dispatcher, b3=Org B driver (Driver id 30..b1),
--        c1=multi-org (admin in A, driver in B, Driver id 30..c1),
--        d1=platform admin (no membership anywhere), e1=no membership anywhere
-- Trips: 80..a1 (Org A, assigned to driver a1/a3), 80..a2 (Org A, assigned to driver a2/a4),
--        80..a3 (Org A, unassigned), 80..b1 (Org B, assigned to driver b1/b3)

-- =============================================================================
-- 1. anon direct helper invocation — all 5 functions
-- =============================================================================
do $$
declare v_denied int := 0;
begin
  set local role anon;
  begin perform is_org_member('10000000-0000-0000-0000-0000000000a1'::uuid); exception when others then v_denied := v_denied + 1; end;
  begin perform has_org_role('10000000-0000-0000-0000-0000000000a1'::uuid, array['organization_admin']); exception when others then v_denied := v_denied + 1; end;
  begin perform current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid); exception when others then v_denied := v_denied + 1; end;
  begin perform is_driver_assigned_to_trip('80000000-0000-0000-0000-0000000000a1'::uuid); exception when others then v_denied := v_denied + 1; end;
  begin perform is_platform_admin(); exception when others then v_denied := v_denied + 1; end;
  if v_denied = 5 then raise notice 'TEST 1 (anon, all 5 helpers): PASS (denied 5/5)';
  else raise notice 'TEST 1 (anon, all 5 helpers): FAIL (denied %/5)', v_denied; end if;
end $$;
reset role;

-- =============================================================================
-- 2. Unaffiliated authenticated user (zero memberships anywhere)
-- =============================================================================
do $$
declare v_a boolean; v_b uuid; v_c boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000e1';
  select is_org_member('10000000-0000-0000-0000-0000000000a1'::uuid) into v_a;
  select current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid) into v_b;
  select is_driver_assigned_to_trip('80000000-0000-0000-0000-0000000000a1'::uuid) into v_c;
  if v_a = false and v_b is null and v_c = false then
    raise notice 'TEST 2 (unaffiliated authenticated user): PASS (all fail closed, no error, no data)';
  else
    raise notice 'TEST 2 (unaffiliated authenticated user): FAIL (is_org_member=%, current_driver_id=%, is_driver_assigned=%)', v_a, v_b, v_c;
  end if;
end $$;
reset role;

-- =============================================================================
-- 3/4. Active Driver — own org (3) and foreign org (4)
-- =============================================================================
do $$
declare v_own uuid; v_foreign uuid; v_own_trip boolean; v_foreign_trip boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  select current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid) into v_own;      -- own org
  select current_driver_id('10000000-0000-0000-0000-0000000000b1'::uuid) into v_foreign;  -- foreign org
  select is_driver_assigned_to_trip('80000000-0000-0000-0000-0000000000a1'::uuid) into v_own_trip;   -- own trip
  select is_driver_assigned_to_trip('80000000-0000-0000-0000-0000000000b1'::uuid) into v_foreign_trip; -- Org B trip
  if v_own = '30000000-0000-0000-0000-0000000000a1'::uuid and v_foreign is null and v_own_trip = true and v_foreign_trip = false then
    raise notice 'TEST 3/4 (driver own org / foreign org): PASS (own id=%, foreign org=null, own trip=true, foreign trip=false)', v_own;
  else
    raise notice 'TEST 3/4 (driver own org / foreign org): FAIL (own=%, foreign=%, own_trip=%, foreign_trip=%)', v_own, v_foreign, v_own_trip, v_foreign_trip;
  end if;
end $$;
reset role;

-- =============================================================================
-- 5/6. Dispatcher — own org (5) and foreign org (6)
-- =============================================================================
do $$
declare v_own boolean; v_foreign boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  select has_org_role('10000000-0000-0000-0000-0000000000a1'::uuid, array['organization_admin','dispatcher']) into v_own;
  select has_org_role('10000000-0000-0000-0000-0000000000b1'::uuid, array['organization_admin','dispatcher']) into v_foreign;
  if v_own = true and v_foreign = false then
    raise notice 'TEST 5/6 (dispatcher own org / foreign org): PASS (own=true, foreign=false)';
  else
    raise notice 'TEST 5/6 (dispatcher own org / foreign org): FAIL (own=%, foreign=%)', v_own, v_foreign;
  end if;
end $$;
reset role;

-- =============================================================================
-- 7/8. Organization Admin — own org (7) and foreign org (8)
-- =============================================================================
do $$
declare v_own boolean; v_foreign boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- Org A admin
  select has_org_role('10000000-0000-0000-0000-0000000000a1'::uuid, array['organization_admin']) into v_own;
  select has_org_role('10000000-0000-0000-0000-0000000000b1'::uuid, array['organization_admin']) into v_foreign;
  if v_own = true and v_foreign = false then
    raise notice 'TEST 7/8 (org admin own org / foreign org): PASS (own=true, foreign=false)';
  else
    raise notice 'TEST 7/8 (org admin own org / foreign org): FAIL (own=%, foreign=%)', v_own, v_foreign;
  end if;
end $$;
reset role;

-- =============================================================================
-- 9. Inactive Membership (Org A, a5 — dispatcher role, status inactive)
-- =============================================================================
do $$
declare v_member boolean; v_role boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a5';
  select is_org_member('10000000-0000-0000-0000-0000000000a1'::uuid) into v_member;
  select has_org_role('10000000-0000-0000-0000-0000000000a1'::uuid, array['organization_admin','dispatcher']) into v_role;
  if v_member = false and v_role = false then
    raise notice 'TEST 9 (inactive membership): PASS (fails closed at the function layer, not just the RLS layer)';
  else
    raise notice 'TEST 9 (inactive membership): FAIL (is_org_member=%, has_org_role=%)', v_member, v_role;
  end if;
end $$;
reset role;

-- =============================================================================
-- 10. Guessed / non-existent organization UUID
-- =============================================================================
do $$
declare v_member boolean; v_driver uuid;
declare v_fake uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  select is_org_member(v_fake) into v_member;
  select current_driver_id(v_fake) into v_driver;
  if v_member = false and v_driver is null then
    raise notice 'TEST 10 (guessed/non-existent org UUID): PASS (false/null, no error, no distinguishable behavior from a real foreign org)';
  else
    raise notice 'TEST 10 (guessed/non-existent org UUID): FAIL (is_org_member=%, current_driver_id=%)', v_member, v_driver;
  end if;
end $$;
reset role;

-- =============================================================================
-- 11. Guessed / non-existent trip UUID
-- =============================================================================
do $$
declare v_assigned boolean;
declare v_fake uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select is_driver_assigned_to_trip(v_fake) into v_assigned;
  if v_assigned = false then
    raise notice 'TEST 11 (guessed/non-existent trip UUID): PASS (false, no error)';
  else
    raise notice 'TEST 11 (guessed/non-existent trip UUID): FAIL (got %)', v_assigned;
  end if;
end $$;
reset role;

-- =============================================================================
-- 12. current_driver_id() foreign-org ID disclosure — dedicated deep check
-- (also covers helper-specific abuse review §6: "cannot reveal another
-- driver's ID", "foreign org_id does not expose an identifier")
-- =============================================================================
do $$
declare v_a3_in_a uuid; v_a3_in_b uuid; v_a4_in_a uuid;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1's user
  select current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid) into v_a3_in_a; -- their own org: own id
  select current_driver_id('10000000-0000-0000-0000-0000000000b1'::uuid) into v_a3_in_b; -- Org B: null, never Driver A1's colleague's id or anyone else's
  reset role;
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2's user, DIFFERENT driver, SAME org
  select current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid) into v_a4_in_a; -- must be A2's own id, never A1's
  if v_a3_in_a = '30000000-0000-0000-0000-0000000000a1'::uuid
     and v_a3_in_b is null
     and v_a4_in_a = '30000000-0000-0000-0000-0000000000a2'::uuid
     and v_a4_in_a <> v_a3_in_a then
    raise notice 'TEST 12 (current_driver_id ID-disclosure deep check): PASS (each driver gets only their own id, in their own org, never a colleague''s or a foreign org''s)';
  else
    raise notice 'TEST 12 (current_driver_id ID-disclosure deep check): FAIL (a3-in-A=%, a3-in-B=%, a4-in-A=%)', v_a3_in_a, v_a3_in_b, v_a4_in_a;
  end if;
end $$;
reset role;

-- =============================================================================
-- 13. Platform Admin check (positive)
-- =============================================================================
do $$
declare v_is_admin boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000d1'; -- the seeded platform admin, no membership anywhere
  select is_platform_admin() into v_is_admin;
  if v_is_admin = true then
    raise notice 'TEST 13 (platform admin positive check): PASS (true for the genuinely granted user)';
  else
    raise notice 'TEST 13 (platform admin positive check): FAIL (got %)', v_is_admin;
  end if;
end $$;
reset role;

-- =============================================================================
-- 14. Org Admin cannot manufacture Platform Admin — function-level angle
-- (table-level angle is adversarial test S in rls_adversarial_tests.sql;
-- this confirms is_platform_admin() itself cannot be influenced by
-- Membership.role, no matter how privileged that role is)
-- =============================================================================
do $$
declare v_is_admin boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- Org A organization_admin — the most privileged ORG role that exists
  select is_platform_admin() into v_is_admin;
  if v_is_admin = false then
    raise notice 'TEST 14 (org admin cannot manufacture platform admin): PASS (organization_admin role has zero influence on is_platform_admin())';
  else
    raise notice 'TEST 14 (org admin cannot manufacture platform admin): FAIL (got true for a plain org admin)';
  end if;
end $$;
reset role;

-- =============================================================================
-- 15/16/17. Public schema CREATE denial for PUBLIC / anon / authenticated
-- =============================================================================
do $$
begin
  if has_schema_privilege('public', 'public', 'CREATE') then
    raise notice 'TEST 15 (PUBLIC schema CREATE denial): FAIL (PUBLIC can CREATE in public)';
  else
    raise notice 'TEST 15 (PUBLIC schema CREATE denial): PASS';
  end if;
  if has_schema_privilege('anon', 'public', 'CREATE') then
    raise notice 'TEST 16 (anon schema CREATE denial): FAIL (anon can CREATE in public)';
  else
    raise notice 'TEST 16 (anon schema CREATE denial): PASS';
  end if;
  if has_schema_privilege('authenticated', 'public', 'CREATE') then
    raise notice 'TEST 17 (authenticated schema CREATE denial): FAIL (authenticated can CREATE in public)';
  else
    raise notice 'TEST 17 (authenticated schema CREATE denial): PASS';
  end if;
end $$;

-- =============================================================================
-- 18. Function ownership check (all 5 helpers)
-- =============================================================================
do $$
declare v_bad text;
begin
  select string_agg(p.proname || '=' || pg_get_userbyid(p.proowner), ', ') into v_bad
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_org_member','has_org_role','current_driver_id','is_driver_assigned_to_trip','is_platform_admin')
    and pg_get_userbyid(p.proowner) <> 'postgres';
  if v_bad is null then
    raise notice 'TEST 18 (function ownership): PASS (all 5 helpers owned by the trusted postgres role)';
  else
    raise notice 'TEST 18 (function ownership): FAIL (unexpected owners: %)', v_bad;
  end if;
end $$;

-- =============================================================================
-- 19. search_path assertion (all 5 helpers)
-- =============================================================================
do $$
declare v_bad text;
begin
  select string_agg(p.proname || '=' || coalesce(array_to_string(p.proconfig, ';'), 'UNSET'), ', ') into v_bad
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_org_member','has_org_role','current_driver_id','is_driver_assigned_to_trip','is_platform_admin')
    and (p.proconfig is null or not ('search_path=public, pg_temp' = any(p.proconfig)));
  if v_bad is null then
    raise notice 'TEST 19 (search_path assertion): PASS (all 5 helpers have explicit search_path=public, pg_temp)';
  else
    raise notice 'TEST 19 (search_path assertion): FAIL (%)', v_bad;
  end if;
end $$;

-- =============================================================================
-- 20. Function ACL assertion (exact expected shape for all 7 public-schema functions)
-- =============================================================================
do $$
declare v_bad text;
begin
  select string_agg(p.proname, ', ') into v_bad
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_org_member','has_org_role','current_driver_id','is_driver_assigned_to_trip','is_platform_admin')
    and not (
      has_function_privilege('authenticated', p.oid, 'EXECUTE')
      and not has_function_privilege('anon', p.oid, 'EXECUTE')
      and not has_function_privilege('public', p.oid, 'EXECUTE')
    );
  if v_bad is not null then
    raise notice 'TEST 20a (helper ACL shape): FAIL (%)', v_bad;
  else
    raise notice 'TEST 20a (helper ACL shape): PASS (all 5 helpers: authenticated=yes, anon=no, PUBLIC=no)';
  end if;

  select string_agg(p.proname, ', ') into v_bad
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('set_updated_at','prevent_organization_id_change')
    and (
      has_function_privilege('authenticated', p.oid, 'EXECUTE')
      or has_function_privilege('anon', p.oid, 'EXECUTE')
      or has_function_privilege('public', p.oid, 'EXECUTE')
    );
  if v_bad is not null then
    raise notice 'TEST 20b (trigger-fn ACL shape): FAIL (% still executable by an untrusted role)', v_bad;
  else
    raise notice 'TEST 20b (trigger-fn ACL shape): PASS (neither trigger function is executable by anon/authenticated/PUBLIC)';
  end if;
end $$;

-- =============================================================================
-- Extra: has_org_role() cannot be tricked with a non-canonical role string
-- (helper-specific abuse review §6 — role array cannot bypass canonical
-- membership roles; memberships.role is CHECK-constrained to exactly
-- organization_admin/dispatcher/driver, so no row could ever match a
-- forged value in the first place — verified behaviorally, not assumed)
-- =============================================================================
do $$
declare v_result boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- real organization_admin
  select has_org_role('10000000-0000-0000-0000-0000000000a1'::uuid, array['platform_admin','super_admin','root']) into v_result;
  if v_result = false then
    raise notice 'TEST 21 (has_org_role non-canonical role array): PASS (forged/non-existent role strings never match, no bypass)';
  else
    raise notice 'TEST 21 (has_org_role non-canonical role array): FAIL (got true for a forged role)';
  end if;
end $$;
reset role;

-- =============================================================================
-- Extra: multi-org user (c1) — driver in Org B must not see Org A driver
-- data, and admin-in-A must not leak into driver-in-B's own id
-- =============================================================================
do $$
declare v_in_a uuid; v_in_b uuid;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1'; -- org_admin in A, driver in B
  select current_driver_id('10000000-0000-0000-0000-0000000000a1'::uuid) into v_in_a; -- admin in A, no Driver row there -> null
  select current_driver_id('10000000-0000-0000-0000-0000000000b1'::uuid) into v_in_b; -- driver in B -> their own driver id
  if v_in_a is null and v_in_b = '30000000-0000-0000-0000-0000000000c1'::uuid then
    raise notice 'TEST 22 (multi-org user driver resolution): PASS (no Driver row in Org A=null, correct own Driver id in Org B=%)', v_in_b;
  else
    raise notice 'TEST 22 (multi-org user driver resolution): FAIL (in_a=%, in_b=%)', v_in_a, v_in_b;
  end if;
end $$;
reset role;

do $$ begin raise notice '=== SECURITY DEFINER exposure test suite complete ==='; end $$;
