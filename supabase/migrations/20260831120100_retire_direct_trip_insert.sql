-- P1-E3-S0A — Controlled Internal Trip Creation Boundary.
--
-- Retires the raw, column-unrestricted `trips` INSERT grant identified as
-- GAP-1 in P1-E3-S0 — now that create_trip() exists as the sole controlled
-- creation path. Mirrors exactly how P1-E2-S2 retired trip_assignments'
-- direct INSERT/UPDATE once assign_trip/reassign_trip existed (ZD-092).
--
-- SELECT is completely untouched. The existing narrowed UPDATE grant
-- (planning columns only, from P1-E2-S1) is completely untouched — this
-- migration touches INSERT only.

drop policy if exists trips_insert_org_operations on public.trips;

revoke insert on public.trips from authenticated;

comment on table public.trips is
  'TENANT-OWNED, HIGH RLS RISK (domain-model.md §C). The canonical entity every cross-tenant test targets. request_id nullable (1:N Request→Trip, ZD-045); no current_driver_id/current_vehicle_id (ZD-051, trip_assignments is sole source of truth). Driver has NO direct SELECT on this table (trips_select_assigned_driver retired, ZD-096). As of P1-E3-S0A, INSERT is also revoked from authenticated entirely (ZD-101) — create_trip() (SECURITY DEFINER) is the sole creation path, closing the raw-INSERT lifecycle-bypass gap identified in P1-E3-S0 (GAP-1).';
