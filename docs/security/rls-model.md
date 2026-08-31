# Zenward Platform — RLS Model

**Work item:** P1-E2-S1 — Supabase Schema + RLS Foundation, amended by P1-E2-S1A — SECURITY DEFINER Exposure Audit (two passes), amended by P1-E2-S2 — Controlled Mutation & Transaction Boundary (`trip_assignments` direct-write retirement, ZD-092)
**Status:** Implemented and tested locally. Not deployed to any remote/production project.
**Last updated:** 2026-08-31

**P1-E2-S2 update:** `trips.state` (still zero-grant below) is now reachable through the controlled mutation RPCs documented in [mutation-api.md](../data/mutation-api.md)/[mutation-authorization.md](./mutation-authorization.md) — the "intentional, temporary over-restriction" this document originally described is now resolved for lifecycle transitions, assignment, cancellation, and no-show. `trip_assignments` direct INSERT/UPDATE (previously granted below) is now revoked entirely (ZD-092) in favor of `assign_trip`/`reassign_trip`.

This document is the security layer on top of [schema.md](../data/schema.md). It implements exactly what [authorization-model.md](../product/authorization-model.md) confirmed. See [rls-test-matrix.md](./rls-test-matrix.md) for how every claim here was actually verified against a running local instance — not asserted from migration syntax alone.

## Baseline posture

Every one of the 15 tables has `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` in the same migration that creates it — confirmed by direct inspection (`pg_class.relrowsecurity = true` for all 15). This Supabase project's local config also has `auto_expose_new_tables` unset (the current default), meaning a freshly created table has **zero** privileges granted to `anon`/`authenticated` until explicitly granted — so before any policy migration ran, every table was already unreachable by any non-superuser role, through the complete absence of privilege, on top of RLS itself.

No table anywhere in this schema has any grant to the `anon` role. Public/anonymous access to every table is denied at two independent layers: no table privilege, and (redundantly) no matching RLS policy either.

## Policy inventory

52 policies were created in P1-E2-S1; P1-E2-S2 dropped 2 of them as superseded (ZD-092), leaving **50** active across 15 tables, all scoped `TO authenticated` (none to `anon`), none using a blanket `USING (true)`. Full list, table by table (see `supabase/migrations/20260830131700_rls_policies.sql` for the original SQL and `supabase/migrations/20260831100000_trip_assignment_privilege_tightening.sql` for the P1-E2-S2 change):

| Table | Policies |
|---|---|
| `organizations` | `organizations_select_members`, `organizations_select_platform_admin`, `organizations_update_org_admin` |
| `memberships` | `memberships_select_self`, `memberships_select_org_admin`, `memberships_insert_org_admin`, `memberships_update_org_admin` |
| `user_profiles` | `user_profiles_select_own`, `user_profiles_select_org_admin`, `user_profiles_insert_own`, `user_profiles_update_own` |
| `platform_admin_grants` | `platform_admin_grants_select_own`, `platform_admin_grants_select_platform_admin` |
| `drivers` | `drivers_select_org_operations`, `drivers_select_own`, `drivers_insert_org_admin`, `drivers_update_org_admin` |
| `passengers` | `passengers_select_org_operations`, `passengers_insert_org_operations`, `passengers_update_org_operations` — **no Driver policy of any kind** |
| `facilities` | `facilities_select_org_operations`, `facilities_insert_org_operations`, `facilities_update_org_operations` — no Driver policy |
| `vehicles` | `vehicles_select_org_operations`, `vehicles_select_assigned_driver`, `vehicles_insert_org_admin`, `vehicles_update_org_admin` |
| `transportation_requests` | `transportation_requests_select_org_operations`, `_insert_org_operations`, `_update_org_operations` — no anonymous policy of any kind |
| `trips` | `trips_select_org_operations`, `trips_select_assigned_driver`, `trips_insert_org_operations`, `trips_update_org_operations` |
| `trip_assignments` | `trip_assignments_select_org_operations`, `trip_assignments_select_own_driver` — **INSERT/UPDATE policies retired in P1-E2-S2 (ZD-092)**; all writes now go through `assign_trip`/`reassign_trip` |
| `trip_events` | `trip_events_select_org_operations`, `trip_events_select_assigned_driver` — **no INSERT/UPDATE/DELETE policy for any role** |
| `trip_notes` | `trip_notes_select_operations`, `trip_notes_select_assigned_driver_visible`, `trip_notes_insert_operations`, `trip_notes_insert_assigned_driver`, `trip_notes_update_operations` — no Driver UPDATE |
| `trip_exceptions` | `trip_exceptions_select_operations`, `trip_exceptions_select_assigned_driver`, `trip_exceptions_insert_operations`, `trip_exceptions_insert_assigned_driver`, `trip_exceptions_update_operations` — no Driver UPDATE (cannot resolve) |
| `audit_events` | `audit_events_select_org_admin`, `audit_events_select_platform_admin` — **no INSERT/UPDATE/DELETE policy for any role**; no Dispatcher or Driver SELECT |

