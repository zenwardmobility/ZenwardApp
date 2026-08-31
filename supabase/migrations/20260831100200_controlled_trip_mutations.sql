-- P1-E2-S2 — Controlled Mutation & Transaction Boundary.
--
-- The controlled RPC/mutation layer. Every write to trips.state,
-- trip_assignments, trip_events, or audit_events happens exclusively
-- through one of the functions below — the underlying columns/tables have
-- no direct authenticated grant that would let a client achieve the same
-- effect any other way (trips.state has zero grant since P1-E2-S1;
-- trip_assignments INSERT/UPDATE was revoked in
-- 20260831100000_trip_assignment_privilege_tightening.sql; trip_events and
-- audit_events have never had an authenticated INSERT grant).
--
-- ── ERROR CONTRACT (ZD-085, docs/security/mutation-authorization.md) ──────
-- Every rejection raises a Postgres exception with one of six custom
-- SQLSTATEs. Callers (and tests) must branch on the SQLSTATE/`code` field
-- PostgREST returns in its JSON error body — never on the message text.
--   ZW001 unauthorized      caller lacks the specific permission for an
--                           action on a resource they can otherwise see
--   ZW002 not_found         resource does not exist, OR caller has no
--                           legitimate visibility into it under existing
--                           RLS (cross-tenant and nonexistent are
--                           deliberately indistinguishable — no existence
--                           oracle)
--   ZW003 stale_state       expected_current_state (or the function's own
--                           required from-state) did not match reality —
--                           optimistic-concurrency conflict
--   ZW004 illegal_transition the requested transition is not a legal edge
--                           from the trip's current state, independent of
--                           any expected_current_state mismatch
--   ZW005 assignment_conflict a trip_assignments precondition failed
--                           (e.g. assign_trip called when one is already
--                           active with a different driver/vehicle;
--                           reassign_trip called when none is active)
--   ZW006 invalid_input     malformed/missing parameter (blank reason,
--                           unknown driver/vehicle, oversized text)
-- Every message is a short, stable, tenant-data-free token (e.g.
-- 'not_found') — never a sentence, never row contents.
--
-- ── AUTHORIZATION / NOT-FOUND vs UNAUTHORIZED CONVENTION ─────────────────
-- Ops functions (cancel_trip, record_no_show, assign_trip, reassign_trip):
-- has_org_role(org, [organization_admin, dispatcher]) is both the
-- visibility test (trips_select_org_operations) and the action test for
-- these roles, so a failed check is uniformly ZW002 not_found — this
-- exactly mirrors what the caller could otherwise SELECT.
-- Driver functions (the 6 driver_* transitions): a driver who has NEVER
-- had any assignment on the trip gets ZW002 not_found (mirrors
-- is_driver_assigned_to_trip, the read-visibility check). A driver who HAS
-- historical visibility but no CURRENTLY ACTIVE assignment gets ZW001
-- unauthorized (they can see the trip per RLS, they just can't act on it
-- anymore) — see _lock_driver_active_assignment below. Exception: if the
-- Trip is already at this function's own target state AND the trusted
-- TripEvent history (trip_events.actor_user_id) shows THIS caller is the
-- one who performed that exact transition (ZD-090, corrected by ZD-093 /
-- P1-E2-S2A), the idempotent no-op path returns success even without an
-- active assignment — that covers a driver retrying their own call after
-- it already completed the Trip (which itself closes the assignment as a
-- normal side effect). A DIFFERENT caller merely observing the same
-- already-achieved state — a formerly-assigned Driver who never performed
-- it, a never-assigned Driver, or a foreign-org Driver — never matches
-- that actor check and falls through to the ordinary ZW001/ZW002 denial.
--
-- ── LOCKING ORDER (ZD-086) ─────────────────────────────────────────────────
-- Every function below locks in the same fixed order: trips row first
-- (SELECT ... FOR UPDATE), then the active trip_assignments row if any
-- (SELECT ... FOR UPDATE). No function ever locks in the reverse order.
-- Uniform ordering across every mutation path is what makes concurrent
-- calls deadlock-free rather than merely "usually fine".
--
-- ── EVENT / AUDIT MATRIX (ZD-087) ──────────────────────────────────────────
-- Driver progression (6 transitions, non-terminal targets): trip_events
-- only — routine operational progress.
-- Assignment, reassignment, cancellation, no-show, and trip completion:
-- trip_events AND audit_events — each materially changes responsibility or
-- reaches a terminal disposition. One event per successful call; closing
-- an assignment as a side effect of reassignment/cancellation/no-show/
-- completion is folded into that one event, never logged separately.

