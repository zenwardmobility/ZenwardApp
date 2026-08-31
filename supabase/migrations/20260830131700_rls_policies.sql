-- RLS policies and privilege grants for every table created in this phase.
-- See docs/security/rls-model.md for the full policy-by-policy rationale
-- and docs/security/rls-test-matrix.md for the adversarial tests this
-- migration must satisfy.
--
-- Baseline posture: Supabase's local default does NOT auto-expose new
-- tables to anon/authenticated (auto_expose_new_tables is unset — see
-- supabase/config.toml). Nothing below grants anything to `anon` at all,
-- for any table — public/anonymous access is denied by the complete
-- absence of privilege, on top of RLS itself (defense in depth). Every
-- GRANT to `authenticated` below is deliberate and minimal; several tables
-- additionally use column-level GRANT/REVOKE so that even an authorized
-- row-level UPDATE cannot touch fields that must remain machine- or
-- privileged-path-only (organization_id, lifecycle state, historical
-- assignment identity — authorization-model.md §K).
--
-- Naming convention (authorization-model.md §U): <table>_<action>_<actor>.

-- =============================================================================
-- organizations
-- =============================================================================
grant select, update on public.organizations to authenticated;

create policy organizations_select_members
  on public.organizations for select to authenticated
  using (public.is_org_member(id));

create policy organizations_select_platform_admin
  on public.organizations for select to authenticated
  using (public.is_platform_admin());

create policy organizations_update_org_admin
  on public.organizations for update to authenticated
  using (public.has_org_role(id, array['organization_admin']))
  with check (public.has_org_role(id, array['organization_admin']));

-- Only `name`/`status` are ordinarily editable — id/created_at/updated_at
-- are not meaningful for a client to set directly.
revoke update on public.organizations from authenticated;
grant update (name, status) on public.organizations to authenticated;

-- No INSERT/DELETE policy for any authenticated role — organization
-- creation/deactivation remains a platform-level action (service role).

-- =============================================================================
-- memberships
-- =============================================================================
grant select, insert, update on public.memberships to authenticated;

create policy memberships_select_self
  on public.memberships for select to authenticated
  using (user_id = auth.uid());

create policy memberships_select_org_admin
  on public.memberships for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']));

create policy memberships_insert_org_admin
  on public.memberships for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin']));

create policy memberships_update_org_admin
  on public.memberships for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']))
  with check (public.has_org_role(organization_id, array['organization_admin']));

-- role/status only — organization_id/user_id are set at creation and
-- otherwise protected by the prevent_organization_id_change trigger plus
-- this column grant (user_id changing would effectively reassign the
-- membership to a different person, which is equally not an ordinary edit).
revoke update on public.memberships from authenticated;
grant update (role, status) on public.memberships to authenticated;

-- No DELETE policy — deactivate (status='inactive') instead of removing
-- history of who had access when (authorization-model.md §S).

-- =============================================================================
-- user_profiles
-- =============================================================================
grant select, insert, update on public.user_profiles to authenticated;

create policy user_profiles_select_own
  on public.user_profiles for select to authenticated
  using (id = auth.uid());

create policy user_profiles_select_org_admin
  on public.user_profiles for select to authenticated
  using (
    exists (
      select 1
      from public.memberships m
      where m.user_id = user_profiles.id
        and m.status = 'active'
        and public.has_org_role(m.organization_id, array['organization_admin'])
    )
  );

create policy user_profiles_insert_own
  on public.user_profiles for insert to authenticated
  with check (id = auth.uid());

create policy user_profiles_update_own
  on public.user_profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- =============================================================================
-- platform_admin_grants
-- =============================================================================
-- Deliberately: SELECT only. No INSERT/UPDATE/DELETE grant to authenticated
-- at all — self-service escalation is structurally impossible, not merely
-- policy-denied (ZD-049).
grant select on public.platform_admin_grants to authenticated;

create policy platform_admin_grants_select_own
  on public.platform_admin_grants for select to authenticated
  using (user_id = auth.uid());

create policy platform_admin_grants_select_platform_admin
  on public.platform_admin_grants for select to authenticated
  using (public.is_platform_admin());

-- =============================================================================
-- drivers
-- =============================================================================
grant select, insert, update on public.drivers to authenticated;

create policy drivers_select_org_operations
  on public.drivers for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy drivers_select_own
  on public.drivers for select to authenticated
  using (user_id = auth.uid());

create policy drivers_insert_org_admin
  on public.drivers for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin']));

create policy drivers_update_org_admin
  on public.drivers for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']))
  with check (public.has_org_role(organization_id, array['organization_admin']));

