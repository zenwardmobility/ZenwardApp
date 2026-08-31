-- P1-E2-S3 — Secure Read Models & Driver Minimum-Necessary Projection.
--
-- The controlled Driver read API. Every field returned here was reviewed
-- against docs/security/driver-data-minimization.md's field matrix before
-- being included — nothing is returned "just in case". No function here
-- uses passenger.*, to_jsonb(passenger), row_to_json(passenger), or any
-- other whole-row serialization (work item §9) — every field is named
-- explicitly.
--
-- All 4 functions are STABLE (read-only, never mutate trips/
-- trip_assignments/trip_events/audit_events), SECURITY DEFINER (Passenger
-- has zero grant to authenticated at all — ZD-080 — and this phase also
-- retires several other Driver base-table SELECT paths in
-- 20260831110200_driver_base_table_policy_tightening.sql, so these
-- functions are now the only route to this data), explicit
-- search_path, EXECUTE granted to authenticated only.
--
-- Reuses the same 6-code error contract as the mutation RPCs (ZD-085):
-- ZW002 not_found for "no legitimate Driver context in this organization"
-- and "Trip does not exist or is not currently, actively yours" — see
-- docs/data/read-api.md for why every denial here is ZW002, never ZW001
-- (explained in the file-level comment below §not_found convention).
--
-- No caller-supplied actor/user id anywhere — every function derives
-- identity exclusively from auth.uid().

-- =============================================================================
-- A. Driver profile
-- =============================================================================
create or replace function public.driver_get_profile(p_organization_id uuid)
returns public.driver_profile_result
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
  v_result public.driver_profile_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  v_driver_id := public.current_driver_id(p_organization_id);
  if v_driver_id is null then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  select d.id, d.organization_id, o.name, d.display_name, d.phone, d.status
    into v_result.driver_id, v_result.organization_id, v_result.organization_name,
         v_result.display_name, v_result.phone, v_result.status
  from public.drivers d
  join public.organizations o on o.id = d.organization_id
  where d.id = v_driver_id and d.organization_id = p_organization_id;

  return v_result;
end;
$$;

comment on function public.driver_get_profile(uuid) is
  'Driver-only. Returns the calling user''s OWN Driver profile within the given organization context. Requires an active Membership resolving (via current_driver_id) to an active Driver row in that organization (ZW002 otherwise). Own data only.';

revoke all on function public.driver_get_profile(uuid) from public;
grant execute on function public.driver_get_profile(uuid) to authenticated;

-- =============================================================================
-- B. Active/upcoming assigned Trip list
-- =============================================================================
create or replace function public.driver_list_active_trips(p_organization_id uuid)
returns setof public.driver_active_trip_summary
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  v_driver_id := public.current_driver_id(p_organization_id);
  if v_driver_id is null then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  return query
    select
      t.id, ta.id, t.state, t.scheduled_pickup_at, t.appointment_at,
      t.pickup_description, t.destination_description,
      p.display_name, v.label, v.status
    from public.trip_assignments ta
    join public.trips t on t.id = ta.trip_id and t.organization_id = ta.organization_id
    join public.passengers p on p.id = t.passenger_id and p.organization_id = t.organization_id
    left join public.vehicles v on v.id = ta.vehicle_id and v.organization_id = ta.organization_id
    where ta.organization_id = p_organization_id
      and ta.driver_id = v_driver_id
      and ta.ended_at is null
    order by t.scheduled_pickup_at asc nulls last, t.created_at asc;
end;
$$;

comment on function public.driver_list_active_trips(uuid) is
  'Driver-only. Lists only Trips with a CURRENTLY active (ended_at IS NULL) trip_assignments row for the calling Driver in the given organization. Never unassigned Trips, another Driver''s Trips, or a Trip the caller was only ever historically assigned to.';

revoke all on function public.driver_list_active_trips(uuid) from public;
grant execute on function public.driver_list_active_trips(uuid) to authenticated;

