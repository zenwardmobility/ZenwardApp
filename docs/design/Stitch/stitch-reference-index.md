# Zenward Platform — Stitch Reference Index

**Work item:** P1-E3-S0 — Stitch UI Ingestion & Implementation Mapping
**Status:** Planning/documentation only. No application code, migration, or reference image was modified.
**Last updated:** 2026-08-31

Inventory of every file in `docs/design/stitch/references/`. These images are the visual source of truth for composition, density, and tone (work item §11) — they are not modified, regenerated, or replaced here. Behavioral truth (what data exists, what mutations are legal) remains the domain/security documentation; conflicts between the two are recorded in [ui-data-action-map.md](../../product/ui-data-action-map.md) and [ui-backend-gap-register.md](../../product/ui-backend-gap-register.md), never resolved by silently changing one side.

All 7 screens the work item names as expected (§5) are present. None missing.

**Note on directory casing:** `git status` reports the reference directory as `docs/design/Stitch/` (capital S) while the actual path on disk is `docs/design/stitch/` (lowercase, per the work item's own path and every prior phase's usage). macOS's default case-insensitive filesystem resolves both to the same directory — this is not two different locations, just an artifact of how git's case-sensitive index reports a path first seen with different casing. No reference file was renamed; flagged here per §58 rather than silently worked around.

---

## 01-todays-operations.png

- **Screen:** Today's Operations / Overview
- **Role:** `organization_admin` / `dispatcher`
- **Viewport:** Desktop, fixed left sidebar + fluid content (≈1600px reference width)
- **Layout regions:** Fixed dark sidebar (logo, primary nav, org context, settings, user); top bar (title + date, global search, "Export Day Sheet", "New Trip" primary CTA, notifications, help, avatar); summary metric strip; two-column body (left: "Needs Attention" table + "Upcoming Trips" table; right: "Driver Availability", "Active Trips", "Activity Log" panels)
- **Navigation model:** Persistent left sidebar, 9 top-level items (Overview, Trips, Dispatch, Passengers, Facilities, Drivers, Fleet, Billing, Reports) + Settings + org/user footer
- **Major components:** Sidebar nav, top app bar, metric/summary strip, data table (×2, different column sets), status/issue badges, right-rail panel stack, activity feed list
- **Visible fields:** trip count metrics, per-row: time, passenger name, route (pickup→destination as one line), issue label, action button; per-row (Upcoming Trips): time, passenger, pickup, destination, driver, vehicle, status badge; driver availability counts by category; active-trip driver+vehicle+status; activity-log actor+action+object+timestamp
- **Visible status indicators:** "Needs Assignment" / "Running Late" / "Pending Confirmation" badges; per-trip status badges (Assigned/En Route/Scheduled/Requested/Completed); driver availability dot colors (green/amber/gray)
- **Visible actions:** New Trip, Export Day Sheet, Assign, Review, Call, View all trips, Filter, global search
- **Responsive assumptions:** None shown — single fixed desktop composition. No tablet/mobile variant provided.
- **Ambiguous concepts:** "Pending Confirmation" has no corresponding domain concept (see ui-backend-gap-register.md). "Running Late" threshold undefined. Export Day Sheet's output format/content undefined.

## 02-trip-detail.png