-- =============================================================================
-- Internal helpers — NOT exposed to any client role. No GRANT to
-- authenticated/anon exists for any function in this section; each is
-- reachable only from within another SECURITY DEFINER function's already-
-- elevated execution context (see docs/security/mutation-authorization.md
-- "Internal helper propagation" for why this is safe and why these
-- functions must never be granted directly).
-- =============================================================================

-- The single canonical Trip state-transition matrix (lifecycle-model.md
-- §C/§Q). Every lifecycle mutation function validates against this, so the
-- legal-edge set exists in exactly one place, never duplicated ad hoc.
create or replace function public._is_valid_trip_transition(p_from_state text, p_to_state text)
returns boolean
language sql
immutable
as $$
  select (p_from_state, p_to_state) in (
    ('scheduled', 'en_route_to_pickup'),
    ('en_route_to_pickup', 'arrived_at_pickup'),
    ('arrived_at_pickup', 'passenger_onboard'),
    ('passenger_onboard', 'en_route_to_destination'),
    ('en_route_to_destination', 'arrived_at_destination'),
    ('arrived_at_destination', 'completed'),
    ('scheduled', 'cancelled'),
    ('en_route_to_pickup', 'cancelled'),
    ('arrived_at_pickup', 'cancelled'),
    ('passenger_onboard', 'cancelled'),
    ('en_route_to_destination', 'cancelled'),
    ('arrived_at_destination', 'cancelled'),
    ('en_route_to_pickup', 'no_show'),
    ('arrived_at_pickup', 'no_show')
  );
$$;

comment on function public._is_valid_trip_transition(text, text) is
  'Internal only — never granted to any client role. The sole source of truth for legal Trip state edges (lifecycle-model.md §C/§Q). Called defensively from within every SECURITY DEFINER mutation function; the 6 driver_* wrappers already hardcode a single legal edge each, so a failure here is expected to be unreachable, not a normal rejection path.';

revoke all on function public._is_valid_trip_transition(text, text) from public;

-- Strict WRITE-authorization check for a Driver: unlike
-- is_driver_assigned_to_trip (READ-scope, "ever assigned"), this requires a
-- CURRENTLY ACTIVE (ended_at IS NULL) assignment for the calling user's
-- Driver row in the trip's own organization, and returns the locked
-- trip_assignments row itself so callers avoid a second lookup. Anticipated
-- explicitly in is_driver_assigned_to_trip's own comment (P1-E2-S1) as a
-- future requirement of this exact phase.
create or replace function public._lock_driver_active_assignment(p_trip_id uuid, p_organization_id uuid)
returns public.trip_assignments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
  v_assignment public.trip_assignments;
begin
  v_driver_id := public.current_driver_id(p_organization_id);
  if v_driver_id is null then
    return null;
  end if;

  select * into v_assignment
  from public.trip_assignments
  where trip_id = p_trip_id
    and organization_id = p_organization_id
    and driver_id = v_driver_id
    and ended_at is null
  for update;

  return v_assignment;
end;
$$;

comment on function public._lock_driver_active_assignment(uuid, uuid) is
  'Internal only. Locks (FOR UPDATE) and returns the calling user''s currently-active trip_assignments row for this trip, or a null-fielded row if none exists. Callers distinguish "no active assignment" by checking the returned id IS NULL.';

revoke all on function public._lock_driver_active_assignment(uuid, uuid) from public;

