-- trip_exceptions — something needing attention that coexists with, but is
-- not, Trip.state (domain-model.md §B entity 14, lifecycle-model.md §G).
-- Classification: TENANT-OWNED, direct organization_id. Exactly two
-- states: open, resolved — no "dismissed" (lifecycle-model.md §G).

create table public.trip_exceptions (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  trip_id uuid not null,
  exception_type text,
  description text,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_by uuid references auth.users (id),
  resolved_by uuid references auth.users (id),
  resolved_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now(),
  foreign key (trip_id, organization_id) references public.trips (id, organization_id)
);

comment on table public.trip_exceptions is
  'TENANT-OWNED. exception_type is deliberately unconstrained free text — taxonomy not yet finalized (domain-model.md §21). Driver may create/report on own assigned trip only; only Dispatcher/Organization Admin resolve (Driver never during MVP).';

create index trip_exceptions_trip_id_idx on public.trip_exceptions (trip_id);
create index trip_exceptions_org_status_idx on public.trip_exceptions (organization_id, status);

alter table public.trip_exceptions enable row level security;
