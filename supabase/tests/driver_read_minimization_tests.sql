-- Zenward Platform — Driver read API minimization tests (P1-E2-S3).
--
-- Covers future-column leak protection (§39, via exact composite-type
-- column-set assertions — a structural guarantee, not just a runtime
-- check: these types CANNOT contain an unlisted field at all), note
-- visibility (§53), phone visibility across contexts (§54), the direct
-- Passenger base-table regression paired with controlled-path success
-- (§40), and explicit absence checks for every excluded data category
-- (§52). Same SET ROLE/request.jwt.claim.sub methodology as the other
-- suites.
--
-- Run with:
--   docker exec -i supabase_db_ZenWard psql -U postgres -d postgres -f - < supabase/tests/driver_read_minimization_tests.sql

\set ON_ERROR_STOP off
\pset pager off

-- =============================================================================
-- Future-column leak protection (§39): each return type's column set is
-- asserted EXACTLY. A new column added to trips/passengers/vehicles/
-- trip_notes in the future cannot appear in any Driver-facing response
-- unless a human deliberately edits these composite type definitions —
-- there is no automatic passthrough to guard against.
-- =============================================================================
do $$
declare v_actual text; v_expected text;
begin
  select string_agg(attname, ',' order by attnum) into v_actual
  from pg_attribute where attrelid = 'public.driver_profile_result'::regclass and attnum > 0 and not attisdropped;
  v_expected := 'driver_id,organization_id,organization_name,display_name,phone,status';
  if v_actual = v_expected then
    raise notice 'TEST MIN-KEYS-PROFILE: PASS (driver_profile_result columns exactly: %)', v_actual;
  else
    raise notice 'TEST MIN-KEYS-PROFILE: FAIL (expected [%], got [%])', v_expected, v_actual;
  end if;
end $$;

do $$
declare v_actual text; v_expected text;
begin
  select string_agg(attname, ',' order by attnum) into v_actual
  from pg_attribute where attrelid = 'public.driver_active_trip_summary'::regclass and attnum > 0 and not attisdropped;
  v_expected := 'trip_id,assignment_id,state,scheduled_pickup_at,appointment_at,pickup_description,destination_description,passenger_display_name,vehicle_label,vehicle_status';
  if v_actual = v_expected then
    raise notice 'TEST MIN-KEYS-LIST: PASS (driver_active_trip_summary columns exactly: %)', v_actual;
  else
    raise notice 'TEST MIN-KEYS-LIST: FAIL (expected [%], got [%])', v_expected, v_actual;
  end if;
end $$;

do $$
declare v_actual text; v_expected text;
begin
  select string_agg(attname, ',' order by attnum) into v_actual
  from pg_attribute where attrelid = 'public.driver_trip_detail_result'::regclass and attnum > 0 and not attisdropped;
  v_expected := 'trip_id,assignment_id,state,scheduled_pickup_at,appointment_at,pickup_description,destination_description,passenger_display_name,passenger_phone,assistance_notes,instructions,vehicle_label,vehicle_status,driver_notes';
  if v_actual = v_expected then
    raise notice 'TEST MIN-KEYS-DETAIL: PASS (driver_trip_detail_result columns exactly: %)', v_actual;
  else
    raise notice 'TEST MIN-KEYS-DETAIL: FAIL (expected [%], got [%])', v_expected, v_actual;
  end if;
end $$;

do $$
declare v_actual text; v_expected text;
begin
  select string_agg(attname, ',' order by attnum) into v_actual
  from pg_attribute where attrelid = 'public.driver_trip_history_entry'::regclass and attnum > 0 and not attisdropped;
  v_expected := 'trip_id,scheduled_pickup_at,assignment_started_at,assignment_ended_at,end_reason,trip_outcome';
  if v_actual = v_expected then
    raise notice 'TEST MIN-KEYS-HISTORY: PASS (driver_trip_history_entry columns exactly: %)', v_actual;
  else
    raise notice 'TEST MIN-KEYS-HISTORY: FAIL (expected [%], got [%])', v_expected, v_actual;
  end if;
end $$;

