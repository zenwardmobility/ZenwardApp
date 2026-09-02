# Zenward Platform — Mutation Authorization Architecture

**Work item:** P1-E2-S2 — Controlled Mutation & Transaction Boundary
**Status:** Implemented and verified. See [mutation-api.md](../data/mutation-api.md) for the per-function contract and [rls-test-matrix.md](./rls-test-matrix.md)/completion report for full test results.
**Last updated:** 2026-08-31

This document explains *why* the mutation layer is built the way it is — the security reasoning behind [mutation-api.md](../data/mutation-api.md)'s contract. It assumes familiarity with [rls-model.md](./rls-model.md) (the baseline RLS/column-privilege posture this phase builds on without weakening).

## The hard rule this phase implements

Before this phase, `trips.state` had zero grant to `authenticated` at all, `trip_events`/`audit_events` had no INSERT grant to any human role, and `trip_assignments` writes went through raw RLS-gated INSERT/UPDATE (the only path available before a controlled mechanism existed). This phase closes that gap **without ever widening a table grant to close it** — every actual write below happens inside a `SECURITY DEFINER` function owned by `postgres`, which can write these privilege-restricted columns/tables regardless of what `authenticated` itself is granted, because `SECURITY DEFINER` executes as the function's owner, not the caller. The client-facing surface is the function's own parameter list and internal validation, not a table grant.

```
client → controlled RPC (SECURITY DEFINER, narrow validated inputs) → privileged write
```

never

```
client → direct INSERT/UPDATE against a privilege-restricted column/table
```

Confirmed by direct inspection after this phase: `trips.state` still has no grant to `authenticated`; `trip_assignments` INSERT/UPDATE is now explicitly revoked (ZD-092, it *did* have a grant before this phase and no longer does); `trip_events`/`audit_events` still have no INSERT grant to any human role.

## Internal helper propagation — why the internal executor is safe unexposed

The 6 Driver transition wrappers share one internal function, `_driver_execute_trip_transition`, which *does* accept a free-form from/to state pair. That function has **no** `EXECUTE` grant to `authenticated`/`anon`/`PUBLIC` — only its owner (`postgres`) can invoke it directly. This is safe specifically because:

- Both the 6 wrappers and the internal function are `SECURITY DEFINER`, owned by `postgres`.
- When `authenticated` calls a wrapper (which *is* granted `EXECUTE`), Postgres switches the *effective identity for the wrapper's entire execution* to the wrapper's owner (`postgres`) — including every function the wrapper itself calls from within its body.
- So when the wrapper calls `_driver_execute_trip_transition`, that nested call happens **as `postgres`**, which always has implicit privilege to execute a function it owns — no explicit grant to `authenticated` is needed or present.
- If `_driver_execute_trip_transition` were instead `SECURITY INVOKER` (or the wrappers were), the nested call would run as whatever identity is *currently* in charge at that point in the call chain, which would still often resolve correctly — but making **both** layers `SECURITY DEFINER` removes any ambiguity and is the pattern this codebase now uses consistently. Getting this backwards — granting `EXECUTE` on the internal function directly, "just to be safe" — would let any `authenticated` client call it with an **arbitrary** from/to pair, bypassing every wrapper's fixed-edge design entirely. `mutation_privilege_tests.sql`'s "internal-helpers-not-exposed" check exists specifically to catch that regression.

The same reasoning applies to `_is_valid_trip_transition` (no elevated privilege even needed — it touches no table) and `_lock_driver_active_assignment`.

## `not_found` vs `unauthorized` — the anti-oracle convention (ZD-085 context)

Two failure shapes exist, deliberately kept distinct:

