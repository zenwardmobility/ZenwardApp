-- organizations — the tenant root (domain-model.md §B entity 1).
-- Classification: SYSTEM-OWNED (creation/root control is a platform-level
-- action, not a normal-user capability — see authorization-model.md §E).

create table public.organizations (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.organizations is
  'Tenant root. SYSTEM-OWNED — ordinary roles never INSERT/DELETE here; only UPDATE their own organization''s settings once RLS policies are added in a later migration in this phase.';

create trigger organizations_set_updated_at
  before update on public.organizations
  for each row execute function public.set_updated_at();

-- Deny-by-default immediately: RLS is enabled in the same migration that
-- creates the table (security invariant, decision register ZD-038/ZD-042).
-- Zero policies exist yet — every role is denied every operation until the
-- policies migration later in this same phase adds narrow, named grants.
alter table public.organizations enable row level security;
