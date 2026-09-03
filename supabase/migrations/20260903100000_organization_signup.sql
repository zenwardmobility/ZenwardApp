-- P1-E3-S9 — Operator Signup & Business Setup: the self-service
-- organization-creation boundary.
--
-- organizations has never had an INSERT grant to `authenticated`
-- (organizations.sql's own comment: "creation/root control is a
-- platform-level action, not a normal-user capability"). This phase
-- deliberately, explicitly extends that: a brand-new NEMT operator
-- signing up now IS a legitimate self-service action. The mechanism
-- stays exactly consistent with that original framing though — no raw
-- INSERT grant is added to `organizations` or `memberships` for this
-- purpose. `signup_create_organization` is the sole controlled path,
-- reusing the exact SECURITY DEFINER / ZW00x / TripEvent-less-but-
-- AuditEvent-yes conventions `create_trip` established (P1-E3-S0A).
--
-- Why one RPC, not three separate client inserts: `memberships_insert_
-- org_admin` requires the caller to ALREADY hold organization_admin in
-- the target org — circular for a brand-new org's very first member.
-- A single SECURITY DEFINER function is also what makes this genuinely
-- atomic (work item §2's "failed signup does not leave a broken partial
-- organization/user state") — a Postgres function body is one implicit
-- transaction; any exception anywhere below rolls back UserProfile,
-- Organization, and Membership together, not just some of them.

-- =============================================================================
-- organizations.business_stage — work item §3. Purely descriptive: controls
-- onboarding EMPHASIS client-side, never a schema fork, never a security
-- input to any RLS policy or RPC authorization check.
-- =============================================================================
alter table public.organizations
  add column business_stage text;

alter table public.organizations
  add constraint organizations_business_stage_valid
  check (business_stage is null or business_stage in ('starting', 'growing', 'established'));

comment on column public.organizations.business_stage is
  'Self-reported operator size band at signup ("How are you operating today?" — starting/growing/established), work item §3. UI emphasis only — never read by any RLS policy or mutation-authorization check, never used to fork the schema, never a pricing input.';

-- =============================================================================
-- signup_create_organization
-- =============================================================================
create type public.organization_signup_result as (
  organization_id uuid,
  membership_id uuid,
  role text,
  created boolean
);

comment on type public.organization_signup_result is
  'Return shape for signup_create_organization. `created` is always true — this function is deliberately non-idempotent, matching create_trip''s own convention (a second call from the same user is a legitimate second organization, not treated as a duplicate).';

create or replace function public.signup_create_organization(
  p_business_name text,
  p_display_name text,
  p_business_stage text default null,
  p_timezone text default 'America/New_York'
)
returns public.organization_signup_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_business_name text;
  v_display_name text;
  v_new_org_id uuid;
  v_new_membership_id uuid;
  v_result public.organization_signup_result;
begin
  -- ---------------------------------------------------------------------
  -- Authorization: the only requirement is a real authenticated session.
  -- Deliberately no "does this user already have an org" gate — multi-
  -- organization ownership is an already-supported, already-tested
  -- concept elsewhere in this schema (authorization-model.md §P); a
  -- second call from the same person is a legitimate second business,
  -- not a suspicious retry.
  -- ---------------------------------------------------------------------
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  -- ---------------------------------------------------------------------
  -- Input validation — same "only rules already canonical or technically
  -- obvious" discipline as create_trip (no invented business rule).
  -- ---------------------------------------------------------------------
  v_business_name := nullif(btrim(p_business_name), '');
  v_display_name := nullif(btrim(p_display_name), '');
  if v_business_name is null or v_display_name is null then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if length(v_business_name) > 200 or length(v_display_name) > 200 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  if p_business_stage is not null and p_business_stage not in ('starting', 'growing', 'established') then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  if not public.is_valid_iana_timezone(p_timezone) then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  -- ---------------------------------------------------------------------
  -- UserProfile — upsert, not insert-or-fail: a returning user completing
  -- a SECOND signup (a second organization) already has a profile row;
  -- refresh the display name rather than erroring on the unique PK.
  -- Exactly the same effect as the already-existing, already-safe
  -- `user_profiles_insert_own`/`_update_own` RLS policies would produce
  -- via ordinary client calls — folded in here purely for atomicity with
  -- the two inserts below, not because the columns needed new privilege.
  -- ---------------------------------------------------------------------
  insert into public.user_profiles (id, display_name)
  values (auth.uid(), v_display_name)
  on conflict (id) do update set display_name = excluded.display_name;

  -- ---------------------------------------------------------------------
  -- Organization. status is hard-coded 'active' — never a parameter.
  -- ---------------------------------------------------------------------
  insert into public.organizations (name, status, timezone, business_stage)
  values (v_business_name, 'active', p_timezone, p_business_stage)
  returning id into v_new_org_id;

  -- ---------------------------------------------------------------------
  -- Membership. role is hard-coded 'organization_admin' — never a
  -- parameter, structurally impossible for a caller to self-grant any
  -- other role through this path.
  -- ---------------------------------------------------------------------
  insert into public.memberships (organization_id, user_id, role, status)
  values (v_new_org_id, auth.uid(), 'organization_admin', 'active')
  returning id into v_new_membership_id;

  -- ---------------------------------------------------------------------
  -- AuditEvent — organization creation is a material administrative
  -- mutation, same reasoning as create_trip's own AuditEvent (ZD-087's
  -- test extended to "brings a new tenant into existence").
  -- ---------------------------------------------------------------------
  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, after_data)
  values (
    v_new_org_id, 'organization', v_new_org_id, 'organization_created', auth.uid(),
    jsonb_build_object('business_stage', p_business_stage, 'timezone', p_timezone)
  );

  v_result.organization_id := v_new_org_id;
  v_result.membership_id := v_new_membership_id;
  v_result.role := 'organization_admin';
  v_result.created := true;
  return v_result;
end;
$$;

comment on function public.signup_create_organization(text, text, text, text) is
  'Any authenticated user. The sole controlled path to self-service-create a new Organization — atomically creates/updates the caller''s own UserProfile, a new Organization, and the caller''s own organization_admin Membership in one transaction (all-or-nothing — work item §2). role is always ''organization_admin'', never caller-supplied. No raw INSERT grant exists on organizations or memberships for this purpose — see docs/product/operator-onboarding-model.md.';

revoke all on function public.signup_create_organization(text, text, text, text) from public;
grant execute on function public.signup_create_organization(text, text, text, text) to authenticated;
