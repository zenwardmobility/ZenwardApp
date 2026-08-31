-- Zenward Platform — schema foundation, part 1: extensions and shared
-- infrastructure used by every tenant-owned table created in later
-- migrations in this same phase (P1-E2-S1). See docs/data/schema.md and
-- docs/security/rls-model.md for the full design rationale.

-- gen_random_uuid() for primary keys.
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Shared trigger: organization_id is immutable for ordinary roles.
-- ---------------------------------------------------------------------------
-- Authorization invariant (authorization-model.md §L, security invariant 5):
-- "organization_id is immutable for every ordinary role, on every
-- tenant-owned table, after row creation — with no exceptions." RLS
-- WITH CHECK clauses alone cannot fully guarantee this (an admin of two
-- organizations could otherwise satisfy both old- and new-org checks). A
-- BEFORE UPDATE trigger applied to every tenant-owned table makes this a
-- schema-level guarantee instead of a policy-logic guarantee.
create or replace function public.prevent_organization_id_change()
returns trigger
language plpgsql
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception 'organization_id is immutable and cannot be changed after row creation (table: %)', tg_table_name
      using errcode = '23514';
  end if;
  return new;
end;
$$;

comment on function public.prevent_organization_id_change() is
  'Blocks any UPDATE that changes organization_id. Attached via BEFORE UPDATE trigger to every tenant-owned table. Not bypassable by RLS policy logic — see authorization-model.md security invariant 5.';

-- ---------------------------------------------------------------------------
-- Shared trigger: maintain updated_at on tables that have one.
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Sets updated_at = now() on every UPDATE. Attached only to tables where updated_at is meaningful (lifecycle-model.md: not applied to append-only history tables like trip_events/audit_events).';
