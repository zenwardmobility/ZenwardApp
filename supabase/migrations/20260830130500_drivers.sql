-- drivers — operational resource, NOT an auth identity (domain-model.md §B
-- entity 5, §H). Classification: TENANT-OWNED, direct organization_id. A
-- person driving for two organizations is two separate driver rows.

create table public.drivers (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  user_id uuid references auth.users (id) on delete set null,
  display_name text not null,
  phone text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Composite-FK target for trip_assignments — makes a cross-tenant
  -- assignment (Trip Org A → Driver Org B) a schema-level impossibility,
  -- not merely something RLS is trusted to catch (domain-model.md §N/§27).
  unique (id, organization_id)
);

comment on table public.drivers is
  'TENANT-OWNED operational resource. user_id is optional and ON DELETE SET NULL — a driver''s historical trip_assignments/trip_events remain valid even if the linked auth account is disabled or deleted (domain-model.md §H). Driver ≠ Auth User, Driver ≠ Membership.';

create trigger drivers_set_updated_at
  before update on public.drivers
  for each row execute function public.set_updated_at();

create trigger drivers_prevent_org_change
  before update on public.drivers
  for each row execute function public.prevent_organization_id_change();

create index drivers_organization_id_idx on public.drivers (organization_id);

-- Resolves auth.uid() → this org's Driver row for that user (current_driver_id()).
create index drivers_user_id_idx on public.drivers (user_id) where user_id is not null;

alter table public.drivers enable row level security;
