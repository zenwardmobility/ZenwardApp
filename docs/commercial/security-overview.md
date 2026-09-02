# Zenward — Security Overview (Buyer-Facing)

**Purpose:** a plain-language description of how Zenward protects operator data, safe to share with a prospective operator's own IT or compliance contact. Written to be accurate without disclosing exploit-relevant implementation detail. Every claim here is bounded by `sales-claims-boundary.md` — this document does not introduce any claim that file doesn't already permit.

## Tenant isolation

Every operator's data — trips, passengers, drivers, vehicles, facilities — is scoped to that operator's own organization at the database policy level, not merely hidden in the application's user interface. This means even a direct, deliberate attempt to request another organization's data through the API is denied by the database itself, not just by the screens you see. This property has been independently, adversarially verified — not merely assumed from configuration — as part of Zenward's own internal testing process, repeated after every change to the data model.

## Role-based access

Every person who signs in has a defined role within their organization: **Organization Admin**, **Dispatcher**, or **Driver**. Each role sees and can act on only what its function requires:

- A **Driver** can see and act on trips currently assigned to them — nothing about other drivers' trips, other passengers, or organization administration.
- A **Dispatcher** manages trips, passengers, drivers, and vehicles for their own organization.
- An **Organization Admin** additionally manages the vehicle fleet.

Access is re-checked on every action, not just at sign-in — if a person's role changes or their access to an organization is revoked while they're signed in, that change takes effect immediately, not the next time they log in.

## Driver-scoped access is deliberately narrow

A driver's access to passenger and trip information is limited to what they need for the trip currently assigned to them, and only for as long as that assignment is active. Once a trip is reassigned away from a driver or completed, that driver no longer has access to its details.

## Controlled data changes, not open database access

Every action that changes data — creating a trip, assigning a driver, advancing a trip's status, reporting or resolving an issue — goes through a specific, purpose-built operation, not an open-ended database write. This means the system itself enforces which fields can change, in what order, and by whom — for example, a trip's status can only move forward through its real lifecycle; nothing in the product can retroactively fabricate that a step happened when it didn't.

## Session security

Signing out ends the session completely — both the authentication session and the organization context are cleared, and returning to a previously-authenticated page afterward (including via a browser's back button) does not restore access.

## What this document does not claim

Zenward has not undergone a third-party security audit, HIPAA compliance assessment, or SOC 2 examination. The properties above are real, and have been verified through Zenward's own internal testing — but internal verification is not the same as independent certification. See `sales-claims-boundary.md` for exactly how to describe this distinction to a buyer, and `product-capability-matrix.md` for what else is and isn't built yet.

## Questions from an operator's IT/compliance contact

If a technical contact asks for detail beyond this document — specific database policy implementation, infrastructure hosting detail, incident response process, data retention specifics — escalate rather than improvising an answer; this document is intentionally a summary, not the full technical or compliance record.
