-- trip_events — structured, append-only operational history (domain-model.md
-- §B entity 12, lifecycle-model.md §H). Classification: TENANT-OWNED,
-- direct organization_id (same fragile-join-chain reasoning as
-- trip_assignments). No UPDATE/DELETE for any ordinary role — see the
-- rls_policies migration, which deliberately grants no UPDATE/DELETE
-- privilege to authenticated for this table at all.

create table public.trip_events (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  trip_id uuid not null,
  event_type text not null check (
    event_type in (
      'trip_scheduled', 'en_route_to_pickup', 'arrived_at_pickup', 'passenger_onboard',
      'en_route_to_destination', 'arrived_at_destination', 'trip_completed', 'trip_cancelled',
      'no_show_recorded', 'driver_assigned', 'driver_reassigned', 'assignment_ended',
      'note_added', 'exception_flagged', 'exception_resolved', 'request_converted_to_trip'
    )
  ),
  actor_user_id uuid references auth.users (id),
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  foreign key (trip_id, organization_id) references public.trips (id, organization_id)
);

comment on table public.trip_events is
  'TENANT-OWNED, append-only. Allow-listed event_type values only (lifecycle-model.md §H) — clients cannot fabricate arbitrary history. No INSERT policy is granted to any human role in this phase (see rls_policies migration) — event creation is deferred to the controlled lifecycle-transition mechanism built in a later phase (ZD-060).';

create index trip_events_trip_id_occurred_idx on public.trip_events (trip_id, occurred_at);
create index trip_events_organization_id_idx on public.trip_events (organization_id);

alter table public.trip_events enable row level security;
