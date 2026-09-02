# Zenward — Product Capability Matrix

**Purpose:** the single source of truth for what Zenward can honestly be shown or claimed to a prospective NEMT operator today, versus what is realistic in a founding-pilot window, versus what is not built. Every commercial document and every demo script step defers to this matrix — no claim in `zenward-demo-script.md`, `sales-claims-boundary.md`, or a live conversation should say more than this file supports.

**Last updated:** 2026-09-02, as of P1-E3-S8C. Grounded directly in `docs/product/ui-backend-gap-register.md` — nothing below is invented for sales purposes; every PLANNED-NOT-AVAILABLE row cites the gap it comes from.

Legend:
- **AVAILABLE NOW** — real, working, backed by a tested database and RLS policy, visible in the current build.
- **LIMITED-PILOT** — the underlying capability is real, but has a scope limitation a buyer should know before relying on it operationally.
- **PLANNED-NOT-AVAILABLE** — does not exist yet. Never demo, imply, or hint at these as present.

---

## Operations (dispatcher / admin)

| Capability | Status | Notes |
|---|---|---|
| Today's Operations dashboard — live trip counts, needs-attention queue, active trips | AVAILABLE NOW | Every number is a real query result, not a hard-coded or cached figure. |
| Trip creation (internal) | AVAILABLE NOW | Server-authoritative `create_trip` RPC — state is not client-settable. |
| Trip creation from an inbound Request | AVAILABLE NOW | "Import request details" pre-fills a New Trip form from a `transportation_requests` row. |
| Dispatch board — assign/reassign a driver + vehicle to a trip | AVAILABLE NOW | Concurrency-hardened (see `docs/reports/P1-E3-S5A-reassignment-concurrency-report.txt`) — two dispatchers assigning the same trip cannot silently clobber each other. |
| Trip Detail — full trip record, status, exceptions, notes | AVAILABLE NOW | |
| Report / resolve a trip issue (Trip Assurance) | AVAILABLE NOW | Restrained, fixed issue-type list; resolution preserves full history, never deletes. |
| Cancel trip / record no-show | AVAILABLE NOW | |
| Trips list — searchable, filterable, paginated | AVAILABLE NOW | |
| Passengers — list, add | AVAILABLE NOW | Edit/deactivate not yet built (GAP-12) — a mis-entered name/phone currently has no in-app fix. |
| Facilities — list | AVAILABLE NOW | Create/edit not yet built (GAP-13) — new referring facilities are added by the Zenward team during onboarding, not self-serve yet. |
| Drivers — list, current-trip context | AVAILABLE NOW | Adding a **new** driver account is not yet self-serve (GAP-15) — see Driver Onboarding row below. |
| Fleet (vehicles) — list | AVAILABLE NOW | Create/edit not yet built (GAP-14) — new vehicles are added by the Zenward team during onboarding. |
| Account menu — organization name, role, sign out | AVAILABLE NOW | Real sign-out (session + org-context cleanup), verified against back-navigation. |
| Driver on-trip location freshness indicator | LIMITED-PILOT | Shows recency of the last location ping received while a trip is actively in progress. This is **not** a live map, not a continuous GPS trace, and not an ETA — see Location Tracking below. |
| Driver Availability panel (Available / Break / Unavailable) | PLANNED-NOT-AVAILABLE | GAP-6. No schema concept of driver-declared availability exists yet — only "on a trip right now" is derivable. |
| Export Day Sheet | PLANNED-NOT-AVAILABLE | GAP-9. The button is visible and honestly disabled, never hidden or faked. |
| Multi-org in-place switcher | LIMITED-PILOT | An operator with access to more than one organization can return to an org-selection screen; there is no in-place context switch without it yet. |

## Driver (mobile web)

