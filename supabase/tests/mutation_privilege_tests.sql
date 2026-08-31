-- Zenward Platform — mutation RPC function privilege audit (P1-E2-S2).
-- Static introspection only, run as postgres — no actor simulation, no
-- mutation, no fixture dependency. Companion to function_privilege_tests.sql
-- (P1-E2-S1A), scoped to the 13 functions added in
-- supabase/migrations/20260831100200_controlled_trip_mutations.sql.

\set ON_ERROR_STOP off
\pset pager off

-- The 3 internal helpers grant EXECUTE to no one but their owner — no
-- PUBLIC, no anon, no authenticated. This is the load-bearing check: if any
-- of these three ever gets an authenticated grant, a client could call
-- _driver_execute_trip_transition directly with an arbitrary from/to state
-- pair and bypass the whole per-action wrapper design.
do $$
declare v_bad text;
begin
  select string_agg(fn, ', ') into v_bad
  from unnest(array[
    '_is_valid_trip_transition(text,text)',
    '_lock_driver_active_assignment(uuid,uuid)',
    '_driver_execute_trip_transition(uuid,text,text,text,text,boolean)'
  ]) as fn
  where has_function_privilege('authenticated', ('public.' || fn)::regprocedure, 'EXECUTE')
     or has_function_privilege('anon', ('public.' || fn)::regprocedure, 'EXECUTE')
     or has_function_privilege('public', ('public.' || fn)::regprocedure, 'EXECUTE');
  if v_bad is null then
    raise notice 'MUTATION-PRIV internal-helpers-not-exposed: PASS (no client role can execute any internal helper)';
  else
    raise notice 'MUTATION-PRIV internal-helpers-not-exposed: FAIL (client-executable internal helper(s): %)', v_bad;
  end if;
end $$;

-- The 10 exposed RPCs grant EXECUTE to authenticated, and to authenticated
-- only — never anon, never PUBLIC.
do $$
declare v_missing text; v_leaked text;
begin
  select string_agg(fn, ', ') into v_missing
  from unnest(array[
    'driver_start_to_pickup(uuid,text)','driver_arrive_at_pickup(uuid,text)',
    'driver_mark_passenger_onboard(uuid,text)','driver_start_to_destination(uuid,text)',
    'driver_arrive_at_destination(uuid,text)','driver_complete_trip(uuid,text)',
    'cancel_trip(uuid,text)','record_no_show(uuid,text)',
    'assign_trip(uuid,uuid,uuid)','reassign_trip(uuid,uuid,uuid,text)'
  ]) as fn
  where not has_function_privilege('authenticated', ('public.' || fn)::regprocedure, 'EXECUTE');

  select string_agg(fn, ', ') into v_leaked
  from unnest(array[
    'driver_start_to_pickup(uuid,text)','driver_arrive_at_pickup(uuid,text)',
    'driver_mark_passenger_onboard(uuid,text)','driver_start_to_destination(uuid,text)',
    'driver_arrive_at_destination(uuid,text)','driver_complete_trip(uuid,text)',
    'cancel_trip(uuid,text)','record_no_show(uuid,text)',
    'assign_trip(uuid,uuid,uuid)','reassign_trip(uuid,uuid,uuid,text)'
  ]) as fn
  where has_function_privilege('anon', ('public.' || fn)::regprocedure, 'EXECUTE')
     or has_function_privilege('public', ('public.' || fn)::regprocedure, 'EXECUTE');

  if v_missing is null and v_leaked is null then
    raise notice 'MUTATION-PRIV exposed-rpcs-authenticated-only: PASS (all 10 RPCs: authenticated yes, anon/PUBLIC no)';
  else
    raise notice 'MUTATION-PRIV exposed-rpcs-authenticated-only: FAIL (missing authenticated on: %; leaked to anon/PUBLIC on: %)', v_missing, v_leaked;
  end if;
end $$;

