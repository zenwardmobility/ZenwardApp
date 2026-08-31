-- P1-E2-S2 — Controlled Mutation & Transaction Boundary.
--
-- trip_assignments direct-write tightening.
--
-- P1-E2-S1 granted authenticated Organization Admin/Dispatcher a direct
-- INSERT and a narrow (ended_at, end_reason) UPDATE on trip_assignments,
-- because no controlled assignment mechanism existed yet and *some* path
-- had to exist for the RLS test suite to exercise. This migration
-- supersedes that path: assign_trip() and reassign_trip() (added in
-- 20260831100200_controlled_trip_mutations.sql) are now the ONLY way any
-- role creates or closes a trip_assignments row. Direct table writes are
-- revoked entirely so a client cannot bypass those functions' auth chain,
-- idempotency handling, event/audit logging, and row-locking discipline
-- by issuing a raw REST insert/update against the table.
--
-- SELECT privilege and its two policies are untouched — reading
-- assignment history remains a direct table concern, not an RPC concern.
--
-- This is a NEW migration, not an edit to the historical
-- 20260830131700_rls_policies.sql file (historical migrations are
-- immutable — work item §72).

-- The two policies below now guard a privilege nobody holds (INSERT/UPDATE
-- have just been revoked). Leaving them in place would misleadingly imply
-- direct mutation is still an intended, RLS-controlled path. Drop them so
-- the policy inventory accurately reflects the new architecture.
drop policy if exists trip_assignments_insert_org_operations on public.trip_assignments;
drop policy if exists trip_assignments_update_org_operations on public.trip_assignments;

revoke insert, update on public.trip_assignments from authenticated;

comment on table public.trip_assignments is
  'TENANT-OWNED, HIGH RLS RISK. Append-oriented: a reassignment closes the active row and inserts a new one, never edits driver_id/vehicle_id in place. As of P1-E2-S2, INSERT/UPDATE are revoked from authenticated entirely — assign_trip()/reassign_trip() (SECURITY DEFINER RPCs) are the sole mutation path. See trip_assignments_one_active_per_trip for the "at most one active assignment per trip" constraint (lifecycle-model.md §F/§G, ZD-051).';
