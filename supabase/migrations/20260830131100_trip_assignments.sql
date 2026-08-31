-- trip_assignments — the canonical, append-oriented source of truth for who
-- is on a trip (domain-model.md §B entity 11, §G, ZD-051). Classification:
-- TENANT-OWNED, direct organization_id (denormalized from Trip
-- deliberately — see the fragile-join-chain warning in domain-model.md §5).
--
-- Active assignment = the row with ended_at IS NULL. Reassignment closes
-- the current row (ended_at, end_reason) and inserts a new one — historical
-- driver/vehicle values are never rewritten in place.

create table public.trip_assignments (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  trip_id uuid not null,
  driver_id uuid not null,
  vehicle_id uuid,
  assigned_by uuid references auth.users (id),
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  end_reason text,
  created_at timestamptz not null default now(),
  foreign key (trip_id, organization_id) references public.trips (id, organization_id),
  foreign key (driver_id, organization_id) references public.drivers (id, organization_id),
  foreign key (vehicle_id, organization_id) references public.vehicles (id, organization_id)
);

comment on table public.trip_assignments is
  'TENANT-OWNED, HIGH RLS RISK. Append-oriented: a reassignment closes the active row and inserts a new one, never edits driver_id/vehicle_id in place. See trip_assignments_one_active_per_trip below for the "at most one active assignment per trip" constraint (lifecycle-model.md §F/§G, ZD-051).';

create index trip_assignments_trip_id_idx on public.trip_assignments (trip_id);
create index trip_assignments_driver_id_idx on public.trip_assignments (driver_id);
create index trip_assignments_organization_id_idx on public.trip_assignments (organization_id);

-- *** REQUIRED ADVERSARIAL CONSTRAINT (work item §51/§14) ***
-- At most one active (ended_at IS NULL) assignment per trip. A second
-- concurrent "insert new active assignment without closing the current
-- one" fails at this constraint, not merely at the application layer.
create unique index trip_assignments_one_active_per_trip
  on public.trip_assignments (trip_id)
  where ended_at is null;

alter table public.trip_assignments enable row level security;
