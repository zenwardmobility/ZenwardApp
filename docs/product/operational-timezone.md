# Zenward Platform — Organization Operational Timezone

**Work item:** P1-E3-S2C — Organization Operational Timezone Boundary
**Status:** Implemented and verified — see docs/reports/P1-E3-S2C-operational-timezone-report.txt for the full validation record (217/217 SQL assertions, 41/41 auth checks, real DST/midnight-boundary/multi-org/server-independence tests).
**Last updated:** 2026-09-01

This document is the concise reference for how Zenward interprets a stored instant as an organization's own "today"/local clock time — read this before touching anything that displays or groups a `timestamptz` by calendar day.

## The problem this exists to solve

Driver Today (P1-E3-S2) originally computed "today," trip grouping, and displayed times using whichever timezone the Next.js **server process** happened to run in — correct only by coincidence when the server and the organization's real operating region agree. An organization operating in `America/New_York`, served by infrastructure running in UTC (or any other zone), could see a late-evening local trip silently reclassified onto the wrong calendar day — an operational-correctness defect, not a cosmetic one.

## Timezone ownership

**The Organization owns its own operational timezone — never the user, never the browser, never the server.** `organizations.timezone` (IANA identifier, e.g. `America/New_York`) is the sole source of truth for interpreting any `timestamptz` on that organization's data as a calendar day or a local clock time. A multi-organization user's two organizations may have two different operational timezones simultaneously — timezone is resolved per-organization-context, exactly like role (authorization-model.md §P), never cached once per user.

## IANA requirement — not an offset, not an abbreviation

`organizations.timezone` must be a genuine IANA zone identifier (`Area/Location`, e.g. `America/Chicago`) or the single unambiguous exception `UTC`. A database `CHECK` constraint (`organizations_timezone_valid_iana`, backed by `public.is_valid_iana_timezone()`) enforces this at write time — `EST`, `EDT`, `GMT-5`, `Georgia`, `Eastern`, and every other fixed-offset or ambiguous abbreviation are rejected outright, never merely discouraged. This is required specifically because a fixed offset or abbreviation cannot correctly represent daylight-saving transitions — `EST` permanently means UTC-5 with no DST, which is wrong for roughly half the year in a real America/New_York organization. See the full mechanism and the exact SQL in docs/reports/P1-E3-S2C-operational-timezone-report.txt §3.

## UTC timestamp storage — unchanged

Every operational timestamp (`trips.scheduled_pickup_at`, `appointment_at`, `trip_assignments.assigned_at`/`ended_at`, etc.) remains exactly what it always was: `timestamptz`, an absolute, UTC-normalized instant. **Nothing about storage changed in this phase.** Only the *interpretation* of that instant — "what calendar day is this, locally" and "what wall-clock time does a Driver see" — now goes through the organization's own timezone rather than the server's.

## Local calendar interpretation

`src/lib/driver/trip-presentation.ts` is the single place this interpretation happens for the Driver surface:

```
formatTripTime(iso, timezone)        — "10:00 AM", in the given IANA zone
formatLongDate(date, timezone)       — "Tuesday, September 1", in the given IANA zone
isSameOperationalDay(a, b, timezone) — same organization-local calendar day?
```

All three take `timezone` as a **required** parameter — there is no default, no optional fallback to the runtime's own local zone. A call site with no timezone to pass has a bug to fix, not a default to reach for; TypeScript enforces this by construction (the parameter isn't optional). Internally, every function passes an explicit `timeZone` to `Intl.DateTimeFormat` — the standards-based, IANA-tzdata-backed mechanism every modern JS runtime ships, never a hand-rolled UTC-offset calculation (work item §11).

## How the timezone reaches the page

```
authenticated user
  → active Membership (live-queried, ZD-106)
  → selected Organization (resolveOrganizationContext, ZD-104)
  → Organization.timezone (read via the SAME embedded join that already resolves Organization.name)
  → OrganizationContext.organizationTimezone
  → Driver Today: toTodayTrip() / formatTripTime() / formatLongDate()
```

`getActiveMemberships()` (`src/lib/auth/membership.ts`) selects `organizations(name, timezone)` in one query — the timezone is never a second lookup, never trusted from the `zw_org_context` cookie (which still names a *requested* organization only, exactly as before — ZD-104), and never inferred from the request's browser/Accept-Language/IP. `ActiveMembership`/`OrganizationContext` (`src/lib/auth/types.ts`) both carry `organizationTimezone: string` as a required field.

## Multi-org behavior

Timezone belongs to the Organization, never the user. A user who is Org A admin (`America/New_York`) and Org B driver (`America/Chicago`) sees `America/New_York` while their resolved context is Org A and `America/Chicago` while it's Org B — the same per-organization-context resolution role already uses, extended with one more field, not a parallel mechanism. Verified directly against the real database with the real seeded multi-org fixture (docs/reports/P1-E3-S2C-operational-timezone-report.txt §12).

## DST behavior

Handled entirely by `Intl.DateTimeFormat`'s own IANA tzdata — verified with `America/New_York` across both a January instant (EST, UTC−5) and a July instant (EDT, UTC−4), same IANA identifier, correct offset resolved automatically both times. No DST offset is computed, stored, or hand-maintained anywhere in this codebase.

## Server/browser timezone: never authoritative

Verified by running the same formatting/grouping logic under three different `TZ` process environments (the unmodified default, explicit `UTC`, explicit `Africa/Lagos`) — byte-identical output every time, for the same instant and the same organization timezone. This holds by construction, not by coincidence: no function in `trip-presentation.ts` reads `process.env.TZ`, the server's OS clock zone, or any browser-supplied value: the *only* input that determines local interpretation is the `timezone` parameter, which always originates from `organizations.timezone`.

## What is explicitly out of scope here

- **Operations screens** (Today's Operations, Dispatch Board, Trip Detail, scheduling presentation) do not yet consume `organizationTimezone` — this phase built the reusable primitive (Organization → context → timezone) but did not wire it into any Operations UI, per explicit instruction. A future Operations phase reuses the exact same `OrganizationContext.organizationTimezone` field.
- **`create_trip`'s scheduling-input semantics** were inspected, not changed: its `p_scheduled_pickup_at`/`p_appointment_at` parameters are already plain `timestamptz` — correct at the database layer by construction (an absolute instant needs no timezone tag of its own). The genuinely open question is a *future UI* one: whichever form eventually lets an Operations user type "10:00 AM" for a new Trip must convert that local wall-clock entry to a UTC instant using the organization's own `timezone` before calling `create_trip` — no such form exists yet, so this is recorded as a forward-looking implementation note, not a defect requiring an RPC change now.
- **A timezone self-service/management UI** was deliberately not built (work item §6) — `organizations.timezone` has no application-level UPDATE path in this phase; it is set only via migration backfill or seed data.

## Related documents

[decision-register.md](./decision-register.md) (ZD-119 onward) · [driver-today-data-map.md](./driver-today-data-map.md) · [domain-model.md](./domain-model.md) §B entity 1 · [auth-session-routing.md](./auth-session-routing.md) "Organization context" · [schema.md](../data/schema.md) · docs/reports/P1-E3-S2C-operational-timezone-report.txt (the full verification record).
