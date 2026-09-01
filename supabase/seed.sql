-- Zenward Platform — fictional development/test seed data (work item §52).
-- No real patient/person data. Fixed, readable UUIDs for test traceability
-- (every UUID's final 12-hex-digit group is `0000000000XX`, XX = a short
-- fixture tag, e.g. `a1` = Org A fixture 1).
-- Loaded by `supabase db reset`. See docs/security/rls-test-matrix.md for
-- how this fixture set is used by the adversarial RLS tests.

-- ---------------------------------------------------------------------------
-- Auth users. Fictional, local-dev-only password ('local-test-only-
-- fictional-pw', bcrypt-hashed) so these accounts can ALSO sign in for real
-- through the local Auth service (POST /auth/v1/token?grant_type=password)
-- when a test needs a genuinely GoTrue-issued token rather than a manually
-- simulated `SET LOCAL request.jwt.claim.sub`. The token-column fields
-- below (confirmation_token etc.) are set to '' rather than left NULL —
-- GoTrue's password-grant lookup errors on NULL there ("converting NULL to
-- string is unsupported"), a real gap found while auditing RPC exposure
-- for P1-E2-S1A; fixed here so it doesn't resurface for the next person
-- who tries the same kind of test. See docs/security/rls-test-matrix.md
-- "Obtaining real tokens" for how to actually sign in as these users.
-- ---------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  email_change_token_current, reauthentication_token
) values
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a1', 'authenticated', 'authenticated', 'org-a-admin@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a2', 'authenticated', 'authenticated', 'org-a-dispatcher@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a3', 'authenticated', 'authenticated', 'org-a-driver-a@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a4', 'authenticated', 'authenticated', 'org-a-driver-b@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a5', 'authenticated', 'authenticated', 'org-a-inactive@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000a6', 'authenticated', 'authenticated', 'org-a-driver-nolink@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000b1', 'authenticated', 'authenticated', 'org-b-admin@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000b2', 'authenticated', 'authenticated', 'org-b-dispatcher@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000b3', 'authenticated', 'authenticated', 'org-b-driver@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000c1', 'authenticated', 'authenticated', 'multi-org-user@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', 'platform-admin@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-0000000000e1', 'authenticated', 'authenticated', 'no-membership@example.test', extensions.crypt('local-test-only-fictional-pw', extensions.gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '', '', '');

-- Matching auth.identities rows — GoTrue's password grant requires an
-- 'email' provider identity per user, which a direct insert into
-- auth.users alone does not create (also found during the P1-E2-S1A audit).
insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id::text, id, jsonb_build_object('sub', id::text, 'email', email), 'email', now(), now(), now()
from auth.users
where id in (
  '20000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2',
  '20000000-0000-0000-0000-0000000000a3', '20000000-0000-0000-0000-0000000000a4',
  '20000000-0000-0000-0000-0000000000a5', '20000000-0000-0000-0000-0000000000a6',
  '20000000-0000-0000-0000-0000000000b1',
  '20000000-0000-0000-0000-0000000000b2', '20000000-0000-0000-0000-0000000000b3',
  '20000000-0000-0000-0000-0000000000c1', '20000000-0000-0000-0000-0000000000d1',
  '20000000-0000-0000-0000-0000000000e1'
);

