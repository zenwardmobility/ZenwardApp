-- P1-E2-S3 — Secure Read Models & Driver Minimum-Necessary Projection.
--
-- Retires the Driver-specific base-table SELECT policies now superseded
-- by the controlled read API (20260831110100_driver_read_api.sql), per
-- the full audit in docs/security/driver-data-minimization.md §Driver
-- read-surface audit. Organization Admin / Dispatcher SELECT access is
-- completely untouched by this migration — every policy dropped below is
-- specifically the "_assigned_driver"/"_own_driver"/"_own" Driver-scoped
-- policy on its table, never the "_org_operations" one.
--
-- Retired (6):
--   drivers.drivers_select_own              -> driver_get_profile
--   trips.trips_select_assigned_driver       -> driver_list_active_trips /
--                                                driver_get_trip_detail /
--                                                driver_list_trip_history
--   trip_assignments.trip_assignments_select_own_driver
--                                             -> driver_list_active_trips /
--                                                driver_list_trip_history
--   vehicles.vehicles_select_assigned_driver -> vehicle summary embedded
--                                                in the read API
--   trip_notes.trip_notes_select_assigned_driver_visible
--                                             -> driver_notes embedded in
--                                                driver_get_trip_detail
--   trip_events.trip_events_select_assigned_driver
--                                             -> retired per work item
--                                                §24, no replacement built
--                                                (no TripEvent timeline is
--                                                exposed to Driver in this
--                                                phase)
--
-- Explicitly NOT retired (documented, not an oversight):
--   trip_exceptions.trip_exceptions_select_assigned_driver — no
--   replacement projection is built this phase (work item §26 explicitly
--   defers building one), so retiring this policy would remove existing,
--   already narrowly-scoped (ever-assigned-Driver-only) functionality
--   with no successor and no independently-identified over-exposure
--   beyond that existing scoping. See docs/security/
--   driver-data-minimization.md for the full reasoning.

drop policy if exists drivers_select_own on public.drivers;
drop policy if exists trips_select_assigned_driver on public.trips;
drop policy if exists trip_assignments_select_own_driver on public.trip_assignments;
drop policy if exists vehicles_select_assigned_driver on public.vehicles;
drop policy if exists trip_notes_select_assigned_driver_visible on public.trip_notes;
drop policy if exists trip_events_select_assigned_driver on public.trip_events;

comment on table public.trips is
  'TENANT-OWNED, HIGH RLS RISK (domain-model.md §C). The canonical entity every cross-tenant test targets. request_id nullable (1:N Request→Trip, ZD-045); no current_driver_id/current_vehicle_id (ZD-051, trip_assignments is sole source of truth). As of P1-E2-S3, Driver has NO direct SELECT on this table at all (trips_select_assigned_driver retired, ZD-096) — driver_list_active_trips/driver_get_trip_detail/driver_list_trip_history (SECURITY DEFINER) are the sole Driver-facing read path.';

comment on table public.trip_assignments is
  'TENANT-OWNED, HIGH RLS RISK. Append-oriented: a reassignment closes the active row and inserts a new one, never edits driver_id/vehicle_id in place. INSERT/UPDATE revoked from authenticated in P1-E2-S2 (ZD-092, assign_trip/reassign_trip are the sole write path). As of P1-E2-S3, Driver SELECT is also retired (ZD-096) — driver_list_active_trips/driver_list_trip_history are the sole Driver-facing read path. See trip_assignments_one_active_per_trip for the "at most one active assignment per trip" constraint (lifecycle-model.md §F/§G, ZD-051).';
