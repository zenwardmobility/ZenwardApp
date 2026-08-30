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

---

**Addendum to ZD-015 (2026-08-29, design gate):** Design review reaffirmed that the trip status list stays PROVISIONAL. The visual system may define status *presentation* categories, but the actual Zenward trip state machine is established during transportation workflow/domain modelling — the provisional list must not be converted into application logic before that.

No decisions have been REJECTED or SUPERSEDED as of this update.

**Related documents:** [product-definition.md](./product-definition.md) · [scope-register.md](./scope-register.md)