-- Explicit confirmation: none of the excluded categories exist as a
-- column anywhere in the 4 types (structural, not merely "we didn't
-- populate it this time").
do $$
declare v_bad text;
begin
  select string_agg(pg_attribute.attrelid::regclass::text || '.' || attname, ', ') into v_bad
  from pg_attribute
  where attrelid in (
    'public.driver_profile_result'::regclass, 'public.driver_active_trip_summary'::regclass,
    'public.driver_trip_detail_result'::regclass, 'public.driver_trip_history_entry'::regclass
  )
  and attnum > 0 and not attisdropped
  and (
    attname ilike '%requester%' or attname ilike '%audit%' or attname ilike '%actor%'
    or attname ilike '%billing%' or attname ilike '%payment%' or attname ilike '%insurance%'
    or attname ilike '%diagnos%' or attname ilike '%medication%' or attname ilike '%dob%'
    or attname ilike '%birth%' or attname ilike '%author%'
  );
  if v_bad is null then
    raise notice 'TEST MIN-EXCLUDED-CATEGORIES: PASS (no requester/audit/actor/billing/payment/insurance/clinical/author field exists in any Driver-facing type)';
  else
    raise notice 'TEST MIN-EXCLUDED-CATEGORIES: FAIL (found: %)', v_bad;
  end if;
end $$;

-- =============================================================================
-- Fixtures for the note-visibility and phone-visibility tests.
-- =============================================================================
insert into public.trips (id, organization_id, passenger_id, state, pickup_description, destination_description) values
  ('91000000-0000-0000-0000-0000000000c1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'scheduled', 'Minimization test C1', 'Minimization test C1');

insert into public.trip_assignments (organization_id, trip_id, driver_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000c1', '30000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2');

insert into public.trip_notes (organization_id, trip_id, author_user_id, visibility, body) values
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000c1', '20000000-0000-0000-0000-0000000000a2', 'driver_visible', 'Fictional: use the side entrance, main door is locked.'),
  ('10000000-0000-0000-0000-0000000000a1', '91000000-0000-0000-0000-0000000000c1', '20000000-0000-0000-0000-0000000000a2', 'operations_only', 'Fictional: verify insurance card is current before pickup.');

-- =============================================================================
-- Note visibility (§53): driver_visible appears, operations_only never does.
-- =============================================================================
do $$
declare v_r public.driver_trip_detail_result; v_note_count int; v_has_ops_text boolean;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
  reset role;
  select jsonb_array_length(v_r.driver_notes) into v_note_count;
  select exists (
    select 1 from jsonb_array_elements(v_r.driver_notes) e
    where e->>'body' ilike '%insurance%'
  ) into v_has_ops_text;
  if v_note_count = 1 and not v_has_ops_text and (v_r.driver_notes->0->>'body') ilike '%side entrance%' then
    raise notice 'TEST NOTE-VISIBILITY-1: PASS (exactly the 1 driver_visible note returned; the operations_only note text never appears)';
  else
    raise notice 'TEST NOTE-VISIBILITY-1: FAIL (note_count=%, ops_text_leaked=%, notes=%)', v_note_count, v_has_ops_text, v_r.driver_notes;
  end if;
end $$;

-- Each returned note has exactly {id, body, created_at} — no author_user_id, no visibility.
do $$
declare v_r public.driver_trip_detail_result; v_keys text;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
  reset role;
  select string_agg(k, ',' order by k) into v_keys
  from jsonb_object_keys(v_r.driver_notes->0) k;
  if v_keys = 'body,created_at,id' then
    raise notice 'TEST NOTE-VISIBILITY-2: PASS (each note object has exactly {id, body, created_at} — no author_user_id, no visibility, no organization_id/trip_id)';
  else
    raise notice 'TEST NOTE-VISIBILITY-2: FAIL (keys=%)', v_keys;
  end if;
end $$;

-- =============================================================================
-- Phone visibility (§54)
-- =============================================================================
do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- actively assigned
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
  reset role;
  if v_r.passenger_phone = '555-0111' then
    raise notice 'TEST PHONE-1 (active assigned Driver): PASS (phone visible)';
  else
    raise notice 'TEST PHONE-1 (active assigned Driver): FAIL (phone=%)', v_r.passenger_phone;
  end if;
end $$;

do $$
declare v_bad text;
begin
  select string_agg(attname, ',') into v_bad
  from pg_attribute where attrelid = 'public.driver_active_trip_summary'::regclass and attname ilike '%phone%';
  if v_bad is null then
    raise notice 'TEST PHONE-2 (active list never carries phone): PASS (driver_active_trip_summary has no phone-named column at all)';
  else
    raise notice 'TEST PHONE-2 (active list never carries phone): FAIL (found: %)', v_bad;
  end if;
end $$;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a4'; -- Driver A2, never assigned to C1
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
    raise notice 'TEST PHONE-3 (never-assigned Driver): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST PHONE-3 (never-assigned Driver): PASS (no detail at all, so no phone)';
  when others then
    raise notice 'TEST PHONE-3 (never-assigned Driver): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000b3'; -- foreign-org Driver
  begin
    v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
    raise notice 'TEST PHONE-4 (foreign Driver): FAIL (expected denial, got success)';
  exception when sqlstate 'ZW002' then
    raise notice 'TEST PHONE-4 (foreign Driver): PASS (no detail at all, so no phone)';
  when others then
    raise notice 'TEST PHONE-4 (foreign Driver): FAIL (wrong error % %)', sqlstate, sqlerrm;
  end;
end $$;
reset role;

-- =============================================================================
-- Direct Passenger base-table regression, paired with controlled-path
-- success on the SAME trip (§40) — demonstrates the difference between
-- base-table access (denied) and controlled projection access (allowed,
-- minimum-necessary fields only).
-- =============================================================================
do $$
declare v_count int;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3'; -- Driver A1, actively assigned to C1
  select count(*) into v_count from public.passengers where id = '40000000-0000-0000-0000-0000000000a1';
  reset role;
  if v_count = 0 then
    raise notice 'TEST BASE-TABLE-REGRESSION-1: PASS (direct SELECT on passengers denied — 0 rows — even for the Driver''s own actively-assigned passenger)';
  else
    raise notice 'TEST BASE-TABLE-REGRESSION-1: FAIL (expected 0, got % — CRITICAL: ZD-080 violated)', v_count;
  end if;
end $$;

do $$
declare v_r public.driver_trip_detail_result;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '20000000-0000-0000-0000-0000000000a3';
  v_r := public.driver_get_trip_detail('91000000-0000-0000-0000-0000000000c1');
  reset role;
  if v_r.passenger_display_name = 'Fictional Passenger A1' and v_r.passenger_phone = '555-0111' then
    raise notice 'TEST BASE-TABLE-REGRESSION-2: PASS (the SAME Driver, on the SAME trip, receives minimum-necessary Passenger fields ONLY through the controlled projection)';
  else
    raise notice 'TEST BASE-TABLE-REGRESSION-2: FAIL (name=%, phone=%)', v_r.passenger_display_name, v_r.passenger_phone;
  end if;
end $$;

do $$ begin raise notice '=== Driver read minimization test suite complete ==='; end $$;