revoke update on public.drivers from authenticated;
grant update (display_name, phone, status, user_id) on public.drivers to authenticated;

-- =============================================================================
-- passengers
-- =============================================================================
-- *** CRITICAL: no Driver policy of any kind on this table (ZD-080). ***
grant select, insert, update on public.passengers to authenticated;

create policy passengers_select_org_operations
  on public.passengers for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy passengers_insert_org_operations
  on public.passengers for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy passengers_update_org_operations
  on public.passengers for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

revoke update on public.passengers from authenticated;
grant update (display_name, phone, assistance_notes, status) on public.passengers to authenticated;

-- =============================================================================
-- facilities
-- =============================================================================
-- No Driver policy in this phase — a driver's facility-related information
-- for an assigned trip comes from the Trip's own address snapshot, not a
-- Facility table read (domain-model.md §17/§J).
grant select, insert, update on public.facilities to authenticated;

create policy facilities_select_org_operations
  on public.facilities for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy facilities_insert_org_operations
  on public.facilities for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy facilities_update_org_operations
  on public.facilities for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

revoke update on public.facilities from authenticated;
grant update (name, address_line1, address_line2, city, state, postal_code, status)
  on public.facilities to authenticated;

-- =============================================================================
-- vehicles
-- =============================================================================
grant select, insert, update on public.vehicles to authenticated;

create policy vehicles_select_org_operations
  on public.vehicles for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- Driver reads only the vehicle on their own active assignment — never the
-- fleet directory (authorization-model.md §21).
create policy vehicles_select_assigned_driver
  on public.vehicles for select to authenticated
  using (
    exists (
      select 1
      from public.trip_assignments ta
      where ta.vehicle_id = vehicles.id
        and ta.organization_id = vehicles.organization_id
        and ta.ended_at is null
        and ta.driver_id = public.current_driver_id(vehicles.organization_id)
    )
  );

-- Fleet administration is Organization Admin only — Dispatcher gets
-- read-only (least-privilege split, ZD-075).
create policy vehicles_insert_org_admin
  on public.vehicles for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin']));

create policy vehicles_update_org_admin
  on public.vehicles for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']))
  with check (public.has_org_role(organization_id, array['organization_admin']));

revoke update on public.vehicles from authenticated;
grant update (label, status) on public.vehicles to authenticated;

-- =============================================================================
-- transportation_requests
-- =============================================================================
-- No anonymous policy of any kind, and no anonymous table grant at all —
-- public intake is deferred to a future controlled path (work item §19/§63).
-- Driver gets no standing access.
grant select, insert, update on public.transportation_requests to authenticated;

create policy transportation_requests_select_org_operations
  on public.transportation_requests for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy transportation_requests_insert_org_operations
  on public.transportation_requests for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy transportation_requests_update_org_operations
  on public.transportation_requests for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

revoke update on public.transportation_requests from authenticated;
grant update (
  passenger_id, requester_name, requester_relationship, requester_phone, requester_email,
  pickup_description, destination_description, preferred_date, preferred_time,
  return_trip_needed, assistance_notes, additional_notes, state
) on public.transportation_requests to authenticated;

-- =============================================================================
-- trips
-- =============================================================================
-- Driver: SELECT only, scoped to trips they have (or had) an assignment on.
-- No standing UPDATE of any kind for Driver — lifecycle transitions are
-- deferred to a future controlled RPC (work item §63/§41).
grant select, insert, update on public.trips to authenticated;

create policy trips_select_org_operations
  on public.trips for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trips_select_assigned_driver
  on public.trips for select to authenticated
  using (public.is_driver_assigned_to_trip(id));

create policy trips_insert_org_operations
  on public.trips for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trips_update_org_operations
  on public.trips for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- Field-level enforcement (authorization-model.md §K), applied at the
-- column-privilege level so it holds even for Organization Admin/Dispatcher
-- via the API, not just "by convention": planning fields are grantable;
-- state, organization_id, passenger_id, request_id, and the terminal
-- timestamp/reason fields are NOT granted to `authenticated` at all in this
-- phase. Those remain reachable only through a future controlled
-- transition mechanism (service role / SECURITY DEFINER RPC), never a
-- direct client UPDATE — deliberately more conservative than the approved
-- model strictly requires, because that mechanism does not exist yet.
revoke update on public.trips from authenticated;
grant update (
  scheduled_pickup_at, appointment_at, pickup_description, destination_description,
  assistance_notes, instructions, pickup_facility_id, destination_facility_id
) on public.trips to authenticated;