Naming convention (authorization-model.md §U): `<table>_<action>_<actor>`.

## Field-level enforcement — column privileges, not just row policies

RLS alone controls *which rows* a query can touch — it says nothing about *which columns* an otherwise-authorized UPDATE can set. Several tables additionally use `REVOKE`/`GRANT (column list)` so that even an Organization Admin or Dispatcher, fully authorized at the row level, cannot touch fields that must stay machine- or privileged-path-only:

| Table | Grantable (client-editable) columns | Never grantable to `authenticated` |
|---|---|---|
| `trips` | `scheduled_pickup_at`, `appointment_at`, `pickup_description`, `destination_description`, `assistance_notes`, `instructions`, `pickup_facility_id`, `destination_facility_id` | `state`, `organization_id`, `passenger_id`, `request_id`, `completed_at`, `cancelled_at`, `cancellation_reason`, `no_show_at` |
| `trip_assignments` | **none** — INSERT/UPDATE fully revoked from `authenticated` in P1-E2-S2 (ZD-092); `ended_at`/`end_reason` were grantable here before this phase | everything, now — `assign_trip`/`reassign_trip` (SECURITY DEFINER) are the sole write path |
| `memberships` | `role`, `status` | `organization_id`, `user_id` |
| `organizations` | `name`, `status` | `id` |
| `drivers`, `passengers`, `facilities`, `vehicles` | their own descriptive/status fields | `organization_id` (and `id`) |

**Note on `trips` (original P1-E2-S1 text, now resolved by P1-E2-S2):** this was deliberately *more conservative* than the approved model strictly required at the time. `authorization-model.md` described Trip lifecycle transitions as eventually happening through a controlled RPC — that RPC didn't exist yet in P1-E2-S1 (work item §63 explicitly deferred it), so `state`/terminal-timestamp columns were revoked entirely rather than granted with policy logic alone trusted to prevent misuse. **P1-E2-S2 built that controlled mechanism** (`docs/data/mutation-api.md`) — `trips.state` and the terminal timestamp/reason columns are still not, and will never be, directly grantable to `authenticated`; they are reachable exclusively through the `SECURITY DEFINER` mutation RPCs, which is the intended permanent shape, not a temporary gap.

Verified directly: `information_schema.column_privileges` for `authenticated` on `trips`/`memberships`/`trip_assignments` shows exactly the columns above and no others (see the completion report).

## RLS helper functions

Five functions, `supabase/migrations/20260830131600_rls_helper_functions.sql`. All `SECURITY DEFINER`, all `STABLE`, all with an explicit `SET search_path = public, pg_temp`. Each answers exactly one narrow question and returns only a boolean or an identifier — never a raw tenant row.

| Function | Purpose | Returns |
|---|---|---|
| `is_org_member(org_id)` | Active membership check for the caller in a specific org | boolean |
| `has_org_role(org_id, roles[])` | Active membership + role-in-list check | boolean |
| `current_driver_id(org_id)` | Resolves the caller to their Driver.id **within that specific org** | uuid or null |
| `is_driver_assigned_to_trip(trip_id)` | Whether the caller (as a driver) has ever had an assignment (active or historical) on this trip | boolean |
| `is_platform_admin()` | Whether the caller holds a PlatformAdminGrant | boolean |

### Why SECURITY DEFINER is necessary, per function

All five read tables (`memberships`, `drivers`, `trip_assignments`, `platform_admin_grants`) that themselves have RLS enabled. Without `SECURITY DEFINER`, a policy calling `is_org_member()` from inside, say, the `organizations_select_members` policy would recursively re-apply the *calling user's own* restricted view of `memberships` while evaluating the helper — at best redundant, at worst incorrect or a source of recursive-RLS evaluation problems. `SECURITY DEFINER` lets each function run with the function owner's privilege for this one narrow, auditable lookup, and nothing else — it is not a general capability grant, since the function body is fixed, takes no dynamic SQL, and returns only a boolean/id.

### SECURITY DEFINER review (work item §57), function by function

