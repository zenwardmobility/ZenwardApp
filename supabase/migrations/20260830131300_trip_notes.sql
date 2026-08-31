-- trip_notes — human-authored contextual information (domain-model.md §B
-- entity 13, ZD-048). Classification: TENANT-OWNED, direct organization_id.
--
-- Exactly two visibility values, database-constrained — no others
-- (operations_only, driver_visible). Only authorized operations roles may
-- change an existing note's visibility (enforced in rls_policies: no
-- UPDATE policy for driver at all).

create table public.trip_notes (
  id uuid primary key default extensions.gen_random_uuid(),
  organization_id uuid not null references public.organizations (id),
  trip_id uuid not null,
  author_user_id uuid references auth.users (id),
  visibility text not null check (visibility in ('operations_only', 'driver_visible')),
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (trip_id, organization_id) references public.trips (id, organization_id)
);

comment on table public.trip_notes is
  'TENANT-OWNED. visibility is exactly operations_only | driver_visible (ZD-048) — no patient_visible/requester_visible/facility_visible/private_driver. Driver may INSERT driver_visible notes on their own assigned trip only (see rls_policies); driver can never UPDATE (reclassify) any note.';

create trigger trip_notes_set_updated_at
  before update on public.trip_notes
  for each row execute function public.set_updated_at();

create trigger trip_notes_prevent_org_change
  before update on public.trip_notes
  for each row execute function public.prevent_organization_id_change();

create index trip_notes_trip_id_idx on public.trip_notes (trip_id);
create index trip_notes_trip_visibility_idx on public.trip_notes (trip_id, visibility);

alter table public.trip_notes enable row level security;
