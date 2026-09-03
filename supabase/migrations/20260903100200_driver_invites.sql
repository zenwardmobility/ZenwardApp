-- P1-E3-S9 — Driver Onboarding Contract (work item §10, GAP-15).
--
-- The highest-risk part of this phase. Closes GAP-15
-- (docs/product/ui-backend-gap-register.md): "Driver is not AuthUser/
-- Membership, and no safe, coherent contract exists yet for inviting a
-- new authenticated user, creating their Membership, AND linking a
-- `drivers` row together."
--
-- Design: a token-gated INVITE RECORD, never a direct admin-driven auth-
-- user creation. The organization_admin never handles the invitee's
-- password or creates their account on their behalf — the invitee signs
-- up (or signs in) THROUGH NORMAL SUPABASE AUTH, then redeems the invite
-- themselves. This is deliberate, not merely convenient:
--   - "no orphan Driver/Auth records on partial failure" (work item §10)
--     is satisfied structurally: the auth user is created by Supabase
--     Auth's own already-tested, already-atomic signUp path, entirely
--     independent of this migration. If a person signs up but never
--     redeems an invite, they land in the SAME already-supported,
--     already-tested "authenticated, zero Membership" state as the
--     `no-membership@example.test` fixture (/access-unavailable) — a
--     real, valid, harmless account, never a broken half-created row.
--   - "invite cannot create foreign-org membership" is satisfied
--     structurally too: redeem_driver_invite takes NO organization_id
--     parameter at all — the organization is always resolved from the
--     invite row itself, never from anything the caller supplies.
--
-- No raw INSERT/UPDATE/DELETE grant on driver_invites to `authenticated`
-- exists anywhere below — every mutation goes through one of the four
-- narrow SECURITY DEFINER functions this migration defines.

create table public.driver_invites (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  email text not null,
  display_name text not null,
  phone text,
  token uuid not null default extensions.gen_random_uuid(),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  invited_by uuid not null references auth.users (id),
  accepted_by uuid references auth.users (id),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (token)
);

comment on table public.driver_invites is
  'TENANT-OWNED. A token-gated invitation record — never itself an auth user, Membership, or Driver row. The invitee redeems it (redeem_driver_invite) only after signing up/in through normal Supabase Auth with the SAME email the invite names. No authenticated-role INSERT/UPDATE/DELETE grant exists on this table — every mutation goes through create_driver_invite / revoke_driver_invite / redeem_driver_invite (all SECURITY DEFINER, all in this migration).';

-- At most one PENDING invite per (organization, email) — a second
-- create_driver_invite call for the same person refreshes the existing
-- pending row (same token) rather than creating a duplicate (work item
-- §10 "duplicate invite/link handled safely"). Accepted/revoked rows are
-- historical and never collide with a later new invite to the same
-- email (re-invited after leaving, for example).
create unique index driver_invites_org_email_pending_idx
  on public.driver_invites (organization_id, lower(email))
  where status = 'pending';

create index driver_invites_organization_id_idx on public.driver_invites (organization_id);
create index driver_invites_token_idx on public.driver_invites (token);

create trigger driver_invites_set_updated_at
  before update on public.driver_invites
  for each row execute function public.set_updated_at();

create trigger driver_invites_prevent_org_change
  before update on public.driver_invites
  for each row execute function public.prevent_organization_id_change();

alter table public.driver_invites enable row level security;

-- SELECT only, Organization Admin, own org — for a future "pending
-- invites" list on the Drivers screen. No INSERT/UPDATE/DELETE grant at
-- all (see header comment) — Dispatcher gets nothing, matching
-- authorization-model.md §F ("create_driver_profile... Not Dispatcher").
grant select on public.driver_invites to authenticated;

create policy driver_invites_select_org_admin
  on public.driver_invites for select to authenticated
  using (public.has_org_role(organization_id, array['organization_admin']));

-- =============================================================================
-- create_driver_invite — Organization Admin only, tenant-scoped.
-- =============================================================================
create type public.driver_invite_result as (
  invite_id uuid,
  token uuid,
  email text,
  status text,
  reused boolean
);

comment on type public.driver_invite_result is
  'Return shape for create_driver_invite. `reused` is true when an existing PENDING invite for this (organization, email) was refreshed rather than a new row created.';

