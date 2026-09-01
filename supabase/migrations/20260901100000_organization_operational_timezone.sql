-- Organization operational timezone (P1-E3-S2C).
--
-- Driver Today (P1-E3-S2) computed "today"/displayed times using whichever
-- timezone the Next.js server process happens to run in — cosmetically fine
-- in local dev (server and org both effectively "local"), but operationally
-- wrong the moment server and organization disagree (e.g. a UTC-hosted
-- server serving an America/New_York organization: an 11:30 PM local trip
-- would be grouped onto the wrong calendar day). This migration adds the
-- canonical, organization-owned source of truth for that interpretation —
-- an IANA timezone identifier, never a fixed offset or abbreviation, so
-- daylight-saving transitions are always resolved correctly by Postgres's
-- (and later, JavaScript's Intl) own timezone database, not a hand-rolled
-- rule. Trip/TripAssignment/etc. timestamps remain exactly what they always
-- were — `timestamptz`, UTC-normalized absolute instants — nothing about
-- storage changes; only how an instant is projected onto a *calendar day*
-- for operational purposes changes, and only by finally doing it correctly.

-- =============================================================================
-- Narrow IANA-timezone validator
-- =============================================================================
-- `pg_timezone_names` is Postgres's own catalog of every zone name its
-- loaded tzdata recognizes — but it also contains legacy/ambiguous
-- backward-compatibility entries Postgres accepts for historical reasons
-- (e.g. `EST`, `PST8PDT`, `Japan`, `GMT-0`) that are exactly the class of
-- value this work item explicitly requires rejecting (a fixed-offset/
-- no-DST-aware abbreviation, not a real geographic zone). A canonical IANA
-- zone name is always `Area/Location` (`America/New_York`), with the sole
-- widely-used exception of the unambiguous, DST-free `UTC` itself. This
-- function requires one of those two shapes AND catalog membership, which
-- together reject every example this work item names (EST, EDT, GMT-5,
-- "Georgia", "Eastern") while accepting every example it requires
-- (America/New_York, America/Chicago, America/Los_Angeles) — verified
-- directly against a live Postgres instance before this migration was
-- written (see docs/reports/P1-E3-S2C-operational-timezone-report.txt §3).
--
-- STABLE, not IMMUTABLE — it genuinely queries a system catalog (tzdata),
-- which is the correct honest volatility category even though that catalog
-- only changes on a Postgres/OS upgrade. No SECURITY DEFINER: it needs no
-- elevated privilege at all — `pg_timezone_names` is a public system view
-- any role may already query directly. Never granted as a callable RPC
-- (revoked from `public` below, matching this project's established
-- pattern for internal-only helpers — e.g. `_is_valid_trip_transition`,
-- 20260831100200_controlled_trip_mutations.sql) — it exists solely to back
-- the CHECK constraint below, not as an application-facing endpoint.
create or replace function public.is_valid_iana_timezone(p_timezone text)
returns boolean
language sql
stable
set search_path = pg_catalog, public
as $$
  select p_timezone is not null
    and (p_timezone = 'UTC' or p_timezone like '%/%')
    and exists (select 1 from pg_timezone_names where name = p_timezone);
$$;

comment on function public.is_valid_iana_timezone(text) is
  'Narrow validator: true only for UTC or a genuine Area/Location IANA zone name present in this server''s tzdata. Backs organizations.timezone''s CHECK constraint. EXECUTE is granted to authenticated (see below) — required, not optional: PostgreSQL re-validates every CHECK constraint on a row for ANY UPDATE to that row, regardless of which columns actually changed, under the privileges of the role performing the UPDATE (not the table owner) — so an Organization Admin updating only organizations.status would fail with "permission denied for function" if authenticated could not execute this validator, even though they never touch timezone. Confirmed empirically before this grant was added (see docs/reports/P1-E3-S2C-operational-timezone-report.txt §3). This function reveals nothing sensitive if called directly (it only echoes a boolean about Postgres''s own public tzdata catalog — no different from a client checking Intl.supportedValuesOf("timeZone") itself) — unlike the SECURITY DEFINER helpers elsewhere in this schema, granting it broadly carries no real exposure risk. anon/service_role are not granted — no legitimate caller in either role needs it.';

revoke all on function public.is_valid_iana_timezone(text) from public;
grant execute on function public.is_valid_iana_timezone(text) to authenticated;

-- =============================================================================
-- organizations.timezone
-- =============================================================================
-- No product-wide geographic default (work item §5) — every organization
-- must state its own operational timezone explicitly. NOT NULL with no
-- default forces exactly that for any future INSERT; existing rows are
-- backfilled deliberately below, per-row, not defaulted en masse.
alter table public.organizations
  add column timezone text;

alter table public.organizations
  add constraint organizations_timezone_valid_iana
  check (public.is_valid_iana_timezone(timezone));

comment on column public.organizations.timezone is
  'IANA timezone identifier (e.g. America/New_York) — the organization''s own operational timezone, the sole authority for interpreting a trip''s timestamptz as a calendar day/local time for that organization''s operations. Never a fixed offset or abbreviation (rejected by the CHECK constraint) so daylight-saving transitions stay correct automatically. Backfilled per-row for existing organizations at migration time (see 20260901100000); NOT NULL enforced immediately after backfill so no organization is ever left with an ambiguous operational timezone.';

-- Deliberate backfill for every organization that existed before this
-- migration. This project has exactly two organizations at this point in
-- its history (both Georgia-launch fixtures — see seed.sql), so
-- America/New_York is the correct, deliberate value for THESE SPECIFIC
-- rows — not a silent product-wide default (work item §5/§7). A
-- geographically distinct future organization gets its own explicit
-- timezone at creation time; this UPDATE never runs again.
update public.organizations
  set timezone = 'America/New_York'
  where timezone is null;

alter table public.organizations
  alter column timezone set not null;