-- ---------------------------------------------------------------------------
-- Organizations
-- ---------------------------------------------------------------------------
-- Deliberately DIFFERENT timezones for Org A/B (P1-E3-S2C), not both
-- defaulted to the same value — this is what actually exercises the
-- multi-org-timezone-context test matrix (a real user, multi-org-user@,
-- already holds Memberships in both), without inventing new fixtures.
-- Org A = America/New_York (the Georgia-launch fixture, matching every
-- other Org A fixture's own real-world framing throughout this project);
-- Org B is deliberately a DIFFERENT real US timezone (America/Chicago) so
-- the two orgs are genuinely distinguishable in tests, not a second
-- "also Georgia" org — neither value is a product-wide default (see the
-- migration's own backfill, which uses America/New_York only for
-- pre-existing rows at migration time, not as an application default).
insert into public.organizations (id, name, status, timezone) values
  ('10000000-0000-0000-0000-0000000000a1', 'Fictional Org A', 'active', 'America/New_York'),
  ('10000000-0000-0000-0000-0000000000b1', 'Fictional Org B', 'active', 'America/Chicago');

-- ---------------------------------------------------------------------------
-- Platform admin grant
-- ---------------------------------------------------------------------------
insert into public.platform_admin_grants (user_id, note) values
  ('20000000-0000-0000-0000-0000000000d1', 'Fictional platform admin for RLS testing');

-- ---------------------------------------------------------------------------
-- Memberships
-- ---------------------------------------------------------------------------
insert into public.memberships (organization_id, user_id, role, status) values
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a1', 'organization_admin', 'active'),
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2', 'dispatcher', 'active'),
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a3', 'driver', 'active'),
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a4', 'driver', 'active'),
  -- Inactive membership — must grant zero access despite existing.
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a5', 'dispatcher', 'inactive'),
  -- role=driver Membership with NO linked drivers row (P1-E3-S1 auth
  -- fixture) — a real Driver-role Membership that nonetheless has no
  -- resolvable Driver record; exercises the "safe account-configuration
  -- state" path (work item §26), never a crash.
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a6', 'driver', 'active'),
  ('10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b1', 'organization_admin', 'active'),
  ('10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b2', 'dispatcher', 'active'),
  ('10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b3', 'driver', 'active'),
  -- Multi-org user: organization_admin in Org A, driver in Org B. Must
  -- never inherit the stronger role globally (authorization-model.md §P).
  ('10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000c1', 'organization_admin', 'active'),
  ('10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000c1', 'driver', 'active');
  -- no-membership user (...n1) and platform-admin user (...p1) intentionally
  -- have zero membership rows.

-- ---------------------------------------------------------------------------
-- Drivers (operational profiles — distinct from the auth users above)
-- ---------------------------------------------------------------------------
insert into public.drivers (id, organization_id, user_id, display_name, phone, status) values
  ('30000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a3', 'Fictional Driver A1', '555-0101', 'active'),
  ('30000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a4', 'Fictional Driver A2', '555-0102', 'active'),
  ('30000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b3', 'Fictional Driver B1', '555-0201', 'active'),
  ('30000000-0000-0000-0000-0000000000c1', '10000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000c1', 'Fictional Multi-Org Driver', '555-0301', 'active');

-- ---------------------------------------------------------------------------
-- Passengers
-- ---------------------------------------------------------------------------
insert into public.passengers (id, organization_id, display_name, phone, assistance_notes, status) values
  ('40000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', 'Fictional Passenger A1', '555-0111', 'Uses a wheelchair', 'active'),
  ('40000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', 'Fictional Passenger B1', '555-0211', null, 'active');

-- ---------------------------------------------------------------------------
-- Facilities
-- ---------------------------------------------------------------------------
insert into public.facilities (id, organization_id, name, city, state, status) values
  ('60000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', 'Fictional Clinic A', 'Atlanta', 'GA', 'active'),
  ('60000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', 'Fictional Clinic B', 'Savannah', 'GA', 'active');

-- ---------------------------------------------------------------------------
-- Vehicles
-- ---------------------------------------------------------------------------
insert into public.vehicles (id, organization_id, label, status) values
  ('50000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', 'Fictional Van A1', 'active'),
  ('50000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', 'Fictional Van B1', 'active');

-- ---------------------------------------------------------------------------
-- Transportation requests
-- ---------------------------------------------------------------------------
insert into public.transportation_requests (
  id, organization_id, passenger_id, requester_name, requester_relationship, requester_phone,
  pickup_description, destination_description, return_trip_needed, state
) values (
  '70000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', '40000000-0000-0000-0000-0000000000a1',
  'Fictional Family Member', 'family', '555-0121', '123 Fictional St, Atlanta, GA', 'Fictional Clinic A', 'no', 'pending'
);

-- ---------------------------------------------------------------------------
-- Trips
-- ---------------------------------------------------------------------------
insert into public.trips (
  id, organization_id, request_id, passenger_id, state, scheduled_pickup_at,
  pickup_description, destination_description
) values
  ('80000000-0000-0000-0000-0000000000a1', '10000000-0000-0000-0000-0000000000a1', '70000000-0000-0000-0000-0000000000a1',
   '40000000-0000-0000-0000-0000000000a1', 'scheduled', now() + interval '1 day',
   '123 Fictional St, Atlanta, GA', 'Fictional Clinic A'),
  -- Second Org A trip, assigned to Driver A2 — needed to test that Driver A1
  -- cannot see another driver's trip/notes within the SAME organization.
  ('80000000-0000-0000-0000-0000000000a2', '10000000-0000-0000-0000-0000000000a1', null,
   '40000000-0000-0000-0000-0000000000a1', 'scheduled', now() + interval '2 days',
   '123 Fictional St, Atlanta, GA', 'Fictional Clinic A'),
  -- Third Org A trip, deliberately UNASSIGNED — used only for the
  -- cross-org composite-FK constraint tests (W/X), so those tests exercise
  -- the FK itself rather than incidentally tripping the one-active-
  -- assignment-per-trip constraint on an already-assigned trip.
  ('80000000-0000-0000-0000-0000000000a3', '10000000-0000-0000-0000-0000000000a1', null,
   '40000000-0000-0000-0000-0000000000a1', 'scheduled', now() + interval '3 days',
   '123 Fictional St, Atlanta, GA', 'Fictional Clinic A'),
  ('80000000-0000-0000-0000-0000000000b1', '10000000-0000-0000-0000-0000000000b1', null,
   '40000000-0000-0000-0000-0000000000b1', 'scheduled', now() + interval '1 day',
   '456 Fictional Ave, Savannah, GA', 'Fictional Clinic B');

-- ---------------------------------------------------------------------------
-- Trip assignments (active — ended_at IS NULL)
-- ---------------------------------------------------------------------------
insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1',
   '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a2',
   '30000000-0000-0000-0000-0000000000a2', null, '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000b1', '80000000-0000-0000-0000-0000000000b1',
   '30000000-0000-0000-0000-0000000000b1', '50000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-0000000000b2');