create or replace function public.create_driver_invite(
  p_organization_id uuid,
  p_email text,
  p_display_name text,
  p_phone text default null
)
returns public.driver_invite_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_email text;
  v_display_name text;
  v_existing_id uuid;
  v_invite_id uuid;
  v_token uuid;
  v_result public.driver_invite_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  -- Organization Admin only — least privilege, matching create_driver_
  -- profile's own existing role restriction (authorization-model.md §J).
  if not public.has_org_role(p_organization_id, array['organization_admin']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  v_email := lower(nullif(btrim(p_email), ''));
  v_display_name := nullif(btrim(p_display_name), '');
  if v_email is null or v_display_name is null then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if length(v_email) > 255 or length(v_display_name) > 200 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  -- Refresh-if-pending, locked for the duration of this transaction —
  -- same lock-before-write discipline as create_trip's Request handling.
  select id, token into v_existing_id, v_token
  from public.driver_invites
  where organization_id = p_organization_id
    and lower(email) = v_email
    and status = 'pending'
  for update;

  if v_existing_id is not null then
    update public.driver_invites
    set display_name = v_display_name, phone = nullif(btrim(p_phone), ''), invited_by = auth.uid()
    where id = v_existing_id;

    v_result.invite_id := v_existing_id;
    v_result.token := v_token;
    v_result.email := v_email;
    v_result.status := 'pending';
    v_result.reused := true;
    return v_result;
  end if;

  insert into public.driver_invites (organization_id, email, display_name, phone, invited_by)
  values (p_organization_id, v_email, v_display_name, nullif(btrim(p_phone), ''), auth.uid())
  returning id, token into v_invite_id, v_token;

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, after_data)
  values (
    p_organization_id, 'driver_invite', v_invite_id, 'driver_invite_created', auth.uid(),
    jsonb_build_object('email', v_email, 'display_name', v_display_name)
  );

  v_result.invite_id := v_invite_id;
  v_result.token := v_token;
  v_result.email := v_email;
  v_result.status := 'pending';
  v_result.reused := false;
  return v_result;
end;
$$;

comment on function public.create_driver_invite(uuid, text, text, text) is
  'Organization Admin only. Creates (or safely refreshes, if one is already pending for the same email) a tenant-scoped Driver invite. See docs/product/driver-invite-linkage-model.md.';

revoke all on function public.create_driver_invite(uuid, text, text, text) from public;
grant execute on function public.create_driver_invite(uuid, text, text, text) to authenticated;

