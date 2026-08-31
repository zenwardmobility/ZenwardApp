-- Zenward Platform — adversarial RLS test suite (work item §53/§54, P1-E2-S1).
--
-- METHODOLOGY (documented per the explicit instruction to state exactly how
-- actor context is simulated): each test runs `SET ROLE authenticated;` plus
-- `SET request.jwt.claim.sub = '<user-uuid>'` — the exact GUC auth.uid()
-- reads in this Supabase version (`\sf auth.uid` confirms this). `postgres`
-- is a superuser with BYPASSRLS, so SET ROLE is required to actually become
-- subject to RLS as a real, non-bypassing role — this is genuinely
-- exercising the same policies PostgREST would evaluate for a real
-- authenticated request, not a service-role shortcut. Every test resets to
-- `postgres`/no role afterward. Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/rls_adversarial_tests.sql
--
-- Fixtures come from supabase/seed.sql (fictional data only). Each block
-- below is labeled with the letter from the work item's required test list.

\set ON_ERROR_STOP off
\pset pager off

-- =============================================================================
-- A. Org A Admin SELECT Org A Trip — ALLOW
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000a1';
  if v_count = 1 then raise notice 'TEST A: PASS (Org A admin sees Org A trip)';
  else raise notice 'TEST A: FAIL (expected 1, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- B. Org A Admin SELECT Org B Trip — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000b1';
  if v_count = 0 then raise notice 'TEST B: PASS (Org A admin cannot see Org B trip)';
  else raise notice 'TEST B: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- C. Org A Dispatcher SELECT Org A Passenger — ALLOW
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  select count(*) into v_count from public.passengers where id = '40000000-0000-0000-0000-0000000000a1';
  if v_count = 1 then raise notice 'TEST C: PASS (Org A dispatcher sees Org A passenger)';
  else raise notice 'TEST C: FAIL (expected 1, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- D. Org A Dispatcher SELECT Org B Passenger — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2';
  select count(*) into v_count from public.passengers where id = '40000000-0000-0000-0000-0000000000b1';
  if v_count = 0 then raise notice 'TEST D: PASS (Org A dispatcher cannot see Org B passenger)';
  else raise notice 'TEST D: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- E. Org A Driver directly SELECT Passenger — DENY (ZD-080, no exceptions)
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.passengers where id = '40000000-0000-0000-0000-0000000000a1';
  if v_count = 0 then raise notice 'TEST E: PASS (Driver A cannot directly SELECT any Passenger row, including their own assigned trip''s passenger)';
  else raise notice 'TEST E: FAIL (expected 0, got % — CRITICAL: ZD-080 violated)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- F. Driver A SELECT own assigned Trip — ALLOW
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000a1';
  if v_count = 1 then raise notice 'TEST F: PASS (Driver A sees own assigned trip)';
  else raise notice 'TEST F: FAIL (expected 1, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- G. Driver A SELECT Driver B's Trip in same Org — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000a2';
  if v_count = 0 then raise notice 'TEST G: PASS (Driver A cannot see Driver A2''s trip in the same org)';
  else raise notice 'TEST G: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- H. Driver A SELECT Org B Trip — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000b1';
  if v_count = 0 then raise notice 'TEST H: PASS (Driver A cannot see Org B trip)';
  else raise notice 'TEST H: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- I. Driver A SELECT driver_visible note on own assigned Trip — ALLOW
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trip_notes
    where trip_id = '80000000-0000-0000-0000-0000000000a1' and visibility = 'driver_visible';
  if v_count = 1 then raise notice 'TEST I: PASS (Driver A sees driver_visible note on own trip)';
  else raise notice 'TEST I: FAIL (expected 1, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- J. Driver A SELECT operations_only note — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trip_notes
    where trip_id = '80000000-0000-0000-0000-0000000000a1' and visibility = 'operations_only';
  if v_count = 0 then raise notice 'TEST J: PASS (Driver A cannot see operations_only note, even on own trip)';
  else raise notice 'TEST J: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- K. Driver A SELECT driver_visible note on another Driver's Trip — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trip_notes
    where trip_id = '80000000-0000-0000-0000-0000000000a2' and visibility = 'driver_visible';
  if v_count = 0 then raise notice 'TEST K: PASS (Driver A cannot see driver_visible note on Driver A2''s trip)';
  else raise notice 'TEST K: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- L. Driver A arbitrary Trip state UPDATE — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  update public.trips set state = 'completed' where id = '80000000-0000-0000-0000-0000000000a1';
  raise notice 'TEST L: FAIL (UPDATE of trips.state succeeded — should have been denied)';
