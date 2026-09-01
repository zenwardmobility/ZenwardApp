# Zenward Mobility — Canonical Domain Model & RLS/Tenancy Architecture

**Work item:** P1-E1-S1 — Canonical Domain Model + RLS/Tenancy Architecture, amended by P1-E1-S1A — Domain Security Decision Resolution
**Phase:** P1 — Core Product Architecture
**Status:** Domain model confirmed; security gate READY for schema design (see Security gate at the end of this document)
**Last updated:** 2026-08-30

This document defines the domain concepts and tenancy/security rules every later schema, API, and query must obey. **No tables, migrations, RLS policies, or APIs exist yet.** This is architecture, written so the domain model is right before it becomes a database.

Terminology used throughout is transportation-focused (organization, membership, request, trip, assignment, passenger, driver, vehicle, facility, event, exception, note, audit) and avoids invented product language.

---

## A. Domain overview

Zenward coordinates non-emergency medical transportation for **organizations** — Zenward's own operating business units (an operating region or brand, not each hospital or client). An organization runs **drivers** and **vehicles**, maintains a directory of **facilities** it commonly transports to/from, and keeps records of **passengers** it transports.

Transportation begins as a **transportation request** — inbound intent, submitted by a **requester** (who is often, but not always, the passenger) — which operations staff review and, when accepted, turn into one or more **trips**. A trip is an operational movement: a passenger, a pickup, a destination, a schedule, and — once dispatched — a **driver/vehicle assignment**. As a trip runs, it accumulates **events** (structured status history), may accumulate **notes** (human context) and **exceptions** (things that need attention outside normal status), and every meaningful mutation is separately recorded as an **audit event** for accountability.

Everything above the auth layer belongs to exactly one organization. Nothing about who is logged in should ever, by itself, decide what data is visible — that's the job of **membership**, evaluated per request, enforced in the database.

## B. Entity catalog

**15 tabled entities** (updated at P1-E1-S1A with the addition of PlatformAdminGrant), plus Requester modeled as embedded fields rather than a standalone table (see below). Each entity below states: purpose, security classification, tenant ownership, ownership key/path, key relationships, lifecycle responsibility, expected future access roles, and RLS risk. Classification definitions (used consistently, see §4 of the work item):

- **TENANT-OWNED** — belongs to exactly one organization for its whole lifecycle; reads/writes are organization-scoped.
- **USER-OWNED** — belongs to an individual authenticated user, independent of any one organization.
- **PUBLIC-INTAKE** — must be creatable by unauthenticated actors through a specifically controlled boundary; never granted ordinary anonymous SELECT/UPDATE/DELETE; becomes tenant-owned-governed for everything after creation.
- **SYSTEM-OWNED** — written exclusively by trusted server-side/platform logic; no ordinary tenant role (including org admins) writes it directly, though reads may be tenant-scoped.

### 1. Organization
- **Purpose:** The tenant root — a Zenward operating business unit (e.g., a market/region). Everything else hangs off this.
- **Classification:** SYSTEM-OWNED (creation/root control is a platform-level action — new operating entities are rare and high-stakes; a self-serve "anyone creates an org" flow is not part of this product). Settings updates within an existing org are performed by that org's admins.
- **Tenant ownership:** Is the tenant. Tenant key = its own `id`.
- **Key relationships:** Parent of Membership, Driver, Vehicle, Facility, Passenger, TransportationRequest, Trip (directly or via direct `organization_id`).
- **Operational timezone** *(added P1-E3-S2C)*: `timezone` (IANA identifier, `NOT NULL`, `CHECK`-validated) — the organization's own authority for interpreting any of its `timestamptz` columns as a local calendar day/clock time. Never the server's or a user's own timezone. See [operational-timezone.md](./operational-timezone.md).
- **Lifecycle:** Created by platform onboarding; deactivated, not deleted, if operations cease.
- **Expected future access roles:** Read (own org) — all members. Write (settings) — Organization Admin. Create/deactivate — Platform Admin only.
- **RLS risk:** Low (few rows, admin-managed), but a mistake here undermines every other table's isolation — treat root-level policy correctness as maximum priority regardless of row count.

### 2. Membership
- **Purpose:** Expresses that a specific authenticated user belongs to a specific organization, with a role and an active/inactive state. This is the root of all RLS evaluation — never `users.organization_id`.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`.
- **Ownership path:** `organization_id` (direct) + `user_id` (references the auth identity).
- **Key relationships:** User (auth identity) ↔ Organization. A user may hold multiple Membership rows (multiple organizations, one row each) — see §H.
- **Lifecycle:** Created on invite/onboarding; deactivated (not deleted) when a person leaves — history of who had access when must survive.
- **Expected future access roles:** Read (own memberships) — the member themself. Read/write (all memberships in org) — Organization Admin. Create/deactivate — Organization Admin or Platform Admin.
- **RLS risk:** Medium — must prevent a user from inserting/editing their own membership (self-granting a role or joining an arbitrary organization) and must prevent role escalation by non-admins.

### 3. UserProfile
- **Purpose:** A thin, org-independent extension of the Supabase auth identity (display name, contact info, avatar) — not itself a domain/operational record.
- **Classification:** USER-OWNED.
- **Tenant ownership:** None — no `organization_id`. Deliberately org-independent, matching §7/§8's requirement not to key identity to a single organization.
- **Ownership path:** `id` = the auth user id.
- **Key relationships:** Referenced by Membership.user_id and (optionally) Driver.user_id.
- **Lifecycle:** Created alongside auth signup; owned entirely by that user.
- **Expected future access roles:** Read/write (own row) — the user. Read (limited fields, via Membership join) — org admins needing to see a member's display name.
- **RLS risk:** Low.

### 4. PlatformAdminGrant *(added P1-E1-S1A §2)*
- **Purpose:** Represents global Zenward platform administration, kept entirely separate from tenant Membership. Platform Admin is **not** an Organization Membership role — `Membership.role = platform_admin` is explicitly rejected as the model for this.
- **Classification:** SYSTEM-OWNED. Keyed to the authenticated user; managed only through trusted privileged paths (not exposed to any application-level self-service mutation); not writable by Organization Admins; not a user-editable profile field.
- **Tenant ownership:** None — deliberately org-independent, since the entire point is privilege that spans organizations.
- **Ownership path:** `user_id` (references the auth identity). No `organization_id`.
- **Key relationships:** User (auth identity), 1:1 or 1:0 — a user either holds a grant or doesn't.
- **Lifecycle:** Created/revoked only through a privileged, out-of-band administrative path (never a normal API mutation, never something an Organization Admin's role can reach). The database row is the canonical source of truth even if a cached or custom JWT claim is considered later for performance.
- **Expected future access roles:** Read (own grant, to know their own status) — the user. Read (all grants) — a Platform Admin. Write — trusted/privileged path only, not modeled as an ordinary role at all.
- **RLS risk:** High by consequence, not by complexity — this table is the single highest-blast-radius row in the system if it is ever writable by anything other than a fully trusted path. A future narrow helper such as `is_platform_admin()` may query this grant; if implemented as SECURITY DEFINER, it must follow the strict function rules in §28/§L (explicit `search_path`, validates `auth.uid()`, minimal capability, never a general bypass).

### 5. Driver
- **Purpose:** An operational resource — a person who drives, with the operational attributes dispatch cares about. **A Driver is not an auth identity** (see §H/§9).
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`. A person driving for two organizations is two separate Driver rows (each optionally linked to the same underlying auth user).
- **Ownership path:** `organization_id` (direct); optional nullable `user_id` (auth link).
- **Key relationships:** Optional User (auth); referenced by TripAssignment.driver_id.
- **Lifecycle:** Created by dispatch/org admin onboarding a driver, independent of whether that driver has app login access yet. Deactivated, not deleted, when a driver leaves — assignment history must remain valid.
- **Expected future access roles:** Read (own record + own assignments) — the driver, if linked to a user. Read/write (all drivers in org) — Dispatcher, Organization Admin.
- **RLS risk:** Medium — must prevent a driver from editing their own `organization_id`, another driver's row, or granting themselves assignments.

