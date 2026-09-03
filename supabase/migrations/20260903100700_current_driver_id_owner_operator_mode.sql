-- P1-E3-S9 — Owner-Operator Mode vs. ZD-100's own security fix.
--
-- CORRECTIVE (append-only, matching the same convention
-- 20260831110300_current_driver_id_membership_check.sql itself used to
-- correct the ORIGINAL current_driver_id — never editing a committed
-- migration file).
--
-- The problem, found via direct live testing while building Owner-
-- Operator Mode: `current_driver_id()` requires `m.role = 'driver'` on
-- the caller's Membership (P1-E2-S3, ZD-100) — deliberately, to close a
-- real vulnerability where an inactive Membership retained Driver access
-- through a stale `drivers.status = 'active'` row alone. That fix was
-- correct and necessary at the time, but it also makes it structurally
-- impossible for `link_self_as_driver`/`redeem_driver_invite`'s own
-- Owner-Operator Mode design (P1-E3-S9, work item §4) to ever work: an
-- organization_admin or dispatcher who legitimately self-links a Driver
-- row keeps their REAL Membership.role (organization_admin/dispatcher —
-- never overwritten, by design), so `role = 'driver'` can never be true
-- for them, and `current_driver_id` — and therefore `driver_get_profile`,
-- every driver-scoped RLS policy, and every driver mutation RPC — denies
-- them regardless of a real, active, correctly-linked Driver row.
--
-- The fix preserves ZD-100's actual security property exactly —
-- **the caller must have an ACTIVE Membership in this organization** —
-- while dropping the now-too-narrow additional constraint that the
-- role specifically be 'driver'. This is not a weakening: the real
-- authorization boundary was never "is this specifically a Driver-role
-- Membership," it was "is this an inactive/revoked Membership retaining
-- access through a stale Driver row" — that exact scenario (an
-- organization_admin/dispatcher/driver whose Membership has gone
-- inactive) is still denied below, unchanged. What newly succeeds is
-- ONLY the case this phase deliberately, reviewedly introduces: an
-- ACTIVE organization_admin/dispatcher who was themselves the one who
-- called the controlled `link_self_as_driver`/`redeem_driver_invite`
-- RPC to create their own Driver linkage — never anyone else's.

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
    )
  limit 1;
$$;

comment on function public.current_driver_id(uuid) is
  'Resolves auth.uid() to the caller''s Driver.id within a SPECIFIC organization (a person may have separate Driver rows per org — domain-model.md §H). Returns null if the caller has no active Driver row there, OR no active Membership there at all (ANY role — relaxed from role=''driver'' specifically, P1-E3-S9/ZD-1xx, to support Owner-Operator Mode: an organization_admin/dispatcher may also hold a genuine, self-linked Driver row without their Membership.role ever changing). The security property ZD-100 originally fixed — an INACTIVE Membership must never retain Driver access via a stale drivers.status=''active'' row — is fully preserved: the exists() check below still requires m.status = ''active''. Live-checked on every call, same as is_org_member/has_org_role (ZD-077).';