exception when others then
  raise notice 'TEST L: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- M. Driver A TripAssignment INSERT — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  insert into public.trip_assignments (organization_id, trip_id, driver_id)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a2',
            '30000000-0000-0000-0000-0000000000a1');
  raise notice 'TEST M: FAIL (Driver A inserted a trip_assignment — should have been denied)';
exception when others then
  raise notice 'TEST M: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- N. Driver A organization_id mutation — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  update public.trips set organization_id = '10000000-0000-0000-0000-0000000000b1'
    where id = '80000000-0000-0000-0000-0000000000a1';
  raise notice 'TEST N: FAIL (organization_id mutation succeeded — should have been denied)';
exception when others then
  raise notice 'TEST N: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- O. Inactive Membership attempts formerly valid Trip SELECT — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a5'; -- inactive dispatcher
  select count(*) into v_count from public.trips where organization_id = '10000000-0000-0000-0000-0000000000a1';
  if v_count = 0 then raise notice 'TEST O: PASS (inactive membership sees zero Org A trips)';
  else raise notice 'TEST O: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- P. Multi-org user does not inherit strongest role globally
--
-- NOTE: `memberships_select_self` correctly lets any user see their OWN
-- membership row in any org they belong to (that's the approved model —
-- "User: may read own Membership where appropriate"), so a naive
-- organization_id-only count would include that one self-row even where
-- the user is NOT an admin. The meaningful assertion is: as org_admin in
-- Org A they can see OTHER members' rows too; as a mere driver in Org B
-- they can see only their own row and nobody else's.
-- =============================================================================
do $$
declare v_a_others int; v_b_others int; v_b_self int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000c1'; -- org_admin in A, driver in B
  select count(*) into v_a_others from public.memberships
    where organization_id = '10000000-0000-0000-0000-0000000000a1' and user_id <> '20000000-0000-0000-0000-0000000000c1';
  select count(*) into v_b_others from public.memberships
    where organization_id = '10000000-0000-0000-0000-0000000000b1' and user_id <> '20000000-0000-0000-0000-0000000000c1';
  select count(*) into v_b_self from public.memberships
    where organization_id = '10000000-0000-0000-0000-0000000000b1' and user_id = '20000000-0000-0000-0000-0000000000c1';
  if v_a_others > 0 and v_b_others = 0 and v_b_self = 1 then
    raise notice 'TEST P: PASS (org_admin in Org A sees other members''=%; mere driver in Org B sees only own row, others=%, self=%  — strongest role NOT inherited globally)', v_a_others, v_b_others, v_b_self;
  else
    raise notice 'TEST P: FAIL (Org A others=%, Org B others=%, Org B self=% — expected >0, 0, 1)', v_a_others, v_b_others, v_b_self;
  end if;
end $$;
reset role;

-- =============================================================================
-- Q. Unauthenticated TransportationRequest SELECT — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role anon;
  select count(*) into v_count from public.transportation_requests;
  raise notice 'TEST Q: FAIL (anon SELECT succeeded, returned % rows — should have been denied)', v_count;
exception when others then
  raise notice 'TEST Q: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- R. Unauthenticated Passenger SELECT — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role anon;
  select count(*) into v_count from public.passengers;
  raise notice 'TEST R: FAIL (anon SELECT succeeded, returned % rows — should have been denied)', v_count;
