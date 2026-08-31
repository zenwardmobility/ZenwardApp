-- trips — the operational transportation movement itself (domain-model.md
-- §B entity 10, lifecycle-model.md §C). Classification: TENANT-OWNED,
-- direct organization_id.
--
-- Canonical lifecycle states (lifecycle-model.md §C, ZD-055) — exactly 9,
-- no "draft" (ZD-056), no ambiguous bare en_route/arrived:
--   scheduled → en_route_to_pickup → arrived_at_pickup → passenger_onboard
--     → en_route_to_destination → arrived_at_destination → completed
--   (from most non-terminal states) → cancelled
--   (from en_route_to_pickup or arrived_at_pickup) → no_show
--
-- current_driver_id/current_vehicle_id are deliberately NOT columns here —
-- trip_assignments is the sole assignment source of truth (ZD-051).

create table public.trips (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  request_id uuid,
  passenger_id uuid not null,
  state text not null default 'scheduled' check (
    state in (
      'scheduled', 'en_route_to_pickup', 'arrived_at_pickup', 'passenger_onboard',
      'en_route_to_destination', 'arrived_at_destination', 'completed', 'cancelled', 'no_show'
    )
  ),
  scheduled_pickup_at timestamptz,
  appointment_at timestamptz,
  -- Immutable address snapshots (domain-model.md §J hybrid strategy) —
  -- never rederived from mutable passenger/facility records. Optional soft
  -- facility references below are for reporting/context linkage only.
  pickup_description text not null,
  destination_description text not null,
  pickup_facility_id uuid,
  destination_facility_id uuid,
  assistance_notes text,
  instructions text,
  -- Write-once terminal timestamps — distinguished from the rejected
  -- current_driver_id/current_vehicle_id denormalization (ZD-068): these
  -- are immutable historical facts set exactly once, not a changing
  -- "current" pointer duplicating another table's live state.
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  no_show_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id),
  foreign key (request_id, organization_id) references public.transportation_requests (id, organization_id),
  foreign key (passenger_id, organization_id) references public.passengers (id, organization_id),
  foreign key (pickup_facility_id, organization_id)
    references public.facilities (id, organization_id) on delete set null,
  foreign key (destination_facility_id, organization_id)
    references public.facilities (id, organization_id) on delete set null
);

comment on table public.trips is
  'TENANT-OWNED, HIGH RLS RISK (domain-model.md §C). The canonical entity every cross-tenant test targets. request_id nullable (1:N Request→Trip, ZD-045); no current_driver_id/current_vehicle_id (ZD-051, trip_assignments is sole source of truth).';

create trigger trips_set_updated_at
  before update on public.trips
  for each row execute function public.set_updated_at();

create trigger trips_prevent_org_change
  before update on public.trips
  for each row execute function public.prevent_organization_id_change();

create index trips_organization_id_idx on public.trips (organization_id);
create index trips_org_state_idx on public.trips (organization_id, state);
create index trips_org_scheduled_pickup_idx on public.trips (organization_id, scheduled_pickup_at);
create index trips_passenger_id_idx on public.trips (passenger_id);
create index trips_request_id_idx on public.trips (request_id) where request_id is not null;

alter table public.trips enable row level security;