-- ---------------------------------------------------------------------------
-- Driver Today QA fixtures (P1-E3-S2, timezone-anchored P1-E3-S2C) — two
-- trips anchored to TODAY IN ORG A'S OWN OPERATIONAL TIMEZONE
-- (America/New_York) — not the database session's timezone (UTC) and not
-- a raw offset from now(), so a `db reset` run late in the UTC day (or
-- across a DST boundary) still lands the same organization-local hour and
-- never rolls a fixture past ORG A's OWN midnight. `midnight_ny` is
-- America/New_York's own midnight, TODAY, computed via the standard
-- double-AT-TIME-ZONE round-trip (see
-- docs/reports/P1-E3-S2C-operational-timezone-report.txt), expressed back
-- as an absolute timestamptz — exactly the same "org-local calendar day"
-- concept src/lib/driver/trip-presentation.ts now uses to group Driver
-- Today. Assigned to Driver A1, so Driver Today has real, non-empty,
-- non-fabricated data to render: one "next" trip and one "later today"
-- trip. Reuses the existing Org A passenger, driver, and vehicle fixtures
-- rather than inventing new ones.
-- ---------------------------------------------------------------------------
with org_a_today as (
  select ((now() at time zone 'America/New_York')::date)::timestamp at time zone 'America/New_York' as midnight_ny
)
insert into public.trips (
  id, organization_id, passenger_id, state, scheduled_pickup_at, appointment_at,
  pickup_description, destination_description
)
select '95000000-0000-0000-0000-0000000000a1'::uuid, '10000000-0000-0000-0000-0000000000a1'::uuid,
   '40000000-0000-0000-0000-0000000000a1'::uuid, 'scheduled',
   midnight_ny + interval '10 hours', midnight_ny + interval '11 hours',
   '1284 Glenwood Avenue SE, Atlanta, GA 30316', 'Fictional Clinic A'
from org_a_today
union all
select '95000000-0000-0000-0000-0000000000a2'::uuid, '10000000-0000-0000-0000-0000000000a1'::uuid,
   '40000000-0000-0000-0000-0000000000a1'::uuid, 'scheduled',
   midnight_ny + interval '14 hours', null,
   '789 Fictional Rd, Atlanta, GA', 'Fictional Clinic A'
from org_a_today;

insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by) values
  ('10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000a1',
   '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000a1', '95000000-0000-0000-0000-0000000000a2',
   '30000000-0000-0000-0000-0000000000a1', '50000000-0000-0000-0000-0000000000a1', '20000000-0000-0000-0000-0000000000a2');

-- ---------------------------------------------------------------------------
-- Trip notes (one of each visibility, on trip A1)
-- ---------------------------------------------------------------------------
insert into public.trip_notes (organization_id, trip_id, author_user_id, visibility, body) values
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1',
   '20000000-0000-0000-0000-0000000000a2', 'operations_only', 'Fictional internal note: verify insurance on file.'),
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1',
   '20000000-0000-0000-0000-0000000000a2', 'driver_visible', 'Fictional driver instruction: use side entrance.'),
  -- driver_visible note on Driver A2's trip — Driver A1 must not see this.
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a2',
   '20000000-0000-0000-0000-0000000000a2', 'driver_visible', 'Fictional driver instruction for A2: bring extra blanket.'),
  ('10000000-0000-0000-0000-0000000000b1', '80000000-0000-0000-0000-0000000000b1',
   '20000000-0000-0000-0000-0000000000b2', 'driver_visible', 'Fictional Org B driver instruction — must stay in Org B.');

-- ---------------------------------------------------------------------------
-- Trip exceptions (open, on trip A1)
-- ---------------------------------------------------------------------------
insert into public.trip_exceptions (organization_id, trip_id, exception_type, description, status, created_by) values
  ('10000000-0000-0000-0000-0000000000a1', '80000000-0000-0000-0000-0000000000a1',
   'timing_conflict', 'Fictional: passenger requested an earlier pickup time.', 'open', '20000000-0000-0000-0000-0000000000a2'),
  ('10000000-0000-0000-0000-0000000000b1', '80000000-0000-0000-0000-0000000000b1',
   'vehicle_issue', 'Fictional Org B exception — must stay in Org B.', 'open', '20000000-0000-0000-0000-0000000000b2');
