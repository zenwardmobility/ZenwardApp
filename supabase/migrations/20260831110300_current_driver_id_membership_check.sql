-- P1-E2-S3 — Secure Read Models & Driver Minimum-Necessary Projection.
--
-- CORRECTIVE: current_driver_id() (defined in the historical, already-
-- committed 20260830131600_rls_helper_functions.sql — corrected here via
-- a new append-only migration, not by editing that file) resolved
-- auth.uid() to a Driver row using only drivers.status = 'active', and
-- NEVER cross-referenced the underlying Membership's status/role at all.
--
-- Discovered by driver_read_authorization_tests.sql (DETAIL-6): a Driver
-- whose Membership is set to status='inactive' (revoked from the
-- organization) but whose `drivers` row itself remains status='active'
-- kept full access through current_driver_id() and everything built on
-- it — is_driver_assigned_to_trip, the P1-E2-S2 mutation RPCs' authorization
-- chain, and this phase's new read RPCs. This directly violated the
-- established, repeatedly-stated principle that an inactive Membership
-- must remove authority immediately and live, on every call (ZD-077) —
-- is_org_member/has_org_role already got this right; current_driver_id
-- did not.
--
-- Fix: also require an ACTIVE Membership with role='driver' for the same
-- (user, organization) pair. Signature and return type are unchanged, so
-- every caller (RLS policies, mutation RPCs, read RPCs) is corrected
-- automatically with no changes needed anywhere else.

create or replace function public.current_driver_id(p_org_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.id
  from public.drivers d
  where d.organization_id = p_org_id
    and d.user_id = auth.uid()
    and d.status = 'active'
    and exists (
      select 1
      from public.memberships m
      where m.organization_id = p_org_id
        and m.user_id = auth.uid()
        and m.status = 'active'
        and m.role = 'driver'
    )
  limit 1;
$$;

comment on function public.current_driver_id(uuid) is
  'Resolves auth.uid() to the caller''s Driver.id within a SPECIFIC organization (a person may have separate Driver rows per org — domain-model.md §H). Returns null if the caller has no active Driver row there, OR (corrected in P1-E2-S3, ZD-100) no active Membership with role=driver there — both must hold. Live-checked on every call, same as is_org_member/has_org_role (ZD-077).';