-- =============================================================================
-- revoke_driver_invite — Organization Admin only, tenant-scoped, pending only.
-- =============================================================================
create or replace function public.revoke_driver_invite(p_invite_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_invite public.driver_invites;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_invite from public.driver_invites where id = p_invite_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.has_org_role(v_invite.organization_id, array['organization_admin']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if v_invite.status <> 'pending' then
    raise exception 'stale_state' using errcode = 'ZW003';
  end if;

  update public.driver_invites set status = 'revoked' where id = p_invite_id;

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id)
  values (v_invite.organization_id, 'driver_invite', p_invite_id, 'driver_invite_revoked', auth.uid());

  return true;
end;
$$;

comment on function public.revoke_driver_invite(uuid) is
  'Organization Admin only, own org only, pending invites only. Never deletes the row — the invite remains a historical record (authorization-model.md §S).';

revoke all on function public.revoke_driver_invite(uuid) from public;
grant execute on function public.revoke_driver_invite(uuid) to authenticated;

-- =============================================================================
-- get_driver_invite_preview — the ONLY driver_invites access anon ever
-- gets, and only through this narrow, token-gated, minimum-necessary
-- projection (never a raw SELECT policy for anon — none exists on this
-- table at all). A 122-bit random UUID token is the credential; knowing
-- it is what authorizes seeing this much, and no more.
-- =============================================================================
create type public.driver_invite_preview as (
  organization_name text,
  display_name text,
  email text,
  status text
);

comment on type public.driver_invite_preview is
  'Minimum-necessary fields for an invite landing page BEFORE the invitee has signed up — deliberately excludes organization_id, phone, invited_by, and every other invite column.';

create or replace function public.get_driver_invite_preview(p_token uuid)
returns public.driver_invite_preview
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_result public.driver_invite_preview;
begin
  select o.name, i.display_name, i.email, i.status
  into v_result.organization_name, v_result.display_name, v_result.email, v_result.status
  from public.driver_invites i
  join public.organizations o on o.id = i.organization_id
  where i.token = p_token;

  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  return v_result;
end;
$$;

comment on function public.get_driver_invite_preview(uuid) is
  'Public (anon + authenticated), token-gated, read-only. Callable before the invitee has an account, so the /join/[token] page can show "You''ve been invited to join {organization} as a driver" and prefill the signup email. Returns only organization_name/display_name/email/status — never organization_id or any other column.';

revoke all on function public.get_driver_invite_preview(uuid) from public;
grant execute on function public.get_driver_invite_preview(uuid) to anon, authenticated;

-- =============================================================================
-- redeem_driver_invite — the linkage step. Requires real auth. Resolves
-- the organization ENTIRELY from the invite row — no organization_id
-- parameter exists, so a caller cannot redeem into any organization
-- other than the one the invite actually names, structurally.
-- =============================================================================
create type public.driver_invite_redemption_result as (
  driver_id uuid,
  organization_id uuid,
  membership_created boolean,
  driver_linked boolean
);

create or replace function public.redeem_driver_invite(p_token uuid)
returns public.driver_invite_redemption_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_invite public.driver_invites;
  v_caller_email text;
  v_membership_exists boolean;
  v_existing_driver_id uuid;
  v_new_driver_id uuid;
  v_result public.driver_invite_redemption_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  -- Row-locked for the duration of this transaction — a second,
  -- concurrent redemption attempt (double-click, two tabs) blocks here
  -- until the first commits, then observes the now-'accepted' status
  -- below rather than racing to create a second Membership/Driver row
  -- (mirrors assign_trip's own row-lock-then-check discipline).
  select * into v_invite from public.driver_invites where token = p_token for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- No existence oracle beyond "a token exists" (which the caller
  -- already necessarily knows, having supplied it) — an email mismatch
  -- and a genuinely nonexistent token both simply mean this caller
  -- cannot act on this token.
  select lower(email) into v_caller_email from auth.users where id = auth.uid();
  if v_caller_email is null or v_caller_email <> lower(v_invite.email) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if v_invite.status = 'revoked' then
    raise exception 'stale_state' using errcode = 'ZW003';
  end if;

  if v_invite.status = 'accepted' then
    -- Idempotent-safe repeat call (a page refresh, a double-submit) only
    -- when it was THIS SAME person who already redeemed it — otherwise a
    -- genuine conflict, denied.
    if v_invite.accepted_by is distinct from auth.uid() then
      raise exception 'stale_state' using errcode = 'ZW003';
    end if;
  end if;

  -- ---------------------------------------------------------------------
  -- Membership: create only if none exists yet for (org, this person) —
  -- never override an existing role (e.g. this person is already this
  -- org's organization_admin and is ALSO the invited driver; leave their
  -- admin Membership untouched, exactly like link_self_as_driver would).
  -- ---------------------------------------------------------------------
  select exists (
    select 1 from public.memberships
    where organization_id = v_invite.organization_id and user_id = auth.uid()
  ) into v_membership_exists;

  if not v_membership_exists then
    insert into public.memberships (organization_id, user_id, role, status)
    values (v_invite.organization_id, auth.uid(), 'driver', 'active');
  end if;

  -- ---------------------------------------------------------------------
  -- Driver row: reuse an existing active one for (org, this person) if
  -- present, else create using the INVITE's own display_name/phone (the
  -- admin-specified values — not caller-suppliable, so an invitee cannot
  -- claim a different identity than the one they were actually invited
  -- under).
  -- ---------------------------------------------------------------------
  select id into v_existing_driver_id
  from public.drivers
  where organization_id = v_invite.organization_id
    and user_id = auth.uid()
    and status = 'active';

  if v_existing_driver_id is not null then
    v_new_driver_id := v_existing_driver_id;
  else
    insert into public.drivers (organization_id, user_id, display_name, phone, status)
    values (v_invite.organization_id, auth.uid(), v_invite.display_name, v_invite.phone, 'active')
    returning id into v_new_driver_id;
  end if;

  if v_invite.status = 'pending' then
    update public.driver_invites
    set status = 'accepted', accepted_at = now(), accepted_by = auth.uid()
    where id = v_invite.id;

    insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, after_data)
    values (
      v_invite.organization_id, 'driver_invite', v_invite.id, 'driver_invite_redeemed', auth.uid(),
      jsonb_build_object('driver_id', v_new_driver_id, 'membership_created', not v_membership_exists)
    );
  end if;

  v_result.driver_id := v_new_driver_id;
  v_result.organization_id := v_invite.organization_id;
  v_result.membership_created := not v_membership_exists;
  v_result.driver_linked := v_existing_driver_id is null;
  return v_result;
end;
$$;

comment on function public.redeem_driver_invite(uuid) is
  'Any authenticated user whose OWN account email matches the invite''s target email. Takes no organization_id parameter — the organization is always resolved from the invite row itself, making cross-org redemption structurally impossible. Atomically creates a driver Membership (only if none already exists for this person+org — never overrides an existing role) and a linked Driver row (reusing one if already present), then marks the invite accepted. Idempotent-safe on repeat calls by the same already-accepted person. See docs/product/driver-invite-linkage-model.md.';

revoke all on function public.redeem_driver_invite(uuid) from public;
grant execute on function public.redeem_driver_invite(uuid) to authenticated;