- **Screen:** Trip Detail (Operations)
- **Role:** `organization_admin` / `dispatcher`
- **Viewport:** Desktop, same sidebar/shell as 01 but narrower sidebar variant shown (icon-only nav, no visible section labels beyond active state) — treated as the same OperationsSidebar component, not a second nav system
- **Layout regions:** Breadcrumb; header (passenger name + status badge, Trip ID, action buttons); 5-column info strip (Pickup/Appointment/Driver/Vehicle/Status); two-column body (left: "Trip Route" panel, "Passenger & Trip Information" panel; right: "Current Status", "Trip Exceptions", "Trip Notes" panels)
- **Navigation model:** Breadcrumb (Trips › ZW-240829-018) back to the Trips list; same persistent sidebar
- **Major components:** Breadcrumb, status badge, info-strip/definition list, route timeline (pickup/destination with connecting line + dot markers), definition-list grid, right-rail status card, exception empty-state, note list + add-note action
- **Visible fields:** passenger name, Trip reference code, pickup/destination address (multi-line), scheduled pickup time, appointment time, driver name, vehicle label, trip state, "Current Status" (state, driver, last-update timestamp, "next action" label), passenger phone, trip type, requester, reference code, assistance requirements, companion, trip notes (author role + timestamp + body)
- **Visible status indicators:** state badge (En Route), "No open exceptions" empty state
- **Visible actions:** Edit Trip, More (menu, contents unclear), Contact Driver, Report Issue, Add Note, "Driver name (View)" link
- **Responsive assumptions:** None shown.
- **Ambiguous concepts:** "More" button's menu contents are not shown. "Next Action: Arrive at pickup" — a derived label, not a stored field (see mapping doc). "Trip Type: One way" and "Reference: FAC-23981" have no direct schema field (see gap register). "Companion: None recorded" has no schema field at all (see gap register).

## 03-dispatch-board.png

- **Screen:** Dispatch Board
- **Role:** `organization_admin` / `dispatcher`
- **Viewport:** Desktop, three-column layout (needs-assignment queue / time×driver grid / driver capacity rail)
- **Layout regions:** Top bar (title + date, day navigator, search, Dispatch Settings, New Trip); summary strip (5 metrics); left column "Needs Assignment (N)" card queue; center "Today's Assignments" time-grid (hour columns, driver rows, positioned trip blocks); right column "Driver Capacity" card list
- **Navigation model:** Same persistent sidebar; day navigator (‹ Today ›) local to this screen
- **Major components:** Card queue (assignment-needed trips), time-axis grid with per-driver rows and spatially-positioned trip blocks, driver capacity cards with status pills
- **Visible fields:** per-queue-card: passenger, time, route, status label; per-grid-block: passenger, time, status; per-driver-row: driver name, vehicle; per-capacity-card: driver name/initials avatar, status pill, current or next assignment summary
- **Visible status indicators:** NEEDS ASSIGNMENT / UNASSIGNED / REVIEW (queue); ON TRIP / CONFLICT / AVAILABLE / BREAK (capacity); "Potential timing conflict" warning on a grid block; "BREAK UNTIL 10:30 AM" block spanning a time range
- **Visible actions:** Assign (×2), Review, New Trip, Dispatch Settings, search, day navigation, an implied filter icon on the capacity panel
- **Responsive assumptions:** None shown — dense 3-column desktop layout, not viable below a wide viewport.
- **Ambiguous concepts:** The spatial time-grid strongly implies a drag-and-drop assignment affordance, but no drag handle/cursor state is visible in a static image — treated as **implied, not confirmed** (see §22/23 analysis in the mapping doc). "Potential timing conflict" and "CONFLICT" status have no defined derivation. "Dispatch Settings" contents unknown.

## 04-driver-active-trip.png

- **Screen:** Driver Active Trip
- **Role:** `driver`
- **Viewport:** Mobile portrait, ≈390-430px reference width
- **Layout regions:** Compact header (avatar, brand, shift status, bell); Trip summary card (name + status); Route card (pickup block with actions + note, connecting line, drop-off block); "Passenger Requirements" card; secondary action row (Report Issue / Trip Details); full-width primary CTA; fixed bottom tab bar
- **Navigation model:** Bottom tab bar (Today / Trips / History / Profile), no visible back/breadcrumb — this screen is reached via "View Trip" from Today or Trips
- **Major components:** Compact app header, status badge, route timeline (2-stop), inline advisory note, secondary button pair, full-width primary CTA button, bottom tab bar
- **Visible fields:** passenger name, Trip reference, pickup time + address, "Call passenger on arrival" note, drop-off appointment time + facility name + address, assistance requirement, companion
- **Visible status indicators:** "En Route" badge, "On Shift" header status
- **Visible actions:** Navigate, Call Passenger, Report Issue, Trip Details, primary CTA ("I'VE ARRIVED" — state-dependent label)
- **Responsive assumptions:** Single-column mobile-first, large touch targets throughout (full-width primary CTA, generously sized secondary buttons) — matches work item §9's requirement directly.
- **Ambiguous concepts:** "Trip Details" button's destination relative to this-same screen's own content is unclear (possibly a fuller detail view, possibly redundant with this screen). "Companion: None recorded" — same gap as 02.