-- Shared executor for the 6 driver progression wrappers below. Accepts the
-- from/to state pair and event_type as parameters, but is ITSELF never
-- exposed — only the 6 named wrappers (which hardcode these values as
-- literals, not client input) get an authenticated EXECUTE grant. Granting
-- this function directly would let any Driver call it with an arbitrary
-- from/to pair, defeating the entire per-action wrapper design.
create or replace function public._driver_execute_trip_transition(
  p_trip_id uuid,
  p_expected_current_state text,
  p_from_state text,
  p_to_state text,
  p_event_type text,
  p_close_assignment boolean default false
)
returns public.trip_transition_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_assignment public.trip_assignments;
  v_result public.trip_transition_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.is_driver_assigned_to_trip(p_trip_id) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- Idempotent no-op check happens BEFORE the active-assignment check,
  -- deliberately — but (P1-E2-S2A correction) "ever assigned" (above)
  -- alone is NOT proof this caller is the legitimate retrying actor. Two
  -- different Drivers can each satisfy is_driver_assigned_to_trip on the
  -- same Trip (one historical, one current); if the Trip already reached
  -- this function's target state, that does not mean THIS caller is the
  -- one who put it there — it may mean a DIFFERENT Driver performed the
  -- transition after this caller was reassigned away. Idempotency means
  -- "the same authorized operation may safely be retried", not "anyone
  -- who can see this resource gets success once the desired state exists
  -- for any reason". So the no-op path additionally requires trusted
  -- proof, from the append-only TripEvent history, that THIS caller
  -- (auth.uid(), never a caller-supplied value) is who actually performed
  -- this exact transition. Every event_type in this transition set is
  -- written at most once per Trip (transitions are strictly forward,
  -- terminal states never revisited), so the lookup is unambiguous.
  if v_trip.state = p_to_state then
    if exists (
      select 1 from public.trip_events
      where trip_id = p_trip_id and event_type = p_event_type and actor_user_id = auth.uid()
    ) then
      v_result.trip_id := v_trip.id;
      v_result.previous_state := v_trip.state;
      v_result.current_state := v_trip.state;
      v_result.changed := false;
      return v_result;
    end if;
    -- Target state holds, but not because of MY action — fall through to
    -- the normal active-assignment/from-state checks below, which
    -- correctly reject a caller with no current standing to act (ZW001,
    -- since a caller in this branch can never still hold the Trip's
    -- active assignment — if they did, they would be the one who
    -- performed the transition and would already have matched above)
    -- rather than silently confirming a state change performed by
    -- someone else.
  end if;

  v_assignment := public._lock_driver_active_assignment(p_trip_id, v_trip.organization_id);
  if v_assignment.id is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  if v_trip.state <> p_from_state
     or (p_expected_current_state is not null and p_expected_current_state <> v_trip.state) then
    raise exception 'stale_state' using errcode = 'ZW003';
  end if;

  if not public._is_valid_trip_transition(p_from_state, p_to_state) then
    raise exception 'illegal_transition' using errcode = 'ZW004';
  end if;

  update public.trips
    set state = p_to_state,
        completed_at = case when p_to_state = 'completed' then now() else completed_at end
    where id = p_trip_id;

  if p_close_assignment then
    update public.trip_assignments
      set ended_at = now(), end_reason = p_event_type
      where id = v_assignment.id;
  end if;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id)
    values (v_trip.organization_id, p_trip_id, p_event_type, auth.uid());

  v_result.trip_id := v_trip.id;
  v_result.previous_state := p_from_state;
  v_result.current_state := p_to_state;
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public._driver_execute_trip_transition(uuid, text, text, text, text, boolean) is
  'Internal only — never granted to any client role. Shared body for the 6 driver_* wrappers, which hardcode from/to/event_type as literals rather than exposing them as caller-controlled parameters.';

revoke all on function public._driver_execute_trip_transition(uuid, text, text, text, text, boolean) from public;

-- =============================================================================
-- Exposed RPCs — the only public surface. Each is SECURITY DEFINER (the
-- writes below require privileges authenticated does not hold directly)
-- with an explicit search_path, and each gets EXECUTE granted to
-- authenticated only — never anon, never PUBLIC.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Driver lifecycle progression — one narrow function per legal edge. No
-- function accepts a target-state parameter; the edge is fixed by which
-- function was called.
-- ---------------------------------------------------------------------------