- **`ZW002 not_found`** — used whenever the caller could not have legitimately discovered the resource's existence through their own normal RLS-granted visibility. A nonexistent Trip and a Trip in an org the caller has no relationship to produce the *identical* error — no existence oracle. For ops functions, `has_org_role` failing for *any* reason (wrong org, or right org but role=`driver`) is uniformly `not_found`, because Organization Admin/Dispatcher are the *only* two roles with ops-level Trip visibility in the first place — a Driver in the same org has zero RLS visibility into ops actions either, so `not_found` correctly mirrors what they could otherwise see.
- **`ZW001 unauthorized`** — used only when the caller *does* have a real, RLS-visible relationship to the specific resource, but lacks the specific action-level permission on it right now. The one case this applies to: a Driver who has *ever* had an assignment on a Trip (so `trips_select_assigned_driver` lets them see it) but has no *currently active* assignment (so they can't act on it — it was reassigned away, or the Trip already reached a terminal state that closed it). They can see the Trip; they just can't act on it anymore. Revealing that distinction to them is safe and more useful than a blanket `not_found`, because they already legitimately know the Trip exists.

This required building a strictly *write*-scoped variant of assignment-checking (`_lock_driver_active_assignment`, "currently active") distinct from the existing *read*-scoped `is_driver_assigned_to_trip` ("ever assigned") — exactly the gap that function's own P1-E2-S1 comment flagged as deferred to this phase.

## Idempotent no-op is actor-scoped, not relationship-scoped (ZD-093)

A subtler version of the same anti-oracle problem surfaced in a dedicated follow-up audit (P1-E2-S2A): the idempotent no-op path ("the Trip is already at my target state") originally fired for *any* Driver who passed the ever-assigned gate, with no check on *who* actually caused that state. Two different Drivers can each satisfy "ever assigned" on the same Trip — one historical, one current. A formerly-assigned Driver retrying an action that a *different* Driver performed after a reassignment would have received a false `changed: false` success, purely because the desired state happened to already exist for an unrelated reason.

The fix: the no-op path additionally requires that a `trip_events` row exists for this Trip, with `event_type` equal to this function's own target event and `actor_user_id = auth.uid()` — trusted, append-only proof that *this caller* is the one who performed that exact transition. `auth.uid()` is the same source of identity used everywhere else in this codebase; no caller-supplied actor id is introduced. A caller who fails this check falls through to the ordinary active-assignment/from-state checks, which correctly deny them (`ZW001`, since a caller in this position can never still hold the Trip's active assignment either — if they did, they would be the one who performed the transition and would already have matched).

This is confined to the Driver-transition family. Ops actions (`cancel_trip`/`record_no_show`/`assign_trip`/`reassign_trip`) authorize by live-checked, org-scoped role, not trip-instance-specific personal identity — any currently-authorized Organization Admin/Dispatcher may legitimately re-assert an already-true org-level fact (e.g. retry cancelling a Trip their colleague already cancelled), which is intended behavior, not a gap. See ZD-093 and `docs/reports/P1-E2-S2A-idempotent-authorization-audit.txt` for the full audit.

## Platform Admin is not a mutation bypass

`is_platform_admin()` is never consulted by any mutation RPC's authorization chain — only `has_org_role`/`is_org_member`/the Driver assignment checks are. A Platform Admin with zero Memberships gets `ZW002 not_found` on every mutation RPC, on every organization's Trips, exactly like any other non-member (verified: `mutation_authorization_tests.sql` D1, `rpc_probe.js` HTTP-9). Platform Admin's authority is read-only and table-scoped per the existing 4-table boundary (domain-model.md); extending it into mutation would need its own explicit, separately-reviewed decision — it was never assumed here.

## Live authorization, not cached claims

Every check re-evaluates `memberships.status`/`role` and `drivers.status`/`trip_assignments.ended_at` live, on every call, the same way the existing RLS helpers do (ZD-077) — there is no session-cached or JWT-claim-derived authorization anywhere in this layer. An inactive Dispatcher Membership loses mutation ability on their very next call, with no session expiry or re-login required (verified: `mutation_authorization_tests.sql` D2, `rpc_probe.js` HTTP-8).

## Multi-tenant role scoping

`has_org_role`/Driver-assignment checks are always evaluated against the *specific* `organization_id` resolved from the Trip row being acted on — never "does this user hold this role anywhere." A user who is `organization_admin` in Org A and `driver` in Org B gets `ZW002` attempting either role's mutation actions against the other organization's Trips (verified: `mutation_authorization_tests.sql` D3/D4).

## Trip creation authorization (P1-E3-S0A, ZD-101/ZD-102)

`create_trip` closes a gap that predates every phase above it: `trips` INSERT was granted to `authenticated` without column restriction from the very first schema migration (P1-E2-S1) — unlike UPDATE, which was narrowed to specific planning columns in the same phase. A raw client INSERT could set `state` to any value at creation, bypassing the entire lifecycle model this document otherwise describes. This was found, not designed around, during P1-E3-S0's UI mapping work (GAP-1) when a real "New Trip" screen exposed the question of how Trip creation should actually be authorized.

