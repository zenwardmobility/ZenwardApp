# Zenward Mobility — Decision Register

**Work item:** P0-E1-S1 — Georgia Launch Decision Brief
**Status:** Draft, pending product review
**Last updated:** 2026-08-29

Allowed statuses: `CONFIRMED` · `PROVISIONAL` · `UNKNOWN` · `REJECTED` · `SUPERSEDED`

Where no rationale has been established yet, the Reason field states: *"Reason pending product validation."* No decision here should be treated as authorization to implement functionality — see [scope-register.md](./scope-register.md) for what is buildable.

---

### ZD-001 — Brand identity

- **Date:** 2026-08-29
- **Category:** Brand
- **Decision:** Product brand is "Zenward Mobility."
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, all customer-facing surfaces
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** Rebrand or trademark conflict discovered

### ZD-002 — Tagline

- **Date:** 2026-08-29
- **Category:** Brand
- **Decision:** Tagline is "Care that gets you there."
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, marketing materials
- **Dependencies:** ZD-001
- **Owner:** Product
- **Review Trigger:** Brand messaging review

### ZD-003 — Product category descriptor

- **Date:** 2026-08-29
- **Category:** Positioning
- **Decision:** Zenward is positioned as Non-Emergency Medical Transportation (NEMT).
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, licensing/compliance scope, driver ops
- **Dependencies:** ZD-008
- **Owner:** Product
- **Review Trigger:** Expansion into adjacent transport categories

### ZD-004 — Launch market

- **Date:** 2026-08-29
- **Category:** Market
- **Decision:** Initial launch market is Georgia, USA.
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Legal/licensing, service area, Operations Console
- **Dependencies:** ZD-016 (exact territory still unknown)
- **Owner:** Product
- **Review Trigger:** Multi-state expansion planning

### ZD-005 — Internal product thesis

- **Date:** 2026-08-29
- **Category:** Strategy
- **Decision:** "Zenward is building the operating system for dependable non-emergency medical transportation."
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** All — governs architecture ambition level
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** Strategic pivot

### ZD-006 — Customer proposition

- **Date:** 2026-08-29
- **Category:** Positioning
- **Decision:** "Book, coordinate, and track medical transportation with less uncertainty."
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Booking/Facility Experience
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** Messaging review

### ZD-007 — Primary operational domain entity

- **Date:** 2026-08-29
- **Category:** Architecture
- **Decision:** "Trip" is the primary business entity; Zenward is not modeled as a booking-form product.
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** All four product surfaces; core data model
- **Dependencies:** None
- **Owner:** Product / Engineering
- **Review Trigger:** Data model design work (not yet authorized)

### ZD-008 — Emergency transportation excluded from category

- **Date:** 2026-08-29
- **Category:** Scope
- **Decision:** Emergency medical transportation is explicitly outside the intended product category.
- **Status:** CONFIRMED
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Positioning, licensing, driver scope
- **Dependencies:** ZD-003
- **Owner:** Product
- **Review Trigger:** None anticipated

### ZD-009 — Initial customer groups

- **Date:** 2026-08-29
- **Category:** Market
- **Decision:** Initial customer groups may include healthcare facilities, private-pay customers, patients, and caregivers/families.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Booking/Facility Experience
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** Go-to-market plan finalization

### ZD-010 — Initial booking modes

- **Date:** 2026-08-29
- **Category:** Product
- **Decision:** Initial booking may support operator-assisted booking and digital transportation requests.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Operations Console, Booking/Facility Experience
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** MVP scope finalization

### ZD-011 — Initial driver product platform

- **Date:** 2026-08-29
- **Category:** Product
- **Decision:** Initial driver experience direction is mobile-first web/PWA (not native).
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Driver Experience
- **Dependencies:** None
- **Owner:** Product / Engineering
- **Review Trigger:** Driver UX research; native app cost-benefit review

### ZD-012 — Initial operations product platform

- **Date:** 2026-08-29
- **Category:** Product
- **Decision:** Initial operations product direction is a desktop-first Operations/Dispatch Console.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Operations / Dispatch Console
- **Dependencies:** None
- **Owner:** Product / Engineering
- **Review Trigger:** Dispatcher workflow research

### ZD-013 — Facility self-service booking and visibility

- **Date:** 2026-08-29
- **Category:** Product
- **Decision:** Healthcare facilities may eventually receive self-service booking and trip visibility.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Booking/Facility Experience
- **Dependencies:** ZD-009
- **Owner:** Product
- **Review Trigger:** Facility portal scope decision (explicitly not MVP by default — see scope register)

### ZD-014 — Compatibility with future Medicaid/broker integration

- **Date:** 2026-08-29
- **Category:** Architecture
- **Decision:** Architecture should avoid foreclosing future Medicaid or transportation-broker integrations, but these are not MVP dependencies.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Billing, Trip/Booking data model
- **Dependencies:** ZD-021, ZD-022, ZD-023
- **Owner:** Engineering
- **Review Trigger:** Payer strategy decision

### ZD-015 — Driver trip status progression

- **Date:** 2026-08-29
- **Category:** Product
- **Decision:** Provisional trip progression: Assigned → En Route → Arrived → Passenger Onboard → Drop-off → Completed.
- **Status:** PROVISIONAL
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Driver Experience, Operations Console, Trip domain model
- **Dependencies:** ZD-007
- **Owner:** Product
- **Review Trigger:** Driver workflow validation; must not be finalized without further review

### ZD-016 — Exact Georgia launch territory

- **Date:** 2026-08-29
- **Category:** Market
- **Decision:** Not yet determined — counties/cities served and service radius are unresolved.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Operations Console, licensing
- **Dependencies:** ZD-004
- **Owner:** Product
- **Review Trigger:** Launch territory decision by leadership

### ZD-017 — Operating hours and after-hours policy

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Operations Console, Public Website
- **Dependencies:** None
- **Owner:** Product / Operations
- **Review Trigger:** Operations policy definition

### ZD-018 — Fleet and vehicle model

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Fleet ownership model, vehicle types, ambulatory capability, wheelchair capability, and wheelchair vehicle specifications are not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Vehicle records, Driver Experience, Operations Console
- **Dependencies:** None
- **Owner:** Operations
- **Review Trigger:** Fleet strategy decision

### ZD-019 — Driver employment model

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Driver employment vs. contractor model not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Driver records, Driver Experience, legal/compliance
- **Dependencies:** ZD-025, ZD-026
- **Owner:** Operations / Legal
- **Review Trigger:** Labor model decision

### ZD-020 — Trip policy rules

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Minimum booking lead time, same-day booking rules, wait-time rules, cancellation rules, no-show rules, return-trip rules, and companion/caregiver rules are not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Trip domain model, Public Website, Booking/Facility Experience, Operations Console
- **Dependencies:** ZD-007
- **Owner:** Product / Operations
- **Review Trigger:** Operations policy definition

### ZD-021 — Pricing model

- **Date:** 2026-08-29
- **Category:** Commercial
- **Decision:** Pricing, mileage pricing, wait-time charges, facility contract pricing, and private-pay payment method are not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Billing records, Booking/Facility Experience
- **Dependencies:** None
- **Owner:** Product / Finance
- **Review Trigger:** Pricing strategy decision

### ZD-022 — Medicaid participation

- **Date:** 2026-08-29
- **Category:** Commercial / Compliance
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Billing, legal/compliance
- **Dependencies:** ZD-014
- **Owner:** Product / Legal
- **Review Trigger:** Payer strategy decision

### ZD-023 — Broker participation

- **Date:** 2026-08-29
- **Category:** Commercial
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Trip intake, Billing
- **Dependencies:** ZD-014
- **Owner:** Product
- **Review Trigger:** Payer strategy decision

### ZD-024 — Billing workflow

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Billing records, Operations Console
- **Dependencies:** ZD-021, ZD-022, ZD-023
- **Owner:** Product / Finance
- **Review Trigger:** Billing model design

### ZD-025 — Legal operating entity and insurance structure

- **Date:** 2026-08-29
- **Category:** Legal / Compliance
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Company formation, licensing, driver contracts
- **Dependencies:** None
- **Owner:** Legal
- **Review Trigger:** Entity formation decision

### ZD-026 — Licensing requirements

- **Date:** 2026-08-29
- **Category:** Legal / Compliance
- **Decision:** Georgia NEMT licensing requirements not yet documented.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Legal/compliance, launch readiness
- **Dependencies:** ZD-004, ZD-025
- **Owner:** Legal
- **Review Trigger:** Licensing research completion

### ZD-027 — Public contact information and domain

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Public contact information, production domain, and dispatch phone number not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Operations Console
- **Dependencies:** None
- **Owner:** Product / Operations
- **Review Trigger:** Launch readiness planning

### ZD-028 — Customer support model

- **Date:** 2026-08-29
- **Category:** Operations
- **Decision:** Not yet determined.
- **Status:** UNKNOWN
- **Reason:** Reason pending product validation.
- **Affected Product Areas:** Public Website, Operations Console
- **Dependencies:** None
- **Owner:** Operations
- **Review Trigger:** Support model decision

### ZD-029 — Route Teal brand anchor retained

- **Date:** 2026-08-29
- **Category:** Brand / Visual System
- **Decision:** The official Zenward brand teal remains `#21A89A` (`brand.route-teal`). It is retained for larger graphical treatments, selected indicators, decorative brand treatments, and any context where WCAG contrast is independently satisfied. It is not silently replaced elsewhere in the design system.
- **Status:** CONFIRMED
- **Reason:** Design review (P0-E2-S1 gate) confirmed the original brand anchor stays as-is; only its use in text-bearing/interactive contexts is constrained (see ZD-030).
- **Affected Product Areas:** Visual system, brand surfaces, marketing/illustrative UI
- **Dependencies:** ZD-030
- **Owner:** Design
- **Review Trigger:** Any proposal to change the brand teal hex itself

### ZD-030 — Interactive Teal approved

- **Date:** 2026-08-29
- **Category:** Brand / Visual System
- **Decision:** The accessibility-derived teal `#178577` (`interactive.teal`) is approved for use wherever stronger contrast is required, including buttons, links, interactive text, controls, and selected application states.
- **Status:** CONFIRMED
- **Reason:** `brand.route-teal` (`#21A89A`) measures 2.94:1 against white and fails WCAG AA as text/button-label color; `interactive.teal` measures 4.51:1 and passes. Design review approved formalizing the distinction rather than compromising either accessibility or the brand anchor.
- **Affected Product Areas:** Buttons, links, form controls, selected-state indicators across all four product surfaces
- **Dependencies:** ZD-029
- **Owner:** Design
- **Review Trigger:** Any change to either teal value, or a request to unify them into one token

### ZD-031 — Icon library direction

- **Date:** 2026-08-29
- **Category:** Visual System
- **Decision:** Phosphor Icons is the approved icon direction, primarily Regular and Medium weights. One coherent icon family; icons support comprehension rather than decoration; no default colored-circle icon treatment; no decorative icons beside every heading; no duotone styling throughout operational UI; icons are not used where clear text communicates better; sizing and visual weight stay consistent.
- **Status:** CONFIRMED
- **Reason:** Design review (P0-E2-S1 gate) approved this direction. The package has not been installed — this is a direction decision, not an implementation action.
- **Affected Product Areas:** All four product surfaces, wherever icons are eventually used
- **Dependencies:** None
- **Owner:** Design
- **Review Trigger:** Icon package installation (implementation phase)

### ZD-033 — Photography sourcing deferred

- **Date:** 2026-08-29
- **Category:** Brand / Visual System
- **Decision:** Photography sourcing remains unresolved. Photographic art direction will be established during the canonical public-site reference design, not during visual-system documentation. General requirements stand: realistic, dignified, human, healthcare-appropriate, transportation-relevant, no fabricated operational claims.
- **Status:** UNKNOWN
- **Reason:** Design review (P0-E2-S1 gate) explicitly deferred this rather than leaving it ambiguous.
- **Affected Product Areas:** Public Website
- **Dependencies:** None
- **Owner:** Design
- **Review Trigger:** Canonical public-site reference design work

### ZD-034 — Implementation stack