### 6. Passenger
- **Purpose:** The person being transported. Passengers are not required to ever authenticate.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`.
- **Ownership path:** `organization_id` (direct). No `user_id` — this model does not assume passenger self-service accounts; if that's added later, it is a new decision with its own RLS review, not an extension made silently here.
- **Key relationships:** Referenced by TransportationRequest.passenger_id and Trip.passenger_id.
- **Lifecycle:** Created by intake/dispatch when a passenger is first requested for; persists across many trips and requests.
- **Expected future access roles:** Read/write — Dispatcher, Organization Admin (within org). Read (minimal fields needed for the trip at hand) — the assigned Driver.
- **RLS risk:** High. Passenger records carry assistance/mobility information that is sensitive by nature — the highest-consequence table to get tenant isolation wrong on.

### 7. Facility
- **Purpose:** A directory entry for a physical place trips are commonly associated with (hospital, clinic, dialysis center, rehab facility, etc.). Facility ≠ Organization (see §I) — it is a location an organization's operations reference, not a tenant of its own, and requires no authenticated facility users to exist.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id` — the same physical hospital, referenced by two different Zenward operating organizations, would be two separate Facility rows. No cross-org facility sharing in this model.
- **Ownership path:** `organization_id` (direct).
- **Key relationships:** Referenced (nullable, soft) by Trip.pickup_facility_id / destination_facility_id and TransportationRequest.facility_id.
- **Lifecycle:** Created by dispatch/org admin as facilities are encountered; not deleted once referenced by historical trips (see §J — trips must not silently change if a facility record is edited/removed later).
- **Expected future access roles:** Read/write — Dispatcher, Organization Admin. Read — Driver (needs address for a trip's facility leg).
- **RLS risk:** Low–Medium under normal use; **Medium–High if a public-facing facility/service-area picker is ever added to the public intake flow** — see the open question in §Q. No such public read exists in this model as designed.

### 8. Vehicle
- **Purpose:** An organization-owned operational resource, independent of any trip.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`.
- **Ownership path:** `organization_id` (direct).
- **Key relationships:** Referenced by TripAssignment.vehicle_id.
- **Lifecycle:** Created/retired by org admin/fleet management as the fleet changes.
- **Expected future access roles:** Read/write — Dispatcher, Organization Admin. Read — Driver (their currently assigned vehicle only).
- **RLS risk:** Low.

### 9. TransportationRequest
- **Purpose:** Inbound transportation *intent* — not a guarantee of a scheduled trip. Represents "a family member submitted a request for James Carter," nothing more, until operations reviews it. See §12/§F.
- **Classification:** **PUBLIC-INTAKE**, transitioning to tenant-owned governance immediately after creation. The row always carries `organization_id` once persisted (assigned by the trusted intake path, never trusted from the client) and from that point behaves like any other tenant-owned record for read/update by org staff. The *only* special property is the creation boundary (§13/§L) — no anonymous SELECT/UPDATE/DELETE policy is ever created for this table, at any point.
- **Tenant ownership:** Direct `organization_id`, assigned server-side at creation. **Public tenant resolution (confirmed, P1-E1-S1A §3):** for the single-operator MVP, the trusted intake path resolves `organization_id` to the one configured Zenward operating organization — the client never supplies it, and no client-supplied `organization_id` field is trusted even if present in the request payload. Future multi-organization intake would select ownership via server-controlled service-area/operating rules; that routing system is not designed now. Invariant: **public clients do not choose tenant ownership.**
- **Ownership path:** `organization_id` (direct, system-assigned).
- **Key relationships:** Optional `passenger_id` (if the passenger is already known); requester details embedded (see §H); zero-to-many Trip rows created from it (`trip.request_id`).
- **Lifecycle:** Created via public intake or internal staff entry → reviewed by operations → accepted (creates Trip(s)), rejected, or left pending. The request record persists after Trip creation — it is not consumed or deleted (§12).
- **Expected future access roles:** Create — unauthenticated public (via controlled path only) or authenticated staff. Read/write/review — Dispatcher, Organization Admin, within their org.
- **RLS risk:** High. The combination of "must accept unauthenticated writes" and "contains passenger/health-adjacent information" makes this the entity most likely to be misconfigured into an accidental data leak if handled with an ordinary anon-insert-policy approach instead of a controlled server-side path.

### 10. Trip
- **Purpose:** The operational transportation movement itself — the canonical entity of the whole product (see §15).
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`.
- **Ownership path:** `organization_id` (direct).
- **Key relationships:** `passenger_id` → Passenger; `request_id` (nullable — internal/operator-created trips may have no request) → TransportationRequest; `pickup_facility_id`/`destination_facility_id` (nullable, soft) → Facility, alongside mandatory immutable snapshot fields (see §J); current driver/vehicle assignment is **not** denormalized on Trip (revised, P1-E1-S1A §4) — TripAssignment is the sole source of truth, found by filtering for the row with `ended_at IS NULL`; carries `current_state` directly (see §K).
- **Lifecycle:** Created from an accepted TransportationRequest, or directly by operations. Progresses through operational states. Never hard-deleted — cancellation/no-show are states, not row removal (auditable history requirement).
- **Expected future access roles:** Read/write — Dispatcher, Organization Admin (within org). Read (their own assigned trips) — Driver. Read — Platform Admin (support/oversight, if a deliberate cross-org role is granted — never by default).
- **RLS risk:** High — the entity most cross-tenant tests will target directly; gets the most scrutiny of any table.

### 11. TripAssignment
- **Purpose:** Who is doing this trip, and the full history of who has ever been assigned to it. Kept separate from Trip because a trip can exist with driver/vehicle unassigned, and because reassignment history is an audit requirement, not a value to overwrite (see §16/§G). **Confirmed as the canonical assignment source of truth (P1-E1-S1A §4)** — no assignment data is duplicated onto Trip.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** **Direct `organization_id`**, denormalized from Trip rather than derived only through a join, specifically to avoid the fragile `assignment → trip → organization` join chain called out in §5/§27 as unsafe to rely on alone.
- **Ownership path:** `organization_id` (direct) + `trip_id`.
- **Key relationships:** `trip_id` → Trip; `driver_id` → Driver; `vehicle_id` → Vehicle; `assigned_by` → the acting user/membership; `ended_at`/`end_reason` marking supersession or cancellation.
- **Lifecycle:** Append-only. A reassignment does not edit the existing row's driver/vehicle: (1) the existing active assignment is closed, (2) `ended_at` is recorded, (3) the reason/context is preserved on that closed row, (4) a new TripAssignment row is inserted, (5) the historical row is never rewritten into the new one. The **active assignment** for a trip is defined as the TripAssignment row with `ended_at IS NULL` — there is no separate "current" pointer anywhere else. At schema-design time, evaluate enforcing **one active assignment per trip** with a PostgreSQL partial unique index (e.g., unique on `trip_id` where `ended_at IS NULL`) or an equivalent simple constraint — not implemented in this phase.
- **Expected future access roles:** Read/write (assign, reassign) — Dispatcher, Organization Admin. Read (their own assignments only, including their own past/superseded ones) — Driver. Driver must never write this table (see §17/P1-E1-S1A §5).
- **RLS risk:** High — the specific scenario "driver reassigns themselves or reads another driver's assignment" (§17, TEST E/F/G/H) lives here.

### 12. TripEvent
- **Purpose:** The structured, historical record of operational occurrences — "Marcus Hall marked trip En Route at 09:52." Trip carries the *current* state; TripEvent is the immutable trail of how it got there (see §19).
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** **Direct `organization_id`**, denormalized from Trip — this is the literal example in §5/§27 of a chain (`event → trip → assignment → driver → membership → organization`) too fragile to rely on for RLS without a direct column.
- **Ownership path:** `organization_id` (direct) + `trip_id`.
- **Key relationships:** `trip_id` → Trip; `actor` (user/driver reference, nullable for system-generated events); `event_type`; `occurred_at`; free-form `metadata`.
- **Lifecycle:** Append-only (see §20) — INSERT only, from an allow-listed set of event types, by an authorized actor for that trip. UPDATE/DELETE denied to ordinary roles; corrections happen through a privileged, audited path only, never a normal edit.
- **Expected future access roles:** Insert (allow-listed event types) — Dispatcher, Driver (for their own active assignment), system. Read — Dispatcher, Organization Admin, the assigned Driver.
- **RLS risk:** Medium–High — integrity (append-only) is as important as isolation here.

### 13. TripNote
- **Purpose:** Human-authored contextual information, distinct from TripEvent's structured occurrences (see §22). "Passenger prefers front-seat access" is a note; "trip marked En Route" is an event.
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id` (same reasoning as TripEvent/TripAssignment).
- **Ownership path:** `organization_id` (direct) + `trip_id`.
- **Visibility model (confirmed, P1-E1-S1A §1):** every TripNote carries exactly one of two visibility classes — no others at MVP:
  - **`operations_only`** — readable by authorized organization operations roles (Organization Admin, Dispatcher, an approved Operations Staff role if retained). Not readable by Driver, public requester, Passenger, or unauthenticated users.
  - **`driver_visible`** — readable by authorized organization operations roles **and** the Driver legitimately assigned to that trip (subject to valid organization membership / driver identity rules). Operations may create driver-visible notes; a driver may eventually create a driver-visible note only for a trip they are legitimately assigned to, and a driver-authored note must not provide any path to access other trips or organizations. Public/requester access remains none either way.
  - Only authorized operations roles may change an existing note's visibility classification — a driver cannot reclassify their own note from `driver_visible` to anything else, and cannot reclassify an `operations_only` note at all.
  - No additional classes (`patient_visible`, `requester_visible`, `facility_visible`, `private_driver`, etc.) are added at MVP.
  - Public transportation-request notes are intake data (fields on TransportationRequest, see §B "Requester"), not TripNote — the two are not equivalent and are not merged.
- **Key relationships:** `trip_id` → Trip; `author` (user reference); `visibility` (`operations_only` | `driver_visible`); free-text `body`.
- **Lifecycle:** Created by dispatcher, driver (driver_visible only, own assigned trip), or system at any point in a trip's life; not append-only in the same strict sense as TripEvent, but edits/deletes should still be limited to the author or an org admin, not open to anyone with trip access. Visibility reclassification is restricted to authorized operations roles, as above.
- **Expected future access roles:** Create — Dispatcher, Organization Admin (either visibility); Driver (`driver_visible` only, own assigned trip). Read — Dispatcher, Organization Admin (both classes, own org); Driver (`driver_visible` only, own assigned trip).
- **RLS risk:** Medium — visibility taxonomy is now resolved (two fixed classes), which removes the previous open-ended risk; remaining risk is standard tenant/assignment-scoping discipline, same shape as TripAssignment.

### 14. TripException
- **Purpose:** Something needing attention that coexists with, but is not itself, a normal trip status — "potential timing conflict," "driver delay," "vehicle issue" (see §21).
- **Classification:** TENANT-OWNED.
- **Tenant ownership:** Direct `organization_id`.
- **Ownership path:** `organization_id` (direct) + `trip_id`.
- **Key relationships:** `trip_id` → Trip; `created_by`; `resolved_by`/`resolved_at` (nullable — open until resolved); `exception_type` (taxonomy not finalized).
- **Lifecycle:** Opened by dispatcher, driver, or system; resolved explicitly by an authorized actor. Not deleted — resolved exceptions remain as history.
- **Expected future access roles:** Create/resolve — Dispatcher, Organization Admin; Driver may create (flag an issue) but likely not resolve. Read — same set, within org.
- **RLS risk:** Medium.

### 15. AuditEvent
- **Purpose:** Administrative/security mutation history — "who changed the driver," "who changed the pickup time," "who cancelled the trip" (see §24). Distinct from TripEvent, which is business/transportation lifecycle, not security accountability.
- **Classification:** **SYSTEM-OWNED**. No ordinary role — including Organization Admin — inserts, updates, or deletes this table directly; it is written exclusively by a trusted trigger or server-side function reacting to tracked mutations. Reads are tenant-scoped.
- **Tenant ownership:** Direct `organization_id` (for scoped reads).
- **Ownership path:** `organization_id` (direct) + a generic `(entity_type, entity_id)` reference to whatever was mutated (Trip, TripAssignment, Driver, Passenger, etc.) — see §26 note on why this isn't a strict per-table foreign key.
- **Key relationships:** Polymorphic reference to the mutated row; `actor_user_id`; `action`; before/after `metadata`.
- **Lifecycle:** Append-only, forever (see §25) — SELECT restricted by organization + privileged role; INSERT only through trusted paths; UPDATE denied; DELETE denied except a tightly controlled, separately-gated system-maintenance path (e.g., retention policy), never a normal user action.
- **Expected future access roles:** Read — Organization Admin (own org), Platform Admin. Write — system/trusted trigger only.
- **RLS risk:** High — this table's entire purpose is to be trustworthy; any write path other than the trusted one defeats it.

### Requester (not a standalone entity) *(retained, confirmed P1-E1-S1A §6)*
Requester is a **role**, not a resource: the person or organization arranging transportation, who may or may not be the Passenger (§11). It is modeled as a small set of snapshot fields directly on TransportationRequest (name, relationship-to-passenger, contact phone/email, optional nullable reference to an authenticated user and/or to a known Passenger if the requester *is* the passenger) rather than a normalized table, because — at MVP — requesters are not managed as a recurring, relationship-bearing resource the way Passenger/Driver/Vehicle are. Whether a persistent "Contact"/"Caregiver" entity is warranted later (for repeat requesters tied to the same passenger) is flagged as an open question (§Q), not decided here.

## C. Entity security classification table

| Entity | Classification | Tenant Key | Readers | Writers | Public Access | RLS Risk |
|---|---|---|---|---|---|---|
| Organization | SYSTEM-OWNED | self (`id`) | Members of the org; Platform Admin | Org Admin (settings); Platform Admin (create/deactivate) | None | Low |
| Membership | TENANT-OWNED | `organization_id` | The member (own row); Org Admin (org's rows) | Org Admin; Platform Admin | None | Medium |
| UserProfile | USER-OWNED | none | The user (own row); Org Admin (limited fields via Membership join) | The user (own row) | None | Low |
| PlatformAdminGrant | SYSTEM-OWNED | none (org-independent) | The user (own grant); Platform Admin (all grants) | Trusted/privileged path only — no ordinary role | None | High (blast radius) |
| Driver | TENANT-OWNED | `organization_id` | Dispatcher, Org Admin; the driver (own row) | Dispatcher, Org Admin | None | Medium |
| Passenger | TENANT-OWNED | `organization_id` | Dispatcher, Org Admin; Driver (limited, trip-relevant fields) | Dispatcher, Org Admin | None | High |
| Facility | TENANT-OWNED | `organization_id` | Dispatcher, Org Admin, Driver | Dispatcher, Org Admin | None (see open question) | Low–Medium |
| Vehicle | TENANT-OWNED | `organization_id` | Dispatcher, Org Admin; Driver (assigned vehicle) | Dispatcher, Org Admin | None | Low |
| TransportationRequest | PUBLIC-INTAKE → TENANT-OWNED | `organization_id` (system-assigned) | Dispatcher, Org Admin | Public (controlled path only); Dispatcher, Org Admin | Create only, via controlled path — never SELECT/UPDATE/DELETE | High |
| Trip | TENANT-OWNED | `organization_id` | Dispatcher, Org Admin; Driver (own assigned trips) | Dispatcher, Org Admin | None | High |
| TripAssignment | TENANT-OWNED | `organization_id` (direct) | Dispatcher, Org Admin; Driver (own assignments only) | Dispatcher, Org Admin only | None | High |
| TripEvent | TENANT-OWNED | `organization_id` (direct) | Dispatcher, Org Admin, assigned Driver | Dispatcher, Driver (own trip, allow-listed types), system | None | Medium–High |
| TripNote | TENANT-OWNED | `organization_id` (direct) | Dispatcher, Org Admin (both classes); Driver (`driver_visible` only, own assigned trip) | Dispatcher, Org Admin (both classes); Driver (`driver_visible` only, own assigned trip) | None | Medium |
| TripException | TENANT-OWNED | `organization_id` (direct) | Dispatcher, Org Admin, Driver | Dispatcher, Driver (create); Dispatcher/Org Admin (resolve) | None | Medium |
| AuditEvent | SYSTEM-OWNED | `organization_id` (direct) | Org Admin, Platform Admin | System/trusted trigger only | None | High |

## D. Relationship map

```
User (auth identity) / UserProfile
 ├── Membership (0..N) ───────► Organization (per-org role + status)
 └── PlatformAdminGrant (0..1) ── org-independent, system-owned global privilege

Organization
 ├── Membership ──────────────► User (auth identity) / UserProfile
 ├── Driver ───(optional)─────► User (auth identity)
 ├── Vehicle
 ├── Facility
 ├── Passenger
 ├── TransportationRequest
 │      ├── passenger_id ─────► Passenger (nullable — may not be known yet)
 │      ├── requester_* fields (snapshot; optional user_id / passenger_id reference)
 │      └── creates 0..N ─────► Trip
 └── Trip
        ├── passenger_id ─────► Passenger
        ├── request_id ───────► TransportationRequest (nullable)
        ├── pickup_facility_id / destination_facility_id ─► Facility (nullable, soft)
        │       + immutable pickup/destination snapshot fields on Trip itself
        ├── TripAssignment (1..N, append-only, sole source of truth) ──► Driver, Vehicle
        │       active assignment = the row with ended_at IS NULL (no pointer on Trip)
        ├── TripEvent (1..N, append-only)
        ├── TripNote (0..N, visibility: operations_only | driver_visible)
        └── TripException (0..N)

AuditEvent ── organization_id + (entity_type, entity_id) ──► any of the above (generic reference, not a strict per-table FK)
```

Every arrow that crosses from a child record back to Driver/Vehicle/Facility/Passenger/Trip is a place a cross-tenant mismatch could theoretically be inserted — see §N for the specific constraint recommended at each one.

## E. Aggregate / ownership boundaries

Two nested ownership boundaries matter:

1. **Organization aggregate (macro, tenant boundary):** Organization + Membership + Driver + Vehicle + Facility + Passenger + TransportationRequest + Trip (and Trip's children). Everything here carries `organization_id` and is isolated by it. This is the boundary RLS enforces.
2. **Trip aggregate (micro, operational boundary):** Trip + its TripAssignment history + TripEvents + TripNotes + TripExceptions, all keyed by `trip_id` (and denormalized `organization_id`). This is the boundary that defines "everything about one movement" for display, audit, and lifecycle purposes — it is never deleted as a unit, only appended to and status-transitioned.

Passenger, Driver, Vehicle, and Facility are **organization-level resources** that outlive any single trip and are referenced by many trips over time — they belong to the macro boundary, not the micro one.

PlatformAdminGrant and UserProfile sit **outside both boundaries** — they're user-scoped, not organization-scoped, by design (§H).

## F. Request → Trip model

A **TransportationRequest** represents inbound intent only. It does **not** imply availability confirmed, driver assigned, operational acceptance, or a guarantee of transportation — those are exactly what review and Trip creation add.

- **Ownership:** organization-scoped (assigned at creation by the trusted intake path).
- **Lifecycle responsibility:** capture what was asked for; hold review state (pending/accepted/declined); once accepted, spawn Trip(s). The request **is not consumed or deleted** by Trip creation — it remains as the origin record.
- **Relation to Passenger:** `passenger_id` is nullable on the request — a first-time requester may not yet have a Passenger record; one is created or matched during review, before or as part of Trip creation.
- **Requester representation:** snapshot fields on the request itself (see §B, "Requester").
- **Cardinality — recommended: one Request : many Trips (1:N), not 1:1.** A single request commonly implies an outbound trip and a separate return trip, and potentially a recurring series (e.g., repeated dialysis transport) — none of which is "the same trip." Every Trip keeps a nullable `request_id` back-reference; a request with zero Trips yet is simply "pending review," and one with several is normal, not an error. Internal/operator-created trips (no public request behind them at all) are also expected, hence the FK is nullable in the other direction too.

## G. Trip → Assignment model

A Trip must be able to exist with driver/vehicle unassigned — so `driver_id`/`vehicle_id` cannot live only as plain columns on Trip if reassignment history matters (it does — dispatch will ask "who was this trip assigned to before it got reassigned").

**Confirmed model (revised at P1-E1-S1A §4):** a separate **TripAssignment** table, append-only, and the **sole source of truth** for who is on a trip — Trip does **not** denormalize `current_driver_id`/`current_vehicle_id`.

- Each assignment or reassignment is a **new row**, never an edit of the previous one's driver/vehicle.
- Reassignment behavior is exactly: (1) the existing active assignment is closed, (2) `ended_at` is recorded, (3) reason/context is preserved on that closed row, (4) a new TripAssignment row is inserted, (5) the historical row is never rewritten into the new one.
- The **active assignment** for a trip is the TripAssignment row with `ended_at IS NULL`. At most one such row exists per trip; at schema-design time, evaluate enforcing this with a PostgreSQL partial unique index (e.g., unique on `trip_id` where `ended_at IS NULL`) or another simple, robust constraint — not implemented in this phase.
- `assigned_by` and `assigned_at` are recorded on every row, giving a complete, queryable reassignment history for audit — without needing to reconstruct it from AuditEvent.
- "Who is on this trip right now" is answered by querying TripAssignment directly (`trip_id = ? AND ended_at IS NULL`), not by reading a field on Trip. This was originally recommended as a denormalized pointer on Trip for read speed; that recommendation is **withdrawn** in favor of one unambiguous source of truth, on the reasoning that it removes a synchronization risk (Trip and TripAssignment could otherwise disagree), simplifies audit history, avoids duplicated privileged references, and is expected to have sufficient query performance at MVP scale with proper indexing (an index on `(trip_id) WHERE ended_at IS NULL`, or the same partial-unique index above, serves both correctness and speed). If a future, *proven* performance need reintroduces denormalization, that is a separate, deliberate architecture decision — not a default.

This keeps the reassignment-history requirement (§16) satisfied structurally rather than through mutation, with exactly one place to look for "who is on this trip."

## H. User / Membership / Driver / Passenger / Requester model

Four layers are kept explicitly separate, per §7/§8 (a fourth added at P1-E1-S1A §2):

- **Authentication identity** — the Supabase auth user, extended by a thin, org-independent UserProfile. This layer answers "who is logged in," nothing else.
- **Organization membership** — a Membership row per (user, organization) pair, carrying role and active status. This layer answers "which organizations can this identity act within, and as what." A user may hold multiple Membership rows (future multi-org support) — security must never be designed around a single `users.organization_id`, because that assumption breaks the moment one person operates across two organizations (e.g., a driver who separately does dispatch work for another org).
- **Operational profile** — role-specific operational resources. For staff roles (Dispatcher, Organization Admin), Membership.role *is* the operational profile — no extra table needed. **Driver is the one role that needs its own table beyond Membership**, because it carries operational state (linked-vehicle history, assignment eligibility) that must be able to exist independent of — and outlive — any auth relationship at all.
- **Platform-level privilege** *(new, P1-E1-S1A §2)* — PlatformAdminGrant, entirely orthogonal to Membership. A regional or global platform administrator's cross-organization capability is **not** expressed as a Membership row (not even a special one, and not `Membership.role = platform_admin`), because Membership is inherently organization-scoped and platform privilege is deliberately not. It is its own system-owned, user-keyed grant (see §B, entity 4).

**Driver ≠ Auth User (§9):** a Driver record has an optional, nullable `user_id`. Consequences:
- **Login:** a Driver with `user_id` set can log in and see their own record via that link; a Driver with no linked user (not yet invited, or contractor without app access) can still be dispatched — matches the still-unresolved contractor/employment model in the decision register.
- **Organization ownership:** `Driver.organization_id` is independent of whatever organizations the linked user separately belongs to via Membership. A person driving for two organizations is two Driver rows.
- **Assignments:** TripAssignment references `driver_id`, never `user_id` — assignment logic never depends on auth state.
- **RLS:** a driver's "my assignments" view resolves `auth.uid() → Driver.user_id → Driver.id`, then filters TripAssignment/Trip by that id and the driver's own organization_id.
- **Driver-only views:** scoped the same way — never by role name alone, always by the resolved Driver.id.
- **If the linked auth account is disabled or deleted:** `Driver.user_id` should be nullable with `ON DELETE SET NULL` (never cascade-delete the Driver row). All historical Trip/TripAssignment/TripEvent rows reference `Driver.id`, which is untouched — history stays intact and valid even if login access is fully removed.

**Driver assignment access (confirmed, P1-E1-S1A §5)** — the strict driver principle, restated precisely for future RLS design. A Driver **may eventually**:
- read their own active/relevant TripAssignment;
- read the Trip necessary to perform that assignment;
- read the permitted passenger/trip details required for transportation;
- read `driver_visible` TripNotes on their own assigned trip.

A Driver **must not**:
- browse all assignments in the organization;
- read another driver's assignment by default;
- self-reassign, or change `driver_id` on any assignment;
- change `vehicle_id` unless a separately approved future workflow explicitly allows a specific vehicle-acknowledgement action (not designed here);
- mutate `organization_id` anywhere;
- access `operations_only` TripNotes;
- access another organization's data in any form.

**Passenger ≠ User (§10):** Passenger has no `user_id` at all in this model — no passenger self-service login is assumed anywhere in current product scope. If that changes later, it is a new decision requiring its own RLS review, not a silent extension of this table.

**Passenger ≠ Requester (§11):** already covered in §B/§F — Requester is a role captured as snapshot fields on TransportationRequest, with optional soft links to a User (if the requester is authenticated staff/future facility user) and/or a Passenger (if the requester is the passenger themselves), never forced into the Passenger record.

## I. Facility / Organization model

Facility ≠ Organization. Organization is the tenant root (a Zenward operating business unit); Facility is a directory entry for a physical place (hospital, clinic, dialysis center) that an organization's trips reference — it carries `organization_id` directly but is not itself a tenant and requires no authenticated users. The same real-world hospital referenced by two different Zenward operating organizations is two separate Facility rows; this model does not attempt cross-organization facility sharing.

A future authenticated "Facility User" (a facility coordinator who logs in to see their own facility's requests) is explicitly **not** designed here — it's post-MVP per the scope register — but the model doesn't preclude it: it would most naturally be a separate Facility-scoped membership-like construct, not a repurposing of Organization Membership.

## J. Location strategy

**Recommended: hybrid — mandatory immutable snapshot on Trip, optional soft reference to a reusable record.**

- Trip stores its own pickup/destination as **plain fields** (address text, and optionally coordinates/label) captured at the time the trip is created/scheduled. These fields are never re-derived and never change if the source Passenger or Facility record is later edited.
- Trip additionally carries **nullable, soft** `pickup_facility_id`/`destination_facility_id` references, used only for reporting/analytics linkage ("how many trips did we run to this facility"). If a Facility is later edited or removed, this reference may go stale or null (`ON DELETE SET NULL`) — it never rewrites the historical snapshot fields.
- No separate generic `Location` table is introduced at MVP. Passenger and Facility each carry their own current address fields directly; Trip's snapshot is simply copied from whichever source was used (Passenger's address, Facility's address, or a manually entered address) at request/scheduling time.

This satisfies the historical-integrity requirement (§23) without the over-normalization risk the same section warns against. A generic reusable Location entity can be introduced later without breaking anything, since Trip's authoritative fields are already self-contained snapshots, not references.

## K. Trip event / note / exception / audit model

Four distinct concerns, deliberately not merged:

| | Purpose | Mutability | Who typically writes |
|---|---|---|---|
| **Trip.current_state** | What is true right now | Overwritten as the trip progresses | Derived from the latest accepted TripEvent |
| **TripEvent** | Structured operational history — how the trip got to its current state | Append-only; corrections need a privileged path (§20) | Dispatcher, Driver (own trip, allow-listed event types), system |
| **TripNote** | Human-authored context, not a status transition | Editable by author/org admin; visibility (`operations_only`/`driver_visible`) reclassifiable only by authorized operations roles | Dispatcher, Organization Admin (either visibility); Driver (`driver_visible` only, own assigned trip) |
| **TripException** | Something needing attention that coexists with the normal status (a delay, a conflict) — not itself a status | Open → resolved lifecycle; not deleted | Dispatcher, Driver (create); Dispatcher/Org Admin (resolve) |
| **AuditEvent** | Administrative/security accountability — who changed what, distinct from the business/transportation lifecycle above | Append-only, forever; no ordinary role writes it directly | System/trusted trigger only |

Trip carries `current_state` directly (fast, obvious reads — "show me all trips currently En Route" shouldn't require scanning history) while TripEvent retains the full transition trail. TripNote's visibility taxonomy is **confirmed** at P1-E1-S1A §1: exactly two classes, `operations_only` and `driver_visible` — see entity 13 in §B for the full rule.

## L. RLS / tenancy architecture

- **Organization ownership model:** every tenant-owned table carries a **direct** `organization_id` column, checked by RLS policies against the caller's active memberships. No policy relies on multi-hop joins to reach the tenant key.
- **Membership model:** `Membership(user_id, organization_id, role, status, ...)`, unique per (user_id, organization_id). RLS is evaluated against active memberships only — a disabled membership row must produce the same result as no membership at all (§3 rule 4, TEST K).
- **Public-intake boundary (§13):** TransportationRequest creation happens through a trusted server-side path (a route handler / server action / controlled RPC) — never a client-side insert against an anon RLS policy. That path validates input server-side and assigns `organization_id` itself (e.g., from the intake channel/routing context); the client never supplies a trusted `organization_id`. No anonymous SELECT, UPDATE, or DELETE policy is ever created for this table.
- **Public request tenant resolution (confirmed, P1-E1-S1A §3):** for the single-operator MVP, the trusted intake path resolves ownership to the one configured Zenward operating organization — never a value read from the request payload. Future multi-organization intake would resolve ownership via server-controlled service-area/operating rules; that routing system is explicitly not designed in this phase. **Security invariant: public clients do not choose tenant ownership**, under any circumstance, at any phase.
- **Platform Admin representation (confirmed, P1-E1-S1A §2):** global platform privilege is a separate, system-owned PlatformAdminGrant keyed to the user — never `Membership.role = platform_admin`, and never a special reserved organization used as a stand-in for "the platform." The grant is managed only through a trusted, privileged path (not exposed to any application-level self-service mutation, and not writable by Organization Admins). A future `is_platform_admin()` helper querying this grant, if built, follows the same SECURITY DEFINER rules as any other helper (§28) — the database grant remains canonical even if a cached or custom JWT claim is considered later for performance.
- **Service-role boundary:** the Supabase service-role key exists only in server-side environment variables, used only in trusted server code (route handlers, server actions, server components) — never in client-bundled code, never a `NEXT_PUBLIC_`-prefixed variable, never written to browser storage or cookies readable by frontend JavaScript.
- **Direct organization_id strategy:** applied to every tenant-owned table, including child records of Trip (TripAssignment, TripEvent, TripNote, TripException), specifically to avoid the fragile deep-join chain (`event → trip → assignment → driver → membership → organization`) called out in §5/§27 as unsafe to depend on alone.
- **Helper-function strategy (not implemented yet):** future SQL functions such as `is_org_member(org_id)` and `has_org_role(org_id, role)` are the intended pattern for keeping policies short and testable, rather than repeating membership-lookup subqueries inline in every policy. Any such function, when built, must follow the SECURITY DEFINER rules in §28 (explicit `search_path`, validates `auth.uid()` and membership, minimal exposed capability, no dynamic SQL, never a blanket bypass).
- **Deny-by-default:** RLS is enabled on every tenant-owned and system-owned table in the same migration that creates it — never created first and "secured later." A table with RLS enabled and zero policies denies everything by default; policies are added deliberately and narrowly from that starting point.

## M. Preliminary access matrix (Entity × Actor × CRUD)

Notation: `C`reate `R`ead `U`pdate `D`elete. `(own)` = restricted to the actor's own record(s)/org. `—` = no access. This is a **preliminary architecture check, not a final RBAC system** — exact role names/counts may still evolve.

| Entity | Public | Auth User (no org context) | Organization Admin | Dispatcher | Driver | Platform Admin |
|---|---|---|---|---|---|---|
| Organization | — | — | R, U (own org settings) | R (own org) | R (own org) | C, R, U (all) |
| Membership | — | R (own rows) | C, R, U (own org) | R (own org) | R (own row) | C, R, U (all) |
| UserProfile | — | C, R, U (own row) | R (org members, limited fields) | R (org members, limited fields) | R (own row) | R (all) |
| PlatformAdminGrant | — | R (own grant) | — | — | — | R (all); write via trusted path only, not this matrix |
| Driver | — | — | C, R, U (own org) | C, R, U (own org) | R (own row) | R (all, support) |
| Passenger | — | — | C, R, U (own org) | C, R, U (own org) | R (own trip's passenger, limited fields) | — (no default cross-org access) |
| Facility | — | — | C, R, U (own org) | C, R, U (own org) | R (own org) | — |
| Vehicle | — | — | C, R, U (own org) | C, R, U (own org) | R (assigned vehicle) | — |
| TransportationRequest | C (controlled path only) | C (controlled path only) | R, U (own org, review) | R, U (own org, review) | — | — |
| Trip | — | — | C, R, U (own org) | C, R, U (own org) | R (own assigned trips) | — |
| TripAssignment | — | — | C, R, U (own org) | C, R, U (own org) | R (own assignments only) | — |
| TripEvent | — | — | R (own org) | C (allow-listed types), R (own org) | C (allow-listed types, own trip), R (own trip) | — |
| TripNote | — | — | C, R, U-reclassify (own org, both classes) | C, R, U-reclassify (own org, both classes) | C, R (`driver_visible` only, own assigned trip) | — |
| TripException | — | — | C, R, U-resolve (own org) | C, R, U-resolve (own org) | C (create/flag only), R (own trip) | — |
| AuditEvent | — | — | R (own org) | — | — | R (all) |

Nothing in this matrix grants Public or generic Auth User standing access beyond the one deliberately controlled TransportationRequest creation path — every other row's Public/Auth-User cells are intentionally `—`.

## N. Cross-tenant leakage analysis

| Relationship | Risk | Recommended constraint |
|---|---|---|
| TripAssignment.driver_id → Driver | A Driver from Org B assigned to a Trip in Org A | Composite FK: `TripAssignment(driver_id, organization_id)` → `Driver(id, organization_id)`, requiring a unique `(id, organization_id)` on Driver |
| TripAssignment.vehicle_id → Vehicle | A Vehicle from Org B referenced by an Org A trip | Composite FK: `TripAssignment(vehicle_id, organization_id)` → `Vehicle(id, organization_id)` |
| TripAssignment.trip_id → Trip | An assignment row claiming a different org than its own trip | Composite FK: `TripAssignment(trip_id, organization_id)` → `Trip(id, organization_id)` |
| TripEvent.trip_id → Trip | Same pattern as above, for events | Composite FK: `TripEvent(trip_id, organization_id)` → `Trip(id, organization_id)` |
| TripNote.trip_id → Trip | Same pattern, for notes | Composite FK: `TripNote(trip_id, organization_id)` → `Trip(id, organization_id)` |
| TripException.trip_id → Trip | Same pattern, for exceptions | Composite FK: `TripException(trip_id, organization_id)` → `Trip(id, organization_id)` |
| Trip.pickup_facility_id / destination_facility_id → Facility | A Facility from Org B referenced by an Org A trip | Composite FK: `Trip(pickup_facility_id, organization_id)` → `Facility(id, organization_id)` (and same for destination) |
| Trip.passenger_id → Passenger | A Passenger from Org B attached to an Org A trip | Composite FK: `Trip(passenger_id, organization_id)` → `Passenger(id, organization_id)` |
| TransportationRequest.passenger_id → Passenger | Same pattern at intake | Composite FK: `TransportationRequest(passenger_id, organization_id)` → `Passenger(id, organization_id)` |
| Membership.user_id / organization_id | Duplicate or conflicting memberships | Unique `(user_id, organization_id)`; no composite-FK risk since Membership *is* the join table |
| AuditEvent.(entity_type, entity_id) | Polymorphic reference can't be a strict FK to a specific table | No FK possible here by construction — mitigated by AuditEvent being SYSTEM-OWNED/insert-only via trusted trigger, which independently derives and stamps the correct `organization_id` at write time; never trust a client-supplied value for it |
| PlatformAdminGrant.user_id *(added P1-E1-S1A §2)* | Not a cross-*tenant* risk but a cross-*all-tenant* one: any actor able to write this table grants themselves (or anyone) access spanning every organization at once — the highest blast radius of any table in the model | No RLS INSERT/UPDATE policy for any ordinary role at all (not Organization Admin, not any Membership role); writes happen only via a privileged, out-of-band administrative path outside normal application code — a constraint enforced by *absence* of policy, not a composite FK, since this table has no `organization_id` to key one on |

**Recommended general strategy (§27):** composite foreign keys anchored on a `(id, organization_id)` uniqueness constraint on every tenant-owned parent table. This is the simplest robust approach — it makes a cross-tenant mismatch a **schema-level impossibility**, not merely something RLS is trusted to catch, satisfying "do not rely on RLS alone where relational constraints can prevent invalid data" (§26). Validation triggers are reserved only for cases a composite FK genuinely can't express (none identified above, aside from AuditEvent's inherently polymorphic reference, which is mitigated differently).

## O. Future RLS test matrix

The adversarial suite below **must pass before any data-layer phase is considered complete** (§3 rule 11). Restated from the work item, plus a few Zenward-specific additions:

| Test | Scenario | Expected |
|---|---|---|
| A — Same tenant | Org A dispatcher reads an Org A trip | ALLOW |
| B — Cross tenant | Org A dispatcher reads an Org B trip | DENY / zero rows |
| C — Direct ID guess | Org A user requests an Org B trip UUID directly | DENY / zero rows |
| D — Forged organization | Org A client INSERTs with `organization_id` = Org B | DENY |
| E — Driver own assignment | Driver A reads their own assignment | ALLOW |
| F — Driver other assignment | Driver A reads Driver B's assignment, same org | DENY unless explicitly required by product |
| G — Cross-org driver | Driver A reads an assignment in Org B | DENY |
| H — Driver privileged update | Driver attempts to change `driver_id` or `organization_id` on an assignment | DENY |
| I — Public request create | Unauthenticated user submits a valid request via the controlled path | ALLOW |
| J — Public request read | Unauthenticated user attempts to list/read TransportationRequest | DENY |
| K — Removed membership | User whose membership is disabled attempts access | DENY |
| L — Direct Supabase access | User bypasses the UI, calls the Supabase REST API directly | Same result as through the UI |
| M — Cross-tenant child record | Org A user accesses an Org B TripNote/TripEvent/TripAssignment | DENY |
| N — Update tenant key | Authorized Org A user attempts to change `organization_id` on an existing row | DENY |
| O — Delete audit history | Normal org user attempts to delete an AuditEvent | DENY |
| P — Reassignment history integrity *(added)* | Trip reassigned from Driver A to Driver B; Driver A reads their now-closed assignment | ALLOW (their own history); Driver A reading Driver B's new active assignment → DENY |
| Q — Audit write bypass *(added)* | Org Admin attempts a direct INSERT into AuditEvent, bypassing the trusted trigger path | DENY |
| R — Facility cross-org reference *(added)* | Org A trip attempts to reference an Org B Facility via forged `facility_id` | DENY at both RLS and the composite-FK constraint level |
| S — Platform admin grant escalation *(added, P1-E1-S1A)* | Organization Admin attempts to INSERT or UPDATE a PlatformAdminGrant row, for themselves or anyone else | DENY |
| T — Driver reads operations-only note *(added, P1-E1-S1A)* | Driver, on their own assigned trip, attempts to read a TripNote marked `operations_only` | DENY |
| U — Driver reads driver-visible note *(added, P1-E1-S1A)* | Driver, on their own assigned trip, reads a TripNote marked `driver_visible` | ALLOW |
| V — Forged public organization *(added, P1-E1-S1A)* | Public client submits a TransportationRequest with a client-supplied `organization_id` differing from the server-configured operating organization | The intake path does not accept `organization_id` as client input at all; if any such field were present in the payload it must be ignored, never trusted — resulting request is created under the server-resolved organization regardless |
| W — Single active assignment *(added, P1-E1-S1A)* | An attempt is made to create a second TripAssignment row for the same trip while another row already has `ended_at IS NULL` | DENY (constraint violation), once the partial unique index recommended in §G/§16 is implemented at schema-design time |

## P. Deferred concepts

Explicitly out of scope for this domain model and everything built on it until a separate decision reopens them: billing claims, insurance claims, Medicaid identifiers, driver ratings, passenger ratings, earnings/payroll, route optimization, driver scoring, advanced vehicle classification taxonomies, advanced provider accounts, clinical records/diagnoses/medical records, complex provider contracts, and any recurring-trip *generation engine* mechanics beyond the request→multiple-trips cardinality already established in §F. This is consistent with, and does not re-litigate, the exclusions already recorded in `product-definition.md` and `scope-register.md`. Per P1-E1-S1A §7, these stay deferred unless one is found to actually prevent secure schema design — none currently do.

## Q. Open product questions

Two of the original six items are now resolved (see decision register ZD-048, ZD-049) and removed from this list. The remainder require an owner decision before the affected part of schema design proceeds, but **none of them block schema design starting** — all are explicitly non-blocking per P1-E1-S1A §7 unless one turns out to prevent secure RLS design, which none currently do:

1. **Public facility/service-area directory** — does the public intake flow ever need to show a facility or service-area picker before submission? If yes, that requires a deliberately scoped, minimal-field public read — never a blanket Facility SELECT — and is additionally gated on ZD-016 (launch territory still unknown). (§14/§26)
2. **Requester as a persistent entity** — do repeat requesters (e.g., the same family member requesting for the same passenger repeatedly) warrant a future "Contact/Caregiver" table, or does the per-request snapshot remain sufficient indefinitely? (§B)
3. **Facility self-service portal** — already POST-MVP per the scope register; this model doesn't preclude it, but its access shape (a Facility-scoped membership, distinct from Organization Membership) is not designed here. (§I)
4. **Dispatcher vs. Operations Staff** — treated as the same permission tier in this model (§M). Explicitly deferred to **P1-E1-S3** as a role-model question, per P1-E1-S1A §7 — do not invent separate permissions for these before then.

## R. Security invariants

These rules govern every later migration, policy, and query. Violating any of them fails phase review regardless of how the rest of the implementation looks.

1. Tenant isolation is enforced in the database (RLS), never only in UI, route guards, or client-side checks.
2. Deny-by-default: RLS is enabled the moment a tenant-owned or system-owned table is created, in the same migration — never "create now, secure later."
3. No tenant-owned table is complete until its policies exist and pass the cross-tenant test matrix (§O).
4. Every tenant-owned table carries a **direct** `organization_id` column — no policy depends on a multi-hop join to reach the tenant key.
5. Client-supplied `organization_id` is never trusted by itself; tenant ownership is derived from or validated against the caller's authenticated membership.
6. Authenticated users never access another organization's records unless a deliberately approved, explicitly-designed platform-level role allows it.
7. The Supabase service-role credential exists only in trusted server-side code — never in browser code, public client bundles, the driver PWA, localStorage, frontend-readable cookies, or public environment variables.
8. TransportationRequest creation from unauthenticated users happens only through a controlled server-side path (route handler / server action / RPC) that assigns `organization_id` itself — never through an anon INSERT policy, and never paired with any anon SELECT/UPDATE/DELETE policy on that table.
9. TripEvent and AuditEvent are append-only for ordinary roles: INSERT only (TripEvent: allow-listed event types by an authorized actor; AuditEvent: system/trusted-path only), UPDATE and DELETE denied except through a separately-gated, audited privileged path.
10. A driver may act on their own assignments only — never assign another driver, reassign themselves, alter `organization_id`, or read another organization's assignments.
11. Every cross-tenant-relevant foreign key (assignment→driver/vehicle/trip, trip→facility/passenger, event/note/exception→trip) is backed by a composite `(id, organization_id)` foreign key, not relational trust alone — relational constraints reinforce RLS, they don't replace it.
12. Any future SECURITY DEFINER function has a specific purpose, an explicit `search_path`, validates `auth.uid()` and membership, exposes minimal capability, avoids dynamic SQL, and is never a general-purpose RLS bypass.
13. Supabase Storage policies (when storage is designed) must enforce the same tenant isolation as database RLS — securing a table never implies its associated storage bucket is secured.
14. Cross-tenant isolation tests (§O) are a mandatory phase gate — a data-layer phase does not pass review without them, run and green.
15. **Public clients do not choose tenant ownership.** TransportationRequest creation never accepts or trusts a client-supplied `organization_id`; the trusted intake path resolves it server-side, under all present and future intake configurations (§L, P1-E1-S1A §3).
16. **Platform Admin privilege is never expressed as an Organization Membership role.** It exists only as PlatformAdminGrant, a system-owned, user-keyed record writable only through a trusted privileged path — never through Organization Admin capability, never through a self-service profile field, never as `Membership.role = platform_admin` (§B, §L, P1-E1-S1A §2).
17. **TripAssignment is the sole source of truth for current driver/vehicle assignment.** Trip does not denormalize `current_driver_id`/`current_vehicle_id`; the active assignment for a trip is always the TripAssignment row with `ended_at IS NULL` (§G, P1-E1-S1A §4).
18. **TripNote visibility is exactly two classes at MVP** — `operations_only` and `driver_visible` — no others. Only authorized operations roles may create or change a note's classification; a driver may create a `driver_visible` note only for a trip they are legitimately assigned to, and can never read or write an `operations_only` note (§B entity 13, P1-E1-S1A §1).

---

## Security gate

**SECURITY GATE — READY FOR SCHEMA DESIGN**

The two items that previously held this gate at NOT READY are now resolved:

- **TripNote visibility** — confirmed as exactly two classes (`operations_only`, `driver_visible`) with clear read/write/reclassification rules (§B entity 13, §K, §M; P1-E1-S1A §1).
- **Platform Admin representation** — confirmed as PlatformAdminGrant, a system-owned, user-keyed record entirely separate from Organization Membership (§B entity 4, §H, §L; P1-E1-S1A §2).

Alongside those, this pass also resolved public-request tenant resolution (§L, invariant 15) and revised the assignment source-of-truth model (§G, invariant 17) — both now equally settled.

Every gate criterion is met: every persistent entity has a classification (§B/§C, 15 entities), every tenant-owned entity has an explicit, direct tenant path (§L), Platform Admin representation is resolved, TripNote visibility is resolved, public intake tenant resolution is resolved, TripAssignment is confirmed as the unambiguous assignment source of truth, cross-tenant risks have concrete mitigation direction including the PlatformAdminGrant blast-radius risk (§N), and the preliminary access matrix is internally consistent with all of the above (§M).

The remaining open questions (§Q: public facility/service-area directory, Requester as a persistent entity, facility self-service portal, Dispatcher vs. Operations Staff) are all genuinely non-blocking — none of them prevent a secure RLS design for any entity scheduled for the next phase, and none are manufactured blockers. Dispatcher vs. Operations Staff is explicitly deferred to P1-E1-S3 as a role-model question, not a schema-design blocker.
