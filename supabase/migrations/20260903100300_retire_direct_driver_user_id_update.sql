-- P1-E3-S9 — retire direct client UPDATE of drivers.user_id (work item
-- §10's own caution: "Do NOT improvise with broad direct INSERT/UPDATE
-- grants").
--
-- Mirrors the exact precedent set by P1-E3-S0A's
-- 20260831120100_retire_direct_trip_insert.sql: a genuinely
-- currently-exploitable gap, found (not merely theorized) while
-- designing this phase's controlled driver-invite/linkage boundary.
--
-- `20260830131700_rls_policies.sql` granted `update (display_name,
-- phone, status, user_id) on public.drivers to authenticated`, gated
-- only by `drivers_update_org_admin` (an org-role check with no
-- constraint on WHAT VALUE user_id is set to). Before this migration, an
-- organization_admin could set any Driver row's user_id to ANY
-- auth.users.id they can guess or otherwise learn — including a
-- completely unrelated person's account, in this org or, since the
-- value itself is never validated against organization membership at
-- the column-grant level, silently granting that stranger's account
-- Driver-scoped access to this organization's trips without their
-- knowledge or consent. This was never exercised by any shipped feature
-- (Driver onboarding was GAP-15, deliberately left unbuilt until now),
-- but the raw grant existed and was live-exploitable via a direct
-- REST/RPC call bypassing the UI entirely (authorization-model.md §A).
--
-- `link_self_as_driver` and `redeem_driver_invite`
-- (20260903100100/100200) are now the sole paths that ever set
-- drivers.user_id — both SECURITY DEFINER, both structurally restricted
-- to only ever writing auth.uid() itself (never an arbitrary supplied
-- id), and redeem_driver_invite additionally requires the target
-- person's own account email to match a real, org_admin-issued invite.

revoke update on public.drivers from authenticated;
grant update (display_name, phone, status) on public.drivers to authenticated;

comment on column public.drivers.user_id is
  'Nullable link to the auth user who fills this Driver role (domain-model.md §H). Set ONLY by link_self_as_driver or redeem_driver_invite (both SECURITY DEFINER, both self-only) — no direct client UPDATE grant exists on this column as of P1-E3-S9 (see 20260903100300_retire_direct_driver_user_id_update.sql for why the prior broad grant was a real, live risk, not a theoretical one).';