-- All 13 new functions are SECURITY DEFINER except the pure, table-free
-- _is_valid_trip_transition (which needs no elevated privilege at all).
do $$
declare v_bad text;
begin
  select string_agg(p.proname || ' prosecdef=' || p.prosecdef, ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in (
      '_lock_driver_active_assignment','_driver_execute_trip_transition',
      'driver_start_to_pickup','driver_arrive_at_pickup','driver_mark_passenger_onboard',
      'driver_start_to_destination','driver_arrive_at_destination','driver_complete_trip',
      'cancel_trip','record_no_show','assign_trip','reassign_trip'
    )
    and not p.prosecdef;
  if v_bad is null then
    raise notice 'MUTATION-PRIV security-definer-flag: PASS (all 12 privilege-requiring mutation functions are SECURITY DEFINER)';
  else
    raise notice 'MUTATION-PRIV security-definer-flag: FAIL (missing SECURITY DEFINER: %)', v_bad;
  end if;
end $$;

-- Every SECURITY DEFINER function among the 13 sets an explicit,
-- non-caller-controlled search_path (public, pg_temp) — required so a
-- malicious/attacker-influenced search_path on the calling session cannot
-- redirect unqualified name resolution inside the function body.
do $$
declare v_bad text;
begin
  select string_agg(p.proname, ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in (
      '_lock_driver_active_assignment','_driver_execute_trip_transition',
      'driver_start_to_pickup','driver_arrive_at_pickup','driver_mark_passenger_onboard',
      'driver_start_to_destination','driver_arrive_at_destination','driver_complete_trip',
      'cancel_trip','record_no_show','assign_trip','reassign_trip'
    )
    and p.prosecdef
    and not (p.proconfig is not null and 'search_path=public, pg_temp' = any(p.proconfig));
  if v_bad is null then
    raise notice 'MUTATION-PRIV search-path-hardened: PASS (every SECURITY DEFINER mutation function sets search_path=public, pg_temp)';
  else
    raise notice 'MUTATION-PRIV search-path-hardened: FAIL (missing/wrong search_path: %)', v_bad;
  end if;
end $$;

-- All 13 new functions are owned by postgres, not an application-facing role.
do $$
declare v_bad text;
begin
  select string_agg(p.proname || ' owned by ' || pg_get_userbyid(p.proowner), ', ') into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname in (
      '_is_valid_trip_transition','_lock_driver_active_assignment','_driver_execute_trip_transition',
      'driver_start_to_pickup','driver_arrive_at_pickup','driver_mark_passenger_onboard',
      'driver_start_to_destination','driver_arrive_at_destination','driver_complete_trip',
      'cancel_trip','record_no_show','assign_trip','reassign_trip'
    )
    and pg_get_userbyid(p.proowner) in ('anon', 'authenticated', 'service_role');
  if v_bad is null then
    raise notice 'MUTATION-PRIV trusted-ownership: PASS (no mutation function is owned by an application-facing role)';
  else
    raise notice 'MUTATION-PRIV trusted-ownership: FAIL (%)', v_bad;
  end if;
end $$;

-- trip_assignments direct INSERT/UPDATE is now revoked from authenticated
-- entirely (20260831100000_trip_assignment_privilege_tightening.sql) — the
-- table-level regression companion to the RPC-level checks above.
do $$
begin
  if has_table_privilege('authenticated', 'public.trip_assignments', 'INSERT')
     or has_table_privilege('authenticated', 'public.trip_assignments', 'UPDATE') then
    raise notice 'MUTATION-PRIV trip-assignments-direct-write-revoked: FAIL (authenticated still holds a direct table privilege on trip_assignments)';
  else
    raise notice 'MUTATION-PRIV trip-assignments-direct-write-revoked: PASS (authenticated has neither INSERT nor UPDATE on trip_assignments)';
  end if;
end $$;

-- The two superseded RLS policies were dropped, not merely left inert.
do $$
declare v_leftover text;
begin
  select string_agg(polname, ', ') into v_leftover
  from pg_policy
  where polrelid = 'public.trip_assignments'::regclass
    and polname in ('trip_assignments_insert_org_operations', 'trip_assignments_update_org_operations');
  if v_leftover is null then
    raise notice 'MUTATION-PRIV superseded-policies-dropped: PASS (the two superseded trip_assignments policies no longer exist)';
  else
    raise notice 'MUTATION-PRIV superseded-policies-dropped: FAIL (still present: %)', v_leftover;
  end if;
end $$;

do $$ begin raise notice '=== Mutation RPC privilege test suite complete ==='; end $$;