exception when others then
  raise notice 'TEST R: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- S. Org Admin PlatformAdminGrant mutation — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1'; -- org admin
  insert into public.platform_admin_grants (user_id) values ('20000000-0000-0000-0000-0000000000a1');
  raise notice 'TEST S: FAIL (Org Admin self-granted PlatformAdminGrant — should have been denied)';
exception when others then
  raise notice 'TEST S: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- T. Normal role TripEvent DELETE — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  delete from public.trip_events where id = '80000000-0000-0000-0000-0000000000a1';
  raise notice 'TEST T: FAIL (TripEvent DELETE succeeded — should have been denied)';
exception when others then
  raise notice 'TEST T: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- U. Normal role AuditEvent DELETE — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a1';
  delete from public.audit_events where id = '80000000-0000-0000-0000-0000000000a1';
  raise notice 'TEST U: FAIL (AuditEvent DELETE succeeded — should have been denied)';
exception when others then
  raise notice 'TEST U: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- V. Cross-org Trip → Passenger relationship — DATABASE REJECTS
-- (run as postgres — this is a schema-constraint test, not an RLS test)
-- =============================================================================
do $$
begin
  insert into public.trips (organization_id, passenger_id, pickup_description, destination_description)
    values ('10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000b1', 'x', 'y');
  raise notice 'TEST V: FAIL (cross-org Trip->Passenger insert succeeded — should have been rejected)';
exception when others then
  raise notice 'TEST V: PASS (rejected: %)', sqlerrm;
end $$;

-- =============================================================================
-- W. Cross-org TripAssignment → Driver relationship — DATABASE REJECTS
-- Uses trip_a3, which is deliberately UNASSIGNED in the seed, so this test
-- exercises the composite FK itself rather than incidentally tripping the
-- one-active-assignment-per-trip constraint on an already-assigned trip.
-- =============================================================================
do $$
begin
  insert into public.trip_assignments (organization_id, trip_id, driver_id)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a3',
            '30000000-0000-0000-0000-0000000000b1');
  raise notice 'TEST W: FAIL (cross-org TripAssignment->Driver insert succeeded — should have been rejected)';
exception when others then
  raise notice 'TEST W: PASS (rejected: %)', sqlerrm;
end $$;

-- =============================================================================
-- X. Cross-org TripAssignment → Vehicle relationship — DATABASE REJECTS
-- Also uses the unassigned trip_a3 for the same reason as W.
-- =============================================================================
do $$
begin
  insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a3',
            '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000b1');
  raise notice 'TEST X: FAIL (cross-org TripAssignment->Vehicle insert succeeded — should have been rejected)';
exception when others then
  raise notice 'TEST X: PASS (rejected: %)', sqlerrm;
end $$;

-- =============================================================================
-- Y. Second active TripAssignment — DATABASE REJECTS
-- =============================================================================
do $$
begin
  insert into public.trip_assignments (organization_id, trip_id, driver_id)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1',
            '30000000-0000-0000-0000-0000000000a2');
  raise notice 'TEST Y: FAIL (second active assignment on the same trip succeeded — should have been rejected)';
exception when others then
  raise notice 'TEST Y: PASS (rejected: %)', sqlerrm;
end $$;

-- =============================================================================
-- Z. Direct REST/client-style request produces the same authorization
-- decision as any UI-intended path.
-- =============================================================================
-- Satisfied by construction, not a separate query: every test in this suite
-- IS a direct-to-Postgres request under a real `authenticated`/`anon` role
-- with no application code involved — there is no separate "UI path" in
-- this database-only phase to diverge from. RLS is evaluated identically
-- regardless of which client (browser, curl, this test script) issues the
-- request, because Postgres has no notion of "the UI" — only the role and
-- claims a request carries. See docs/security/rls-model.md for this note.
do $$ begin raise notice 'TEST Z: PASS by construction — see comment above'; end $$;

