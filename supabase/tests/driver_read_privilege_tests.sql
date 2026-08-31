-- Zenward Platform — Driver read API function privilege audit (P1-E2-S3).
-- Static introspection only, run as postgres — no actor simulation, no
-- mutation, no fixture dependency. Companion to mutation_privilege_tests.sql
-- (P1-E2-S2), scoped to the 4 functions added in
-- supabase/migrations/20260831110100_driver_read_api.sql, plus the base-
-- table policy retirement in 20260831110200_driver_base_table_policy_tightening.sql.

\set ON_ERROR_STOP off
\pset pager off

-- The 4 Driver read RPCs grant EXECUTE to authenticated only — never anon,
-- never PUBLIC.
do $$
declare v_missing text; v_leaked text;
begin
  select string_agg(fn, ', ') into v_missing
  from unnest(array[
    'driver_get_profile(uuid)','driver_list_active_trips(uuid)',
    'driver_get_trip_detail(uuid)','driver_list_trip_history(uuid,timestamptz,timestamptz)'
  ]) as fn
  where not has_function_privilege('authenticated', ('public.' || fn)::regprocedure, 'EXECUTE');

  select string_agg(fn, ', ') into v_leaked
  from unnest(array[
    'driver_get_profile(uuid)','driver_list_active_trips(uuid)',
    'driver_get_trip_detail(uuid)','driver_list_trip_history(uuid,timestamptz,timestamptz)'
  ]) as fn
  where has_function_privilege('anon', ('public.' || fn)::regprocedure, 'EXECUTE')
     or has_function_privilege('public', ('public.' || fn)::regprocedure, 'EXECUTE');

  if v_missing is null and v_leaked is null then
    raise notice 'DRIVER-READ-PRIV exposed-rpcs-authenticated-only: PASS (all 4 read RPCs: authenticated yes, anon/PUBLIC no)';
  else
    raise notice 'DRIVER-READ-PRIV exposed-rpcs-authenticated-only: FAIL (missing authenticated on: %; leaked to anon/PUBLIC on: %)', v_missing, v_leaked;
  end if;
end $$;

-- All 4 are SECURITY DEFINER.
do $$
declare v_bad text;
begin
  select string_agg(p.proname || ' prosecdef=' || p.prosecdef, ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in ('driver_get_profile','driver_list_active_trips','driver_get_trip_detail','driver_list_trip_history')
    and not p.prosecdef;
  if v_bad is null then
    raise notice 'DRIVER-READ-PRIV security-definer-flag: PASS (all 4 read functions are SECURITY DEFINER)';
  else
    raise notice 'DRIVER-READ-PRIV security-definer-flag: FAIL (missing SECURITY DEFINER: %)', v_bad;
  end if;
end $$;

-- All 4 are STABLE (read-only, never mutate) — provolatile = 's'.
do $$
declare v_bad text;
begin
  select string_agg(p.proname || ' provolatile=' || p.provolatile::text, ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in ('driver_get_profile','driver_list_active_trips','driver_get_trip_detail','driver_list_trip_history')
    and p.provolatile <> 's';
  if v_bad is null then
    raise notice 'DRIVER-READ-PRIV stable-volatility: PASS (all 4 read functions are STABLE, not VOLATILE)';
  else
    raise notice 'DRIVER-READ-PRIV stable-volatility: FAIL (%)', v_bad;
  end if;
end $$;

-- Explicit search_path on all 4.
do $$
declare v_bad text;
begin
  select string_agg(p.proname, ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in ('driver_get_profile','driver_list_active_trips','driver_get_trip_detail','driver_list_trip_history')
    and not (p.proconfig is not null and 'search_path=public, pg_temp' = any(p.proconfig));
  if v_bad is null then
    raise notice 'DRIVER-READ-PRIV search-path-hardened: PASS (every read function sets search_path=public, pg_temp)';
  else
    raise notice 'DRIVER-READ-PRIV search-path-hardened: FAIL (missing/wrong search_path: %)', v_bad;
  end if;
end $$;

-- Trusted ownership.
do $$
declare v_bad text;
begin
  select string_agg(p.proname || ' owned by ' || pg_get_userbyid(p.proowner), ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in ('driver_get_profile','driver_list_active_trips','driver_get_trip_detail','driver_list_trip_history')
    and pg_get_userbyid(p.proowner) in ('anon', 'authenticated', 'service_role');
  if v_bad is null then
    raise notice 'DRIVER-READ-PRIV trusted-ownership: PASS (no read function is owned by an application-facing role)';
  else
    raise notice 'DRIVER-READ-PRIV trusted-ownership: FAIL (%)', v_bad;
  end if;
end $$;

-- The 6 retired Driver base-table SELECT policies are actually gone.
do $$
declare v_leftover text;
begin
  select string_agg(polrelid::regclass::text || '.' || polname, ', ') into v_leftover
  from pg_policy
  where polname in (
    'drivers_select_own', 'trips_select_assigned_driver',
    'trip_assignments_select_own_driver', 'vehicles_select_assigned_driver',
    'trip_notes_select_assigned_driver_visible', 'trip_events_select_assigned_driver'
  );
  if v_leftover is null then
    raise notice 'DRIVER-READ-PRIV retired-policies-gone: PASS (all 6 superseded Driver base-table SELECT policies removed)';
  else
    raise notice 'DRIVER-READ-PRIV retired-policies-gone: FAIL (still present: %)', v_leftover;
  end if;
end $$;

-- trip_exceptions_select_assigned_driver was a DELIBERATE non-retirement
-- (docs/security/driver-data-minimization.md) — confirm it still exists,
-- so a future change removing it is a conscious decision, not drift.
do $$
begin
  if exists (select 1 from pg_policy where polname = 'trip_exceptions_select_assigned_driver') then
    raise notice 'DRIVER-READ-PRIV trip-exceptions-deliberately-retained: PASS (trip_exceptions_select_assigned_driver still exists, as decided)';
  else
    raise notice 'DRIVER-READ-PRIV trip-exceptions-deliberately-retained: FAIL (policy missing — was it dropped unintentionally?)';
  end if;
end $$;

-- Organization Admin / Dispatcher SELECT policies on the affected tables
-- are completely untouched (5 policies expected: trips, trip_assignments,
-- vehicles, trip_notes, trip_events _org_operations policies).
do $$
declare v_missing text;
begin
  select string_agg(fn, ', ') into v_missing
  from unnest(array[
    'trips_select_org_operations','trip_assignments_select_org_operations',
    'vehicles_select_org_operations','trip_notes_select_operations',
    'trip_events_select_org_operations','drivers_select_org_operations'
  ]) as fn
  where not exists (select 1 from pg_policy where polname = fn);
  if v_missing is null then
    raise notice 'DRIVER-READ-PRIV ops-access-untouched: PASS (all 6 Organization Admin/Dispatcher policies on affected tables still exist)';
  else
    raise notice 'DRIVER-READ-PRIV ops-access-untouched: FAIL (missing: %)', v_missing;
  end if;
end $$;

do $$ begin raise notice '=== Driver read API privilege test suite complete ==='; end $$;
