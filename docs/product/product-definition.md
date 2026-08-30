# Zenward Mobility — Product Definition

**Work item:** P0-E1-S1 — Georgia Launch Decision Brief
**Phase:** P0 — Product Foundation
**Epic:** P0-E1 — Product Definition
**Status:** Draft, pending product review
**Last updated:** 2026-08-29

This document is the canonical product definition for Zenward Mobility. It exists to prevent the product from being built as a generic SaaS/booking app before the underlying operational model has been deliberately decided. Every statement below is labeled **CONFIRMED**, **PROVISIONAL**, **UNKNOWN**, or **EXCLUDED**. Do not treat provisional or unknown items as requirements. Do not silently promote a provisional item to confirmed — that requires an explicit decision, recorded in [decision-register.md](./decision-register.md).

---

## 1. Brand (CONFIRMED)

| Field | Value |
|---|---|
| Brand | Zenward Mobility |
| Tagline | Care that gets you there. |
| Product category | Non-Emergency Medical Transportation (NEMT) |
| Launch market | Georgia, USA |

## 2. Internal Product Thesis (CONFIRMED)

> Zenward is building the operating system for dependable non-emergency medical transportation.

## 3. Customer Proposition (CONFIRMED)

> Book, coordinate, and track medical transportation with less uncertainty.

## 4. Product Purpose

Zenward must initially operate as a credible NEMT operator while its internal technology foundation is deliberately structured to support a much more capable transportation coordination platform over time. It is not a booking website with a form bolted on the front — it is a system for coordinating the full operational lifecycle of a medical transportation trip.

## 5. Product Principles (CONFIRMED)

1. Zenward is not just a booking website. The product must eventually coordinate the complete operational lifecycle of a trip (see §6).
2. The **Trip** is the primary business entity, not a form submission (see §7).
3. Technology should remain largely invisible to the customer. Zenward should feel dependable before it feels futuristic.
4. Interfaces originate from real operational tasks, never from dashboard or SaaS templates (see §12, Anti-Template Product Rule).
5. Architecture should avoid *foreclosing* future capabilities (e.g., Medicaid/broker integrations) without being required to implement them now.

## 6. Long-Term Operational Model (CONFIRMED as guiding model; NOT authorized for implementation)

The intended operational chain that should guide architecture and product decisions:

```
Trip Request
  → Intake
  → Scheduling
  → Dispatch
  → Driver Assignment
  → Trip Execution
  → Trip Status Events
  → Proof of Service
  → Exception Handling
  → Billing Record
  → Operational History
```

This chain is documentation only. No stage of it is authorized for implementation under P0-E1-S1.

## 7. Primary Domain Object: TRIP (CONFIRMED)

The Trip is a first-class business entity. The architecture should eventually allow a Trip to relate to:

- requesting organization
- healthcare facility
- passenger
- caregiver / contact
- pickup location
- destination
- appointment
- assistance requirements
- mobility requirements
- scheduled pickup time
- scheduled appointment time
- assigned driver
- assigned vehicle
- trip stops
- trip status
- trip events
- location events
- delays
- exceptions
- cancellation
- no-show state
- proof of service
- billing information
- operational history

No database migrations or schema were created for this. This is a relationship model to guide future architecture, not a table design.

## 8. Initial Product Surfaces (CONFIRMED as intended surfaces; none built)

### 8.1 Public Website
**Purpose:** build trust and convert prospective customers into transportation requests or commercial conversations.
**Primary audiences:** patients, family members, caregivers, healthcare facilities, clinics, dialysis centers, rehabilitation facilities, senior care organizations, hospital discharge teams, referral partners.
**Constraint:** must not resemble a generic SaaS marketing template.

### 8.2 Operations / Dispatch Console
Expected to become the operational center of Zenward. Likely responsibilities: trip intake, trip scheduling, dispatch, passenger records, facility records, driver management, vehicle management, trip assignment, trip monitoring, exception management, trip history, proof of service, operational documentation, billing records.
**Constraint:** should emerge from real transportation workflows, not dashboard templates.

### 8.3 Driver Experience
**Initial direction (PROVISIONAL):** mobile-first web/PWA.
A driver primarily needs to understand: where to go, when to arrive, who they are transporting, what assistance may be required, what trip stage they are currently in, and what action they need to take next.

**Provisional trip status progression (NOT final):**
```
Assigned → En Route → Arrived → Passenger Onboard → Drop-off → Completed
```
This status model is provisional and must not be treated as final without further product review.

### 8.4 Booking / Facility Experience
Healthcare organizations should eventually be able to request and follow transportation without relying exclusively on calls, texts, or email. Potential future capabilities: transportation request submission, passenger selection, appointment information, trip status, trip history, recurring transport requests, basic facility account management.
**Constraint:** do not build a large facility portal during MVP simply because it may eventually be useful.

## 9. Expected Operational Entities (CONFIRMED as expected concepts; not finalized schema)

organizations · facilities · passengers · caregivers / passenger contacts · trip requests · trips · trip stops · appointments · drivers · vehicles · driver assignments · trip events · trip exceptions · proof of service · billing records

