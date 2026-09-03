-- P1-E3-S9 — Owner-Operator Mode (work item §4).
--
-- Supports one person genuinely holding Owner + Dispatcher + Driver
-- simultaneously, WITHOUT collapsing roles insecurely. The two identity
-- layers stay exactly as separate as authorization-model.md §B already
-- requires: Membership.role is untouched by this function — the caller
-- keeps whatever Operations role they already hold (organization_admin
-- or dispatcher). A NEW, SEPARATE Driver row is created (or, if one
-- already exists for this exact person+org, safely reused — no
-- duplicate) and linked via drivers.user_id = auth.uid(). Operations
-- authorization (Membership.role) and Driver-execution authorization
-- (the drivers table + current_driver_id()) remain two completely
-- independent checks after this call, exactly as before — see
-- docs/product/owner-operator-mode.md for the full contract.
--
-- Self-service, not an admin-on-behalf-of-someone-else action: this
-- function only EVER links auth.uid() to a Driver row for auth.uid()
-- themselves. It cannot be used to link any other person's account —
-- that is the deliberately separate, more heavily authorized invite/
-- redeem flow (20260903100200_driver_invites.sql).

create type public.owner_driver_link_result as (
  driver_id uuid,
  organization_id uuid,
  linked boolean
);

comment on type public.owner_driver_link_result is
  'Return shape for link_self_as_driver. `linked` is true when a NEW Driver row was created this call, false when an existing active Driver row for this person+org was found and simply returned (idempotent-safe re-entry — e.g. the onboarding flow''s Owner-Driver step is revisited).';

create or replace function public.link_self_as_driver(
  p_organization_id uuid,
  p_display_name text,
  p_phone text default null
)
returns public.owner_driver_link_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_display_name text;
  v_existing_driver_id uuid;
  v_new_driver_id uuid;
  v_result public.owner_driver_link_result;
begin
  -- ---------------------------------------------------------------------
  -- Authorization: any ACTIVE member of the target organization — not
  -- restricted to organization_admin, since a small operator's sole
  -- dispatcher might also drive. Never anyone else's account: the ONLY
  -- identity this function ever touches is auth.uid() itself.
  -- ---------------------------------------------------------------------
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  if not public.is_org_member(p_organization_id) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  v_display_name := nullif(btrim(p_display_name), '');
  if v_display_name is null or length(v_display_name) > 200 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  -- ---------------------------------------------------------------------
  -- Idempotent re-entry: this exact person may already have a Driver row
  -- in this org (a prior linking call, or an org_admin who was invited
  -- as a driver in some other org and is now doing this in their own).
  -- Reuse rather than duplicate.
  -- ---------------------------------------------------------------------
  select id into v_existing_driver_id
  from public.drivers
  where organization_id = p_organization_id
    and user_id = auth.uid()
    and status = 'active';

  if v_existing_driver_id is not null then
    v_result.driver_id := v_existing_driver_id;
    v_result.organization_id := p_organization_id;
    v_result.linked := false;
    return v_result;
  end if;

  insert into public.drivers (organization_id, user_id, display_name, phone, status)
  values (p_organization_id, auth.uid(), v_display_name, nullif(btrim(p_phone), ''), 'active')
  returning id into v_new_driver_id;

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, after_data)
  values (
    p_organization_id, 'driver', v_new_driver_id, 'driver_self_linked', auth.uid(),
    jsonb_build_object('display_name', v_display_name)
  );

  v_result.driver_id := v_new_driver_id;
  v_result.organization_id := p_organization_id;
  v_result.linked := true;
  return v_result;
end;
$$;

comment on function public.link_self_as_driver(uuid, text, text) is
  'Any active member of the target organization (org_admin or dispatcher) — self-service only, never on behalf of another person. Creates (or safely reuses) a Driver row linked to the CALLER''s own auth.uid() in that organization. Never touches Membership.role — Operations and Driver authorization remain fully independent afterward. See docs/product/owner-operator-mode.md.';

revoke all on function public.link_self_as_driver(uuid, text, text) from public;
grant execute on function public.link_self_as_driver(uuid, text, text) to authenticated;