-- =============================================================================
-- trip_assignments
-- =============================================================================
-- Driver: SELECT own (including past) assignments only. NO INSERT/UPDATE/
-- DELETE for Driver whatsoever (no grant at all) — assignment creation and
-- reassignment are Dispatcher/Organization Admin actions.
grant select, insert, update on public.trip_assignments to authenticated;

create policy trip_assignments_select_org_operations
  on public.trip_assignments for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trip_assignments_select_own_driver
  on public.trip_assignments for select to authenticated
  using (driver_id = public.current_driver_id(organization_id));

create policy trip_assignments_insert_org_operations
  on public.trip_assignments for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trip_assignments_update_org_operations
  on public.trip_assignments for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- Only closing fields are editable — driver_id/vehicle_id/trip_id are never
-- rewritten in place (lifecycle-model.md §F: reassignment closes the row
-- and inserts a new one, it never edits the existing driver/vehicle).
revoke update on public.trip_assignments from authenticated;
grant update (ended_at, end_reason) on public.trip_assignments to authenticated;

-- =============================================================================
-- trip_events
-- =============================================================================
-- SELECT only, for any role, in this phase. No INSERT/UPDATE/DELETE grant
-- to authenticated at all — event creation is deferred to a future
-- controlled lifecycle-transition mechanism (ZD-060); granting a broad
-- INSERT now would let clients fabricate history ahead of that mechanism
-- existing.
grant select on public.trip_events to authenticated;

create policy trip_events_select_org_operations
  on public.trip_events for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trip_events_select_assigned_driver
  on public.trip_events for select to authenticated
  using (public.is_driver_assigned_to_trip(trip_id));

-- =============================================================================
-- trip_notes
-- =============================================================================
grant select, insert, update on public.trip_notes to authenticated;

create policy trip_notes_select_operations
  on public.trip_notes for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trip_notes_select_assigned_driver_visible
  on public.trip_notes for select to authenticated
  using (visibility = 'driver_visible' and public.is_driver_assigned_to_trip(trip_id));

create policy trip_notes_insert_operations
  on public.trip_notes for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- Driver INSERT is safely constrained exactly as prescribed: driver_visible
-- only, on a trip they are legitimately assigned to, in the same
-- organization the trip belongs to.
create policy trip_notes_insert_assigned_driver
  on public.trip_notes for insert to authenticated
  with check (
    visibility = 'driver_visible'
    and public.is_driver_assigned_to_trip(trip_id)
    and organization_id = (select t.organization_id from public.trips t where t.id = trip_id)
    and author_user_id = auth.uid()
  );

-- Reclassification is operations-only — no UPDATE policy exists for Driver
-- at all, so a driver can never change visibility on any note, including
-- their own.
create policy trip_notes_update_operations
  on public.trip_notes for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- =============================================================================
-- trip_exceptions
-- =============================================================================
grant select, insert, update on public.trip_exceptions to authenticated;

create policy trip_exceptions_select_operations
  on public.trip_exceptions for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

create policy trip_exceptions_select_assigned_driver
  on public.trip_exceptions for select to authenticated
  using (public.is_driver_assigned_to_trip(trip_id));

create policy trip_exceptions_insert_operations
  on public.trip_exceptions for insert to authenticated
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- Driver INSERT constrained to their own assigned trip, and forced to
-- create it as 'open' — a driver can report an issue but never file one
-- pre-resolved.
create policy trip_exceptions_insert_assigned_driver
  on public.trip_exceptions for insert to authenticated
  with check (
    public.is_driver_assigned_to_trip(trip_id)
    and organization_id = (select t.organization_id from public.trips t where t.id = trip_id)
    and created_by = auth.uid()
    and status = 'open'
  );

-- Resolve is operations-only — no UPDATE policy for Driver at all, so a
-- driver can never resolve any exception, including their own (lifecycle-
-- model.md §G, work item §26/§45).
create policy trip_exceptions_update_operations
  on public.trip_exceptions for update to authenticated
  using (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']))
  with check (public.has_org_role(organization_id, array['organization_admin', 'dispatcher']));

-- =============================================================================
-- audit_events
-- =============================================================================
-- SELECT only. No INSERT/UPDATE/DELETE grant to authenticated at all —
-- writes are system/trusted-path only (a future trigger/function), never a
-- client action, ever.
grant select on public.audit_events to authenticated;

create policy audit_events_select_org_admin
  on public.audit_events for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']));

create policy audit_events_select_platform_admin
  on public.audit_events for select to authenticated
  using (public.is_platform_admin());

-- Dispatcher and Driver deliberately have no SELECT policy on audit_events
-- at all (authorization-model.md §46: "Dispatcher: no broad audit access",
-- "Driver: none").
