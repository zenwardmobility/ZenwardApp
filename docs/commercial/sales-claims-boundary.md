# Zenward — Sales Claims Boundary

**Purpose:** the exact list of what any Zenward team member may say to a prospective or founding operator, without exception, until a claim's status changes and this document is updated to match. This document is authoritative over any individual's memory of a past conversation.

**Core rule:** never claim a certification, compliance status, or capability Zenward has not independently and verifiably established. When unsure, say the CAN SAY version and stop there.

---

## MUST NOT CLAIM (never say these, in any form, regardless of context)

- **"HIPAA compliant."** Zenward has not undergone a HIPAA compliance assessment or attestation. Do not say "HIPAA compliant," "HIPAA certified," or imply certification with phrasing like "built for HIPAA" or "HIPAA-ready" without a qualifier (see REQUIRES QUALIFICATION below).
- **"SOC 2 compliant" / "SOC 2 certified."** No SOC 2 audit (Type I or Type II) has been performed. Do not say "SOC 2" in any affirmative sentence about Zenward's current status.
- **"NEMTAC certified."** No such certification has been pursued or obtained.
- **"Medicaid certified" / "Medicaid-approved."** Zenward is not certified by any state Medicaid program or broker.
- **"We guarantee on-time performance"** or any on-time percentage. Zenward reports what happened; it does not promise a schedule outcome.
- **"AI-powered" / "predictive" / "machine learning"** applied to any current feature. Every number, flag, and list in the product today is a direct, literal database query result — nothing is model-generated, scored, or predicted.
- **"Live GPS tracking" / "real-time map."** There is no live map, no continuous location trace, and no background tracking. The real capability (foreground, driver-initiated, trip-scoped location freshness) is described precisely in REQUIRES QUALIFICATION below — never round it up to "tracking."
- **"Broker-integrated" / "connects to your existing broker."** No broker or payer integration exists.
- **"Billing included" / "we handle your invoicing."** No billing capability is functional in the product today.
- **Any specific uptime SLA number** (e.g. "99.9% uptime") — none has been established or contracted.
- **"Used by [any specific named operator]"** unless that operator has given explicit written permission to be named, and Sales has confirmed that permission is current.

## REQUIRES QUALIFICATION (may be said only with the qualifier attached, every time)

- **Location freshness:** "Zenward shows dispatch when a driver's device last reported its location during an active trip — a freshness signal, not a live map or continuous GPS trace. It's foreground and driver-initiated, active only while a trip is in progress." Never drop the qualifier, even in a follow-up sentence.
- **Security architecture:** "Zenward enforces tenant data isolation and role-based access at the database policy level — one organization's data is never visible to another, and we've verified this through direct adversarial testing, not just code review." Do not extend this into "so we're HIPAA compliant" or "so we're audit-ready" — isolation and RBAC are real, but they are not a certification.
- **Reliability of demo data:** "Everything you're seeing is real application data from a real (local, sandboxed) database — not mocked or hard-coded for the demo." True, and worth saying — but don't extend it into a claim about production uptime or scale, which have not yet been established.
- **Founding operator pricing:** "We have a founding-cohort program with pilot pricing" — refer any specific number to `founding-operator-program.md` and to Sales leadership; never quote a number that isn't in that document, and never treat a verbal quote as binding without going through the actual proposal process.

## CAN SAY (freely, without qualification, because it is simply and verifiably true)

- "Every trip, passenger, driver, and vehicle you're seeing lives in one system — not spreadsheets plus a dispatch board plus a group chat."
- "Dispatch, at a glance, sees what needs attention today — unassigned trips, open issues, and location signals that have gone stale."
- "Assigning a driver to a trip is one action, and it's protected against two dispatchers double-booking the same trip at the same moment."
- "The driver experience is a mobile web app — no separate native app to install — and every lifecycle step (heading to pickup, arrived, passenger onboard, en route to destination, arrived, complete) is a deliberate, server-recorded action."
- "A driver or dispatcher can report a problem on a trip, and dispatch can resolve it, all inside the same system — with the full history preserved, never deleted."
- "Every completed trip has a full, timestamped activity record — what happened, in order, by whom."
- "The product is under active development, built specifically for non-emergency medical transportation operators, not a generic dispatch tool retrofitted for healthcare."

## When a buyer asks something not covered here

Say "let me confirm that and follow up" rather than improvising. Escalate compliance, security-certification, and pricing questions to whoever owns those answers before responding — this document does not cover every possible question, and a wrong answer given confidently is worse than a delayed correct one.

## Keeping this document current

If a capability's status changes (a certification is pursued or achieved, a feature ships, an integration is built), update this file, `product-capability-matrix.md`, and `security-overview.md` together, in the same change — they must never drift apart from each other or from the real product.