| Capability | Status | Notes |
|---|---|---|
| Today / Trips — assigned trips for the day | AVAILABLE NOW | |
| Active Trip — full lifecycle (Start to Pickup → Arrived → Passenger Onboard → Start to Destination → Arrived → Complete) | AVAILABLE NOW | Every transition is a server-authoritative RPC — a driver cannot skip or fabricate a state. |
| Share My Location | LIMITED-PILOT | Foreground-only, explicit opt-in tap, active only while the trip is in an eligible in-progress window. See Location Tracking below — this is not background/always-on GPS. |
| Report Issue | AVAILABLE NOW | Same restrained issue-type list and RPC as the Operations side. |
| Trip History | LIMITED-PILOT | Deliberately redacted — shows date/time/outcome only, not passenger identity or route (privacy decision, ZD-099), so it will look sparser than an active trip. |
| Driver Profile | PLANNED-NOT-AVAILABLE | GAP-3 — route exists, screen is a stub. |
| Driver-facing issue/exception list (seeing the status of a reported issue) | PLANNED-NOT-AVAILABLE | GAP-7 (second half) — a driver can report an issue but cannot yet see its resolution status in-app. |

## Platform-wide

| Capability | Status | Notes |
|---|---|---|
| Multi-tenant data isolation (RLS-enforced) | AVAILABLE NOW | Independently verified via live adversarial testing this phase and prior phases — not merely assumed from policy text. |
| Role-based access (organization_admin / dispatcher / driver) | AVAILABLE NOW | |
| Driver-role denial of Operations routes, inactive-Membership denial, mid-session role-change denial | AVAILABLE NOW | Live-tested, not merely policy review. |
| Location Tracking — background GPS / continuous route trace | PLANNED-NOT-AVAILABLE | No background location capability exists in any current or planned-for-pilot form. Location is a foreground, driver-initiated, trip-scoped signal only. |
| Route optimization / suggested routing | PLANNED-NOT-AVAILABLE | No routing engine integration exists. |
| Live map view with driver markers | PLANNED-NOT-AVAILABLE | Location freshness is shown as a timestamp/badge, never a map pin, never a synthesized position between pings. |
| ETA calculation | PLANNED-NOT-AVAILABLE | No ETA is computed, shown, or implied anywhere in the product. |
| On-time performance guarantee | PLANNED-NOT-AVAILABLE | Zenward reports what happened; it does not promise or guarantee schedule adherence. |
| Predictive/AI trip assignment or anomaly detection | PLANNED-NOT-AVAILABLE | Every list, flag, and count in the product is a direct, literal query result — nothing is model-generated or predicted. |
| Broker / payer integration (Medicaid broker feeds, etc.) | PLANNED-NOT-AVAILABLE | No integration exists with any broker or payer system. |
| Billing / invoicing | PLANNED-NOT-AVAILABLE | Files exist behind a hidden nav item for future work; nothing is functional or shown to any user. |
| Facility Portal (facility-side self-service) | PLANNED-NOT-AVAILABLE | Facilities are represented as records the operator manages; facilities do not yet have their own login. |
| Native Driver mobile app | PLANNED-NOT-AVAILABLE | Driver experience today is a mobile-responsive web app, not an installable native app. |
| Driver Onboarding (self-serve invite a new driver) | PLANNED-NOT-AVAILABLE | GAP-15 — adding a new Driver account currently requires the Zenward team; no in-app invite flow exists. Scoped as P1-E3-S9. |

---

## How to use this matrix

- **Sales conversations:** only describe a row as available if it says AVAILABLE NOW. For LIMITED-PILOT rows, state the limitation in the same breath — never let a buyer infer more than the row supports.
- **Demo script:** every clickable step in `zenward-demo-script.md` maps to an AVAILABLE NOW or LIMITED-PILOT row here. No demo step should exercise a PLANNED-NOT-AVAILABLE capability.
- **When this file is out of date:** if a future phase builds a PLANNED-NOT-AVAILABLE row, move it here as part of that phase's own report — do not let sales collateral drift ahead of the real product.
