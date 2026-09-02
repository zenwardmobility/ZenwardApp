-- Reassignment concurrency hardening (P1-E3-S5A).
--
-- P1-E3-S5's own real, live-application concurrency testing confirmed a
-- transactionally-safe but operationally undesirable behavior: reassign_trip
-- has no precondition tying a reassignment to the SPECIFIC assignment the
-- Dispatcher actually reviewed — it atomically closes whatever assignment
-- is currently active and opens a new one, regardless of what the caller's
-- own UI last displayed. A Dispatcher whose stale form submission targets a
-- Trip another Dispatcher already reassigned would silently overwrite that
-- newer decision (see docs/reports/P1-E3-S5-completion-report.txt §27,
-- decision-register.md ZD-142 — now retired by ZD-145 below).
--
-- This migration adds an explicit optimistic-concurrency precondition:
-- p_expected_assignment_id. The Dispatch UI now always supplies the id of
-- the active trip_assignments row it loaded; the RPC verifies, under the
-- SAME row lock already used for every other check, that this still IS the
-- active assignment. A mismatch fails closed with the existing,
-- already-safe ZW005 assignment_conflict category — never a new error
-- code, never exposed SQLSTATE/Postgres detail (see docs/data/mutation-api.md).
--
-- P1-E3-S5B tightened the ORDER of this check: p_expected_assignment_id is
-- now verified BEFORE the idempotent driver/vehicle match, not after. The
-- original P1-E3-S5A ordering checked idempotency first, which meant a
-- stale expected id could still be silently treated as a successful no-op
-- whenever the requested driver/vehicle happened to already match the
-- CURRENT (not the caller's expected) assignment — contradicting the
-- explicit product rule that a stale expected assignment must never be
-- treated as an idempotent success. See the function body's own comments
-- for the precise reasoning and decision-register.md ZD-146.
--
-- assign_trip is intentionally NOT modified — its existing "no existing
-- active assignment allowed" precondition already correctly rejects a
-- second, stale assignment attempt (verified in P1-E3-S5's own concurrency
-- test); there is nothing analogous to add there.
--
-- Postgres cannot add a new REQUIRED-by-convention parameter to an existing
-- function via CREATE OR REPLACE without an explicit DROP first (the old
-- 4-arg overload would otherwise remain independently callable, exactly
-- the "second competing reassignment RPC" this phase's work item explicitly
-- avoids) — so the old signature is dropped before the new one is created.

drop function if exists public.reassign_trip(uuid, uuid, uuid, text);

create or replace function public.reassign_trip(
  p_trip_id uuid,
  p_driver_id uuid,
  p_vehicle_id uuid default null,
  p_reason text default null,
  p_expected_assignment_id uuid default null
)
returns public.trip_assignment_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_existing public.trip_assignments;
  v_new_id uuid;
  v_close_reason text;
  v_result public.trip_assignment_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;
  if p_driver_id is null then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.has_org_role(v_trip.organization_id, array['organization_admin', 'dispatcher']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if v_trip.state not in ('scheduled', 'en_route_to_pickup', 'arrived_at_pickup') then
    raise exception 'illegal_transition' using errcode = 'ZW004';
  end if;

  select * into v_existing
  from public.trip_assignments
  where trip_id = p_trip_id and organization_id = v_trip.organization_id and ended_at is null
  for update;

  if v_existing.id is null then
    -- Nothing to reassign: assign_trip is the correct function here.
    -- p_expected_assignment_id is irrelevant when there is no active
    -- assignment to have expected in the first place.
    raise exception 'assignment_conflict' using errcode = 'ZW005';
  end if;

  -- P1-E3-S5B: the expected-assignment precondition is checked BEFORE the
  -- idempotent driver/vehicle match below — deliberately, not incidentally.
  -- P1-E3-S5A's original ordering checked idempotency FIRST, which let a
  -- stale Dispatcher decision slip through as a silent "success" whenever
  -- the requested driver/vehicle happened to already match whatever the
  -- CURRENT (not the caller's expected) assignment was — e.g. active
  -- assignment changed X -> Y, caller still expects X, but Y's own
  -- driver/vehicle happen to equal what the caller is requesting. That
  -- contradicts the explicit product rule (P1-E3-S5B): a stale expected
  -- assignment must NEVER be treated as an idempotent success, even when
  -- the requested driver/vehicle coincidentally match the current one.
  -- IS DISTINCT FROM treats a NULL p_expected_assignment_id (an old/
  -- unaware caller) as a mismatch, never as "skip the check" — there is
  -- no way to bypass this by omitting the parameter.
  if v_existing.id is distinct from p_expected_assignment_id then
    raise exception 'assignment_conflict' using errcode = 'ZW005';
  end if;

  if v_existing.driver_id = p_driver_id and v_existing.vehicle_id is not distinct from p_vehicle_id then
    -- Reached ONLY when p_expected_assignment_id already matches the
    -- active assignment — i.e. the caller's own expectation is confirmed
    -- current, not stale. A genuine idempotent no-op: the caller reviewed
    -- assignment Y and is requesting exactly what Y already represents.
    -- This is deliberately narrower than P1-E3-S5A's original version,
    -- which also treated a request matching the CURRENT assignment as
    -- idempotent even when the caller's OWN expected id was stale (e.g. a
    -- dropped-response retry using a since-superseded id) — P1-E3-S5B's
    -- explicit product rule removes that leniency: staleness is staleness,
    -- full stop, regardless of what the request happens to ask for. This
    -- does not touch ZD-093's own guarantee, which concerns a DIFFERENT
    -- mechanism (`p_expected_current_state` on the driver_* transition
    -- RPCs, checked against Trip state, not an assignment id) — unrelated
    -- code, not modified here.
    v_result.trip_id := v_trip.id;
    v_result.assignment_id := v_existing.id;
    v_result.driver_id := v_existing.driver_id;
    v_result.vehicle_id := v_existing.vehicle_id;
    v_result.changed := false;
    return v_result;
  end if;

  -- A REAL change is being requested, and p_expected_assignment_id has
  -- already been confirmed current above.
  if not exists (
    select 1 from public.drivers
    where id = p_driver_id and organization_id = v_trip.organization_id and status = 'active'
  ) then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  if p_vehicle_id is not null and not exists (
    select 1 from public.vehicles
    where id = p_vehicle_id and organization_id = v_trip.organization_id and status = 'active'
  ) then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  v_close_reason := coalesce(nullif(btrim(p_reason), ''), 'reassigned');

  update public.trip_assignments
    set ended_at = now(), end_reason = v_close_reason
    where id = v_existing.id;

  insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by)
    values (v_trip.organization_id, p_trip_id, p_driver_id, p_vehicle_id, auth.uid())
    returning id into v_new_id;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
    values (v_trip.organization_id, p_trip_id, 'driver_reassigned', auth.uid(),
            jsonb_build_object(
              'previous_driver_id', v_existing.driver_id, 'previous_vehicle_id', v_existing.vehicle_id,
              'driver_id', p_driver_id, 'vehicle_id', p_vehicle_id));

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, before_data, after_data, reason)
    values (v_trip.organization_id, 'trip', p_trip_id, 'driver_reassigned', auth.uid(),
            jsonb_build_object('assignment_id', v_existing.id, 'driver_id', v_existing.driver_id, 'vehicle_id', v_existing.vehicle_id),
            jsonb_build_object('assignment_id', v_new_id, 'driver_id', p_driver_id, 'vehicle_id', p_vehicle_id),
            nullif(btrim(p_reason), ''));

  v_result.trip_id := v_trip.id;
  v_result.assignment_id := v_new_id;
  v_result.driver_id := p_driver_id;
  v_result.vehicle_id := p_vehicle_id;
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.reassign_trip(uuid, uuid, uuid, text, uuid) is
  'Organization Admin / Dispatcher only. Requires an EXISTING active trip_assignments row (ZW005 if none — use assign_trip instead). P1-E3-S5A/S5B: requires p_expected_assignment_id to match that active row''s id (ZW005 on any mismatch, including a null/omitted value) BEFORE anything else is evaluated — a stale expected assignment is always assignment_conflict, even if the requested driver/vehicle happen to already equal the current (not the caller''s expected) assignment. Only once p_expected_assignment_id is confirmed current is the requested driver+vehicle checked against it for a genuine idempotent no-op (changed:false, no write). Closes the old row and inserts a new one in the same transaction for a real change (never edits driver_id/vehicle_id in place, per ZD-051). Reason is optional context, not a precondition.';

revoke all on function public.reassign_trip(uuid, uuid, uuid, text, uuid) from public;
grant execute on function public.reassign_trip(uuid, uuid, uuid, text, uuid) to authenticated;
