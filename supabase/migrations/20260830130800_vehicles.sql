-- vehicles — organization-owned operational resource, independent of any
-- trip (domain-model.md §B entity 8). Classification: TENANT-OWNED, direct
-- organization_id.

create table public.vehicles (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  label text not null,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id)
);

comment on table public.vehicles is
  'TENANT-OWNED. Deliberately minimal MVP fields — no capability taxonomy (wheelchair/ambulatory classification etc. are unresolved product decisions, see decision-register.md).';

create trigger vehicles_set_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();

create trigger vehicles_prevent_org_change
  before update on public.vehicles
  for each row execute function public.prevent_organization_id_change();

create index vehicles_organization_id_idx on public.vehicles (organization_id);

alter table public.vehicles enable row level security;
