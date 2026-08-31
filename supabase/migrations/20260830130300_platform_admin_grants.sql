-- platform_admin_grants — global platform authority, entirely separate from
-- Organization Membership (domain-model.md §B entity 4, ZD-049).
-- Classification: SYSTEM-OWNED. No organization_id — this is deliberately
-- org-independent. Never writable by any ordinary authenticated role; see
-- the policies migration later in this phase for the (deliberate) absence
-- of any INSERT/UPDATE/DELETE policy for authenticated users.

create table public.platform_admin_grants (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  granted_by uuid references auth.users (id),
  granted_at timestamptz not null default now(),
  note text
);

comment on table public.platform_admin_grants is
  'SYSTEM-OWNED. No organization_id by design — platform authority is deliberately not organization-scoped. No authenticated-role policy grants INSERT/UPDATE/DELETE here at all (see rls_policies migration) — writes happen only via a trusted privileged path (service role), never a self-service action.';

alter table public.platform_admin_grants enable row level security;
