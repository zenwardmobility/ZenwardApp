# Zenward Platform — Application Route Map

**Work item:** P1-E3-S0 — Stitch UI Ingestion & Implementation Mapping
**Status:** Planning/documentation only — no route was created, modified, or removed.
**Last updated:** 2026-08-31

Proposed route structure derived from the Stitch references and the existing (already-scaffolded, placeholder-only) Next.js route tree under `src/app/`. **This phase does not create routes** — the structure below already exists as stub pages from a prior UI-foundation phase (P0-E2-S3/S3A); this document reconciles that existing scaffold against what the Stitch references actually require, rather than proposing from a blank slate.

## Existing scaffold (confirmed by inspection, not modified)

```
src/app/operations/            layout.tsx, page.tsx (Overview stub)
src/app/operations/trips/      page.tsx, [tripId]/page.tsx, new/page.tsx
src/app/operations/dispatch/   page.tsx
src/app/operations/passengers/ page.tsx
src/app/operations/facilities/ page.tsx
src/app/operations/drivers/    page.tsx
src/app/operations/fleet/      page.tsx
src/app/operations/billing/    page.tsx
src/app/operations/reports/    page.tsx
src/app/driver/                layout.tsx, page.tsx (Today stub)
src/app/driver/trips/          page.tsx, [tripId]/page.tsx
src/app/driver/history/        page.tsx
src/app/driver/profile/        page.tsx
```

Every one of these is a placeholder rendering `OperationsRouteStub`/`DriverRouteStub` — confirmed by reading `src/app/operations/page.tsx` directly (explicit comment: "Placeholder only... the real Overview screen is a later, canonical-screen work item"). No auth, no data fetching, no Supabase client exists anywhere in `src/` (confirmed: `grep -rl "supabase" src/` returns nothing).

## Operations routes

