-- facilities — directory of physical places trips reference (domain-model.md
-- §B entity 7). Facility ≠ Organization — no authenticated facility users
-- exist yet. Classification: TENANT-OWNED, direct organization_id.

create table public.facilities (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  name text not null,
  address_line1 text,
  address_line2 text,
  city text,
  state text,
  postal_code text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id)
);

comment on table public.facilities is
  'TENANT-OWNED. The same real-world facility referenced by two Zenward organizations is two separate rows here — no cross-organization facility sharing (domain-model.md §I). No standing Driver directory SELECT in this phase; no public access.';

create trigger facilities_set_updated_at
  before update on public.facilities
  for each row execute function public.set_updated_at();

create trigger facilities_prevent_org_change
  before update on public.facilities
  for each row execute function public.prevent_organization_id_change();

create index facilities_organization_id_idx on public.facilities (organization_id);

alter table public.facilities enable row level security;
