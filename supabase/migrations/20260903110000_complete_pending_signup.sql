-- P1-E4-S0A — Cloud Staging Validation Closure: the real S9 gap this phase
-- found and is required to fix (work item §8): when Supabase Auth requires
-- email confirmation, `signUp()` returns no session, so `/sign-up`'s own
-- Server Action never reaches `signup_create_organization` — the caller's
-- full name and business name, only ever local variables in that one
-- Server Action invocation, were silently lost the moment the response
-- came back without a session. The person who later confirms their email
-- and signs in landed on `/access-unavailable` (zero Memberships) with no
-- way to recover their original Organization/business name at all.
--
-- Fix: the full name/business name are no longer transient — `/sign-up`'s
-- Server Action now also passes them as Supabase Auth `user_metadata`
-- (`pending_full_name`/`pending_business_name`) at `signUp()` time, which
-- Supabase persists on the `auth.users` row itself regardless of whether a
-- session comes back. `complete_pending_signup()` is the one-shot
-- continuation: `/sign-in`'s own Server Action calls it after every
-- successful sign-in (cheap no-op for the overwhelming majority of
-- sign-ins that aren't mid-pending-signup); if this caller has no
-- Membership yet AND carries pending metadata, it calls the SAME
-- `signup_create_organization` the immediate-session path already uses,
-- with the SAME originally-entered values — so Organization/UserProfile/
-- Membership creation follows one single code path regardless of which
-- environment's confirmation behavior triggered it.
--
-- Idempotency (work item §9 — "NO duplicate Organization/Membership/
-- UserProfile" across confirmation-callback refresh, repeated sign-in,
-- browser back/forward): `signup_create_organization` is DELIBERATELY
-- non-idempotent by its own design (a second call is a legitimate second
-- business — see 20260903100000_organization_signup.sql's own comment).
-- This function is therefore NOT a thin wrapper around it — it is the
-- exactly-once gate in front of it:
--   1. `pg_advisory_xact_lock` keyed by the caller's own auth.uid()
--      serializes concurrent calls from the SAME person (two tabs, a
--      double sign-in) so at most one can pass the check below at a time.
--   2. If the caller already holds ANY Membership, this is a no-op
--      (`created = false`) — covers every repeat call after the first
--      successful completion, and also anyone who already has an org
--      through a different path entirely.
-- Together these make repeated calls (refresh, re-sign-in, concurrent
-- tabs) safe by construction, not by convention.

create or replace function public.complete_pending_signup()
returns public.organization_signup_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_full_name text;
  v_business_name text;
  v_already_member boolean;
  v_result public.organization_signup_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  -- Serialize concurrent calls for the same user — transaction-scoped,
  -- auto-released at commit/rollback, no schema/table of its own needed.
  perform pg_advisory_xact_lock(hashtext(auth.uid()::text)::bigint);

  select exists (
    select 1 from public.memberships where user_id = auth.uid()
  ) into v_already_member;

  if v_already_member then
    v_result.created := false;
    return v_result;
  end if;

  select
    raw_user_meta_data ->> 'pending_full_name',
    raw_user_meta_data ->> 'pending_business_name'
  into v_full_name, v_business_name
  from auth.users
  where id = auth.uid();

  -- No pending signup recorded for this caller at all (a Driver who was
  -- invited and never went through /sign-up, or any other non-signup
  -- authenticated caller) — nothing to complete, not an error.
  if v_full_name is null or v_business_name is null then
    v_result.created := false;
    return v_result;
  end if;

  v_result := public.signup_create_organization(v_business_name, v_full_name);
  return v_result;
end;
$$;

comment on function public.complete_pending_signup() is
  'Any authenticated user. The one-shot continuation for a signup that required email confirmation (work item P1-E4-S0A §8): completes the SAME organization/profile/membership creation signup_create_organization already performs for the immediate-session case, using full name/business name persisted in auth.users.raw_user_meta_data (pending_full_name/pending_business_name) at signUp() time. Idempotent by construction (advisory lock + existing-Membership guard) — safe to call on every sign-in.';

revoke all on function public.complete_pending_signup() from public;
grant execute on function public.complete_pending_signup() to authenticated;

-- =============================================================================
-- complete_pending_signup_manual — P1-E4-S0A1 §9 ("RECOVER THE CURRENT
-- FAILED ACCOUNT"). A caller-supplied fallback for the case
-- complete_pending_signup() cannot auto-recover: an authenticated,
-- zero-Membership account with NO pending_full_name/pending_business_name
-- in its metadata at all (e.g. an account created before this phase's own
-- fix existed, when signUp() never persisted that metadata in the first
-- place). Never a manual database edit — a legitimate, explicit,
-- user-initiated "Complete your organization setup" form
-- (src/app/complete-signup) submits real values here.
--
-- Reuses the EXACT SAME idempotency machinery as complete_pending_signup()
-- (advisory lock + existing-Membership guard) — not a looser cousin of
-- it. The only difference is where the name/business name come from.
-- Identity is still derived entirely from auth.uid(); nothing here trusts
-- a client-supplied user id, organization id, or role.
-- =============================================================================
create or replace function public.complete_pending_signup_manual(
  p_full_name text,
  p_business_name text
)
returns public.organization_signup_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_already_member boolean;
  v_result public.organization_signup_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  perform pg_advisory_xact_lock(hashtext(auth.uid()::text)::bigint);

  select exists (
    select 1 from public.memberships where user_id = auth.uid()
  ) into v_already_member;

  if v_already_member then
    v_result.created := false;
    return v_result;
  end if;

  v_result := public.signup_create_organization(p_business_name, p_full_name);
  return v_result;
end;
$$;

comment on function public.complete_pending_signup_manual(text, text) is
  'Any authenticated user. The explicit, user-initiated fallback for complete_pending_signup() when no pending signup metadata exists at all (work item P1-E4-S0A1 §9) — backs the /complete-signup recovery form. Same idempotency guard as complete_pending_signup() (advisory lock + existing-Membership check); role is still always organization_admin via signup_create_organization, never caller-supplied.';

revoke all on function public.complete_pending_signup_manual(text, text) from public;
grant execute on function public.complete_pending_signup_manual(text, text) to authenticated;
