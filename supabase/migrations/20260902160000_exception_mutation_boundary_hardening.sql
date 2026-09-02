-- P1-E3-S8A — Exception Mutation Boundary Hardening.
--
-- P1-E3-S8 built report_trip_exception()/resolve_trip_exception() as the
-- application's own intended write path, but its own completion report
-- (docs/reports/P1-E3-S8-trip-assurance-operational-exceptions-report.txt
-- §6) flagged that it deliberately did NOT retire the pre-existing direct
-- RLS INSERT/UPDATE policies on trip_exceptions (present since the very
-- first schema migration, 20260830131700_rls_policies.sql) — meaning a
-- legitimate authenticated Operations user could still bypass both RPCs
-- entirely via a raw PostgREST/Supabase-client table write. "The UI
-- doesn't call it" is not a security boundary. This migration closes that
-- gap the same way P1-E2-S2 closed the identical gap for
-- trip_assignments (ZD-092, 20260831100000_trip_assignment_privilege_
-- tightening.sql) and P1-E3-S0A closed it for trips (ZD-101,
-- 20260831120100_retire_direct_trip_insert.sql): drop the now-superseded
-- policies and revoke the underlying table privilege outright, rather
-- than rely on RLS alone to guard a privilege nobody should hold.
--
-- =============================================================================
-- Retire direct INSERT/UPDATE — RPC-only from here on.
-- =============================================================================
-- These three policies now guard privileges about to be revoked entirely.
-- Leaving them in place would misleadingly imply direct mutation is still
-- an intended, RLS-controlled path (identical reasoning to ZD-092's own
-- migration comment, reused verbatim).
drop policy if exists trip_exceptions_insert_operations on public.trip_exceptions;
drop policy if exists trip_exceptions_insert_assigned_driver on public.trip_exceptions;
drop policy if exists trip_exceptions_update_operations on public.trip_exceptions;

-- SELECT privilege and both SELECT policies (trip_exceptions_select_
-- operations, trip_exceptions_select_assigned_driver) are completely
-- untouched (work item §4/§15 — "preserve read policies as appropriate").
-- DELETE was never granted to authenticated on this table by any prior
-- migration (grep-verified) — already denied by omission, not newly
-- revoked here; this migration's own bypass test suite proves it
-- explicitly rather than leaving it an unverified assumption.
revoke insert, update on public.trip_exceptions from authenticated;

comment on table public.trip_exceptions is
  'TENANT-OWNED. exception_type is deliberately unconstrained free text — taxonomy not yet finalized (domain-model.md §21); the application layer offers a restrained 7-value list. As of P1-E3-S8A, INSERT/UPDATE are revoked from authenticated entirely (ZD-1xx) — report_trip_exception()/resolve_trip_exception() (SECURITY DEFINER RPCs) are the sole mutation path, closing the direct-bypass gap P1-E3-S8 itself identified but did not yet close. DELETE was never granted to any client role — history is permanent. SELECT is unaffected: trip_exceptions_select_operations (Operations, org-scoped) and trip_exceptions_select_assigned_driver (Driver, own assigned trips) remain the only read policies.';

