-- transportation_requests — inbound transportation intent (domain-model.md
-- §B entity 9). Classification: PUBLIC-INTAKE → TENANT-OWNED. The row
-- always carries organization_id once persisted, assigned by a trusted
-- server-side path — never trusted from a client. No anonymous
-- SELECT/UPDATE/DELETE policy is created for this table in this phase, and
-- no anonymous INSERT policy either (ZD-044/ZD-050 — public intake is
-- deferred to a future controlled path; this phase does not implement it).
-- Requester is snapshot fields here, not a standalone table (ZD-045).

create table public.transportation_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  passenger_id uuid references public.passengers (id),
  requester_name text not null,
  requester_relationship text not null
    check (requester_relationship in ('self', 'family', 'caregiver', 'facility_coordinator', 'other')),
  requester_phone text not null,
  requester_email text,
  requester_user_id uuid references auth.users (id),
  pickup_description text not null,
  destination_description text not null,
  preferred_date date,
  preferred_time time,
  return_trip_needed text not null check (return_trip_needed in ('yes', 'no', 'not_sure')),
  assistance_notes text,
  additional_notes text,
  state text not null default 'pending' check (state in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id),
  -- Nullable composite FK: satisfied trivially while passenger_id is NULL
  -- (Postgres MATCH SIMPLE default), enforced once a passenger is matched.
  foreign key (passenger_id, organization_id) references public.passengers (id, organization_id)
);

comment on table public.transportation_requests is
  'PUBLIC-INTAKE → TENANT-OWNED (domain-model.md §B). Lifecycle: pending → accepted (system-driven, triggered by first Trip creation) | declined | cancelled (lifecycle-model.md §B). No anonymous access of any kind exists in this phase — public intake is deferred to a future trusted server-side path, not implemented here.';

create trigger transportation_requests_set_updated_at
  before update on public.transportation_requests
  for each row execute function public.set_updated_at();

create trigger transportation_requests_prevent_org_change
  before update on public.transportation_requests
  for each row execute function public.prevent_organization_id_change();

create index transportation_requests_organization_id_idx on public.transportation_requests (organization_id);

-- Ops queue: "pending requests for my org, oldest first."
create index transportation_requests_org_state_created_idx
  on public.transportation_requests (organization_id, state, created_at);

alter table public.transportation_requests enable row level security;