-- =============================================================================
-- C. Assigned Trip detail — the minimum-necessary projection
-- =============================================================================
create or replace function public.driver_get_trip_detail(p_trip_id uuid)
returns public.driver_trip_detail_result
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_trip public.trips;
  v_driver_id uuid;
  v_assignment public.trip_assignments;
  v_result public.driver_trip_detail_result;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  v_driver_id := public.current_driver_id(v_trip.organization_id);
  if v_driver_id is null then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- Detail requires a CURRENTLY active assignment — a historical
  -- assignment alone is never sufficient (work item §15). A Driver
  -- reassigned away loses detailed access immediately, on their very next
  -- call, because this is a live lookup, not a cached grant.
  select * into v_assignment
  from public.trip_assignments
  where trip_id = p_trip_id and organization_id = v_trip.organization_id
    and driver_id = v_driver_id and ended_at is null;
  if not found then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  select
    v_trip.id, v_assignment.id, v_trip.state, v_trip.scheduled_pickup_at, v_trip.appointment_at,
    v_trip.pickup_description, v_trip.destination_description,
    p.display_name, p.phone,
    v_trip.assistance_notes, v_trip.instructions,
    veh.label, veh.status,
    coalesce(notes.driver_notes, '[]'::jsonb)
  into
    v_result.trip_id, v_result.assignment_id, v_result.state, v_result.scheduled_pickup_at, v_result.appointment_at,
    v_result.pickup_description, v_result.destination_description,
    v_result.passenger_display_name, v_result.passenger_phone,
    v_result.assistance_notes, v_result.instructions,
    v_result.vehicle_label, v_result.vehicle_status,
    v_result.driver_notes
  from public.passengers p
  left join public.vehicles veh on veh.id = v_assignment.vehicle_id and veh.organization_id = v_trip.organization_id
  left join lateral (
    select jsonb_agg(jsonb_build_object('id', n.id, 'body', n.body, 'created_at', n.created_at) order by n.created_at asc) as driver_notes
    from public.trip_notes n
    where n.trip_id = v_trip.id and n.organization_id = v_trip.organization_id and n.visibility = 'driver_visible'
  ) notes on true
  where p.id = v_trip.passenger_id and p.organization_id = v_trip.organization_id;

  return v_result;
end;
$$;

comment on function public.driver_get_trip_detail(uuid) is
  'Driver-only. The controlled minimum-necessary projection for a Trip the caller CURRENTLY, actively holds. Organization is derived from the Trip itself, never accepted as a parameter (work item §11). Every field is explicitly named — see docs/security/driver-data-minimization.md for the full field-by-field rationale. driver_notes includes only visibility=driver_visible rows, built via jsonb_build_object (never a whole-row serialization).';

revoke all on function public.driver_get_trip_detail(uuid) from public;
grant execute on function public.driver_get_trip_detail(uuid) to authenticated;

-- =============================================================================
-- D. Limited Driver Trip history
-- =============================================================================
create or replace function public.driver_list_trip_history(
  p_organization_id uuid,
  p_from timestamptz default null,
  p_to timestamptz default null
)
returns setof public.driver_trip_history_entry
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
  v_from timestamptz;
  v_to timestamptz;
  v_max_window interval := interval '180 days';
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'ZW001';
  end if;

  v_driver_id := public.current_driver_id(p_organization_id);
  if v_driver_id is null then
    raise exception 'not_found' using errcode = 'ZW002';
  end if;

  -- Bounded, defaulted range — a query/performance/privacy safeguard, NOT
  -- a business retention policy (work item §29). Default: the trailing 90
  -- days if no range is given. Hard cap: 180 days per request, regardless
  -- of what the caller asks for.
  v_to := coalesce(p_to, now());
  v_from := coalesce(p_from, v_to - interval '90 days');
  if v_from > v_to then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;
  if v_to - v_from > v_max_window then
    raise exception 'invalid_input' using errcode = 'ZW006';
  end if;

  return query
    select
      t.id, t.scheduled_pickup_at, ta.assigned_at, ta.ended_at, ta.end_reason,
      case when t.state in ('completed', 'cancelled', 'no_show') then t.state else null end
    from public.trip_assignments ta
    join public.trips t on t.id = ta.trip_id and t.organization_id = ta.organization_id
    where ta.organization_id = p_organization_id
      and ta.driver_id = v_driver_id
      and ta.ended_at is not null
      and ta.ended_at >= v_from
      and ta.ended_at <= v_to
    order by ta.ended_at desc;
end;
$$;

comment on function public.driver_list_trip_history(uuid, timestamptz, timestamptz) is
  'Driver-only. Limited, materially-redacted history of the caller''s own ENDED (ended_at IS NOT NULL) trip_assignments in the given organization. No passenger identity/phone, no notes, no pickup/destination text, no requester data (docs/security/driver-data-minimization.md). trip_outcome is null unless the Trip reached a terminal state, so a past assignment never reveals a later Driver''s in-progress work on the same Trip. Range defaults to the trailing 90 days; hard-capped at 180 days per call (ZW006 if exceeded or inverted) as a query-cost/privacy safeguard, not a retention rule.';

revoke all on function public.driver_list_trip_history(uuid, timestamptz, timestamptz) from public;
grant execute on function public.driver_list_trip_history(uuid, timestamptz, timestamptz) to authenticated;
