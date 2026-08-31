-- user_profiles — thin, org-independent extension of the auth identity
-- (domain-model.md §B entity 3). Classification: USER-OWNED. No
-- organization_id, no role, no platform-admin flag — those live on
-- memberships / platform_admin_grants (authorization-model.md §B/§D).

create table public.user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.user_profiles is
  'USER-OWNED. Deliberately has no organization_id, role, or admin flag — tenant access lives entirely in memberships/platform_admin_grants, never here.';

create trigger user_profiles_set_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();

alter table public.user_profiles enable row level security;
