# Zenward Mobility — Scope Register

**Work item:** P0-E1-S1 — Georgia Launch Decision Brief
**Status:** Draft, pending product review
**Last updated:** 2026-08-29

Classifications: `MVP` · `POST-MVP` · `FUTURE` · `EXPLICITLY EXCLUDED`

**Important:** classification as `MVP` here documents intended scope direction only. It is **not** authorization to implement. No functionality has been built under P0-E1-S1. Uncertain capabilities are not classified as MVP merely because they are common in NEMT software — each MVP entry below is traceable to the MVP Principle or the confirmed core operational loop in [product-definition.md](./product-definition.md).

---

## MVP

| Scope ID | Capability | Reason | Dependencies | Review Trigger |
|---|---|---|---|---|
| ZS-001 | Trip request intake (receive a transportation request) | Directly named in MVP Principle step 1 | ZD-010 (booking mode, provisional) | MVP build kickoff |
| ZS-002 | Trip scheduling (turn request into a scheduled trip) | Directly named in MVP Principle step 2 | ZS-001 | MVP build kickoff |
| ZS-003 | Trip dispatch / driver & vehicle assignment | Directly named in MVP Principle steps 3–4 | ZS-002, ZS-008, ZS-009 | MVP build kickoff |
| ZS-004 | Driver trip progression (status updates through the trip) | Directly named in MVP Principle step 5 | ZD-015 (status model, provisional) | Driver workflow validation |
| ZS-005 | Trip outcome recording (what happened) | Directly named in MVP Principle step 6 | ZS-004 | MVP build kickoff |
| ZS-006 | Auditable trip history | Directly named in MVP Principle step 7 | ZS-005 | MVP build kickoff |
| ZS-007 | Minimal passenger record (name + trip-relevant details) | Required to support ZS-001–ZS-003; Trip must relate to a passenger per domain model | ZS-001 | MVP build kickoff |
| ZS-008 | Minimal driver record | Required to support ZS-003 | None | MVP build kickoff |
| ZS-009 | Minimal vehicle record | Required to support ZS-003 | None | MVP build kickoff |
| ZS-010 | Public informational website (what Zenward is, how to request transportation) | Named as one of four initial product surfaces; needed as an entry point for ZS-001 | ZD-004 | Website scope review |
| ZS-011 | Driver mobile trip view (where to go, who, what stage, next action) | Directly named in Driver Experience surface description | ZS-004 | Driver workflow validation |

## POST-MVP

| Scope ID | Capability | Reason | Dependencies | Review Trigger |
|---|---|---|---|---|
| ZS-012 | Facility self-service transportation request submission (portal) | Explicitly: "do not build a large facility portal during the MVP simply because it may eventually be useful" | ZD-013 | Facility portal scope decision |
| ZS-013 | Facility passenger selection (portal) | Same as ZS-012 | ZS-012 | Facility portal scope decision |
| ZS-014 | Facility-visible trip status | Same as ZS-012 | ZS-012 | Facility portal scope decision |
| ZS-015 | Facility-visible trip history | Same as ZS-012 | ZS-012 | Facility portal scope decision |
| ZS-016 | Recurring transport requests | Listed as a "potential future capability" for Booking/Facility Experience, not core loop | ZS-012 | Facility portal scope decision |
| ZS-017 | Facility account management | Same as ZS-012 | ZS-012 | Facility portal scope decision |
| ZS-018 | Facility & organization records (full management, beyond minimal trip linkage) | Named as an Operations Console responsibility, not part of the seven MVP Principle steps | ZS-001 | Operations Console scope review |
| ZS-019 | Exception management workflow | Named in long-term operational chain and Operations Console responsibilities; not named in MVP Principle | ZS-004 | Operations Console scope review |
| ZS-020 | Proof of service capture | Named in long-term operational chain; not named in MVP Principle | ZS-004 | Operations Console scope review |
| ZS-021 | Billing record generation | Billing workflow is UNKNOWN (ZD-024); not named in MVP Principle | ZD-021, ZD-024 | Pricing/billing model decision |
| ZS-022 | Trip stops (multi-stop trips) | Named as a Trip relation in the domain model; not required for the minimal core loop | ZS-002 | Trip domain model review |
| ZS-023 | Delay tracking / location events | Named in long-term operational chain; not named in MVP Principle | ZS-004 | Operations Console scope review |

## FUTURE

| Scope ID | Capability | Reason | Dependencies | Review Trigger |
|---|---|---|---|---|
| ZS-024 | Architectural compatibility with future Medicaid / broker integration (non-functional — data model and integration points only, no working integration) | "Architecture should avoid preventing future Medicaid or transportation-broker integrations" | ZD-014 | Payer strategy decision |

## EXPLICITLY EXCLUDED

| Scope ID | Capability | Reason | Dependencies | Review Trigger |
|---|---|---|---|---|
| ZS-025 | Emergency medical transportation | Explicitly outside intended product category (ZD-008) | None | Not anticipated |
| ZS-026 | Ambulance services | Explicitly excluded | None | Not anticipated |
| ZS-027 | Stretcher transportation | Explicitly excluded | None | Further approval required |
| ZS-028 | Native iOS application | Explicitly excluded; current direction is mobile-first web/PWA (ZD-011) | ZD-011 | Native app cost-benefit review |
| ZS-029 | Native Android application | Explicitly excluded; current direction is mobile-first web/PWA (ZD-011) | ZD-011 | Native app cost-benefit review |
| ZS-030 | AI dispatching | Explicitly excluded | None | Further approval required |
| ZS-031 | Autonomous dispatch optimization | Explicitly excluded | None | Further approval required |
| ZS-032 | Complex route optimization | Explicitly excluded | None | Further approval required |
| ZS-033 | Automated Medicaid claims processing | Explicitly excluded; architecture may remain compatible per ZS-024 | ZD-022 | Payer strategy decision |
| ZS-034 | Transportation broker integrations | Explicitly excluded; architecture may remain compatible per ZS-024 | ZD-023 | Payer strategy decision |
| ZS-035 | Provider marketplace | Explicitly excluded | None | Further approval required |
| ZS-036 | Loyalty program | Explicitly excluded | None | Further approval required |
| ZS-037 | Sophisticated predictive analytics | Explicitly excluded | None | Further approval required |
| ZS-038 | Fabricated live vehicle maps | Explicitly excluded; also prohibited by Anti-Template Product Rule | None | Not anticipated |
| ZS-039 | Fabricated operational activity | Explicitly excluded; also prohibited by Anti-Template Product Rule | None | Not anticipated |
| ZS-040 | Unnecessary social features | Explicitly excluded | None | Further approval required |

---

**Related documents:** [product-definition.md](./product-definition.md) · [decision-register.md](./decision-register.md)
