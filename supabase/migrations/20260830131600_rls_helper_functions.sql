-- RLS helper functions (authorization-model.md §T, domain-model.md §L/§28).
--
-- Each function answers exactly one narrow question and returns only a
-- boolean or an identifier — never a tenant row. All are SECURITY DEFINER
-- because they read tables (memberships, drivers, trip_assignments) that
-- themselves have RLS enabled; without SECURITY DEFINER, a policy calling
-- these functions would recursively re-apply the calling user's own
-- restricted view of those tables, which is either wrong or leads to
-- recursive RLS evaluation. SECURITY DEFINER lets them run with the
-- function owner's privilege for this one narrow lookup only. Every
-- function sets an explicit search_path to prevent search-path hijacking,
-- per the explicit instruction not to leave SECURITY DEFINER functions
-- relying on a caller-controlled search path.
--
-- None of these is a universal bypass: none accepts arbitrary dynamic SQL,
-- none returns raw rows, and none grants standing access beyond the single
-- fact it computes.

-- ---------------------------------------------------------------------------
create or replace function public.is_org_member(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.memberships m
    where m.organization_id = p_org_id
      and m.user_id = auth.uid()
      and m.status = 'active'
  );
$$;

comment on function public.is_org_member(uuid) is
  'True iff the calling user has an ACTIVE membership in the given organization. Live lookup every call — never trusts a cached JWT claim (ZD-077).';

revoke all on function public.is_org_member(uuid) from public;
grant execute on function public.is_org_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
create or replace function public.has_org_role(p_org_id uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.memberships m
    where m.organization_id = p_org_id
      and m.user_id = auth.uid()
      and m.status = 'active'
      and m.role = any (p_roles)
  );
$$;

comment on function public.has_org_role(uuid, text[]) is
  'True iff the calling user has an ACTIVE membership in the given organization with one of the given roles. Built on the same live-membership check as is_org_member.';

revoke all on function public.has_org_role(uuid, text[]) from public;
grant execute on function public.has_org_role(uuid, text[]) to authenticated;

-- ---------------------------------------------------------------------------
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
  limit 1;
$$;

comment on function public.current_driver_id(uuid) is
  'Resolves auth.uid() to the caller''s Driver.id within a SPECIFIC organization (a person may have separate Driver rows per org — domain-model.md §H). Returns null if the caller has no active Driver row there.';

revoke all on function public.current_driver_id(uuid) from public;
grant execute on function public.current_driver_id(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- NOTE on scope: this checks whether the calling driver has EVER had an
-- assignment on this trip (active or historical), matching the confirmed
-- read-access rule "Driver may read own assignments only, including their
-- own past/superseded ones" (domain-model.md §17/§B). This is a READ-scope
-- check only. A future phase implementing lifecycle-transition RPCs will
-- need a separate, stricter "currently ACTIVE assignment" check for
-- write/transition authorization — not built here, since transition RPCs
-- are explicitly deferred (work item §63).
create or replace function public.is_driver_assigned_to_trip(p_trip_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_org_id uuid;
  v_driver_id uuid;
begin
  select t.organization_id into v_org_id from public.trips t where t.id = p_trip_id;
  if v_org_id is null then
    return false;
  end if;

  v_driver_id := public.current_driver_id(v_org_id);
  if v_driver_id is null then
    return false;
  end if;

  return exists (
    select 1
    from public.trip_assignments ta
    where ta.trip_id = p_trip_id
      and ta.organization_id = v_org_id
      and ta.driver_id = v_driver_id
  );
end;
$$;

comment on function public.is_driver_assigned_to_trip(uuid) is
  'True iff the calling user (resolved to a Driver row in the trip''s own organization) has ever had a trip_assignment — active or historical — on this trip. READ-scope check only; see the note above for why a stricter active-only variant will be needed for future write authorization.';

revoke all on function public.is_driver_assigned_to_trip(uuid) from public;
grant execute on function public.is_driver_assigned_to_trip(uuid) to authenticated;

-- ---------------------------------------------------------------------------
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.platform_admin_grants g
    where g.user_id = auth.uid()
  );
$$;

comment on function public.is_platform_admin() is
  'True iff the calling user holds a PlatformAdminGrant. This is the ONLY mechanism that establishes platform authority — never Membership.role, never a UserProfile flag, never a JWT claim (ZD-049).';

revoke all on function public.is_platform_admin() from public;
grant execute on function public.is_platform_admin() to authenticated;
