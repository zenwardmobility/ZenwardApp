-- audit_events — administrative/security mutation history, distinct from
-- trip_events' business/transportation lifecycle (domain-model.md §B
-- entity 15). Classification: SYSTEM-OWNED. No ordinary role — including
-- Organization Admin — writes this table directly; see rls_policies for
-- the deliberate absence of any authenticated INSERT/UPDATE/DELETE grant.
-- entity_type/entity_id is a generic polymorphic reference (documented in
-- domain-model.md §26 as not FK-able by construction) — organization_id is
-- still direct and required for scoped reads.

create table public.audit_events (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  actor_user_id uuid references auth.users (id),
  occurred_at timestamptz not null default now(),
  before_data jsonb,
  after_data jsonb,
  reason text
);

comment on table public.audit_events is
  'SYSTEM-OWNED. Append-only forever — no authenticated role ever gets INSERT/UPDATE/DELETE on this table in this phase; writes will come from a trusted trigger/function in a later phase. SELECT is organization_id-scoped for Organization Admin, all-organization for Platform Admin; Dispatcher and Driver get none.';

create index audit_events_org_occurred_idx on public.audit_events (organization_id, occurred_at);
create index audit_events_entity_idx on public.audit_events (entity_type, entity_id);

alter table public.audit_events enable row level security;
