-- memberships — auth user × organization × role (domain-model.md §B entity
-- 2). This is the root of all tenant RLS evaluation — never
-- users.organization_id (authorization-model.md §P). Classification:
-- TENANT-OWNED, direct organization_id.

create table public.memberships (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('organization_admin', 'dispatcher', 'driver')),
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- One logical membership per (user, organization) — a role change updates
  -- this row, it never creates a second one (ZD-039/ZD-073).
  unique (organization_id, user_id)
);

comment on table public.memberships is
  'TENANT-OWNED. Approved MVP roles only: organization_admin, dispatcher, driver — no operations_staff (ZD-072), no platform_admin value (that is platform_admin_grants, entirely separate — ZD-049). status=inactive must grant zero access; see is_org_member()/has_org_role() in the rls_helper_functions migration, which check status live on every evaluation.';

create trigger memberships_set_updated_at
  before update on public.memberships
  for each row execute function public.set_updated_at();

create trigger memberships_prevent_org_change
  before update on public.memberships
  for each row execute function public.prevent_organization_id_change();

-- Fast "is this user an active member of this org, with which role" lookup
-- — the single most frequently evaluated query in the entire RLS model,
-- since every helper function (is_org_member, has_org_role) runs it.
create index memberships_user_org_active_idx
  on public.memberships (user_id, organization_id)
  where status = 'active';

create index memberships_organization_id_idx on public.memberships (organization_id);

alter table public.memberships enable row level security;