## 05-internal-new-trip.png

- **Screen:** Internal New Trip
- **Role:** `organization_admin` / `dispatcher`
- **Viewport:** Desktop
- **Layout regions:** Breadcrumb; header (title + description, Cancel/Create Trip actions); "Request Source" panel (source-type radio group, import-from-request affordance, requester fields); "Passenger" panel (search/add, selected passenger card); right-rail "Needs Attention" advisory
- **Navigation model:** Breadcrumb (Trips › New Trip)
- **Major components:** Segmented radio-card group, labeled text inputs, passenger search/typeahead input, selected-passenger chip/card, right-rail warning card
- **Visible fields:** requester type (Passenger/Family-Caregiver/Healthcare Facility/Other), request reference code, requester name/organization/phone/email, passenger search, selected passenger (name, phone)
- **Visible status indicators:** "Needs Attention — Driver not assigned" advisory (anticipating a state the Trip will be in immediately after creation, before assignment)
- **Visible actions:** Import request details, Add New Passenger, remove-passenger (×), Cancel, Create Trip
- **Responsive assumptions:** None shown.
- **Ambiguous concepts:** This is the most architecturally significant reference in the set — "Import request details" against a request reference implies TransportationRequest-to-Trip conversion; the form's own remaining sections (pickup/destination/timing/vehicle/driver — not visible in this single screenshot, likely below the fold or a later step) are not shown, so the full field set this screen ultimately needs is incomplete information. See §12/§13 of the mapping doc and the gap register for the CONTROLLED INTERNAL TRIP CREATION finding.

## 06-driver-today.png

- **Screen:** Driver Today
- **Role:** `driver`
- **Viewport:** Mobile portrait
- **Layout regions:** Header (avatar, brand, shift status, bell); date + "N trips assigned" badge; "NEXT TRIP" featured card; "LATER TODAY" card list; "COMPLETED TODAY" card list; bottom tab bar
- **Navigation model:** Bottom tab bar (Today active)
- **Major components:** Featured trip card (larger, with inline actions), compact trip row cards, section labels, status badges, bottom tab bar
- **Visible fields:** date, trips-assigned count, per-trip: time, passenger, pickup address, destination + appointment time, advisory note, status badge; a "Pickup updated from X" change-notice badge on one row
- **Visible status indicators:** Assigned / Completed badges; "Pickup updated from 3:15 PM" change notice
- **Visible actions:** View Trip, Navigate, Call Passenger (on the featured card only — later/completed rows are read-only summaries)
- **Responsive assumptions:** Mobile-first, matches 04/07.
- **Ambiguous concepts:** The change-notice ("Pickup updated from X") implies field-level change tracking/notification not present in any reviewed schema or event type — see gap register.

## 07-driver-trips.png

- **Screen:** Driver Trips
- **Role:** `driver`
- **Viewport:** Mobile portrait
- **Layout regions:** Header (same as 06); date-grouped sections ("TODAY", "TOMORROW"); trip cards per group; bottom tab bar
- **Navigation model:** Bottom tab bar (Trips active)
- **Major components:** Date-group section headers, featured/compact trip cards (same components as 06), status badges, change-notice badge
- **Visible fields:** grouped date labels, per-trip: time, passenger, pickup→destination, status badge; same "Pickup updated from X" pattern on a different trip
- **Visible status indicators:** Assigned badges; change-notice badge
- **Visible actions:** View Trip (first card only)
- **Responsive assumptions:** Mobile-first, matches 04/06.
- **Ambiguous concepts:** This screen shows only **today + tomorrow, all `Assigned`** — no completed/historical entries and no explicit date-range control are visible, confirming this maps to the active/upcoming list (`driver_list_active_trips`), not the redacted history RPC (`driver_list_trip_history`) reached via the separate "History" tab, which has no reference image in this set (see gap register — "History" tab exists in the nav but its own screen was not provided).