-- =============================================================================
-- report_trip_exception — Driver authorization tightened from "ever
-- assigned" (is_driver_assigned_to_trip, a READ-scope check never
-- intended for write authorization — see that function's own original
-- P1-E2-S1 comment) to a CURRENTLY ACTIVE assignment
-- (_lock_driver_active_assignment, the same strict WRITE-authorization
-- primitive driver_record_location already uses). A Driver who has been
-- reassigned away, or whose Trip has since reached a terminal state, no
-- longer has an active trip_assignments row and is denied — no re-login
-- required, matching every other write RPC's own "live authorization,
-- not cached claims" contract.
--
-- No separate explicit "Trip is not terminal" branch is added, and this
-- is a deliberate decision, not an oversight (see decision-register.md,
-- ZD-1xx): every path that brings a Trip to a terminal state
-- (driver_complete_trip, cancel_trip, record_no_show — all three,
-- verified directly in this migration's own review of
-- 20260831100200_controlled_trip_mutations.sql) closes that Trip's
-- active trip_assignments row in the SAME transaction as the state
-- change. Requiring a currently-active assignment is therefore already
-- structurally sufficient to exclude every terminal Trip for Driver
-- reporting — a second explicit terminal-state check would either be
-- unreachable dead code (if placed after the assignment check, which can
-- never find an active assignment on a terminal Trip) or a genuine
-- existence-oracle leak (if placed before it, since it would disclose a
-- foreign-org Trip's terminal/non-terminal status to a caller who has
-- proven no relationship to it yet). The application-level, black-box
-- behavior the work item requires — "current Driver reports issue during
-- non-terminal Trip: ALLOWED; Trip becomes terminal; former/current
-- Driver's next report attempt: DENIED" — is fully satisfied by the
-- assignment check alone, and is proven directly by this phase's own
-- TERMINAL-1 test (report_trip_exception denied once the Trip's active
-- assignment closes on transition to completed/cancelled/no_show).
create or replace function public.report_trip_exception(
  p_trip_id uuid,
  p_exception_type text default null,
  p_description text default null
)
returns public.trip_exception_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_is_ops boolean;
  v_assignment public.trip_assignments;
  v_exception_id uuid;
  v_created_at timestamptz;
  v_result public.trip_exception_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  v_is_ops := public.has_org_role(v_trip.organization_id, array['organization_admin', 'dispatcher']);

  if not v_is_ops then
    -- Driver path (P1-E3-S8A): CURRENTLY ACTIVE assignment required, not
    -- merely "ever assigned." _lock_driver_active_assignment resolves the
    -- caller's Driver row within v_trip.organization_id itself (returning
    -- a null-fielded row for a caller with no Membership/Driver row in
    -- that org at all), so this one check alone already covers: wrong
    -- org, no Driver row, inactive Driver/Membership (current_driver_id's
    -- own ZD-100 correction), never assigned, reassigned away, and
    -- terminal Trip (see the migration-level comment above) — all
    -- collapsing to the identical ZW002, no existence oracle.
    v_assignment := public._lock_driver_active_assignment(p_trip_id, v_trip.organization_id);
    if v_assignment.id is null then
      raise exception 'not_found' using errcode = 'ZW002';
    end if;
  end if;

  if p_description is not null and length(btrim(p_description)) = 0 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if p_description is not null and length(p_description) > 2000 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  insert into public.trip_exceptions (
    organization_id, trip_id, exception_type, description, status, created_by
  ) values (
    v_trip.organization_id, p_trip_id, nullif(btrim(p_exception_type), ''), nullif(btrim(p_description), ''),
    'open', auth.uid()
  )
  returning id, created_at into v_exception_id, v_created_at;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
  values (v_trip.organization_id, p_trip_id, 'exception_flagged', auth.uid(),
    jsonb_build_object('exception_id', v_exception_id));

  v_result.exception_id := v_exception_id;
  v_result.trip_id := p_trip_id;
  v_result.organization_id := v_trip.organization_id;
  v_result.exception_type := nullif(btrim(p_exception_type), '');
  v_result.description := nullif(btrim(p_description), '');
  v_result.status := 'open';
  v_result.created_by := auth.uid();
  v_result.resolved_by := null;
  v_result.resolved_at := null;
  v_result.resolution_note := null;
  v_result.created_at := v_created_at;
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.report_trip_exception(uuid, text, text) is
  'Organization Admin/Dispatcher (any Trip in their org) OR the Trip''s own CURRENTLY-assigned Driver (P1-E3-S8A tightened this from "ever assigned" to a live _lock_driver_active_assignment check — reassignment/terminal transitions revoke immediately, no re-login required). Creates a new open TripException, always created_by=auth.uid() and status=''open'' (structurally, not by convention). Writes one trip_events row (exception_flagged). No AuditEvent. As of P1-E3-S8A this is the ONLY way any actor creates a TripException — direct table INSERT is revoked from authenticated entirely.';

revoke all on function public.report_trip_exception(uuid, text, text) from public;
grant execute on function public.report_trip_exception(uuid, text, text) to authenticated;

comment on function public.resolve_trip_exception(uuid, text) is
  'Organization Admin/Dispatcher only — never Driver. Resolves an existing open TripException (ZW002 if it does not exist or caller has no org role over it — no existence oracle). Idempotent no-op (changed=false, returns the real already-persisted resolution) if already resolved by anyone. Writes one trip_events row (exception_resolved) on a real resolve only. No AuditEvent. Never deletes the row — history preserved. As of P1-E3-S8A this is the ONLY way any actor updates a TripException — direct table UPDATE is revoked from authenticated entirely, so a resolved exception cannot be reopened, and no field (exception_type/description/created_by/created_at) outside this function''s own narrow (status/resolved_by/resolved_at/resolution_note) column set can be rewritten by any normal actor.';