create or replace function public.driver_start_to_pickup(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'scheduled', 'en_route_to_pickup', 'en_route_to_pickup', false);
end;
$$;

create or replace function public.driver_arrive_at_pickup(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'en_route_to_pickup', 'arrived_at_pickup', 'arrived_at_pickup', false);
end;
$$;

create or replace function public.driver_mark_passenger_onboard(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'arrived_at_pickup', 'passenger_onboard', 'passenger_onboard', false);
end;
$$;

create or replace function public.driver_start_to_destination(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'passenger_onboard', 'en_route_to_destination', 'en_route_to_destination', false);
end;
$$;

create or replace function public.driver_arrive_at_destination(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'en_route_to_destination', 'arrived_at_destination', 'arrived_at_destination', false);
end;
$$;

-- The one driver transition that also reaches a terminal Trip state — it
-- closes the active trip_assignments row as part of the same atomic call
-- (lifecycle-model.md: "do not leave a Driver permanently actively
-- assigned to a completed Trip").
create or replace function public.driver_complete_trip(p_trip_id uuid, p_expected_current_state text)
returns public.trip_transition_result
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  return public._driver_execute_trip_transition(
    p_trip_id, p_expected_current_state, 'arrived_at_destination', 'completed', 'trip_completed', true);
end;
$$;

comment on function public.driver_start_to_pickup(uuid, text) is 'Driver-only. scheduled -> en_route_to_pickup. Requires a currently ACTIVE assignment on this trip for the calling Driver.';
comment on function public.driver_arrive_at_pickup(uuid, text) is 'Driver-only. en_route_to_pickup -> arrived_at_pickup.';
comment on function public.driver_mark_passenger_onboard(uuid, text) is 'Driver-only. arrived_at_pickup -> passenger_onboard.';
comment on function public.driver_start_to_destination(uuid, text) is 'Driver-only. passenger_onboard -> en_route_to_destination.';
comment on function public.driver_arrive_at_destination(uuid, text) is 'Driver-only. en_route_to_destination -> arrived_at_destination.';
comment on function public.driver_complete_trip(uuid, text) is 'Driver-only. arrived_at_destination -> completed. Also closes the active trip_assignments row (ended_at, end_reason=''trip_completed'') in the same transaction.';

revoke all on function public.driver_start_to_pickup(uuid, text) from public;
revoke all on function public.driver_arrive_at_pickup(uuid, text) from public;
revoke all on function public.driver_mark_passenger_onboard(uuid, text) from public;
revoke all on function public.driver_start_to_destination(uuid, text) from public;
revoke all on function public.driver_arrive_at_destination(uuid, text) from public;
revoke all on function public.driver_complete_trip(uuid, text) from public;

grant execute on function public.driver_start_to_pickup(uuid, text) to authenticated;
grant execute on function public.driver_arrive_at_pickup(uuid, text) to authenticated;
grant execute on function public.driver_mark_passenger_onboard(uuid, text) to authenticated;
grant execute on function public.driver_start_to_destination(uuid, text) to authenticated;
grant execute on function public.driver_arrive_at_destination(uuid, text) to authenticated;
grant execute on function public.driver_complete_trip(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Operations lifecycle actions — Organization Admin / Dispatcher only.
-- ---------------------------------------------------------------------------

create or replace function public.cancel_trip(p_trip_id uuid, p_reason text)
returns public.trip_transition_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_assignment public.trip_assignments;
  v_reason text;
  v_result public.trip_transition_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  v_reason := nullif(btrim(p_reason), '');
  if v_reason is null or length(v_reason) > 500 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.has_org_role(v_trip.organization_id, array['organization_admin', 'dispatcher']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if v_trip.state = 'cancelled' then
    v_result.trip_id := v_trip.id;
    v_result.previous_state := v_trip.state;
    v_result.current_state := v_trip.state;
    v_result.changed := false;
    return v_result;
  end if;

  if v_trip.state in ('completed', 'no_show') then
    raise exception 'illegal_transition' using errcode = 'ZW004';
  end if;

  select * into v_assignment
  from public.trip_assignments
  where trip_id = p_trip_id and organization_id = v_trip.organization_id and ended_at is null
  for update;

  update public.trips
    set state = 'cancelled', cancelled_at = now(), cancellation_reason = v_reason
    where id = p_trip_id;

  if v_assignment.id is not null then
    update public.trip_assignments
      set ended_at = now(), end_reason = 'trip_cancelled'
      where id = v_assignment.id;
  end if;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
    values (v_trip.organization_id, p_trip_id, 'trip_cancelled', auth.uid(), jsonb_build_object('reason', v_reason));

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, before_data, after_data, reason)
    values (v_trip.organization_id, 'trip', p_trip_id, 'trip_cancelled', auth.uid(),
            jsonb_build_object('state', v_trip.state), jsonb_build_object('state', 'cancelled'), v_reason);

  v_result.trip_id := v_trip.id;
  v_result.previous_state := v_trip.state;
  v_result.current_state := 'cancelled';
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.cancel_trip(uuid, text) is
  'Organization Admin / Dispatcher only. Any non-terminal state -> cancelled. Idempotent no-op if already cancelled; ZW004 if the Trip already reached a DIFFERENT terminal state (completed/no_show). Closes any active trip_assignments row as part of the same transaction. Reason is required (1-500 chars).';

revoke all on function public.cancel_trip(uuid, text) from public;
grant execute on function public.cancel_trip(uuid, text) to authenticated;

create or replace function public.record_no_show(p_trip_id uuid, p_reason text)
returns public.trip_transition_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_assignment public.trip_assignments;
  v_reason text;
  v_result public.trip_transition_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  v_reason := nullif(btrim(p_reason), '');
  if v_reason is null or length(v_reason) > 500 then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if not public.has_org_role(v_trip.organization_id, array['organization_admin', 'dispatcher']) then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  if v_trip.state = 'no_show' then
    v_result.trip_id := v_trip.id;
    v_result.previous_state := v_trip.state;
    v_result.current_state := v_trip.state;
    v_result.changed := false;
    return v_result;
  end if;

  if v_trip.state not in ('en_route_to_pickup', 'arrived_at_pickup') then
    raise exception 'illegal_transition' using errcode = 'ZW004';
  end if;

  select * into v_assignment
  from public.trip_assignments
  where trip_id = p_trip_id and organization_id = v_trip.organization_id and ended_at is null
  for update;

  update public.trips
    set state = 'no_show', no_show_at = now()
    where id = p_trip_id;

  if v_assignment.id is not null then
    update public.trip_assignments
      set ended_at = now(), end_reason = 'no_show'
      where id = v_assignment.id;
  end if;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
    values (v_trip.organization_id, p_trip_id, 'no_show_recorded', auth.uid(), jsonb_build_object('reason', v_reason));

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, before_data, after_data, reason)
    values (v_trip.organization_id, 'trip', p_trip_id, 'no_show_recorded', auth.uid(),
            jsonb_build_object('state', v_trip.state), jsonb_build_object('state', 'no_show'), v_reason);

  v_result.trip_id := v_trip.id;
  v_result.previous_state := v_trip.state;
  v_result.current_state := 'no_show';
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.record_no_show(uuid, text) is
  'Organization Admin / Dispatcher only. Legal only from en_route_to_pickup or arrived_at_pickup (lifecycle-model.md §J). Idempotent no-op if already no_show. trips has no no_show_reason column by design — the reason is recorded in trip_events.metadata and audit_events.reason, not a new schema field.';

revoke all on function public.record_no_show(uuid, text) from public;
grant execute on function public.record_no_show(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Assignment — Organization Admin / Dispatcher only.
--
-- Assignment-eligible states (ZD-088): scheduled, en_route_to_pickup,
-- arrived_at_pickup. Neither lifecycle-model.md nor authorization-model.md
-- enumerated a restricted eligible-state list for (re)assignment before
-- this phase (checked directly; no existing rule to follow or contradict)
-- — this conservative MVP rule is recorded fresh as ZD-088 rather than
-- assumed silently, per work item §21.
-- ---------------------------------------------------------------------------

create or replace function public.assign_trip(p_trip_id uuid, p_driver_id uuid, p_vehicle_id uuid default null)
returns public.trip_assignment_result
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_existing public.trip_assignments;
  v_new_id uuid;
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

  if v_existing.id is not null then
    if v_existing.driver_id = p_driver_id and v_existing.vehicle_id is not distinct from p_vehicle_id then
      v_result.trip_id := v_trip.id;
      v_result.assignment_id := v_existing.id;
      v_result.driver_id := v_existing.driver_id;
      v_result.vehicle_id := v_existing.vehicle_id;
      v_result.changed := false;
      return v_result;
    else
      -- A different active assignment already exists: assign_trip's
      -- contract is "create the first assignment". Changing an existing
      -- one is reassign_trip's job.
      raise exception 'assignment_conflict' using errcode = 'ZW005';
    end if;
  end if;

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

  insert into public.trip_assignments (organization_id, trip_id, driver_id, vehicle_id, assigned_by)
    values (v_trip.organization_id, p_trip_id, p_driver_id, p_vehicle_id, auth.uid())
    returning id into v_new_id;

  insert into public.trip_events (organization_id, trip_id, event_type, actor_user_id, metadata)
    values (v_trip.organization_id, p_trip_id, 'driver_assigned', auth.uid(),
            jsonb_build_object('driver_id', p_driver_id, 'vehicle_id', p_vehicle_id));

  insert into public.audit_events (organization_id, entity_type, entity_id, action, actor_user_id, before_data, after_data)
    values (v_trip.organization_id, 'trip', p_trip_id, 'driver_assigned', auth.uid(),
            jsonb_build_object('assignment_id', null),
            jsonb_build_object('assignment_id', v_new_id, 'driver_id', p_driver_id, 'vehicle_id', p_vehicle_id));

  v_result.trip_id := v_trip.id;
  v_result.assignment_id := v_new_id;
  v_result.driver_id := p_driver_id;
  v_result.vehicle_id := p_vehicle_id;
  v_result.changed := true;
  return v_result;
end;
$$;

comment on function public.assign_trip(uuid, uuid, uuid) is
  'Organization Admin / Dispatcher only. Requires NO existing active trip_assignments row (ZW005 if one already exists with a different driver/vehicle; idempotent no-op if identical). Trip must be in an assignment-eligible state (ZD-088: scheduled/en_route_to_pickup/arrived_at_pickup). Driver/vehicle must belong to the same organization_id and have status=''active''.';

revoke all on function public.assign_trip(uuid, uuid, uuid) from public;
grant execute on function public.assign_trip(uuid, uuid, uuid) to authenticated;

create or replace function public.reassign_trip(p_trip_id uuid, p_driver_id uuid, p_vehicle_id uuid default null, p_reason text default null)
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
    raise exception 'assignment_conflict' using errcode = 'ZW005';
  end if;

  if v_existing.driver_id = p_driver_id and v_existing.vehicle_id is not distinct from p_vehicle_id then
    v_result.trip_id := v_trip.id;
    v_result.assignment_id := v_existing.id;
    v_result.driver_id := v_existing.driver_id;
    v_result.vehicle_id := v_existing.vehicle_id;
    v_result.changed := false;
    return v_result;
  end if;

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

comment on function public.reassign_trip(uuid, uuid, uuid, text) is
  'Organization Admin / Dispatcher only. Requires an EXISTING active trip_assignments row (ZW005 if none — use assign_trip instead). Idempotent no-op if the requested driver+vehicle already match the active assignment. Closes the old row and inserts a new one in the same transaction (never edits driver_id/vehicle_id in place, per ZD-051). Reason is optional context, not a precondition.';

revoke all on function public.reassign_trip(uuid, uuid, uuid, text) from public;
grant execute on function public.reassign_trip(uuid, uuid, uuid, text) to authenticated;