No repository code or schema currently exists to compare these against (see §14, Repository Inspection).

## 10. Provisional Assumptions (PROVISIONAL — not confirmed)

- Initial customer groups may include: healthcare facilities, private-pay customers, patients, caregivers/families.
- Initial booking may support: operator-assisted booking, digital transportation requests.
- Initial driver product: mobile-first web/PWA.
- Initial operations product: desktop-first operations console.
- Healthcare facilities may eventually receive self-service booking and trip visibility.
- Architecture should avoid preventing future Medicaid or transportation-broker integrations — but broker integrations and Medicaid workflow automation are **not** dependencies for the first MVP.

## 11. Unresolved Questions (UNKNOWN — do not invent answers)

Exact Georgia launch territory · initial counties/cities served · service radius · operating hours · after-hours policy · fleet ownership model · vehicle types · ambulatory transport capability · wheelchair transport capability · wheelchair vehicle specifications · driver employment/contractor model · minimum booking lead time · same-day booking rules · wait-time rules · cancellation rules · no-show rules · return-trip rules · companion/caregiver rules · pricing · mileage pricing · wait-time charges · facility contract pricing · private-pay payment method · Medicaid participation · broker participation · billing workflow · legal operating entity · insurance structure · licensing requirements · public contact information · production domain · dispatch phone number · customer support model.

These remain unresolved until product documentation or an explicit decision confirms them. See [decision-register.md](./decision-register.md) for tracked status.

## 12. Explicit Exclusions (EXCLUDED until further approval)

- Emergency medical transportation
- Ambulance services
- Stretcher transportation
- Native iOS application
- Native Android application
- AI dispatching
- Autonomous dispatch optimization
- Complex route optimization
- Automated Medicaid claims processing
- Transportation broker integrations
- Provider marketplace
- Loyalty program
- Sophisticated predictive analytics
- Fabricated live vehicle maps
- Fabricated operational activity
- Unnecessary social features

Architecture may remain *compatible* with these without prematurely implementing them.

## 13. Anti-Template Product Rule (CONFIRMED — permanent product-development principle)

Zenward must not look, read, or operate like a generic AI-generated SaaS product.

**Avoid:** arbitrary dashboard cards, decorative metrics, fabricated statistics, random charts, generic gradient-heavy SaaS layouts, generic stock icon systems, feature sections created only to fill space, excessive rounded cards, meaningless glassmorphism, random AI imagery, invented testimonials, invented customers, fake trust badges, unnecessary animations, UI patterns that do not correspond to actual transportation workflows.

**Visual quality should come from:** strong information hierarchy, typography, spacing, photography where appropriate, restraint, interaction quality, operational clarity, excellent responsive behavior, accessibility, real domain context.

Technology should remain largely invisible to the customer. Zenward should feel dependable before it feels futuristic.

## 14. Repository Inspection Findings

- `/Users/datamatics/ZenWard` contains **no files and no subdirectories** — there is no existing application code, no prior product documentation, and no prior implementation of any kind.
- No conflicting domain assumptions (stretcher/ambulance terminology, fabricated statistics, hard-coded service areas or pricing, Medicaid assumptions, a "trip" modeled as a plain contact-form submission, unjustified dashboard features) exist, because nothing has been built yet.
- **Anomaly (not a code contradiction, flagged for awareness):** the git repository containing this working directory is rooted at the user's home directory (`/Users/datamatics`, tracked at `/Users/datamatics/.git`), not at `/Users/datamatics/ZenWard`. This working directory is not itself inside a project-scoped git repo. This is an infrastructure/tooling issue outside the scope of P0-E1-S1 and was not modified. See the Completion Report for the recommendation.

## 15. MVP Principle (CONFIRMED as direction; not an authorization to build)

The MVP should prove that Zenward can reliably:

1. receive a transportation request,
2. turn that request into a scheduled trip,
3. coordinate the trip operationally,
4. assign the appropriate driver and vehicle,
5. allow the driver to progress through the trip,
6. record what happened,
7. and preserve an auditable trip history.

This statement establishes direction only. It is not authorization to implement these capabilities during this or any adjacent work item unless a separate, approved work item says so.

## 16. Product Development Control System (CONFIRMED — process framework)

```
Product Vision
  → Outcome
  → Phase
  → Epic
  → User Story
  → Implementation Slice
  → Acceptance Criteria
  → Evidence
  → Approval Gate
```

**Current work item:**

| Level | Value |
|---|---|
| Phase | P0 — Product Foundation |
| Epic | P0-E1 — Product Definition |
| Story | P0-E1-S1 — Georgia Launch Decision Brief |

No subsequent work item (P0-E1-S2 or later, design work, database architecture, UI implementation, marketing page development, dispatch development, driver interface development) is authorized by this document. Work stops at the P0-E1-S1 gate pending product review.

---

**Related documents:** [decision-register.md](./decision-register.md) · [scope-register.md](./scope-register.md)