| | `is_org_member` | `has_org_role` | `current_driver_id` | `is_driver_assigned_to_trip` | `is_platform_admin` |
|---|---|---|---|---|---|
| Purpose | Active org membership check | Active membership + role check | Resolve caller → Driver.id in one org | Caller has (ever) had an assignment on this trip | Caller holds a platform grant |
| Owner expectation | Migration-runner role (`postgres` in this local setup; the equivalent trusted migration role in any deployed environment) | same | same | same | same |
| `search_path` | `public, pg_temp` | `public, pg_temp` | `public, pg_temp` | `public, pg_temp` | `public, pg_temp` |
| Why SECURITY DEFINER is necessary | Reads RLS-protected `memberships` | same | Reads RLS-protected `drivers` | Reads RLS-protected `trips`/`drivers`/`trip_assignments` (via `current_driver_id`) | Reads RLS-protected `platform_admin_grants` |
| Can it expose tenant data? | No — returns boolean only | No — boolean only | Returns a Driver **id** only, never a Driver row, and only for the org explicitly passed in by the caller (never inferred/leaked across orgs) | No — boolean only | No — boolean only |
| Does it bypass RLS? | Only internally, for its own single-table lookup; the caller's actual query is still fully subject to RLS | same | same | same | same |
| Abuse tests covering it | RLS suite A–D, O, P, AA, AB, AC + exposure suite tests 1, 2, 5–10, 21 | same, + exposure suite tests 1, 2, 5–10, 21 | Exposure suite tests 3, 4, 10, 12, 22 (dedicated ID-disclosure deep check) | RLS suite E–K, AD, AE + exposure suite tests 1, 3, 4, 11 | Exposure suite tests 1, 13, 14 (positive check + confirms Org Admin role has zero influence) |

No helper needing only `SECURITY INVOKER` semantics was implemented as `SECURITY DEFINER` — all five genuinely need it for the reason above.

## RPC exposure policy (P1-E2-S1A)

Every public-schema function is potentially reachable as a Supabase RPC endpoint (`/rest/v1/rpc/<function>`) the moment any role has EXECUTE on it — a function "returning a safe value" is not the same claim as "this function should be public API surface," and this schema does not conflate the two. Verified directly against the local PostgREST endpoint using genuinely GoTrue-issued tokens (not simulated): `anon` gets a hard permission-denied on every helper (HTTP 401/`42501`); an authenticated user only ever gets back their own scoped boolean/identifier, never another user's or another organization's, for every helper and every actor tested (see [rls-test-matrix.md](./rls-test-matrix.md) for the full matrix). The two trigger-support functions (`set_updated_at`, `prevent_organization_id_change`) are additionally confirmed **not listed at all** in PostgREST's own schema cache — `RETURNS trigger` functions are never exposed as RPC routes regardless of privilege, and Postgres independently refuses a direct call to one ("trigger functions can only be called as triggers"). Their `PUBLIC` EXECUTE grant was still revoked (migration `20260831090000`) — belt-and-suspenders, not required by the RPC-exposure finding alone.

**Rule for every future SECURITY DEFINER or RPC-reachable function:** `EXECUTE` starts denied to everyone. A function is exposed to `authenticated` only if an actual RLS policy needs to call it, or a genuine, reviewed API need exists — never by leaving PostgreSQL's default PUBLIC grant in place. See "Future function privilege convention" below for the exact required migration shape.

## Public schema CREATE — verified, not assumed

`anon`, `authenticated`, `service_role`, and bare `PUBLIC` all have `USAGE` but **not** `CREATE` on the `public` schema — confirmed directly via `has_schema_privilege()` for every role, not inferred from Supabase's documented defaults. Only `postgres` (via `pg_database_owner` membership) can create objects in `public`. This is the precondition that makes every SECURITY DEFINER helper's `search_path = public, pg_temp` safe: no untrusted role can create a same-named function/table in `public` to shadow an unqualified reference inside a SECURITY DEFINER function body. Re-verified as a standing regression assertion in `supabase/tests/security_definer_exposure_tests.sql` (tests 15–17) and `function_privilege_tests.sql`.

## Future function privilege convention (mandatory)

`ALTER DEFAULT PRIVILEGES` is deliberately **not** used to pre-grant or pre-revoke EXECUTE for functions not yet written. That command is scoped to a specific creator role, and this project cannot safely assume the local migration-runner role (`postgres`, in this Docker-based local setup) is identical to whatever role runs migrations in a future hosted/deployed environment — applying a role-specific default-privilege rule against a role that turns out to be the wrong one would silently fail to protect anything. Instead, the following is a **mandatory migration convention**, not a database mechanism:

