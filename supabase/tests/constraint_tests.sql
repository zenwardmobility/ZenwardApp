-- Zenward Platform — schema constraint tests (work item §55). Run as
-- postgres (superuser/BYPASSRLS) — these verify CHECK/UNIQUE/FK
-- constraints fire regardless of role, independent of RLS.

\set ON_ERROR_STOP off
\pset pager off

-- Unique membership per (user, organization).
do $$
begin
  insert into public.memberships (organization_id, user_id, role)
    values ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a1', 'dispatcher');
  raise notice 'CONSTRAINT unique-membership: FAIL (duplicate accepted)';
exception when unique_violation then
  raise notice 'CONSTRAINT unique-membership: PASS (rejected: %)', sqlerrm;
end $$;

-- Valid role values only.
do $$
begin
  insert into public.memberships (organization_id, user_id, role)
    values ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000e1', 'operations_staff');
  raise notice 'CONSTRAINT membership-role-check: FAIL (invalid role accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT membership-role-check: PASS (rejected: %)', sqlerrm;
end $$;

-- Valid membership status values only.
do $$
begin
  insert into public.memberships (organization_id, user_id, role, status)
    values ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000e1', 'dispatcher', 'pending');
  raise notice 'CONSTRAINT membership-status-check: FAIL (invalid status accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT membership-status-check: PASS (rejected: %)', sqlerrm;
end $$;

-- Valid TransportationRequest state values only.
do $$
begin
  insert into public.transportation_requests (
    organization_id, requester_name, requester_relationship, requester_phone,
    pickup_description, destination_description, return_trip_needed, state
  ) values (
    '10000000-0000-0000-0000-0000000000a1', 'x', 'self', 'x', 'x', 'x', 'no', 'ride_confirmed'
  );
  raise notice 'CONSTRAINT request-state-check: FAIL (invalid state accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT request-state-check: PASS (rejected: %)', sqlerrm;
end $$;

-- Valid Trip state values only.
do $$
begin
  insert into public.trips (organization_id, passenger_id, pickup_description, destination_description, state)
    values ('10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'x', 'y', 'en_route');
  raise notice 'CONSTRAINT trip-state-check: FAIL (invalid ambiguous state accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT trip-state-check: PASS (rejected ambiguous ''en_route'': %)', sqlerrm;
end $$;

-- Valid TripNote visibility values only.
do $$
begin
  insert into public.trip_notes (organization_id, trip_id, visibility, body)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1', 'patient_visible', 'x');
  raise notice 'CONSTRAINT note-visibility-check: FAIL (unapproved visibility value accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT note-visibility-check: PASS (rejected: %)', sqlerrm;
end $$;

-- Valid TripException status values only.
do $$
begin
  insert into public.trip_exceptions (organization_id, trip_id, status)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1', 'dismissed');
  raise notice 'CONSTRAINT exception-status-check: FAIL (unapproved ''dismissed'' status accepted)';
exception when check_violation then
  raise notice 'CONSTRAINT exception-status-check: PASS (rejected: %)', sqlerrm;
end $$;

-- Request/Trip organization consistency (Trip.request_id must belong to the same org).
do $$
begin
  insert into public.trips (organization_id, request_id, passenger_id, pickup_description, destination_description)
    values ('10000000-0000-0000-0000-0000000000b1', '70000000-0000-0000-0000-0000000000a1',
            '40000000-0000-0000-0000-0000000000b1', 'x', 'y');
  raise notice 'CONSTRAINT trip-request-org-consistency: FAIL (cross-org request_id accepted)';
exception when foreign_key_violation then
  raise notice 'CONSTRAINT trip-request-org-consistency: PASS (rejected: %)', sqlerrm;
end $$;

-- Trip/Facility relationship consistency (pickup_facility_id must belong to the same org).
do $$
begin
  insert into public.trips (organization_id, passenger_id, pickup_description, destination_description, pickup_facility_id)
    values ('10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1', 'x', 'y',
            '60000000-0000-0000-0000-0000000000b1');
  raise notice 'CONSTRAINT trip-facility-org-consistency: FAIL (cross-org pickup_facility_id accepted)';
exception when foreign_key_violation then
  raise notice 'CONSTRAINT trip-facility-org-consistency: PASS (rejected: %)', sqlerrm;
end $$;

-- Child Trip record organization consistency: TripNote.trip_id cross-org.
do $$
begin
  insert into public.trip_notes (organization_id, trip_id, visibility, body)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000b1', 'operations_only', 'x');
  raise notice 'CONSTRAINT note-trip-org-consistency: FAIL (cross-org trip_id accepted on trip_notes)';
exception when foreign_key_violation then
  raise notice 'CONSTRAINT note-trip-org-consistency: PASS (rejected: %)', sqlerrm;
end $$;

-- Child Trip record organization consistency: TripException.trip_id cross-org.
do $$
begin
  insert into public.trip_exceptions (organization_id, trip_id)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000b1');
  raise notice 'CONSTRAINT exception-trip-org-consistency: FAIL (cross-org trip_id accepted on trip_exceptions)';
exception when foreign_key_violation then
  raise notice 'CONSTRAINT exception-trip-org-consistency: PASS (rejected: %)', sqlerrm;
end $$;

-- Child Trip record organization consistency: TripEvent.trip_id cross-org.
do $$
begin
  insert into public.trip_events (organization_id, trip_id, event_type)
    values ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000b1', 'trip_scheduled');
  raise notice 'CONSTRAINT event-trip-org-consistency: FAIL (cross-org trip_id accepted on trip_events)';
exception when foreign_key_violation then
  raise notice 'CONSTRAINT event-trip-org-consistency: PASS (rejected: %)', sqlerrm;
end $$;

-- organization_id immutability trigger (direct, independent of RLS/grants —
-- run as postgres, which has full table privileges, to isolate the trigger
-- itself from the column-grant layer already covered by adversarial test N).
do $$
begin
  update public.trips set organization_id = '10000000-0000-0000-0000-0000000000b1'
    where id = '80000000-0000-0000-0000-0000000000a1';
  raise notice 'CONSTRAINT organization-id-immutable-trigger: FAIL (organization_id changed even as postgres)';
exception when others then
  raise notice 'CONSTRAINT organization-id-immutable-trigger: PASS (rejected: %)', sqlerrm;
end $$;

do $$ begin raise notice '=== Constraint test suite complete ==='; end $$;
