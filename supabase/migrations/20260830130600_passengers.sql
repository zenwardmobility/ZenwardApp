-- passengers — the person being transported (domain-model.md §B entity 6).
-- Classification: TENANT-OWNED, direct organization_id. No user_id — no
-- passenger self-service login is assumed anywhere in current scope.
--
-- *** CRITICAL, NON-NEGOTIABLE RULE (ZD-080) ***
-- Driver receives NO generic direct SELECT on this table, under any RLS
-- policy shape — not even one scoped to "the passenger on my assigned
-- trip." See the rls_policies migration: there is deliberately no
-- passengers_select_assigned_driver policy anywhere in this phase.
-- Row Level Security controls rows, not columns — a row-scoped policy
-- would still return every column. Driver-required passenger information
-- will come later through a controlled, assignment-scoped projection
-- (view/RPC/trusted query), never a table grant. See
-- docs/security/rls-model.md "Driver data minimization" for the full
-- rationale and docs/data/schema.md for the deferred read-model note.

create table public.passengers (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  display_name text not null,
  phone text,
  assistance_notes text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id)
);

comment on table public.passengers is
  'TENANT-OWNED. HIGH RLS RISK (domain-model.md §C). CRITICAL: no Driver SELECT policy exists or should ever be added directly against this table — see ZD-080. No user_id — passenger self-service accounts are not part of current scope.';

create trigger passengers_set_updated_at
  before update on public.passengers
  for each row execute function public.set_updated_at();

create trigger passengers_prevent_org_change
  before update on public.passengers
  for each row execute function public.prevent_organization_id_change();

create index passengers_organization_id_idx on public.passengers (organization_id);

alter table public.passengers enable row level security;
