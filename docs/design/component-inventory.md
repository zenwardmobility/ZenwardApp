# Zenward Platform — Component Inventory

**Work item:** P1-E3-S0 — Stitch UI Ingestion & Implementation Mapping, amended by P1-E3-S2 — Driver Application Shell & Driver Today (Driver components below actually built/refined)
**Status:** P1-E3-S0 itself was planning/documentation only. P1-E3-S2 implemented the Driver Today screen and refined the shared Driver shell — see "Driver components — P1-E3-S2" below.
**Last updated:** 2026-09-01

Reconciles the Stitch references (docs/design/stitch/references/) against the component library that **already exists** in `src/components/` (built during P0-E2-S3/S3A) rather than proposing an inventory from scratch. Confirmed by direct inspection: the existing `TRIP_STATUS_MAP`/`DRIVER_STATUS_MAP` in `TripStatus.tsx`/`DriverStatus.tsx` already anticipate the exact labels seen in these references (`Requested`, `Pending Confirmation`, `Needs Assignment`, `Available`, `On Trip`, `Break`, `Unavailable`) — the primitive layer is well-aligned; this phase's job is identifying the screen/feature-level composition still needed on top of it.

## Existing primitives (confirmed present, not modified)

| Component | Purpose | Screens using it (per this reference batch) |
|---|---|---|
| `OperationsShell`, `OperationsSidebar`, `AppHeader` | Operations desktop chrome | All 4 Operations screens (01, 02, 03, 05) |
| `PageHeader` | Title + description (+ breadcrumb slot) | 02, 05 (breadcrumb variant) |
| `Breadcrumb` | Trail navigation | 02, 05 |
| `Panel` | Standard bordered content grouping | All Operations screens |
| `SummaryStrip` | Metric row (label/value/tone) | 01, 03 |
| `StatusBadge` (+ `TripStatus`, `DriverStatus` label maps) | Semantic status pill | All screens with any status label |
| `DataTable` | Column-defined tabular list | 01 (Needs Attention, Upcoming Trips) |
| `DefinitionList` | Label/value grid | 02 (info strip, Passenger & Trip Information) |
| `AttentionState` | Warning/critical callout | 01 (Needs Attention header), 03, 05 (Needs Attention rail) |
| `EmptyState` | No-data placeholder | 02 (Trip Exceptions "No open exceptions") |
| `Avatar` | User/driver photo | All screens (header avatar), 03 (driver capacity cards) |
| `Button`, `IconButton`, `LinkButton` | Actions | Throughout |
| `Input`, `SearchInput`, `Select`, `Textarea` | Form fields | 05 |
| `DriverTripCard`, `DriverTripRow` | Compact/featured trip card | 06, 07 |
| `DriverPrimaryAction` | Full-width dominant CTA | 04 |
| `DriverRoute` | Two-point pickup→destination indicator | 04, 06, 07 |
| `DriverInstruction` | Inline advisory note | 04, 06 ("Call passenger on arrival") |

## New components needed (Stitch-driven, not yet built)