- **Date:** 2026-08-30
- **Category:** Engineering / Architecture
- **Decision:** The UI foundation is implemented in Next.js (App Router) with TypeScript, as a single application using route groups per surface (public site, `/ops`, `/driver`), styled with Tailwind CSS v4 using CSS-first (`@theme`) tokens rather than a JS config file or CSS Modules.
- **Status:** CONFIRMED
- **Reason:** No stack had been chosen previously — this was the first work item to write code. Next.js covers all three surfaces from one codebase (SSR for the public site's SEO needs, client-heavy rendering for console/driver) with the least setup overhead; confirmed directly with the user before scaffolding began rather than assumed.
- **Affected Product Areas:** All implementation work going forward
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** A surface needing an independent deploy pipeline (would motivate splitting into a monorepo)

### ZD-035 — Trips nav icon substitution

- **Date:** 2026-08-30
- **Category:** Visual System / Implementation
- **Decision:** The Trips sidebar item uses the Phosphor `Path` icon rather than `Route`.
- **Status:** CONFIRMED (implementation detail; flagged for design review)
- **Reason:** The approved reference mapping specified `Route`, but the installed Phosphor Icons package (`@phosphor-icons/react`) has no icon by that name. `Path` was chosen as the closest official equivalent, per the instruction to substitute the nearest Phosphor icon when a named one doesn't exist.
- **Affected Product Areas:** Operations Console sidebar
- **Dependencies:** ZD-031
- **Owner:** Design
- **Review Trigger:** Design review of the icon mapping; revisit if a future Phosphor release adds a literal `Route` icon

### ZD-036 — Operations route namespace and component naming

- **Date:** 2026-08-30
- **Category:** Engineering / Architecture
- **Decision:** The operations surface's canonical route prefix is `/operations` (renamed from the temporary `/ops`, with no alias kept). The corresponding shell components were renamed to match the surface-prefixed pattern already used elsewhere: `AppShell` → `OperationsShell`, `Sidebar` → `OperationsSidebar`. `AppHeader` was kept unchanged. A `(public)` route group with a shared `PublicLayout` was added so `/`, `/request-transportation`, and `/healthcare-providers` share one header/footer instance instead of each page wrapping itself.
- **Status:** CONFIRMED
- **Reason:** `/ops` was a placeholder chosen during initial scaffolding, before the canonical route prefix had been confirmed; `/operations` is the intended long-term name, so it was corrected now rather than carried forward and renamed later once more routes/links depend on it.
- **Affected Product Areas:** Operations Console (all routes), Public Website
- **Dependencies:** ZD-034
- **Owner:** Engineering
- **Review Trigger:** None anticipated — this is the canonical namespace going forward

### ZD-037 — Operations narrow-width guard

- **Date:** 2026-08-30
- **Category:** Product / Engineering
- **Decision:** Below the operations console's supported width (below the `md` / 768px breakpoint), `OperationsShell` renders an intentional guard state ("Zenward Operations — This workspace is designed for tablet and desktop use.") instead of silently hiding the sidebar and leaving an unusable content pane. No mobile dispatcher interface, hamburger drawer, or second navigation system was built.
- **Status:** CONFIRMED
- **Reason:** The prior foundation pass hid the sidebar below `md` via CSS but left the header/content area rendering regardless, which is a broken, not merely unsupported, experience at phone widths. A guard state was the minimal correct fix without expanding scope into mobile ops UI, which remains out of scope.
- **Affected Product Areas:** Operations Console
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** A future decision to support phone-width dispatch use

### ZD-038 — RLS-first, deny-by-default tenant isolation

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Tenant isolation is enforced at the database layer via PostgreSQL/Supabase Row Level Security, never only in UI, route guards, or client-side checks. Every tenant-owned and system-owned table has RLS enabled in the same migration that creates it, starting from deny-by-default (zero policies = zero access).
- **Status:** CONFIRMED
- **Reason:** The system must remain secure even when the UI is bypassed (direct API calls, forged payloads, guessed UUIDs) — the only sound way to guarantee that is enforcement at the data layer itself.
- **Affected Product Areas:** All future schema, all future APIs
- **Dependencies:** None
- **Owner:** Engineering / Security
- **Review Trigger:** Any future migration touching a tenant-owned table (mandatory RLS review, see ZD-042)

### ZD-039 — Organization / Membership as the tenancy root

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** "Organization" is the canonical term for the tenant root (not "Workspace"). Tenant access is derived from a Membership table (user × organization × role × status), never from a single `users.organization_id` column, since a user may belong to more than one organization.
- **Status:** CONFIRMED
- **Reason:** A single organization_id on the user table cannot express multi-organization membership and would need to be redesigned the moment it's needed; the membership pattern costs nothing now and avoids that rework.
- **Affected Product Areas:** All tenant-owned schema, auth/session logic
- **Dependencies:** ZD-038
- **Owner:** Engineering
- **Review Trigger:** None anticipated — foundational naming/pattern

### ZD-040 — Direct organization_id on every tenant-owned table

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Every tenant-owned table (including Trip's child records — TripAssignment, TripEvent, TripNote, TripException) carries a direct `organization_id` column, denormalized where necessary, rather than relying on multi-hop joins (e.g., event → trip → assignment → driver → membership → organization) to reach the tenant key.
- **Status:** CONFIRMED
- **Reason:** Fragile join chains make RLS policies slow, hard to reason about, and easy to get subtly wrong; a direct column keeps every policy a single-hop check.
- **Affected Product Areas:** Trip, TripAssignment, TripEvent, TripNote, TripException, and all other tenant-owned tables
- **Dependencies:** ZD-038, ZD-039
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-041 — Composite foreign keys for tenant consistency

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Cross-tenant-relevant relationships (assignment→driver/vehicle/trip, trip→facility/passenger, event/note/exception→trip) will be enforced with composite foreign keys anchored on a unique `(id, organization_id)` per parent table, so a cross-tenant mismatch (e.g., a Trip in Org A referencing a Driver in Org B) is a schema-level impossibility, not something RLS alone is trusted to catch.
- **Status:** CONFIRMED (as the future implementation strategy — not yet built)
- **Reason:** Relational constraints reinforce RLS and catch mistakes RLS bugs or bypasses would otherwise let through; composite FKs are the simplest mechanism that achieves this without validation triggers.
- **Affected Product Areas:** Every tenant-owned child table's schema design
- **Dependencies:** ZD-040
- **Owner:** Engineering
- **Review Trigger:** Schema design (P1-E1-S2)

### ZD-042 — RLS and table creation happen together; isolation testing is a phase gate

- **Date:** 2026-08-30
- **Category:** Process / Security
- **Decision:** No table is created without its RLS policies in the same implementation stage — tables are never "secured later." No data-layer phase is considered complete until the cross-tenant adversarial test matrix (domain-model.md §O) passes.
- **Status:** CONFIRMED
- **Reason:** A tenant-owned table with no policies yet is a live data leak the moment it goes live, even briefly; making the test matrix a phase gate is the only way to guarantee this is actually verified, not assumed.
- **Affected Product Areas:** All future schema/data-layer work
- **Dependencies:** ZD-038
- **Owner:** Engineering / Security
- **Review Trigger:** Every future data-layer phase

### ZD-043 — Service-role credential boundary

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** The Supabase service-role credential exists only in trusted server-side code (route handlers, server actions, server components) — never in browser code, client bundles, the driver PWA, localStorage, frontend-readable cookies, or public (`NEXT_PUBLIC_`) environment variables.
- **Status:** CONFIRMED
- **Reason:** The service-role key bypasses RLS entirely; any client-side exposure defeats every other tenancy guarantee in this document at once.
- **Affected Product Areas:** All backend/API implementation
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** Any code review touching Supabase client initialization

### ZD-044 — Public intake boundary for TransportationRequest

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Unauthenticated transportation-request submission is handled through a trusted server-side path (route handler / server action / controlled RPC) that validates input and assigns `organization_id` itself. No anonymous SELECT, UPDATE, or DELETE policy is ever created for TransportationRequest, and the client never supplies a trusted `organization_id` for the insert.
- **Status:** CONFIRMED
- **Reason:** An anon-insert RLS policy is the easy, wrong way to support public intake; it's a short step from an anon-insert policy to an accidental anon-select policy, and either allows enumeration/scraping of passenger-adjacent data.
- **Affected Product Areas:** Public request intake, TransportationRequest
- **Dependencies:** ZD-038, ZD-043
- **Owner:** Engineering / Security
- **Review Trigger:** Public intake implementation (P1 API design)

### ZD-045 — Trip domain separations: Request, Assignment, Event, Exception

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Four separations are confirmed as the canonical domain model: (1) TransportationRequest is a distinct entity from Trip, related 1:N, not consumed by Trip creation; (2) TripAssignment is a separate, append-only entity from Trip, not plain `driver_id`/`vehicle_id` columns; (3) TripEvent is separate from Trip's `current_state` field — Trip carries current state directly, TripEvent retains history; (4) TripException is separate from Trip status — exceptions coexist with, rather than replace, a normal trip state.
- **Status:** CONFIRMED
- **Reason:** Each separation was evaluated against a concrete requirement this domain must support (multiple trips per request, reassignment history, current-state performance, exceptions coexisting with normal status) and each requirement is real, not speculative.
- **Affected Product Areas:** Trip, TransportationRequest, TripAssignment, TripEvent, TripException schema design
- **Dependencies:** None
- **Owner:** Product / Engineering
- **Review Trigger:** Schema design (P1-E1-S2)

### ZD-046 — Driver/Passenger separated from auth identity

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Driver is an operational resource with an optional, nullable link to an auth user (`user_id`, `ON DELETE SET NULL`) — never merged with the auth identity. Passenger has no auth link at all in the current model; no passenger self-service login is assumed.
- **Status:** CONFIRMED
- **Reason:** Driver records and their assignment/trip history must remain valid even if login access is revoked or the linked auth account is deleted; Passenger accounts aren't part of any confirmed product scope.
- **Affected Product Areas:** Driver, Passenger schema design; driver auth flow
- **Dependencies:** ZD-039
- **Owner:** Engineering
- **Review Trigger:** Any future decision to add passenger self-service accounts (would need its own RLS review)

### ZD-047 — Location strategy: immutable snapshot, no generic Location table

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Trip stores its own pickup/destination as plain, immutable fields captured at creation/scheduling time, plus optional soft (nullable, `ON DELETE SET NULL`) references to Facility for reporting linkage only. No generic reusable `Location` entity is introduced at MVP.
- **Status:** CONFIRMED
- **Reason:** Historical trips must not silently change if a Passenger's or Facility's address is edited later; a snapshot-on-Trip model guarantees this without the over-normalization risk a generic Location table would introduce this early.
- **Affected Product Areas:** Trip schema design
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** A future need for structured, queryable location data beyond what a text snapshot provides

### ZD-048 — TripNote visibility: two fixed classes

- **Date:** 2026-08-30
- **Category:** Product / Security
- **Decision:** TripNote supports exactly two visibility classes at MVP: `operations_only` (Organization Admin, Dispatcher, approved Operations Staff role if retained — never Driver, Passenger, requester, or unauthenticated users) and `driver_visible` (the same operations roles, plus the Driver legitimately assigned to that trip). Only authorized operations roles may create or change a note's visibility classification. No additional classes (`patient_visible`, `requester_visible`, `facility_visible`, `private_driver`, etc.) are added at MVP. Public transportation-request notes remain intake data on TransportationRequest, not TripNote.
- **Status:** CONFIRMED
- **Reason:** Resolves the blocking open question from P1-E1-S1 (Q1) that prevented finalizing TripNote's RLS policy shape; two classes cover the concrete operational need (internal coordination vs. driver instruction) without inventing unused taxonomy.
- **Affected Product Areas:** TripNote schema design and RLS
- **Dependencies:** ZD-045
- **Owner:** Product / Security
- **Review Trigger:** A concrete product need for a third visibility class (e.g., facility-visible) once facility portal access is designed

### ZD-049 — Platform Admin as a system-owned grant, not a Membership role

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Platform Admin is represented by a new system-owned entity, PlatformAdminGrant, keyed to the authenticated user and entirely independent of Organization Membership. `Membership.role = platform_admin` is explicitly rejected as the model. The grant is managed only through a trusted, privileged path — never writable by Organization Admins, never a self-service profile field. A future `is_platform_admin()` helper, if built, follows the same SECURITY DEFINER rules as any other helper (ZD-041's sibling pattern); the database grant remains canonical even if a cached/JWT claim is considered later.
- **Status:** CONFIRMED
- **Reason:** Resolves the blocking open question from P1-E1-S1 (Q5). Organization Membership is inherently organization-scoped; platform-wide privilege is deliberately not, so conflating the two into one role system would make Membership's own RLS harder to reason about and create a privilege-escalation path through org-admin-manageable data.
- **Affected Product Areas:** New PlatformAdminGrant entity; any future cross-organization read/support path
- **Dependencies:** ZD-039
- **Owner:** Security
- **Review Trigger:** Schema design (P1-E1-S2) — the grant's exact storage shape

### ZD-050 — Public request tenant resolution: server-determined, single operator at MVP

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** For the MVP single-operator launch, a public TransportationRequest's `organization_id` is resolved entirely server-side by the trusted intake path to the one configured Zenward operating organization. A client-supplied `organization_id` is never trusted, whether or not one happens to be present in the request payload. Future multi-organization intake would need server-controlled service-area/operating-rule routing — not designed now.
- **Status:** CONFIRMED
- **Reason:** Removes any ambiguity in the P1-E1-S1 public-intake boundary about where tenant ownership comes from; makes explicit that this remains true even as the product scales beyond one operating organization.
- **Affected Product Areas:** Public intake implementation (P1 API design)
- **Dependencies:** ZD-044
- **Owner:** Security
- **Review Trigger:** Multi-organization expansion (service-area routing design)

### ZD-051 — TripAssignment is the sole assignment source of truth (supersedes prior denormalization recommendation)

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Trip does **not** carry denormalized `current_driver_id`/`current_vehicle_id` fields. TripAssignment alone is the source of truth for current assignment; the active assignment for a trip is the row with `ended_at IS NULL`. At schema-design time, evaluate a PostgreSQL partial unique index (or equivalent) enforcing one active assignment per trip.
- **Status:** CONFIRMED — **supersedes** the P1-E1-S1 domain-model.md §G recommendation to denormalize current-assignment fields onto Trip
- **Reason:** One unambiguous source of truth removes a Trip/TripAssignment synchronization risk, simplifies audit history, and avoids duplicated privileged references; MVP-scale query performance is expected to be sufficient with proper indexing. A future, *proven* performance need would be a separate, deliberate decision, not a default.
- **Affected Product Areas:** Trip, TripAssignment schema design
- **Dependencies:** ZD-045
- **Owner:** Engineering
- **Review Trigger:** A measured performance problem with the non-denormalized query pattern at real scale

### ZD-052 — Driver assignment access, restated precisely

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** A Driver may eventually read their own active/relevant TripAssignment, the Trip necessary to perform it, permitted passenger/trip details required for transportation, and `driver_visible` TripNotes. A Driver must not: browse all assignments in the organization, read another driver's assignment by default, self-reassign or change `driver_id`, change `vehicle_id` (unless a separately approved future vehicle-acknowledgement workflow allows it), mutate `organization_id`, access `operations_only` notes, or access another organization's data in any form.
- **Status:** CONFIRMED
- **Reason:** Restates the P1-E1-S1 §17 driver-assignment principle precisely enough to design RLS policies directly from it, removing any ambiguity about edge cases (vehicle changes, note visibility) that the original pass left implicit.
- **Affected Product Areas:** TripAssignment, TripNote RLS design
- **Dependencies:** ZD-041, ZD-048
- **Owner:** Security
- **Review Trigger:** Schema design (P1-E1-S2)

---

**Open / undecided (domain-model.md §Q) — none of these are confirmed decisions. TripNote visibility (ZD-048), Platform Admin representation (ZD-049), and Dispatcher vs. Operations Staff (now ZD-072) are resolved and removed from this list:**

- **Public facility/service-area directory for intake** — UNKNOWN, additionally gated on ZD-016 (launch territory still unknown).
- **Requester as a persistent entity** (vs. per-request snapshot) — UNKNOWN; deferred, not blocking current schema design.
- **Facility self-service portal shape** — UNKNOWN; already POST-MVP per the scope register.

### ZD-053 — Five separate lifecycle concepts; no unified status field

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Zenward has five distinct lifecycle concepts — TransportationRequest, Trip, TripAssignment, TripException, and TripEvent (the last being history, not a stateful lifecycle) — and a status on one entity is never used to represent another's lifecycle. UI labels are analyzed individually rather than mechanically converted into stored states.
- **Status:** CONFIRMED
- **Reason:** Conflating these (e.g., letting assignment presence live on Trip, or letting a delay condition become a Trip state) was identified as the single most likely path to an unmaintainable, ambiguous state machine.
- **Affected Product Areas:** All lifecycle/state schema design
- **Dependencies:** ZD-045
- **Owner:** Product / Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-054 — TransportationRequest lifecycle: pending / accepted / declined / cancelled

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** TransportationRequest has exactly four states. `pending → accepted` is system-driven, triggered atomically by the creation of the first Trip against the request — never a separate manual action. Child Trip outcomes (cancellation, completion) never write back onto Request.state.
- **Status:** CONFIRMED
- **Reason:** Smallest state model that captures every real behavioral distinction the product needs (submitted-vs-reviewed carries no distinct behavior, so was collapsed into `pending`).
- **Affected Product Areas:** TransportationRequest schema design
- **Dependencies:** ZD-045
- **Owner:** Product
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-055 — Trip lifecycle: 9 canonical states, En Route/Arrived disambiguated

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** Trip.state is one of exactly 9 values: `scheduled`, `en_route_to_pickup`, `arrived_at_pickup`, `passenger_onboard`, `en_route_to_destination`, `arrived_at_destination`, `completed`, `cancelled`, `no_show`. The backend never stores a bare `en_route` or `arrived` value — always the pickup-leg or destination-leg variant. `completed` is reachable only from `arrived_at_destination`.
- **Status:** CONFIRMED
- **Reason:** Resolves the ambiguity flagged in the work item directly; keeping `passenger_onboard` distinct from `en_route_to_destination` captures a real NEMT-specific loading-time gap, not an arbitrary split.
- **Affected Product Areas:** Trip schema design, driver execution UI
- **Dependencies:** ZD-045
- **Owner:** Product / Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-056 — No Draft Trip state at MVP

- **Date:** 2026-08-30
- **Category:** Product
- **Decision:** Trip is created directly into `scheduled` once minimum required data is valid. No `draft` state is introduced.
- **Status:** CONFIRMED
- **Reason:** No approved draft-trip workflow exists; an unassigned `scheduled` Trip already represents "not yet fully arranged" without a separate concept.
- **Affected Product Areas:** Trip creation flow
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** A future, explicitly approved multi-step/draft trip-creation workflow

### ZD-057 — Assignment presence stays fully derived, never stored on Trip

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** "Needs Assignment" and "Assigned" remain UI-only presentations derived from TripAssignment's existence, never a field on Trip.
- **Status:** CONFIRMED
- **Reason:** Direct continuation of ZD-051 (TripAssignment as sole source of truth) — storing a redundant status on Trip would reintroduce the exact synchronization risk that decision eliminated.
- **Affected Product Areas:** Trip, TripAssignment schema design
- **Dependencies:** ZD-051
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-058 — TripAssignment lifecycle stays timestamp-based; no enum added

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** No additional lifecycle enum is added to TripAssignment. Creation, ending, and reassignment remain fully expressed through `assigned_at`/`ended_at`/`end_reason` and row insertion.
- **Status:** CONFIRMED
- **Reason:** Timestamps and row history already express every state transition TripAssignment needs; an enum would duplicate what the timestamps already say.
- **Affected Product Areas:** TripAssignment schema design
- **Dependencies:** ZD-051
- **Owner:** Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-059 — Driver execution actions and their event/state mapping

- **Date:** 2026-08-30
- **Category:** Product
- **Decision:** Six driver actions are state-changing (each maps 1:1 to a Trip transition and a TripEvent): Start Trip, Arrived at Pickup, Passenger Onboard, Depart to Destination, Arrived at Destination, Complete Trip. "Call Passenger" is a utility action that does not change Trip.state but does generate an informational TripEvent (audit value for no-show/contact-attempt history). "View Trip" and "Navigate" generate no event. "Flag Exception" creates a TripException, not a Trip state change.
- **Status:** CONFIRMED
- **Reason:** Distinguishes state-changing actions (which need the full controlled-transition boundary) from utility actions (which don't), directly informing which future endpoints need the heaviest verification.
- **Affected Product Areas:** Driver execution flow, TripEvent taxonomy
- **Dependencies:** ZD-055
- **Owner:** Product / Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-060 — Controlled transition boundary as the mandatory mutation pattern

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** No future client (driver or operations) is ever granted generic `UPDATE trips SET state = <value>` capability. Every lifecycle mutation passes through a controlled boundary verifying auth user → membership → linked Driver (where applicable) → active TripAssignment → organization consistency → current Trip state → transition legality, before writing state + TripEvent + AuditEvent atomically.
- **Status:** CONFIRMED
- **Reason:** Direct continuation of the RLS-first, deny-by-default principle (ZD-038) applied specifically to lifecycle mutations, which are more complex than simple CRUD and need transition-specific validation RLS alone can't fully express.
- **Affected Product Areas:** All future lifecycle-mutation APIs/RPCs
- **Dependencies:** ZD-038
- **Owner:** Engineering / Security
- **Review Trigger:** API/RPC design (P1-E2)

### ZD-061 — Atomic state + event + audit writes

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Every state-changing mutation writes Trip.state, its TripEvent, and any required AuditEvent in a single database transaction. The system must never be observable with one written and not the others.
- **Status:** CONFIRMED
- **Reason:** A Trip state change without a corresponding event (or vice versa) would break the auditability the whole event/audit model exists for.
- **Affected Product Areas:** All future lifecycle-mutation implementation
- **Dependencies:** ZD-060
- **Owner:** Engineering
- **Review Trigger:** RPC/transaction implementation (P1-E2)

### ZD-062 — Concurrency strategy: expected-state validation + row locking, no idempotency keys at MVP

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Concurrency is handled via expected-current-state validation plus row-level locking within the transition transaction, a future partial unique index enforcing one active TripAssignment per trip, and treating a repeated identical transition (retry) as an idempotent no-op success. Client-supplied idempotency keys and `updated_at`/version optimistic-concurrency columns are explicitly not adopted at MVP.
- **Status:** CONFIRMED
- **Reason:** Covers the realistic race conditions (simultaneous cancel/arrival, simultaneous reassignment, driver retry on poor connectivity) without the added protocol complexity of idempotency keys or version columns, which would be redundant given row locking.
- **Affected Product Areas:** All future lifecycle-mutation implementation
- **Dependencies:** ZD-051, ZD-060
- **Owner:** Engineering
- **Review Trigger:** A demonstrated real-world case the simpler approach doesn't cover

### ZD-063 — TripEvent categories; TripAssignment vs. TripEvent relationship

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** TripEvent entries fall into four categories — state-transition, assignment, informational, system — illustrative, not a finalized enum. TripAssignment remains the canonical, queryable source of truth for current/historical assignment; TripEvent additionally carries human-readable assignment-change entries so the timeline reads naturally without a separate query.
- **Status:** CONFIRMED
- **Reason:** Keeps TripAssignment's RLS-critical role (domain-model.md §17) separate from TripEvent's narrative role, while still giving dispatchers a single readable timeline.
- **Affected Product Areas:** TripEvent schema design
- **Dependencies:** ZD-051
- **Owner:** Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-064 — TripException lifecycle: open/resolved only; driver create-only

- **Date:** 2026-08-30
- **Category:** Product / Security
- **Decision:** TripException has exactly two states, `open` and `resolved` — no separate `dismissed` state. Driver may create an exception only on their own actively-assigned trip; only Dispatcher/Organization Admin may resolve one. An open exception does not automatically block Trip transitions at MVP.
- **Status:** CONFIRMED
- **Reason:** A third state would track a distinction the resolution note already carries; the create/resolve split matches the same driver-narrow-write pattern already established for TripNote.
- **Affected Product Areas:** TripException schema design
- **Dependencies:** ZD-045
- **Owner:** Product / Security
- **Review Trigger:** A specific, approved need for exception types to hard-block transitions

### ZD-065 — Running Late is a derived condition, never a Trip state

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** "Running Late" is computed from scheduled time vs. current time and is never stored as a Trip field or Trip state. A delay significant enough to need tracking or action is recorded as a TripException, not a Trip.state change.
- **Status:** CONFIRMED
- **Reason:** A stored "late" field would immediately go stale; a Trip.state value would conflict with the trip's genuine operational state (e.g., simultaneously `en_route_to_pickup` and "late"), which the work item explicitly identified as the failure mode to avoid.
- **Affected Product Areas:** Trip presentation layer, TripException
- **Dependencies:** ZD-055, ZD-064
- **Owner:** Product
- **Review Trigger:** None anticipated

### ZD-066 — No-show is a distinct Trip terminal state, separate from the related exception

- **Date:** 2026-08-30
- **Category:** Product
- **Decision:** `no_show` is a Trip terminal state, reachable only from `en_route_to_pickup` or `arrived_at_pickup`, and always a deliberate human decision — never automatic or time-triggered. `passenger_unavailable` (a TripException) may precede it as an in-progress attention flag but does not automatically become a no-show.
- **Status:** CONFIRMED
- **Reason:** NEMT operations need an unambiguous, queryable no-show outcome distinct from a routine cancellation; automatic time-based triggering isn't possible yet since wait-time policy (ZD-020) remains unresolved, so the decision is deliberately kept human-driven.
- **Affected Product Areas:** Trip schema design, driver/dispatcher execution UI
- **Dependencies:** ZD-055
- **Owner:** Product
- **Review Trigger:** Resolution of ZD-020 (wait-time rules), which may enable a future assisted/automatic no-show suggestion — not automatic execution

### ZD-067 — Cancellation model

- **Date:** 2026-08-30
- **Category:** Product / Security
- **Decision:** Only Dispatcher/Organization Admin execute a `→ cancelled` transition (from any non-terminal state); a driver may request one via a TripException but never executes it; a public requester's request goes through operations, not a direct mutation. The active TripAssignment is closed (never deleted); a reason is mandatory; `cancelled` is terminal with no normal-actor reopening.
- **Status:** CONFIRMED
- **Reason:** Matches the established driver-narrow-write pattern and keeps cancellation fully auditable with a mandatory reason, consistent with the no-silent-history-rewrite principle.
- **Affected Product Areas:** Trip, TripAssignment schema design
- **Dependencies:** ZD-055, ZD-058
- **Owner:** Product / Security
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-068 — Write-once terminal timestamps may be denormalized on Trip

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Fields like `completed_at` (and analogously `cancelled_at`) may exist directly on Trip despite ZD-051's rejection of denormalizing *current* assignment fields. These are distinguished as write-once historical facts, never subsequently changed, unlike a "current driver" pointer, which represents a changing relationship that can drift out of sync with its source of truth.
- **Status:** CONFIRMED
- **Reason:** Clarifies that ZD-051 is about avoiding duplicated *mutable* state, not about avoiding all denormalization — a distinction worth making explicit so schema design doesn't over-apply ZD-051 to unrelated cases.
- **Affected Product Areas:** Trip schema design
- **Dependencies:** ZD-051
- **Owner:** Engineering
- **Review Trigger:** Schema design (P1-E1-S3)

### ZD-069 — Return transportation as a second Trip row; optional `leg` label

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** Return transportation is a second, ordinary Trip row sharing `request_id` with the outbound Trip — no new relational entity. A not-yet-arranged return is the absence of a second Trip row, not a state on anything. A lightweight optional `leg` label (`outbound`/`return`/`unspecified`) on Trip is recommended for display grouping.
- **Status:** CONFIRMED for the core model (second Trip row, shared request_id, independent timing); the `leg` field itself is **PROVISIONAL**, pending confirmation it's wanted
- **Reason:** Confirms and extends the P1-E1-S1 1:N Request→Trip cardinality decision (ZD-045) directly to the outbound/return case, which was its original motivating example.
- **Affected Product Areas:** Trip schema design
- **Dependencies:** ZD-045
- **Owner:** Product
- **Review Trigger:** Schema design (P1-E1-S3) — confirm the `leg` field before or during

### ZD-070 — Driver availability confirmed out of Trip-lifecycle scope

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** Driver operational availability (`Available`/`On Trip`/`Break`/`Unavailable`) is confirmed as a separate concept from Trip lifecycle, not designed in this phase, and never derived from or stored as a Trip field.
- **Status:** CONFIRMED (as a scope boundary — the availability system itself remains undesigned)
- **Reason:** Not required for the clarity of the five lifecycle concepts this phase defines; designing it now would be speculative without an approved driver-scheduling workflow.
- **Affected Product Areas:** Future driver availability/shift design
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** A future work item scoped specifically to driver availability/scheduling

### ZD-071 — Public request-state wording must never imply Trip/Assignment facts

- **Date:** 2026-08-30
- **Category:** Product / Security
- **Decision:** Public-facing copy for TransportationRequest states must never imply driver assignment, vehicle confirmation, or a locked pickup time — those are Trip/TripAssignment facts, which the public surface has no read access to. "Ride Confirmed" is never permitted copy driven by Request state alone.
- **Status:** CONFIRMED as a principle; exact copy for each state is **deferred** (content decision, not architecture)
- **Reason:** Directly follows from Public having zero read access to Trip/TripAssignment (domain-model.md §M) — any UI implying otherwise would be describing data the requester was never actually shown.
- **Affected Product Areas:** Public website request-status messaging
- **Dependencies:** ZD-054
- **Owner:** Product
- **Review Trigger:** Public request-status UI design

---

**Open / undecided from P1-E1-S2 (lifecycle-model.md, Open product questions) — none of these are confirmed decisions, and none block the Lifecycle Security Gate:**

- **Driver acknowledgement of assignment** — recommended useful-but-deferred (not required MVP behavior); needs explicit product confirmation before schema design treats it as present or absent.
- **Driver assignment-decline capability** — not designed; UNKNOWN whether it exists at all.
- **`leg` field adoption** (ZD-069) — PROVISIONAL, needs confirmation.
- **Exact public-facing Request-state copy** (ZD-071) — deferred content decision.
- **Exact cancellation-reason taxonomy** — free text assumed sufficient at MVP; confirm.

### ZD-072 — Operations Staff removed; Dispatcher is the one canonical operations role

- **Date:** 2026-08-30
- **Category:** Product / Architecture
- **Decision:** `operations_staff` is not introduced as a Membership role. `dispatcher` is the sole canonical operations-tier role. This resolves the item deferred from P1-E1-S1A/S2.
- **Status:** CONFIRMED
- **Reason:** Every permission evaluated for "Dispatcher" and "Operations Staff" across P1-E1-S1 and P1-E1-S2 was identical; no genuine permission difference was ever identified, only a title difference in prior UI copy. Per the explicit instruction to collapse identical-permission roles, a second role was not preserved by default.
- **Affected Product Areas:** Membership role enum, all operations-facing permissions
- **Dependencies:** ZD-039
- **Owner:** Product / Security
- **Review Trigger:** A concretely identified, approved permission difference between operations staff tiers

### ZD-073 — MVP organization role set finalized

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Membership.role is exactly one of `{organization_admin, dispatcher, driver}`. No other value is valid, including anything resembling platform admin (which is never expressed via Membership at all — see ZD-049).
- **Status:** CONFIRMED
- **Reason:** Smallest role set that covers every distinct permission tier identified across the domain, lifecycle, and authorization passes; avoids speculative role proliferation.
- **Affected Product Areas:** Membership schema design
- **Dependencies:** ZD-039, ZD-072
- **Owner:** Product / Security
- **Review Trigger:** Schema design (P1-E2)

### ZD-074 — Platform Admin direct read is scoped to four tables

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** Platform Admin receives standing, RLS-level, cross-organization SELECT only on Organization, PlatformAdminGrant, Membership, and AuditEvent. All other tenant-operational tables (Passenger, Trip, TripAssignment, TripEvent, TripNote, TripException, TransportationRequest, Driver, Vehicle, Facility) require a specific, controlled, audited support action if cross-organization access is ever genuinely needed — never a blanket SELECT policy.
- **Status:** CONFIRMED
- **Reason:** Directly implements the instruction not to assume platform admins need unrestricted browser-level SELECT on every tenant table; the four granted tables are genuinely platform-level or low-sensitivity/high-support-value, while operational and passenger data stay behind an audited, deliberate path even for platform admins.
- **Affected Product Areas:** RLS policy design for all 15 entities
- **Dependencies:** ZD-049
- **Owner:** Security
- **Review Trigger:** RLS policy design (P1-E2); any future concrete need for cross-org operational-data support access, which should be designed as its own audited action, not a policy widening

### ZD-075 — Least-privilege split between Organization Admin and Dispatcher

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** Driver profile management (create/deactivate) and Vehicle administration (create/update) belong to Organization Admin, not Dispatcher. Dispatcher gets read-only access to Driver and Vehicle records for assignment purposes.
- **Status:** CONFIRMED
- **Reason:** Both have access-management or fleet-liability implications beyond routine day-to-day dispatch; keeping them with Organization Admin is a deliberate least-privilege choice, not an oversight.
- **Affected Product Areas:** Driver, Vehicle RLS design
- **Dependencies:** ZD-073
- **Owner:** Security
- **Review Trigger:** RLS policy design (P1-E2)

### ZD-076 — Named transition actions replace a generic transition action

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** There is no generic `transition_trip_state` action. Each driver-initiated Trip transition is its own named action (`start_trip_to_pickup`, `mark_arrived_at_pickup`, `mark_passenger_onboard`, `start_trip_to_destination`, `mark_arrived_at_destination`, `complete_trip`).
- **Status:** CONFIRMED
- **Reason:** Matches the "small, single-purpose" policy-shape principle directly — one action name standing for six different real operations would be exactly the ambiguity this whole model set out to avoid.
- **Affected Product Areas:** Driver execution API/RPC design
- **Dependencies:** ZD-055, ZD-060
- **Owner:** Engineering
- **Review Trigger:** API/RPC design (P1-E2)

### ZD-077 — Membership status stays binary (active/inactive); no cached authorization claims

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** Membership.status is exactly `active` or `inactive` — no `invited`/`pending`/`suspended` domain states. RLS authorization checks query live Membership state on every request; no custom JWT claim is trusted as authoritative for the active/inactive gate.
- **Status:** CONFIRMED
- **Reason:** An invitation-not-yet-accepted nuance is better captured by a nullable timestamp than a new state; a cached claim would reintroduce exactly the "session still valid after revocation" risk the whole membership-lifecycle rule exists to prevent.
- **Affected Product Areas:** Membership schema design, RLS helper design
- **Dependencies:** ZD-039
- **Owner:** Security
- **Review Trigger:** Schema design (P1-E2)

### ZD-078 — Hard delete philosophy: presumptively denied for historically significant entities

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** No ordinary hard DELETE, for any role, on Trip, TripAssignment, TripEvent, TripNote, TripException, AuditEvent, TransportationRequest, Driver (with any assignment history), or Passenger (with any trip history). Narrow exceptions (a Vehicle/Facility/Membership row with provably zero historical references) remain Organization Admin/Platform Admin actions, not routine capabilities.
- **Status:** CONFIRMED (as philosophy — no archive-field mechanism is introduced yet)
- **Reason:** Consistent with the append-only/no-silent-history-rewrite principle already established for TripEvent and AuditEvent, extended to every entity with plausible historical significance.
- **Affected Product Areas:** All entity schema design
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** Schema design (P1-E2)

---

**Open / undecided from P1-E1-S3 (authorization-model.md, Open questions) — none of these are confirmed decisions, and none block the Authorization Security Gate:**

- **Exact Passenger field-level visibility for Driver** — which specific columns, vs. the full record Organization Admin/Dispatcher see. Schema-design-time question.
- **Driver acknowledgement/decline capability** — carried over from lifecycle-model.md, still unresolved.
- **Narrow hard-delete edge cases for Vehicle/Facility** — minor implementation convenience, not a security requirement either way.
- **Future JWT claim caching for performance** — if ever introduced, must be paired with the live-check discipline in ZD-077; not needed at MVP.

**Addendum to ZD-015 (2026-08-30, lifecycle model):** ZD-015's provisional trip-status list is now superseded for backend purposes by the canonical Trip state model in ZD-055/lifecycle-model.md §C. The visual system's status *presentation* categories (StatusBadge, TripStatus) remain valid at the UI layer — the label→category mapping in `src/components/ui/TripStatus.tsx` should be revisited against the confirmed canonical states during schema design, but no UI code is changed in this phase.

**Addendum to ZD-015 (2026-08-29, design gate):** Design review reaffirmed that the trip status list stays PROVISIONAL. The visual system may define status *presentation* categories, but the actual Zenward trip state machine is established during transportation workflow/domain modelling — the provisional list must not be converted into application logic before that.

### ZD-079 — Public marketing site becomes a separate repository

- **Date:** 2026-08-30
- **Category:** Architecture / Deployment
- **Decision:** The public Zenward marketing/acquisition website will become a separate Next.js project in its own independently deployable repository. This repository (`ZenWard`) remains the product application, ultimately containing only `/operations/...`, `/driver/...`, and minimal application-level routes (e.g. authentication, once designed) — no marketing pages. The standalone marketing repository (not yet created) will own `/`, `/request-transportation`, `/healthcare-providers`, `/services`, `/about`, `/contact`, and required legal pages. `PublicHeader`/`PublicFooter` and other marketing-specific components belong to that repository, not this one.
- **Status:** CONFIRMED (the separation itself). Execution is explicitly **not** performed yet — see public-marketing-separation.md for what moves, what's shared, and what's cleaned up once the standalone repository exists.
- **Reason:** The marketing site needs to launch and evolve independently of the operational platform's development pace; separation also reduces the public-facing surface's proximity to operational systems and gives each surface its own deployment lifecycle.
- **Affected Product Areas:** `src/app/(public)/`, `src/components/public/`, deployment/DNS strategy, README structure
- **Dependencies:** None
- **Owner:** Engineering / Product
- **Review Trigger:** Creation of the standalone marketing repository — at which point the cleanup list in public-marketing-separation.md §4 executes

**Open / undecided from this decision (public-marketing-separation.md §6) — non-blocking for recording the decision itself, but must resolve before executing the cleanup:**

- What `/` serves in the product app once marketing moves out.
- Domain/subdomain strategy for the two deployments (compounds ZD-027, production domain still UNKNOWN).
- Whether design tokens eventually warrant a shared, versioned package instead of two manually-synced `globals.css` copies.

### ZD-080 — Driver has no generic Passenger table SELECT; passenger data is minimum-necessary and assignment-scoped

- **Date:** 2026-08-30
- **Category:** Security
- **Decision:** The Driver role does not receive generic direct SELECT access to the canonical Passenger table, under any RLS policy shape — not even one scoped to "the passenger on my assigned trip." Driver-required passenger information (potentially: display name, phone number where operationally required, pickup/destination information, permitted assistance requirements, companion information, driver-visible instructions) is delivered only through a controlled, assignment-scoped read model — a narrowly defined security-invoker view, a carefully scoped RPC, or a trusted server query returning explicit fields — chosen at schema/API design time, not decided here. No universal Passenger read helper is created. The authorization chain remains: auth user → active Membership → linked Driver → active/relevant TripAssignment → same Organization → permitted Trip → minimum-necessary driver data projection. Direct knowledge of a `passenger_id` or `trip_id` grants no access on its own.
- **Status:** CONFIRMED
- **Reason:** Row Level Security controls which rows a query can see, but does not by itself guarantee minimum-necessary *column* exposure — a row-scoped Driver SELECT policy on Passenger would still return every column in that row. Removing table-level SELECT entirely, in favor of an explicit field-projecting mechanism, removes that failure mode by construction rather than relying on a second, easy-to-forget column-privilege layer.
- **Affected Product Areas:** Passenger, Trip, TripAssignment RLS/API design
- **Dependencies:** ZD-041, ZD-060 (amends the Driver-Passenger access description in authorization-model.md §M/§I, which had described a row-scoped table SELECT)
- **Owner:** Security
- **Review Trigger:** Schema/API design (P1-E2) — choice of view vs. RPC vs. trusted-query mechanism, and the exact minimum-necessary field list

### ZD-081 — CHECK constraints, not native ENUM types, for canonical states

- **Date:** 2026-08-30
- **Category:** Architecture
- **Decision:** Every canonical state/role/visibility column (`memberships.role`/`status`, `transportation_requests.state`, `trips.state`, `trip_notes.visibility`, `trip_exceptions.status`) is implemented as `text` + a `CHECK` constraint, not a native PostgreSQL `ENUM` type.
- **Status:** CONFIRMED
- **Reason:** Adding a new allowed value to a CHECK constraint is a plain, transaction-safe migration; altering a native ENUM has real migration friction (values can't be added and used in the same transaction in the way DDL elsewhere in a migration can). Several of these lists are documented as likely to evolve (e.g., trip exception taxonomy), so migration maintainability was prioritized without sacrificing "no unconstrained free text for canonical states."
- **Affected Product Areas:** All canonical-state columns across the schema
- **Dependencies:** ZD-053 through ZD-055 (lifecycle states), ZD-048 (note visibility), ZD-064 (exception states)
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-082 — Composite foreign keys implemented via UNIQUE(id, organization_id)

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** ZD-041's composite-FK strategy is now implemented exactly as specified: every tenant-owned parent table (`drivers`, `passengers`, `facilities`, `vehicles`, `transportation_requests`, `trips`) carries `UNIQUE (id, organization_id)`, and every cross-entity child reference (trip→passenger/request/facility, trip_assignment→trip/driver/vehicle, trip_events/trip_notes/trip_exceptions→trip) is a composite FK against that pair — never a plain single-column FK for these relationships.
- **Status:** CONFIRMED — implemented and verified (adversarial tests V/W/X and the full constraint-test suite, all passing)
- **Reason:** Makes a cross-tenant relationship a schema-level impossibility rather than something RLS alone is trusted to prevent, exactly as ZD-041 anticipated.
- **Affected Product Areas:** All tenant-owned table relationships
- **Dependencies:** ZD-041
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-083 — Column-level GRANT/REVOKE for field-level mutation enforcement

- **Date:** 2026-08-30
- **Category:** Architecture / Security
- **Decision:** Where authorization-model.md §K distinguishes field groups with different owners (planning vs. lifecycle vs. tenant vs. reference fields), this is enforced at the Postgres column-privilege level (`REVOKE UPDATE ... ; GRANT UPDATE (col1, col2, ...) ...`), not by policy logic alone. Applied to `trips`, `trip_assignments`, `memberships`, and `organizations`. On `trips` specifically, this phase is deliberately more conservative than the approved model strictly requires: `state` and all terminal timestamp/reason fields are not grantable to any authenticated role at all yet, since the controlled transition RPC that would need them is explicitly out of scope for this phase (ZD-060/ZD-061 not yet built).
- **Status:** CONFIRMED
- **Reason:** RLS controls row visibility, not column exposure — column-level privilege is the correct, native Postgres mechanism for the field-level distinctions authorization-model.md §K already called for, and closes the gap without waiting for RPCs that don't exist yet.
- **Affected Product Areas:** `trips`, `trip_assignments`, `memberships`, `organizations` RLS design
- **Dependencies:** ZD-060, ZD-061
- **Owner:** Security
- **Review Trigger:** Lifecycle-transition RPC design (a later phase) — at that point, `trips.state`/terminal fields may become reachable only through that RPC's SECURITY DEFINER context, still never through a direct client GRANT

### ZD-084 — Future SECURITY DEFINER/RPC function privilege convention (mandatory migration rule, not ALTER DEFAULT PRIVILEGES)

- **Date:** 2026-08-31
- **Category:** Security / Process
- **Decision:** Every future migration that creates a `SECURITY DEFINER` function, or any function intended to be Supabase-RPC-callable, must explicitly `REVOKE EXECUTE ... FROM PUBLIC` and then `GRANT EXECUTE ... TO <only the roles that genuinely need it>` in the **same migration** that creates the function. `ALTER DEFAULT PRIVILEGES` is deliberately **not** used to pre-harden this project-wide, because that command is scoped to a specific creator role, and the local migration-runner role (`postgres`, in this Docker-based local setup) cannot be safely assumed identical to whatever role runs migrations in a future hosted/deployed environment — applying a role-specific default-privilege rule against the wrong role would silently protect nothing.
- **Status:** CONFIRMED
- **Reason:** Discovered via direct audit (P1-E2-S1A) that two trigger-support functions from the very first migration had never had PostgreSQL's default PUBLIC EXECUTE grant revoked — not exploitable in practice (both are `RETURNS trigger` functions, callable neither directly nor via PostgREST's RPC schema cache), but a real minimum-privilege gap all the same, and exactly the kind of gap a per-migration convention prevents at the source rather than requiring a later corrective audit to catch.
- **Affected Product Areas:** All future SECURITY DEFINER/RPC function migrations
- **Dependencies:** ZD-038 (RLS-first), the SECURITY DEFINER rules already established in authorization-model.md §T
- **Owner:** Security
- **Review Trigger:** Every future migration adding a SECURITY DEFINER or RPC-reachable function — reviewed against this convention before merge

### ZD-085 — Controlled-mutation error contract: six custom SQLSTATEs, code-based branching only

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** Every controlled-mutation RPC (P1-E2-S2) rejects with one of exactly six custom SQLSTATEs — `ZW001 unauthorized`, `ZW002 not_found`, `ZW003 stale_state`, `ZW004 illegal_transition`, `ZW005 assignment_conflict`, `ZW006 invalid_input` — via `RAISE EXCEPTION ... USING ERRCODE = 'ZW0xx'`, with a short, stable, tenant-data-free message token (never a sentence, never row contents). Callers (application code and tests alike) must branch on PostgREST's `code` field in the JSON error body, never on message text.
- **Status:** CONFIRMED — implemented and verified (125 SQL assertions plus 12 real-HTTP cross-validation checks, all passing; HTTP-12 specifically confirms PostgREST surfaces the custom code in the response body)
- **Reason:** A stable, small, documented error vocabulary lets every caller (future UI, tests, other services) distinguish failure modes reliably without parsing human-readable text, which is exactly the kind of brittleness that breaks silently when a message is later reworded for clarity.
- **Affected Product Areas:** All P1-E2-S2 mutation RPCs; docs/data/mutation-api.md
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** Any future mutation RPC family — must reuse this same six-code vocabulary rather than inventing new codes ad hoc

### ZD-086 — Fixed row-locking order: Trip, then active TripAssignment

- **Date:** 2026-08-31
- **Category:** Architecture
- **Decision:** Every controlled-mutation RPC that touches both tables locks `trips` first (`SELECT ... FOR UPDATE`) and the active `trip_assignments` row (if any) second, in that fixed order, with no exception. A pure idempotent-no-op read path may skip the second lock entirely (nothing to protect), but never acquires it out of order.
- **Status:** CONFIRMED — implemented and verified (mutation_atomicity_tests.sql forced-failure test; mutation_concurrency_test.sh genuine two-process concurrency test, both passing)
- **Reason:** Uniform lock ordering across every mutation path is what makes concurrent calls deadlock-free by construction rather than "usually fine" — two transactions each following the same fixed order can never form a lock cycle.
- **Affected Product Areas:** All P1-E2-S2 mutation RPCs
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** Any future mutation RPC touching more than one of these tables — must follow this same order, extended consistently if a third table is added to a lock chain

### ZD-087 — Event/Audit matrix: Driver progression is TripEvent-only, assignment/cancellation/no-show/completion get both

- **Date:** 2026-08-31
- **Category:** Product / Security
- **Decision:** The 5 non-terminal Driver progression transitions write a TripEvent only. Assignment, reassignment, cancellation, no-show, and Trip completion (the one Driver action that reaches a terminal state) write both a TripEvent and an AuditEvent. Exactly one of each per successful call — closing an assignment as a side effect (on reassignment/cancellation/no-show/completion) is folded into that one event/audit row, never logged as a separate event.
- **Status:** CONFIRMED
- **Reason:** lifecycle-model.md/authorization-model.md never fully enumerated this split; the work item's own guidance (AuditEvent "strongly considered mandatory" for actions that materially change responsibility or reach a terminal disposition, TripEvent sufficient for routine progress) is adopted directly and recorded here as the definitive rule, rather than left to be reinvented per-function.
- **Affected Product Areas:** trip_events, audit_events, all P1-E2-S2 mutation RPCs
- **Dependencies:** None
- **Owner:** Product / Security
- **Review Trigger:** Any future mutation RPC family — apply this same "does it change responsibility or reach a terminal state" test to decide TripEvent-only vs. both

### ZD-088 — Assignment-eligible Trip states: scheduled, en_route_to_pickup, arrived_at_pickup

- **Date:** 2026-08-31
- **Category:** Product
- **Decision:** `assign_trip` and `reassign_trip` are legal only while a Trip is in `scheduled`, `en_route_to_pickup`, or `arrived_at_pickup`. Once a Trip reaches `passenger_onboard` or later, ordinary (re)assignment is no longer permitted through these RPCs.
- **Status:** CONFIRMED — recorded fresh; neither lifecycle-model.md nor authorization-model.md specified a restricted eligible-state list for (re)assignment before this phase (checked directly against both documents; no existing rule was found to follow or contradict)
- **Reason:** Reassigning a driver mid-transport (after the passenger is already onboard) is an operationally unusual, high-risk action that the MVP does not need to support through the ordinary controlled path; a conservative allow-list is safer than an unconstrained one and is trivially loosened later if a real dispatch workflow needs it.
- **Affected Product Areas:** assign_trip, reassign_trip
- **Dependencies:** None
- **Owner:** Product
- **Review Trigger:** A real dispatcher workflow that needs mid-transport reassignment — would require a deliberate, separately-reviewed extension, not a silent widening

### ZD-089 — RPC architecture: one narrow function per Driver action, sharing one unexposed internal executor

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** The 6 Driver lifecycle transitions are each their own named, narrow SECURITY DEFINER function (`driver_start_to_pickup`, etc.) accepting only `p_trip_id` and `p_expected_current_state` — never a target-state parameter. All 6 delegate to one shared internal SECURITY DEFINER function (`_driver_execute_trip_transition`) that does accept a from/to state pair, but that internal function is never granted EXECUTE to any client role (`authenticated`, `anon`, or `PUBLIC`) — it is reachable only from within the 6 wrappers' own already-elevated execution context. The single canonical Trip transition matrix lives in one place (`_is_valid_trip_transition`), also never exposed directly.
- **Status:** CONFIRMED — implemented and verified (mutation_privilege_tests.sql "internal-helpers-not-exposed" check; security_definer_exposure-style ACL inspection showing the 3 internal helpers carry only the owner's implicit privilege)
- **Reason:** A single generic "transition trip to state X" RPC would let any caller who could reach it choose an arbitrary target state, defeating the entire per-action authorization design; splitting into narrow named functions while still sharing one implementation avoids both that risk and inconsistent duplicated logic across 6 near-identical function bodies.
- **Affected Product Areas:** All 6 driver_* RPCs, _driver_execute_trip_transition, _is_valid_trip_transition
- **Dependencies:** ZD-084 (privilege convention)
- **Owner:** Security
- **Review Trigger:** Any future action family with more than one legal edge — apply this same "narrow public wrapper, shared unexposed internal executor" pattern rather than one parameterized public function

### ZD-090 — Idempotency semantics: target-state-already-holds is always a safe no-op

- **Date:** 2026-08-31
- **Category:** Architecture
- **Decision:** For every lifecycle mutation RPC, if the Trip is already at the function's own target/terminal state, the call returns success with `changed=false` and performs no write — regardless of what `expected_current_state` (Driver functions) or prior call history the caller supplied. This check is evaluated before any active-assignment requirement, since a terminal transition itself is what closes the active assignment (ZD-087), so a driver retrying their own just-succeeded call must not be rejected merely because their assignment is now closed as a normal consequence. Any state that is neither the function's required from-state nor its target state is rejected as `ZW003 stale_state`, independent of whether `expected_current_state` was supplied.
- **Status:** CONFIRMED — implemented and verified (mutation_lifecycle_tests.sql L7/L16, and the L8 case that specifically distinguishes "retry of one's own successful action" from "terminal reopening via an unrelated action")
- **Reason:** A caller retrying an already-successful request (network timeout, double-tap, at-least-once delivery) must get a safe, informative success back — bouncing them into an authorization error because a natural side effect (assignment closure) already happened would be actively misleading.
- **Affected Product Areas:** All P1-E2-S2 lifecycle mutation RPCs
- **Dependencies:** ZD-087
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-091 — Cancellation and no-show are Organization Admin / Dispatcher actions only, never Driver-initiated

- **Date:** 2026-08-31
- **Category:** Product / Security
- **Decision:** `cancel_trip` and `record_no_show` both require `has_org_role(organization_id, [organization_admin, dispatcher])`; no Driver-facing function exists for either action, even for a Driver's own actively-assigned Trip.
- **Status:** CONFIRMED
- **Reason:** Cancellation and no-show are dispositive, often billing/reporting-relevant administrative decisions with follow-on consequences (rescheduling, family notification, no-show tracking) that authorization-model.md already scopes to operations roles; the work item reaffirms this is not one of the 6 actions a Driver may perform directly, and a Driver observing a genuine no-show or needing a cancellation reports it through operations rather than executing it unilaterally.
- **Affected Product Areas:** cancel_trip, record_no_show, authorization-model.md action matrix
- **Dependencies:** authorization-model.md §N (actor transition permissions)
- **Owner:** Product
- **Review Trigger:** A future Driver-facing "report a problem" workflow — would raise a TripException or a flagged note, not call these RPCs directly, unless explicitly re-decided

### ZD-092 — trip_assignments direct table write retired in favor of assign_trip/reassign_trip

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** The direct INSERT/UPDATE grant and the two RLS policies (`trip_assignments_insert_org_operations`, `trip_assignments_update_org_operations`) that P1-E2-S1 gave Organization Admin/Dispatcher on `trip_assignments` — necessary then because no controlled assignment mechanism existed — are revoked and dropped outright in P1-E2-S2, now that `assign_trip`/`reassign_trip` exist. No role retains any direct write path to this table; SELECT and its two policies are unchanged.
- **Status:** CONFIRMED — implemented and verified (mutation_privilege_tests.sql "trip-assignments-direct-write-revoked"/"superseded-policies-dropped"; mutation_assignment_tests.sql C16)
- **Reason:** Per ZD-084's spirit and the work item's explicit direction, once a controlled RPC exists for a mutation, the raw table-level path that predated it should be retired rather than left as a silent bypass around the RPC's auth chain, idempotency handling, locking, and event/audit logging.
- **Affected Product Areas:** trip_assignments RLS/grants
- **Dependencies:** ZD-084, ZD-089
- **Owner:** Security
- **Review Trigger:** Any future table that gains its own controlled-mutation RPC — apply the same retirement of the direct-write path that predated it

### ZD-093 — Idempotent no-op for Driver transitions requires actor-verified proof, not merely ever-assigned (amends ZD-090)

- **Date:** 2026-08-31
- **Category:** Security
- **Decision:** Amends ZD-090. The Driver-transition idempotent no-op path (`_driver_execute_trip_transition`: "Trip already at target state") additionally requires trusted proof — a `trip_events` row for this Trip with `event_type` = this function's own target event and `actor_user_id = auth.uid()` — that the calling Driver is the one who actually performed that exact transition, not merely that they hold (or ever held) *some* relationship to the Trip. `is_driver_assigned_to_trip` (ever-assigned) remains the correct gate for whether the caller may be considered at all, but it was never sufficient on its own to justify a no-op *success*, since two different Drivers can each satisfy it on the same Trip (one historical, one current). No caller-supplied actor id is introduced anywhere — the check is against the same trusted, append-only `trip_events.actor_user_id` column every mutation function already writes, resolved the same way `auth.uid()` is resolved everywhere else in this codebase.
- **Status:** CONFIRMED — implemented and verified (P1-E2-S2A audit: `mutation_idempotent_authorization_tests.sql` A-F, all passing, including 3 real-HTTP cross-validation checks; the pre-fix gap was additionally reproduced empirically under a temporary, non-persistent copy of the old logic before being fixed, not merely reasoned about)
- **Reason:** Found via targeted audit (P1-E2-S2A) that the original ZD-090 wording ("the Trip is already at the target state" as the sole idempotency test) let a formerly-assigned Driver who never performed a given transition receive a false success merely because a *different* Driver had already performed it after a reassignment — idempotency correctly means "the same authorized operation may safely be retried by the actor who performed it", not "anyone with any historical relationship to the resource receives success once the desired state exists for any reason." Confined to the Driver-transition family: ops actions (`cancel_trip`/`record_no_show`/`assign_trip`/`reassign_trip`) authorize by live-checked, org-scoped role rather than trip-instance-specific actor identity, so no analogous gap exists there — any currently-authorized Organization Admin/Dispatcher legitimately may re-assert an already-true org-level fact, unlike a Driver's inherently personal "this is MY assignment" authorization.
- **Affected Product Areas:** `_driver_execute_trip_transition` (and therefore all 6 `driver_*` RPCs)
- **Dependencies:** ZD-090 (amended, not superseded — the target-state-already-holds precedence over the active-assignment check is unchanged; only the no-op's own eligibility test is tightened)
- **Owner:** Security
- **Review Trigger:** Any future actor-scoped (not role-scoped) mutation RPC with idempotent-retry semantics — apply this same "verify the retry via trusted history, never via mere historical relationship" pattern

### ZD-094 — Driver read API architecture: narrow SECURITY DEFINER projections, explicit composite types, no wildcard serialization

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** The Driver read boundary (P1-E2-S3) is implemented as 4 narrow, purpose-specific `SECURITY DEFINER` functions (`driver_get_profile`, `driver_list_active_trips`, `driver_get_trip_detail`, `driver_list_trip_history`), each `STABLE` (read-only, verified to never mutate `trips`/`trip_assignments`/`trip_events`/`audit_events`), each returning an explicit composite type (`driver_profile_result`, `driver_active_trip_summary`, `driver_trip_detail_result`, `driver_trip_history_entry`) rather than any canonical table rowtype. No function anywhere in this layer uses `passenger.*`, `to_jsonb(passenger)`, `row_to_json(passenger)`, or any other whole-row serialization — every returned field is named explicitly, including inside the `driver_notes` jsonb array (`jsonb_build_object('id', ..., 'body', ..., 'created_at', ...)`, never a serialized `trip_notes` row).
- **Status:** CONFIRMED — implemented and verified (`driver_read_privilege_tests.sql`; `driver_read_minimization_tests.sql`'s exact-column-set assertions against `pg_attribute`, which prove this structurally, not merely by inspection; real HTTP cross-validation confirming the PostgREST JSON shape matches exactly)
- **Reason:** RLS controls rows, not columns (work item §4) — a Driver-facing policy on `passengers` or a widened `trips` policy would still return every column on that row, including any added later. An explicit composite type makes the projection itself the security boundary: a future column added to `trips`/`passengers`/`vehicles`/`trip_notes` cannot appear in a Driver-facing response without a human deliberately editing the type definition.
- **Affected Product Areas:** All 4 Driver read RPCs and their return types
- **Dependencies:** ZD-085 (reuses the same 6-code error contract), ZD-089 (same narrow-function-per-purpose pattern as the mutation RPCs)
- **Owner:** Security
- **Review Trigger:** Any future Driver-facing (or other role-facing) read capability — apply this same pattern rather than a row-scoped table policy or a whole-row-serializing function

### ZD-095 — Trip detail requires a CURRENTLY active assignment; uniform not_found convention for all read denials

- **Date:** 2026-08-31
- **Category:** Security
- **Decision:** `driver_get_trip_detail` requires the caller to hold a currently active (`ended_at IS NULL`) `trip_assignments` row on the specific Trip — a historical assignment alone is never sufficient, and reassignment revokes detailed access on the caller's very next call (live-checked, no JWT refresh needed). Every denial reason for the 4 read RPCs — nonexistent Trip, foreign-org, never-assigned, formerly-assigned-but-reassigned-away, inactive Membership, inactive Driver, zero-membership user, Platform Admin without Driver context — is uniformly `ZW002 not_found`. Unlike the mutation layer (ZD-085's `not_found` vs `unauthorized` distinction, which exists because a Driver retained *read* visibility into a Trip they'd been reassigned away from, via the now-retired `trips_select_assigned_driver`), no such carve-out applies here: since direct base-table Trip access is retired for Driver entirely (ZD-096), a formerly-assigned Driver has zero remaining legitimate visibility into the Trip through any path, so there is no "they can see it, they just can't act on it" case to distinguish — `unauthorized` (ZW001) is simply never reachable from these 4 functions.
- **Status:** CONFIRMED — implemented and verified (`driver_read_authorization_tests.sql` DETAIL-1 through DETAIL-11, MULTIORG-1/2; real HTTP READ-5/5B for reassignment revocation)
- **Reason:** Matches the work item's explicit requirement (§15/§30) that reassignment revoke detailed access immediately, and keeps the read boundary simpler and more conservative than the write boundary's necessarily more nuanced convention, since no legitimate reason exists for a Driver to retain any visibility into a Trip they no longer hold.
- **Affected Product Areas:** `driver_get_trip_detail` (and, by the same reasoning, `driver_list_active_trips`/`driver_list_trip_history`, which are inherently scoped by their own WHERE clauses rather than needing a separate denial-reason distinction)
- **Dependencies:** ZD-085, ZD-096
- **Owner:** Security
- **Review Trigger:** None anticipated

### ZD-096 — Driver base-table SELECT retirement: 6 policies retired, trip_exceptions deliberately retained

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** Following the full Driver read-surface audit (docs/security/driver-data-minimization.md), 6 Driver-scoped base-table SELECT policies are retired as superseded by the new read API: `drivers_select_own` (→ `driver_get_profile`), `trips_select_assigned_driver` (→ `driver_list_active_trips`/`driver_get_trip_detail`/`driver_list_trip_history`), `trip_assignments_select_own_driver` (→ the same three), `vehicles_select_assigned_driver` (→ vehicle summary embedded in the read API), `trip_notes_select_assigned_driver_visible` (→ `driver_notes` embedded in `driver_get_trip_detail`), and `trip_events_select_assigned_driver` (retired per work item §24 with no replacement — no TripEvent timeline is exposed to Driver in this phase at all). `trip_exceptions_select_assigned_driver` is deliberately **NOT** retired: no replacement projection is built this phase (work item §26 explicitly defers building one), so retiring it would remove existing, already narrowly-scoped (ever-assigned-Driver-only) functionality with no successor and no independently-identified over-exposure beyond that existing scoping. Organization Admin/Dispatcher SELECT access on every affected table is completely untouched.
- **Status:** CONFIRMED — implemented and verified (`driver_read_privilege_tests.sql` "retired-policies-gone"/"trip-exceptions-deliberately-retained"/"ops-access-untouched"; `rls_adversarial_tests.sql` tests F/I updated to the new contract per work item §58, with the old/new contract documented inline in that file rather than silently changed)
- **Reason:** `trips_select_assigned_driver` in particular exposed every column on any Trip a Driver ever held an assignment on, indefinitely, including fields with no Driver-facing need (`request_id`, `cancellation_reason`, etc.) — a textbook case of the exact column-minimization risk RLS alone cannot prevent (work item §4/§5, "do not assume Passenger is the only table with column-minimization risk"). `trip_events_select_assigned_driver` separately exposed `actor_user_id` (identifying which other person performed historical actions) indefinitely, matching the work item's explicit "no internal actor/event metadata without a concrete need" (§24).
- **Affected Product Areas:** `drivers`, `trips`, `trip_assignments`, `vehicles`, `trip_notes`, `trip_events` RLS policy inventory
- **Dependencies:** ZD-080 (the same data-minimization principle extended beyond Passenger), ZD-094
- **Owner:** Security
- **Review Trigger:** A future Driver-facing TripException status view — would need its own explicit review of whether `trip_exceptions_select_assigned_driver` should then also be retired in favor of a purpose-built projection, consistent with the pattern established here

### ZD-097 — Passenger minimum-necessary allowlist for the Driver read API

- **Date:** 2026-08-31
- **Category:** Security / Product
- **Decision:** The Driver read API returns exactly two `passengers` fields, ever: `display_name` (active list and detail) and `phone` (detail only, never list or history). Every other `passengers` column (`id`, `organization_id`, `assistance_notes`, `status`, `created_at`, `updated_at`) is never returned. Assistance/instruction information shown to a Driver comes from `trips.assistance_notes`/`trips.instructions` — the existing immutable per-Trip operational snapshot (schema.md) — never from `passengers.assistance_notes`, to avoid two divergent sources of the same kind of fact for the same Trip.
- **Status:** CONFIRMED — implemented and verified (`driver_read_minimization_tests.sql` MIN-KEYS-DETAIL, PHONE-1 through PHONE-4, BASE-TABLE-REGRESSION-1/2)
- **Reason:** Direct base-table Passenger SELECT remains permanently off the table for Driver (ZD-080, untouched by this phase) — this allowlist is the entirety of what a Driver ever receives about a Passenger, reviewed field-by-field rather than assumed.
- **Affected Product Areas:** `driver_active_trip_summary`, `driver_trip_detail_result`
- **Dependencies:** ZD-080
- **Owner:** Product / Security
- **Review Trigger:** Any proposed new Passenger field — must be independently reviewed against this allowlist before being added to any Driver-facing response, never assumed included

### ZD-098 — Driver-visible TripNote embedding: explicit fields only, author metadata never exposed

- **Date:** 2026-08-31
- **Category:** Security
- **Decision:** `driver_get_trip_detail` embeds only `visibility='driver_visible'` `trip_notes` rows, as a `jsonb` array of explicitly-constructed `{id, body, created_at}` objects. `author_user_id`, `visibility`, `organization_id`, and `trip_id` are never included in the note objects (the last two are redundant with the surrounding response; the first two are unnecessary operational/administrative metadata for a Driver). `operations_only` notes are never returned under any condition.
- **Status:** CONFIRMED — implemented and verified (`driver_read_minimization_tests.sql` NOTE-VISIBILITY-1/2)
- **Reason:** Matches the same data-minimization principle applied everywhere else in this phase — the existing `trip_notes_select_assigned_driver_visible` policy (retired, ZD-096) was already correctly row-scoped but still exposed the full row including `author_user_id`, which the embedded projection now excludes by construction.
- **Affected Product Areas:** `driver_get_trip_detail`, `driver_trip_detail_result.driver_notes`
- **Dependencies:** ZD-048 (TripNote visibility), ZD-096
- **Owner:** Security
- **Review Trigger:** None anticipated

### ZD-099 — History redaction model and query bound

- **Date:** 2026-08-31
- **Category:** Security / Product
- **Decision:** `driver_list_trip_history` returns only: `trip_id`, `scheduled_pickup_at`, `assignment_started_at`, `assignment_ended_at`, `end_reason`, and `trip_outcome` (populated only when the Trip reached a terminal state — `completed`/`cancelled`/`no_show` — by the time of the query; `null` otherwise). No passenger identity, phone, notes, pickup/destination text, or requester data ever appears in history — materially more restricted than `driver_trip_detail_result`. The query range defaults to the trailing 90 days and is hard-capped at 180 days per call (`ZW006` if exceeded or inverted); this bound is an explicit query-cost/privacy safeguard, not a business data-retention policy, and does not itself delete or expire any underlying `trip_assignments`/`trips` data.
- **Status:** CONFIRMED — implemented and verified (`driver_read_history_tests.sql` HISTORY-1 through HISTORY-7)
- **Reason:** A past assignment is fundamentally lower-need than an active one (work item §28) — indefinitely retaining a Driver's access to a Passenger's phone number or driver-visible note text after the assignment has ended has no operational justification. `trip_outcome` being `null` for a non-terminal Trip specifically prevents a past assignment from revealing what a *different*, later Driver has done on the same Trip since — a privacy property beyond what the work item explicitly required, adopted because it followed directly from the same "when uncertain, exclude" principle applied throughout this phase.
- **Affected Product Areas:** `driver_list_trip_history`, `driver_trip_history_entry`
- **Dependencies:** None
- **Owner:** Product / Security
- **Review Trigger:** If a genuine product need for a longer history window emerges — revisit the 180-day cap explicitly rather than silently widening it

### ZD-100 — current_driver_id() corrected to require an active Membership, not just an active Driver row (fixes a pre-existing P1-E2-S1 gap)

- **Date:** 2026-08-31
- **Category:** Security
- **Decision:** `current_driver_id()` (defined in the historical, already-committed `20260830131600_rls_helper_functions.sql`; corrected via the new append-only `20260831110300_current_driver_id_membership_check.sql`, never by editing the historical file) now additionally requires an active `memberships` row with `role='driver'` for the same `(user, organization)` pair, not merely `drivers.status='active'`. Signature and return type are unchanged, so every caller — RLS policies, the P1-E2-S2 mutation RPCs' authorization chain, and this phase's read RPCs — is corrected automatically.
- **Status:** CONFIRMED — implemented and verified (`driver_read_authorization_tests.sql` DETAIL-6, the specific test that discovered this gap; full regression re-run across all 13 SQL suites plus the concurrency test after the fix, zero regressions)
- **Reason:** Before this fix, a Driver whose Membership was revoked (`status='inactive'`) but whose `drivers` row remained `status='active'` kept full authority through `current_driver_id()` and everything built on it — a real, previously-undetected violation of the repeatedly-stated principle that an inactive Membership must remove authority immediately and live, on every call (ZD-077), which `is_org_member`/`has_org_role` already correctly implemented but `current_driver_id` did not. Discovered by a new P1-E2-S3 read-authorization test, but the gap itself predates this phase and affected the mutation layer equally — fixed here rather than merely noted, consistent with the project's established practice of fixing a discovered gap rather than deferring it once found.
- **Affected Product Areas:** `current_driver_id`, and transitively every function that calls it: `is_driver_assigned_to_trip`, `_lock_driver_active_assignment`, all 6 `driver_*` mutation RPCs, all 4 Driver read RPCs, and the `trip_assignments_select_own_driver`/`vehicles_select_assigned_driver` RLS policies (both now retired, ZD-096, but were still live and affected at the time this gap existed)
- **Dependencies:** ZD-077
- **Owner:** Security
- **Review Trigger:** None anticipated — this is now the permanent, correct definition

### ZD-101 — Direct `trips` INSERT retired in favor of `create_trip`

- **Date:** 2026-08-31
- **Category:** Security / Architecture
- **Decision:** The `trips` INSERT grant to `authenticated` (unrestricted by column, unlike UPDATE) and its supporting policy `trips_insert_org_operations` — both present since P1-E2-S1's very first migration — are revoked/dropped outright. `create_trip()` (ZD-102) is now the sole path to create a Trip. SELECT and the existing narrowed UPDATE grant are completely unchanged.
- **Status:** CONFIRMED — implemented and verified (`create_trip_privilege_tests.sql` "direct-insert-revoked"/"select-and-update-untouched"/"superseded-policy-dropped"; `create_trip_tests.sql` "TEST DIRECT-INSERT"; real HTTP `create_trip_probe.js` CT-6)
- **Reason:** This grant was found, during P1-E3-S0's UI-mapping work (GAP-1), to be a genuine, currently-exploitable gap: unlike every other lifecycle-sensitive column (already locked down since P1-E2-S1/S2), a raw INSERT could set `trips.state` to any value at creation, bypassing the lifecycle model this project otherwise carefully protects. Exactly the same retirement pattern as ZD-092 (`trip_assignments`) and ZD-096 (6 Driver base-table SELECT policies) — once a controlled RPC exists for a mutation, the raw path that predated it is retired, not left as a silent bypass.
- **Affected Product Areas:** `trips` RLS/grants
- **Dependencies:** ZD-084, ZD-092, ZD-102
- **Owner:** Security
- **Review Trigger:** None anticipated

### ZD-102 — `create_trip` architecture: no caller-supplied state, separate from assignment, non-idempotent by design

- **Date:** 2026-08-31
- **Category:** Architecture / Security
- **Decision:** `create_trip` accepts no `state`/`initial_state` parameter at all — the initial value (`'scheduled'`) is a fixed literal inside the function body, not merely validated input, so a caller has no mechanism to request any other value regardless of what they send. `create_trip` never touches `trip_assignments` — Trip creation and assignment remain separate commands (`assign_trip` is still the only path to an active assignment), a deliberate command-boundary decision, not an oversight. `create_trip` is deliberately **non-idempotent**: no duplicate-submission heuristic is attempted (matching passenger/time/address is not reliable evidence of an accidental resubmit — two legitimate Trips can share all three), so the `created` field in its result is always `true`, and preventing accidental double-submission is left to application code (e.g. disabling the submit control while a request is in flight), not solved at the database layer in this phase. When `p_request_id` is supplied and the referenced request is `pending`, it is atomically transitioned to `accepted` in the same transaction as the Trip INSERT (the system-driven transition `transportation_requests`' own original comment anticipated but nothing implemented before this decision); an already-`accepted` request is left untouched, preserving 1:N Request→Trip.
- **Status:** CONFIRMED — implemented and verified (`create_trip_tests.sql`, 20 assertions covering the full role/membership/cross-tenant/state-impossibility/request-lifecycle matrix; `create_trip_atomicity_tests.sql`, forced-failure rollback of Trip+TripEvent+AuditEvent+conditional Request update; real HTTP `create_trip_probe.js`, 6/6)
- **Reason:** Matches this project's established RPC-architecture principles (ZD-089: narrow, intention-revealing functions; ZD-090: idempotency is deliberate and documented, never assumed) extended to the one operation — creation — that has no natural "current state" to check idempotency against, unlike every transition RPC. Structurally eliminating the state parameter (rather than merely rejecting an unexpected value) closes the exact class of gap GAP-1 identified, by construction rather than by convention.
- **Affected Product Areas:** `create_trip`, `trip_creation_result`
- **Dependencies:** ZD-085 (error contract, reused), ZD-089 (RPC architecture pattern), ZD-090 (idempotency-is-deliberate principle, applied here as "deliberately absent"), ZD-101
- **Owner:** Security
- **Review Trigger:** If application usage reveals accidental double-submission is a real, recurring problem — revisit whether a deliberate, durable idempotency key belongs in a future revision, rather than adding one reactively without review

### ZD-103 — SSR auth architecture: `@supabase/ssr`, two clients, server-first resolution

- **Date:** 2026-09-01
- **Category:** Architecture / Security
- **Decision:** The application uses `@supabase/ssr`'s current, supported cookie-based pattern — a browser client (`src/lib/supabase/client.ts`) and a server client (`src/lib/supabase/server.ts`), both publishable-key-only, plus a middleware session-refresh helper (`src/lib/supabase/middleware.ts`). Every protected route's authorization (user, Membership, organization context, role, Driver linkage) is resolved server-side, in a Server Component, before any client code renders — never a client-side redirect after a flash of protected content.
- **Status:** CONFIRMED — implemented and verified (41 real integration checks against the actual running app and local Supabase Auth; zero client-side route guards exist anywhere in `src/`)
- **Reason:** Matches the work item's explicit "no flash of unauthorized content" requirement, and reuses the exact SDK pattern Supabase currently recommends for Next.js App Router rather than the deprecated `auth-helpers` package or a hand-rolled session mechanism.
- **Affected Product Areas:** All of `src/lib/supabase/`, `src/lib/auth/`, `middleware.ts`
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** A future Supabase SSR SDK major version — re-verify the cookie/session pattern still matches current guidance before upgrading

### ZD-104 — Organization context: cookie names a request, never authority; single-org auto-selects, multi-org requires explicit selection

- **Date:** 2026-09-01
- **Category:** Security / Product
- **Decision:** A `zw_org_context` cookie (httpOnly, `sameSite=lax`) holds which of the caller's own active Memberships to use when they have more than one. It is never trusted as authorization by itself — `resolveOrganizationContext()` re-validates it against a fresh `getActiveMemberships()` call on every request; a value matching none of the caller's own active Memberships is treated exactly like no cookie at all. A single active Membership auto-selects with no extra screen; multiple require `/select-organization`, a plain server-validated list (organization name + role only, no internal tenant metadata) — not a designed org-switcher component.
- **Status:** CONFIRMED — implemented and verified (`application-auth-test-matrix.md` MULTIORG-*/FOREIGNORG-* rows, including a forged-cookie test for both single- and multi-org users)
- **Reason:** Matches the work item's explicit instruction that "the caller choosing an organization UUID does not grant authority" and the smallest-safe-MVP recommendation already recorded in `application-route-map.md` "Multi-org UX" before this phase built it.
- **Affected Product Areas:** `src/lib/auth/organization.ts`, `/select-organization`
- **Dependencies:** ZD-103
- **Owner:** Security
- **Review Trigger:** A richer org-switcher UX (e.g. changing context without a full re-selection screen) — revisit the storage mechanism then if needed, not before

### ZD-105 — Route guards are UX-only; the database remains final authority

- **Date:** 2026-09-01
- **Category:** Architecture / Security
- **Decision:** `requireOperationsAccess()`/`requireDriverAccess()` are narrow, single-purpose functions that improve navigation (redirect a Driver to `/driver` instead of a confusing Operations denial, resolve `/` to the correct landing page) — they are explicitly not a reimplementation of RLS/RPC authorization, and no attempt was made to recreate every database policy in TypeScript. Every data read/write this application will ever perform remains independently enforced by the same database layer P1-E2-S1 through P1-E3-S0A built and exhaustively tested.
- **Status:** CONFIRMED
- **Reason:** Directly follows the work item's own explicit instruction (§30) and keeps a single source of truth for authorization — a bug in this application layer would be a UX defect (an unexpected redirect), never a security breach, because the database refuses an unauthorized caller regardless of what the application layer's own routing logic decided.
- **Affected Product Areas:** `src/lib/auth/authorization.ts`
- **Dependencies:** ZD-084, ZD-089 through ZD-102 (the entire database mutation/read-model architecture this layer sits in front of, none of it re-derived here)
- **Owner:** Security
- **Review Trigger:** None anticipated — this is the permanent intended relationship between the two layers

### ZD-106 — Live Membership/role/Driver-linkage resolution, no caching, at the application layer

- **Date:** 2026-09-01
- **Category:** Security
- **Decision:** `getActiveMemberships()` and the Driver-linkage check (`driver_get_profile` RPC call inside `requireDriverAccess()`) both re-query the database on every protected request. Nothing is cached in a session claim, a cookie, or module-level state. A Membership status/role change takes effect on the very next request using the same session — no sign-out/sign-in cycle required.
- **Status:** CONFIRMED — implemented and verified (the mandatory same-session revocation matrix, `application-auth-test-matrix.md`, all 10 steps across 3 scenarios passing)
- **Reason:** Extends ZD-077's live-check principle (established at the database/RLS layer in P1-E2-S1) to the application layer that now actually calls it — a cached role in this layer would silently reintroduce exactly the stale-authorization risk ZD-077 exists to prevent, one layer up from where it was originally solved.
- **Affected Product Areas:** `src/lib/auth/membership.ts`, `src/lib/auth/authorization.ts`
- **Dependencies:** ZD-077
- **Owner:** Security
- **Review Trigger:** None anticipated

### ZD-107 — Platform Admin routing posture: no tenant-Operations bypass

- **Date:** 2026-09-01
- **Category:** Security
- **Decision:** `PlatformAdminGrant` is never consulted by any route guard in this layer. A user holding only a Platform Admin grant (zero Memberships) is routed to `/access-unavailable`, identical to any other zero-Membership user.
- **Status:** CONFIRMED — implemented and verified (`application-auth-test-matrix.md` PLATFORMADMIN-1)
- **Reason:** Directly extends the database layer's own established posture (ZD-049: Platform Admin authority is a separate, narrow, read-scoped mechanism, never Membership-equivalent; work item §80 in P1-E2-S2 explicitly forbade an `is_platform_admin() OR ...` bypass in mutation authorization) to the application routing layer — no new reasoning was needed, only consistent application of an already-settled decision.
- **Affected Product Areas:** `src/lib/auth/authorization.ts`
- **Dependencies:** ZD-049
- **Owner:** Security
- **Review Trigger:** A future Platform Admin console — would need its own explicit, separately-reviewed routing decision, never assumed from this one

### ZD-108 — Redirect safety: allowlist, not denylist

- **Date:** 2026-09-01
- **Category:** Security
- **Decision:** `isSafeRedirectPath()` accepts only a single-leading-slash path built from `[A-Za-z0-9\-_/]` plus a simple query segment — everything else is rejected, including values that don't resemble any known attack pattern. Every `next`/`returnTo` value in the application (the `/sign-in?next=` query parameter, `selectOrganizationAction`'s form field) is validated through this one function before ever reaching `redirect()`.
- **Status:** CONFIRMED — implemented and verified (`application-auth-test-matrix.md` "Redirect safety", including a real POST to the actual sign-in Server Action with `https://evil.example` as `next`)
- **Reason:** An allowlist rejects an entire class of open-redirect vectors by construction (protocol-relative URLs, any absolute scheme, backslash tricks) rather than requiring every future attack variant to be individually enumerated and added to a denylist.
- **Affected Product Areas:** `src/lib/auth/redirect.ts`
- **Dependencies:** None
- **Owner:** Security
- **Review Trigger:** A genuine future need for a redirect target outside this pattern (e.g. a query string with different characters) — extend the allowlist deliberately, never widen it reflexively to unblock a specific case

### ZD-109 — Driver-linkage-missing renders inline, never redirects (avoids a redirect loop)

- **Date:** 2026-09-01
- **Category:** Architecture
- **Decision:** `requireDriverAccess()` returns a discriminated `{ status: "ok" | "link-missing" }` result rather than redirecting when a `driver` Membership has no resolvable linked `drivers` row. The `/driver` layout renders a safe, non-crashing "account not yet set up" state inline for the `link-missing` case, with a sign-out action, no internal ID exposed.
- **Status:** CONFIRMED — implemented and verified (`application-auth-test-matrix.md` DRIVERLINK-1; the dedicated `org-a-driver-nolink` seed fixture added this phase)
- **Reason:** Any redirect target for this case is either `/driver` itself (an infinite loop, since the guard would fail identically on the next request) or a route with no clear ownership of this specific, narrow situation. Rendering inline avoids the loop entirely rather than routing around it.
- **Affected Product Areas:** `src/lib/auth/authorization.ts`, `src/app/driver/layout.tsx`
- **Dependencies:** None
- **Owner:** Engineering
- **Review Trigger:** None anticipated

### ZD-110 — `getActiveMemberships()` corrected to filter by user_id explicitly (fixes a real cross-membership-visibility bug found this phase)

- **Date:** 2026-09-01
- **Category:** Security
- **Decision:** `getActiveMemberships()` now filters `.eq("user_id", user.id)` explicitly, not merely `.eq("status", "active")`. `memberships` carries two applicable RLS policies for a caller who is an `organization_admin`: `memberships_select_self` (their own row) and `memberships_select_org_admin` (every row in an org they administer) — these OR together under RLS, they don't narrow each other. A query with no `user_id` filter therefore returned every active Membership in any organization the caller administers, not just their own, for an org_admin caller specifically.
- **Status:** CONFIRMED — implemented and verified (found by `ROLE-1` failing against real seeded data during this phase's own integration testing — an Org A admin with exactly one Membership was incorrectly resolved as a multi-org user and routed to `/select-organization`; fixed, then the full 41-check suite re-run from a clean `supabase db reset` with zero remaining failures)
- **Reason:** RLS correctly protected the *table* (no cross-tenant row was ever exposed to the wrong tenant) — this was an application-layer *query-intent* bug, not an RLS gap: the query asked a broader question ("what can I see in `memberships`") than the one its caller actually needed answered ("what are MY OWN organizations"), and RLS answered the question it was actually asked, correctly. Recorded because it is exactly the kind of subtle "RLS scopes rows, but a query must still express what it actually means" mistake work item §17's own caution was written to prevent, caught here by genuine integration testing against real data rather than assumed correct from a passing build.
- **Affected Product Areas:** `src/lib/auth/membership.ts`
- **Dependencies:** None
- **Owner:** Security
- **Review Trigger:** Any future query against a table with more than one applicable SELECT policy for the same role — explicitly verify which policy will actually apply for the caller in question, not just that RLS is enabled

No decisions have been REJECTED or SUPERSEDED as of this update.

**Related documents:** [product-definition.md](./product-definition.md) · [scope-register.md](./scope-register.md) · [domain-model.md](./domain-model.md) · [lifecycle-model.md](./lifecycle-model.md) · [authorization-model.md](./authorization-model.md) · [public-marketing-separation.md](./public-marketing-separation.md) · [schema.md](../data/schema.md) · [rls-model.md](../security/rls-model.md) · [mutation-api.md](../data/mutation-api.md) · [mutation-authorization.md](../security/mutation-authorization.md) · [read-api.md](../data/read-api.md) · [driver-data-minimization.md](../security/driver-data-minimization.md)