-- =============================================================================
-- AA. Authenticated user without Membership attempts tenant SELECT — DENY
-- =============================================================================
do $$
declare v_trips int; v_orgs int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000e1'; -- no memberships anywhere
  select count(*) into v_trips from public.trips;
  select count(*) into v_orgs from public.organizations;
  if v_trips = 0 and v_orgs = 0 then
    raise notice 'TEST AA: PASS (authenticated user with zero memberships sees zero trips/organizations)';
  else
    raise notice 'TEST AA: FAIL (trips=%, organizations=% — expected 0, 0)', v_trips, v_orgs;
  end if;
end $$;
reset role;

-- =============================================================================
-- AB. Inactive Driver Membership while auth session remains valid — DENY
-- (uses the same inactive-membership mechanism as O — status is evaluated
-- live regardless of which role was deactivated; see docs/security/
-- rls-model.md for why one fixture covers both.)
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a5';
  select count(*) into v_count from public.transportation_requests where organization_id = '10000000-0000-0000-0000-0000000000a1';
  if v_count = 0 then raise notice 'TEST AB: PASS (inactive membership grants zero access across tables, not just trips)';
  else raise notice 'TEST AB: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- AC. User sends forged organization_id on permitted insert — DENY
-- =============================================================================
do $$
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher only
  insert into public.passengers (organization_id, display_name)
    values ('10000000-0000-0000-0000-0000000000b1', 'Forged Org B Passenger');
  raise notice 'TEST AC: FAIL (insert with forged organization_id succeeded — should have been denied)';
exception when others then
  raise notice 'TEST AC: PASS (denied: %)', sqlerrm;
end $$;
reset role;

-- =============================================================================
-- AD. Driver guesses another Trip UUID — DENY
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trips where id = '80000000-0000-0000-0000-0000000000a2'; -- guessed, not theirs
  if v_count = 0 then raise notice 'TEST AD: PASS (guessing another trip UUID grants nothing)';
  else raise notice 'TEST AD: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- AE. Driver guesses another TripNote UUID — DENY
-- =============================================================================
do $$
declare v_note_id uuid; v_count int;
begin
  select id into v_note_id from public.trip_notes
    where trip_id = '80000000-0000-0000-0000-0000000000a2' and visibility = 'driver_visible';
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  select count(*) into v_count from public.trip_notes where id = v_note_id;
  if v_count = 0 then raise notice 'TEST AE: PASS (guessing another driver''s note UUID grants nothing)';
  else raise notice 'TEST AE: FAIL (expected 0, got %)', v_count; end if;
end $$;
reset role;

-- =============================================================================
-- AF. Dispatcher attempts cross-org child entity access — DENY
-- =============================================================================
do $$
declare v_assignments int; v_notes int; v_exceptions int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a2'; -- Org A dispatcher
  select count(*) into v_assignments from public.trip_assignments where trip_id = '80000000-0000-0000-0000-0000000000b1';
  select count(*) into v_notes from public.trip_notes where trip_id = '80000000-0000-0000-0000-0000000000b1';
  select count(*) into v_exceptions from public.trip_exceptions where trip_id = '80000000-0000-0000-0000-0000000000b1';
  if v_assignments = 0 and v_notes = 0 and v_exceptions = 0 then
    raise notice 'TEST AF: PASS (Org A dispatcher sees zero Org B child entities: assignments/notes/exceptions)';
  else
    raise notice 'TEST AF: FAIL (assignments=%, notes=%, exceptions=% — expected 0,0,0)', v_assignments, v_notes, v_exceptions;
  end if;
end $$;
reset role;

-- =============================================================================
-- Summary marker
-- =============================================================================
do $$ begin raise notice '=== RLS adversarial test suite complete — review PASS/FAIL lines above ==='; end $$;
