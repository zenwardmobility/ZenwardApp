-- P1-E3-S8 — Trip Assurance & Operational Exceptions.
--
-- Controlled TripException mutations: report_trip_exception (create) and
-- resolve_trip_exception. P1-E3-S6 deferred both, leaving the direct-RLS
-- INSERT/UPDATE paths (20260830131700_rls_policies.sql) as the only
-- access. Inspected before building against them (work item §19/§24):
--
--   trip_exceptions_insert_operations — org-scoped (has_org_role), but
--     does NOT force created_by = auth.uid() (an Operations caller could
--     set it to an arbitrary user id, an impersonation risk) and does NOT
--     force status = 'open' (a caller could insert a pre-resolved row,
--     fabricating history that never had an open period).
--   trip_exceptions_insert_assigned_driver — already narrow and safe
--     (is_driver_assigned_to_trip + org match + created_by = auth.uid()
--     + status = 'open' forced) — this ONE policy alone would have been
--     fine to build directly against.
--   trip_exceptions_update_operations — org-scoped, but has NO column
--     restriction at all: a raw UPDATE could rewrite exception_type/
--     description/created_by on an already-resolved historical row, or
--     silently reopen a resolved exception by writing status='open'
--     again — exactly the "arbitrary free-form UPDATE of every field"
--     work item §25 explicitly warns against, and structurally
--     unenforceable via RLS column grants alone without narrowing this
--     table's UPDATE grant the same way trips/trip_assignments already
--     were (which would itself require an RPC to reach the narrowed
--     fields safely).
--
-- Conclusion (ZD-1xx, decision-register.md): the CREATE side is narrow
-- enough for Driver alone, but not for Operations; the RESOLVE side is
-- not narrow enough for anyone. Rather than split the write path
-- (Driver via RLS, Operations via RPC — two different mechanisms for the
-- same logical action, harder to reason about together), BOTH actor
-- populations go through the same controlled RPC pair, matching this
-- project's own established "prefer the path that is easiest to prove
-- safe" convention (work item §12 of P1-E3-S7A, reused verbatim here).
--
-- event_type values 'exception_flagged'/'exception_resolved' have been
-- allow-listed in trip_events' own CHECK constraint since the very first
-- schema migration (20260830131200_trip_events.sql) but never actually
-- written by any function until now — this phase is the first to
-- exercise them (work item §36).
--
-- No AuditEvent: reporting/resolving an exception does not "materially
-- change responsibility or reach a terminal disposition" of the TRIP
-- itself (ZD-087's own literal test) — it is an operational flag, not an
-- administrative mutation of who owns or how a Trip concludes. Matches
-- the identical, already-established precedent for `trip_notes` (Add
-- Note also writes no AuditEvent).

create type public.trip_exception_result as (
  exception_id uuid,
  trip_id uuid,
  organization_id uuid,
  exception_type text,
  description text,
  status text,
  created_by uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_note text,
  created_at timestamptz,
  changed boolean
);

comment on type public.trip_exception_result is
  'Shared return shape for report_trip_exception and resolve_trip_exception — both describe "the current state of one TripException row" (mirrors trip_transition_result being shared across all 6 driver_* RPCs). changed distinguishes a real resolve from resolve_trip_exception''s own idempotent no-op path (see that function''s comment).';

-- =============================================================================
-- report_trip_exception — CREATE. Callable by Operations (organization_admin/
-- dispatcher, any Trip in their org) OR the Trip's own currently-assigned
-- Driver (mirrors trip_notes'/the existing trip_exceptions RLS policies'
-- own dual-actor shape — Driver reporting was ALREADY a safely-scoped,
-- approved capability at the RLS layer before this migration; this RPC
-- reaches the identical population, just through one auditable path
-- instead of two, and additionally forces created_by/status safely for
-- BOTH actor types, which the Operations RLS policy alone did not).
-- =============================================================================
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

  -- Same two-population authorization the existing RLS policies already
  -- established: Operations (any Trip in their org) OR the Trip's own
  -- Driver (ever-assigned — is_driver_assigned_to_trip, matching
  -- trip_notes'/trip_exceptions' own existing driver INSERT policy
  -- precedent, not the stricter currently-active-only check — a Driver
  -- noticing something just after completing or being reassigned off a
  -- Trip may still legitimately report it, exactly as they already could
  -- add a note in that same window).
  if not v_is_ops and not public.is_driver_assigned_to_trip(p_trip_id) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- Free-text fields (exception_type/description) — no fabricated
  -- taxonomy enforced at the database layer (work item §20: schema's own
  -- comment says "taxonomy not yet finalized"); a caller may omit both,
  -- though the application layer requires at least a description for a
  -- genuinely useful report (enforced above this RPC, not duplicated
  -- here — the RPC itself stays permissive to the column's own real
  -- nullability).
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
  'Organization Admin/Dispatcher (any Trip in their org) OR the Trip''s own ever-assigned Driver. Creates a new open TripException, always created_by=auth.uid() and status=''open'' (structurally, not by convention) — see this migration''s own header for why the pre-existing direct-INSERT paths were not narrow enough for the Operations population. Writes one trip_events row (exception_flagged). No AuditEvent (see header).';

revoke all on function public.report_trip_exception(uuid, text, text) from public;
grant execute on function public.report_trip_exception(uuid, text, text) to authenticated;

-- =============================================================================
-- resolve_trip_exception — RESOLVE. Operations only (organization_admin/
-- dispatcher) — Driver never resolves, matching the schema's own original
-- comment ("only Dispatcher/Organization Admin resolve — Driver never
-- during MVP") and the existing trip_exceptions_update_operations
-- policy's own actor scope exactly.
-- =============================================================================
create or replace function public.resolve_trip_exception(
  p_exception_id uuid,
  p_resolution_note text default null
)
returns public.trip_exception_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_exception public.trip_exceptions;
  v_result public.trip_exception_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_exception from public.trip_exceptions where id = p_exception_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.has_org_role(v_exception.organization_id, array['organization_admin', 'dispatcher']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if p_resolution_note is not null and length(p_resolution_note) > 2000 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  -- Idempotent no-op (work item §50's own explicit "stale resolution"
  -- scenario): if a SECOND dispatcher's resolve arrives after a first one
  -- already resolved it, this is treated as a safe no-op — changed=false,
  -- returning the row's REAL, already-persisted resolution (whoever
  -- resolved it first), never overwritten by the second (stale) caller's
  -- own resolution_note. This deliberately differs from reassign_trip's
  -- "stale precondition always fails closed" contract (P1-E3-S5B) — there,
  -- a stale caller could silently clobber a DIFFERENT newer decision
  -- (a different Driver/Vehicle); here, "already resolved" is a strictly
  -- weaker, one-way outcome — two resolutions of the SAME exception never
  -- disagree about the operationally relevant fact ("is this handled?"),
  -- so silently discarding the second (redundant) caller's own note,
  -- rather than raising a conflict, is the more useful behavior for this
  -- specific action (documented explicitly, not a default).
  if v_exception.status = 'resolved' then
    v_result.exception_id := v_exception.id;
    v_result.trip_id := v_exception.trip_id;
    v_result.organization_id := v_exception.organization_id;
    v_result.exception_type := v_exception.exception_type;
    v_result.description := v_exception.description;
    v_result.status := v_exception.status;
    v_result.created_by := v_exception.created_by;
    v_result.resolved_by := v_exception.resolved_by;
    v_result.resolved_at := v_exception.resolved_at;
    v_result.resolution_note := v_exception.resolution_note;
    v_result.created_at := v_exception.created_at;
    v_result.changed := false;
    return v_result;
  end if;

  update public.trip_exceptions
    set status = 'resolved', resolved_by = auth.uid(), resolved_at = now(),
        resolution_note = nullif(btrim(p_resolution_note), '')
    where id = p_exception_id
    returning * into v_exception;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
  values (v_exception.organization_id, v_exception.trip_id, 'exception_resolved', auth.uid(),
    jsonb_build_object('exception_id', v_exception.id));

  v_result.exception_id := v_exception.id;
  v_result.trip_id := v_exception.trip_id;
  v_result.organization_id := v_exception.organization_id;
  v_result.exception_type := v_exception.exception_type;
  v_result.description := v_exception.description;
  v_result.status := v_exception.status;
  v_result.created_by := v_exception.created_by;
  v_result.resolved_by := v_exception.resolved_by;
  v_result.resolved_at := v_exception.resolved_at;
  v_result.resolution_note := v_exception.resolution_note;
  v_result.created_at := v_exception.created_at;
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.resolve_trip_exception(uuid, text) is
  'Organization Admin/Dispatcher only — never Driver. Resolves an existing open TripException (ZW002 if it does not exist or caller has no org role over it — no existence oracle). Idempotent no-op (changed=false, returns the real already-persisted resolution) if already resolved by anyone — see this function''s own comment for why this differs from reassign_trip''s fail-closed staleness contract. Writes one trip_events row (exception_resolved) on a real resolve only. No AuditEvent (see this migration''s header). Never deletes the row — history preserved (work item §23/§25).';

revoke all on function public.resolve_trip_exception(uuid, text) from public;
grant execute on function public.resolve_trip_exception(uuid, text) to authenticated;