The fix follows the identical pattern as every function above it, with one important structural difference: **the resource being authorized does not exist yet.** Every other function in this document resolves its organization from an existing row (`SELECT ... FOR UPDATE`, then check the row's `organization_id`). `create_trip` cannot do that — `p_organization_id` is a caller-*requested* context, not yet an authoritative fact about anything. The same `has_org_role` live check applies regardless, and the same consequence follows: **the caller choosing an organization UUID never grants authority over it** — a foreign-org Admin/Dispatcher gets the identical `ZW002 not_found` as a Driver or an inactive Membership, exactly as it would if the resource already existed.

Every referenced entity supplied by the caller — Passenger, Facility, TransportationRequest — is independently validated for tenant consistency (same `organization_id` as the validated context) before the Trip is ever inserted, using the same `ZW006 invalid_input`, no-existence-oracle categorization already established for `assign_trip`'s Driver/Vehicle checks (ZD-085). `state` itself is not merely validated — it is not a parameter at all, so there is no input to reject; the initial value is a Postgres literal inside the function body, structurally unreachable by any caller regardless of what they send.

## Driver location write authorization (P1-E3-S7A)

`driver_record_location` reuses the existing Driver-mutation authorization primitives exactly, adding one new dimension: **Trip lifecycle-state eligibility**, not present in any prior mutation family. `_lock_driver_active_assignment()` (built in P1-E2-S2, anticipated in `is_driver_assigned_to_trip`'s own original comment as "a future requirement of this exact phase") already provides the strict active-assignment check every write here needs — reused verbatim, not reimplemented. The state-eligibility check (5 states: `en_route_to_pickup` through `arrived_at_destination`) reuses the existing `ZW004 illegal_transition` category — semantically "this action is not valid given the Trip's current lifecycle state," the same category `cancel_trip`/`record_no_show` already use for their own state-eligibility checks, even though a location update is not itself a state transition.

This RPC is the first in this document's own history that intentionally does NOT write `trip_events`/`audit_events` — a location update is a routine, high-frequency operational signal, not a lifecycle transition or a material administrative action (ZD-087's own test), so it is deliberately excluded from that matrix rather than silently omitted.

## Trip exception authorization (P1-E3-S8)

`report_trip_exception`/`resolve_trip_exception` are the first RPC pair in this document built to *replace* a set of pre-existing direct RLS policies rather than close a gap where none existed. Inspecting `trip_exceptions_insert_operations`/`_insert_assigned_driver`/`_update_operations` (all present since P1-E2-S1) found the Driver-INSERT policy already narrow and safe (org match, `is_driver_assigned_to_trip`, `created_by`/`status` forced) — reusable as-is — but the Operations-INSERT policy left `created_by` and `status` fully caller-controlled (an impersonation/fabricated-history risk), and the UPDATE policy had no column restriction at all (a raw UPDATE could rewrite `exception_type`/`description`/`created_by` on a resolved historical row, or silently reopen it). Rather than split the write path across two different mechanisms for the same logical action (Driver via RLS, Operations via RPC), both actor populations now go through the same controlled RPC pair — the identical "prefer the path that is easiest to prove safe" reasoning P1-E3-S7A already established for `driver_record_location`.

`report_trip_exception` originally kept the dual-actor shape the RLS policies already had (Operations `organization_admin`/`dispatcher`, any Trip in their org; OR the Trip's own ever-assigned Driver, via `is_driver_assigned_to_trip` — the same non-strict "ever assigned," not "currently assigned," population `trip_notes` already uses). **P1-E3-S8A tightened the Driver population** — see the dedicated section below; the dual-actor shape itself (Operations OR Driver) is unchanged. `resolve_trip_exception` is Operations-only, matching the schema's own original column comment ("only Dispatcher/Organization Admin resolve — Driver never during MVP") — there is no Driver resolve path at any layer.

`resolve_trip_exception` is also the first idempotent RPC in this document whose no-op contract is deliberately looser than `reassign_trip`'s established fail-closed staleness precedent (P1-E3-S5B, ZD-093's "actor-scoped, not relationship-scoped" idempotency). A second resolve of an already-resolved exception is a safe no-op that returns the real, already-persisted resolution untouched (`changed=false`) rather than raising a conflict — reasoned as correct specifically for this action because two resolutions of the same exception can never disagree about the operationally relevant fact ("is this handled?"), unlike a reassignment's driver/vehicle choice, which can.

Neither RPC writes an `audit_events` row — reporting or resolving an operational exception does not "materially change responsibility or reach a terminal disposition" of the Trip itself (ZD-087's own literal test), matching the already-established precedent that `trip_notes` writes no AuditEvent either. Both RPCs write one `trip_events` row each (`exception_flagged`/`exception_resolved`) — values allow-listed in `trip_events`' own CHECK constraint since the first schema migration but unused until this phase.

## Exception mutation boundary hardening (P1-E3-S8A)

S8's own completion report flagged that it deliberately left the pre-existing direct `trip_exceptions` INSERT/UPDATE policies in place rather than retiring them, reasoning that narrowing them correctly would require rebuilding the same column-restriction logic the RPCs already provide. On reflection, that left a real gap: **"the UI doesn't call the direct table mutation" is not a security boundary** — any legitimately authenticated Operations (or Driver) user could still write `trip_exceptions` directly via PostgREST/the Supabase client, bypassing `created_by`/`status` forcing on create and bypassing the entire resolve contract (reopening a resolved exception, rewriting historical fields) on update. S8A closes this the same way P1-E2-S2 closed the identical gap for `trip_assignments` (ZD-092) and P1-E3-S0A closed it for `trips` (ZD-101): the three superseded policies (`trip_exceptions_insert_operations`, `trip_exceptions_insert_assigned_driver`, `trip_exceptions_update_operations`) are dropped and `INSERT`/`UPDATE` are revoked from `authenticated` on the table entirely. `report_trip_exception`/`resolve_trip_exception` are now structurally the *only* way any normal actor writes this table — proven directly (not merely argued) by a dedicated bypass test suite (`exception_mutation_boundary_tests.sql`) covering direct INSERT/UPDATE/DELETE, forged `created_by`, forged pre-resolved `status`, reopening a resolved row, and historical-field rewriting, for both Operations and Driver actors, same-org and foreign-org. DELETE was never granted to `authenticated` by any migration — verified explicitly rather than left an unstated assumption.

The same phase also tightened `report_trip_exception`'s Driver authorization from `is_driver_assigned_to_trip` (READ-scope, "ever assigned" — the same population `trip_notes` still uses, since a Note is a lower-stakes, append-only remark) to `_lock_driver_active_assignment` (WRITE-scope, "currently assigned" — the identical primitive `driver_record_location` already uses). A Driver who has been reassigned away, or whose Trip has reached a terminal state, is denied immediately, same session, no re-login — proven directly (`DRV-2`/`DRV-5-TERMINAL` in the new test file). No separate explicit "Trip is not terminal" branch was added to the function: every path that reaches a terminal state (`driver_complete_trip`, `cancel_trip`, `record_no_show`) already closes the Trip's active `trip_assignments` row in the same transaction as the state change, so requiring a currently-active assignment is already structurally sufficient to exclude every terminal Trip for Driver reporting. A second, separate terminal check was considered and rejected: placed after the assignment check it would be unreachable dead code (no terminal Trip can have an active assignment); placed before it, it would leak Trip existence/terminal-status to a foreign-org caller who has proven no relationship to the Trip yet — the opposite of the "no existence oracle" convention this document establishes everywhere else.

## What this phase deliberately does not change

- No RLS policy was broadened, and no `USING (true)` policy exists anywhere (work item §41) — every existing policy is untouched except the two `trip_assignments` policies retired in ZD-092 and the `trips` INSERT policy retired in ZD-101, all of which removed privilege, never added it.
- Driver still has no direct-table path to `passengers` (ZD-080) — nothing in this phase touches that boundary; a future minimum-necessary Driver projection remains a separate, deferred piece of work (P1-E2-S3 in the original phase numbering).
- Trip *assignment* remains entirely separate from Trip *creation* (ZD-102) — `create_trip` never touches `trip_assignments`; `assign_trip` is still the only path to an active assignment.
- No UI/application code was touched — this phase, like every phase above it, is the database mutation layer only.