| Component | Purpose | Screens | Responsive behavior | Design-system dependencies |
|---|---|---|---|---|
| `MetricCard` (vs. `SummaryStrip` item) | 01's summary items are closer to a horizontal stat row than discrete cards — **confirm which pattern before building**; `SummaryStrip` may already suffice. Flagged for design review, not a confirmed new component. | 01, 03 | — | Existing `SummaryStrip` may cover this — verify before adding |
| `TripListTable` (a `DataTable` composition, not a new primitive) | Named column configuration for the two distinct table shapes on 01 (Needs Attention vs. Upcoming Trips have different columns) | 01 | Desktop only | `DataTable` |
| `DispatchAssignmentGrid` | Time-axis × driver-row grid with spatially-positioned trip blocks | 03 | Desktop/tablet only — no mobile equivalent is implied or required | New — no existing primitive covers a 2D time/resource grid |
| `DispatchQueueCard` | Needs-assignment queue card (passenger, time, route, status, Assign/Review action) | 03 | Desktop | Composes `StatusBadge`, `Button` |
| `DriverCapacityCard` | Driver photo/initials, status pill, current/next assignment line | 03 | Desktop | Composes `Avatar`, `DriverStatus` |
| `TripRouteTimeline` | Two-stop pickup/destination with connecting line, inline note, per-stop action buttons | 02 (Operations variant, richer than `DriverRoute`) | Desktop | Distinct from `DriverRoute` — Operations variant carries more per-stop detail (call-passenger note, appointment badges) |
| `TripCurrentStatusCard` | Right-rail status summary (state, driver link, last update, next action) | 02 | Desktop | Composes `StatusBadge`, `DefinitionList` |
| `TripNoteList` | Timestamped note list + add-note affordance | 02 | Desktop (Driver's note surface is simpler — see `DriverInstruction`, already covers the read-only display case) | New list component; write action ("Add Note") is a direct-table INSERT per the data-action map, not an RPC — no special mutation-layer dependency |
| `ExceptionBadge` / exception panel | "No open exceptions" / Report Issue | 02, 04 | Both | `EmptyState` already covers the empty case; the populated-list case is new |
| `RequestSourceSelector` | Segmented radio-card group (Passenger/Family-Caregiver/Healthcare Facility/Other) | 05 | Desktop | New — no existing radio-card component |
| `PassengerPicker` | Search/typeahead + selected-passenger chip + "Add New Passenger" | 05 | Desktop | Composes `SearchInput` |
| `ChangeNoticeBadge` | "Pickup updated from X" advisory | 06, 07 | Mobile | New, small — **blocked on the underlying change-tracking gap** (see gap register); component shape can be designed, but has no real data source yet |
| Org switcher (minimal, unstyled) | Multi-org context resolution | Not in any reference | Both | Deferred per route-map §Multi-org UX — build only the minimal functional version when actually needed, not a designed component now |

## Driver components — P1-E3-S2

Reused/refined the existing Driver primitives rather than rebuilding them (work item §7) — only `DriverNextTripCard` is genuinely new:

| Component | Status | Change |
|---|---|---|
| `DriverShell` | Refined (P1-E3-S2, further refined P1-E3-S2B) | Inner column capped at `max-w-md`, centered — keeps the Driver surface compact at tablet/desktop widths (ZD-115). `max-w-md` computed to 16px, not 448px, until P1-E3-S2B fixed a project-wide Tailwind theme-token collision (ZD-117); P1-E3-S2B also added a `sm:` border matching the design system's established panel convention (ZD-118). Real screenshots: `docs/design/qa/driver-today/`. |
| `DriverHeader` | Refined | Added an optional `driverName` identity subtitle (real data, replaces any notion of a fabricated "On Shift" status) and top safe-area-inset padding |
| `DriverLayoutClient` | Refined | Passes `driverName` through; adds a leading avatar (swapped for the existing back-button on a trip-detail route) and a trailing sign-out affordance reusing the existing `signOutAction` |
| `DriverBottomNavigation` | Refined | Added bottom safe-area-inset padding |
| `DriverRoute` | Refined | Added an optional `appointmentLabel` suffix on the Destination line |
| `DriverTripCard` | Refined | Denser row treatment matching the Stitch reference (time+name on one line, single arrow-joined route line, optional appointment caption); prop shape kept stable — the existing `/foundation` showcase call site is unaffected |
| `DriverNextTripCard` | **New** | The featured "Next Trip" card — composes `DriverRoute` + a `LinkButton` "View Trip" CTA. Deliberately carries no Navigate/Call Passenger actions (ZD-114) |
| `DriverTripRow`, `DriverInstruction`, `DriverPrimaryAction` | Unchanged | Not used by Driver Today this phase — `DriverInstruction`'s "Call passenger on arrival" pattern and `DriverPrimaryAction`'s single-CTA rule remain available for the Active Trip screen |

Full field-level rationale: [driver-today-data-map.md](../product/driver-today-data-map.md).

## Explicitly not building generically

Per work item §35's own caution: no generic "Card" or "ListItem" abstraction is proposed merely for reuse. `DispatchQueueCard`, `DriverCapacityCard`, `TripRouteTimeline`, etc. are each named for what they specifically show, following the existing codebase's own pattern (`DriverTripCard`, not a generic `Card`).