> Every new migration that creates a `SECURITY DEFINER` function, or any function intended to be callable via Supabase RPC, must explicitly:
> ```sql
> revoke execute on function <exact_signature> from public;
> grant execute on function <exact_signature> to <only the roles that genuinely need it>;
> ```
> in the **same migration** that creates the function — never left to a later "hardening" migration, and never assumed safe because "Supabase revokes public exposure by default" (that default — `auto_expose_new_tables` — governs *table* auto-exposure, not a function's own PostgreSQL EXECUTE ACL, which still defaults to PUBLIC per standard PostgreSQL behavior unless explicitly revoked).

This is exactly the gap the P1-E2-S1A audit found (the two trigger-support functions had never had their default PUBLIC grant revoked) and exactly the rule that would have prevented it.

## Driver data minimization (ZD-080, non-negotiable)

**Driver has no generic direct SELECT on the `passengers` table — not even one scoped to "the passenger on my assigned trip."** There is no `passengers_select_assigned_driver` policy anywhere in this migration set, confirmed by direct inspection of `pg_policies` (exactly three policies exist on `passengers`, all `_org_operations`, none mentioning Driver). This is deliberate, not an oversight: **RLS controls rows, not columns** — even a row-scoped Driver policy would return every column in the passenger row, and a Passenger record's sensitive fields (assistance notes, phone) are exactly the kind of over-exposure minimum-necessary access is supposed to prevent.

**What this phase leaves deferred, explicitly, per instruction:** the actual mechanism a driver will eventually use to get the minimum-necessary passenger information for an assigned trip (name, phone where operationally required, pickup/destination, assistance/companion info, driver-visible instructions) is not built here. The three candidate shapes remain: a narrowly-scoped `SECURITY INVOKER` view, a scoped RPC, or a trusted server-side query — each would still need to verify the full chain (`auth.uid()` → active Membership → linked Driver → same Organization → active/relevant TripAssignment → permitted Trip) and return only an explicit, minimal field list, never a full Passenger row. Building this is out of scope for P1-E2-S1; a driver currently has **zero** path to passenger information through this schema, which is the conservative, correct state to leave things in until that read model is deliberately designed.

## Security assumptions

- **RLS is the authorization boundary.** Nothing in the application layer (once built) is trusted as a substitute for what's enforced here.
- **`auth.uid()` reflects the live JWT `sub` claim per request** — Supabase (PostgREST) sets `request.jwt.claim.sub`/`request.jwt.claims` per request from the verified token; there is no session-long cached role/org context inside Postgres itself. Combined with `is_org_member()`/`has_org_role()` always querying `memberships` live (never a cached claim), this is what makes membership deactivation take effect immediately (ZD-077) — see the "inactive membership" tests (O, AB), both passing.
- **The service-role key is system authority, not an application role.** No migration in this phase grants anything special to `service_role` beyond what it inherently has (`BYPASSRLS`) — it is not used as a substitute for real RLS anywhere in this schema, and no application code path is wired up yet that would use it (work item §60). Confirmed directly (P1-E2-S1A): `service_role` has **no explicit EXECUTE grant** on any of the 5 RLS helpers either — it doesn't need them, since it bypasses RLS entirely and would query tables directly if it ever needed equivalent logic; this is correctly zero exposure and zero functional gap, not an oversight.
- **Multi-organization users are supported by construction**, not as an afterthought: every policy is written against `has_org_role(<the specific row's organization_id>, ...)`, never a cached "current org" — confirmed directly by test P (an org_admin-in-A/driver-in-B user gets admin-level access in A and only self-row access in B, in the same session) and by the exposure suite's dedicated multi-org driver-resolution test (test 22).

## Storage (not built)

No Supabase Storage bucket is created in this phase. Restated as the required invariant: **Storage security must eventually derive from the same Organization/Membership/Driver-assignment/visibility rules as this document, and database RLS does not secure Storage automatically.** Storage remains its own explicit, later security gate.

## What's deliberately NOT solved yet

- ~~Trip lifecycle-transition RPCs~~ — **built in P1-E2-S2**, see [mutation-api.md](../data/mutation-api.md).
- ~~Assignment/reassignment RPCs~~ — **built in P1-E2-S2** (`assign_trip`/`reassign_trip`); the plain INSERT/UPDATE policies this line used to describe were retired in the same phase (ZD-092).
- The driver → passenger projection (see above) — still deferred; unaffected by P1-E2-S2.
- `trip_events`/`audit_events` INSERT for any *human* role directly — still true; both tables are written only from inside the P1-E2-S2 `SECURITY DEFINER` mutation functions, never via a direct client grant to `authenticated`.
- Public transportation-request intake (no anonymous INSERT policy exists — deferred per ZD-044/ZD-050 and this work item's explicit instruction not to add one merely to support the marketing site). Unaffected by P1-E2-S2.