| Route | Screen (Stitch ref) | Roles | Desktop/mobile behavior | Nav label | Icon (existing mapping) | Notes |
|---|---|---|---|---|---|---|
| `/operations` | Today's Operations (01) | organization_admin, dispatcher | Desktop/tablet primary; see responsive boundary below | Overview | `SquaresFour` | Default landing page for Ops roles |
| `/operations/trips` | (list view — no dedicated Stitch reference; implied by Trip Detail's breadcrumb "Trips ›") | organization_admin, dispatcher | Desktop/tablet | Trips | `Path` (Route not in Phosphor — ZD-035) | List screen itself not in the reference set — see gap register (non-blocking, low-risk to infer) |
| `/operations/trips/[tripId]` | Trip Detail (02) | organization_admin, dispatcher | Desktop/tablet | — (detail, not nav-level) | — | |
| `/operations/trips/new` | Internal New Trip (05) | organization_admin, dispatcher | Desktop/tablet | — (reached via "New Trip" CTA, not nav-level) | — | **Blocked on backend gap** — see gap register |
| `/operations/dispatch` | Dispatch Board (03) | organization_admin, dispatcher | Desktop/tablet — dense 3-column layout, not viable narrow | Dispatch | `NavigationArrow` | |
| `/operations/passengers` | (no dedicated reference) | organization_admin, dispatcher | Desktop/tablet | Passengers | `Users` | Existing stub; not in this Stitch batch |
| `/operations/facilities` | (no dedicated reference) | organization_admin, dispatcher | Desktop/tablet | Facilities | `Buildings` | Existing stub; not in this Stitch batch |
| `/operations/drivers` | (no dedicated reference) | organization_admin, dispatcher | Desktop/tablet | Drivers | `IdentificationCard` | Existing stub; not in this Stitch batch |
| `/operations/fleet` | (no dedicated reference) | organization_admin, dispatcher | Desktop/tablet | Fleet | `Van` | Existing stub; not in this Stitch batch |
| `/operations/billing` | (no dedicated reference) | organization_admin only (billing is an admin-sensitive concern — role split not yet confirmed by any reference) | Desktop/tablet | Billing | `Receipt` | Existing stub; not in this Stitch batch; role restriction is a recommendation, not yet confirmed |
| `/operations/reports` | (no dedicated reference, "Export Day Sheet" hints at related capability) | organization_admin, dispatcher | Desktop/tablet | Reports | `ChartBar` | Existing stub |
| `/operations/settings` (implied by sidebar footer, no dedicated route file confirmed) | — | organization_admin only (org settings) | Desktop/tablet | Settings | `Gear` | Not enumerated in the file listing above — confirm during S1 |

## Driver routes

| Route | Screen (Stitch ref) | Roles | Desktop/mobile behavior | Nav label | Notes |
|---|---|---|---|---|---|
| `/driver` | Driver Today (06) | driver | Mobile-first, 390-430px minimum | Today | Default landing page for Driver role |
| `/driver/trips` | Driver Trips (07) | driver | Mobile-first | Trips | Active/upcoming only (`driver_list_active_trips`) |
| `/driver/trips/[tripId]` | Driver Active Trip (04) | driver | Mobile-first | — (detail, not nav-level) | |
| `/driver/history` | (no dedicated reference) | driver | Mobile-first | History | **No Stitch reference provided** — see gap register; maps to `driver_list_trip_history` |
| `/driver/profile` | (no dedicated reference) | driver | Mobile-first | Profile | **No Stitch reference provided** — maps to `driver_get_profile` |

## Shared / auth / utility routes

Not covered by any Stitch reference in this batch (no sign-in screen was provided) — proposed based on the existing route tree's absence of an auth route and the established authorization model:

| Route (proposed) | Purpose | Notes |
|---|---|---|
| `/sign-in` (exact path TBD) | Unauthenticated entry point | **No Stitch reference** — must be designed or a minimal functional version built directly against the design system for S1; not fabricated here |
| `/` or a role-resolution redirect | Post-auth landing, resolves to `/operations` or `/driver` per Membership role (see auth boundary below) | |

## Responsive surface split (work item §7-9)

- **Operations** (`/operations/*`): desktop/tablet primary. The Dispatch Board (03) in particular is a dense 3-column layout that cannot be meaningfully compressed below roughly **1024px** without losing the grid's own information density — this is documented as the **intended minimum Operations width**, not implemented as an enforced breakpoint in this phase. Below that width, Operations should show a deliberate "use a larger screen" message rather than auto-morphing into a cramped mobile dashboard (work item §8) — the exact fallback UI is deferred, not designed here.
- **Driver** (`/driver/*`): mobile-first, must work at 390px/430px and common Android/iPhone widths (work item §9). All 4 driver reference images already demonstrate this correctly (full-width primary CTAs, bottom tab bar, single-column card stacks) — no redesign is implied, only implementation against the existing pattern.

## Auth boundary (work item §33) — conceptual, not implemented

| Session state | Routing behavior |
|---|---|
| Unauthenticated | → sign-in (route TBD, no reference provided) |
| Authenticated, `organization_admin`/`dispatcher` Membership | → `/operations` |
| Authenticated, `driver` Membership | → `/driver` |
| Authenticated, multi-org user | → org-context resolution (see below) — **PRODUCT UX DECISION REQUIRED**, no reference provided |
| Authenticated, zero Membership anywhere | → a safe "no access" state, never a raw error or a guess at role | 
| Authenticated, Platform Admin only (no Membership) | → **out of scope for this reference set** — no Platform Admin screen was provided; Platform Admin's own console (if any) is not addressed here |

This is what **P1-E3-S1 must build** — none of it exists yet (no Supabase client, no session retrieval, no role-guard middleware anywhere in `src/`).

## Multi-org UX (work item §34)

No Stitch reference includes an organization switcher. Recorded as **PRODUCT UX DECISION REQUIRED**. Smallest safe approach for initial implementation, recommended (not decided) here: resolve to the user's **sole** active Membership automatically when they have exactly one; when they have more than one, show a minimal, unstyled-but-functional org picker (a plain list, not a designed component) before entering `/operations` or `/driver`, rather than guessing which org to land in or building a full switcher UI speculatively. A real switcher component belongs in a later phase once the actual UX is designed.
