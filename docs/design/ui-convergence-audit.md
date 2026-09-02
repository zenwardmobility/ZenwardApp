# Zenward Platform — UI/UX Design Convergence Audit

**Work item:** P1-E3-S8B — Full Product UI/UX Design Convergence
**Status:** Complete. Every P0 and P1 finding below is marked FIXED, JUSTIFIED, or DEFERRED — none left unexplained.
**Last updated:** 2026-09-02

Methodology: for each of the 7 canonical screens, the real running application was screenshotted at the reference's own approximate canvas width (or the closest required QA viewport) and compared side-by-side against `docs/design/stitch/references/`. Severity: **P0** = materially wrong hierarchy/layout, **P1** = clearly visible product-quality discrepancy, **P2** = refinement, **JUSTIFIED** = real data/backend constraint. Screenshots: `docs/design/qa/ui-convergence/before/` (pre-fix) and `docs/design/qa/ui-convergence/after/` (post-fix).

---

## Global / systemic findings (apply across all 4 Operations screens)

### G1 — Sidebar rendered light, reference is dark Care Navy
- **Reference element:** A fixed dark (`#123447`-family) left sidebar with white/muted-light nav text, a teal-tinted active-item treatment, white brand wordmark.
- **Current implementation (before):** `OperationsSidebar` rendered on `bg-surface-elevated` (white) with the same Calm Mist/Interactive Teal active treatment used everywhere else in the app.
- **Discrepancy:** The single most visible systemic gap — every prior phase explicitly accepted this as a temporary deviation while backend work was the priority (this phase's own premise).
- **Severity:** P0 (systemic — affects Today's Operations, Trip Detail, Dispatch, New Trip identically).
- **Action:** **FIXED.** New `--color-navy-*` token set added to `globals.css` (Care Navy background, on-navy muted/hover/active text and border tokens — reserved for the sidebar alone, never used as a body surface). `OperationsSidebar.tsx` rewritten to the dark treatment. See `docs/design/zenward-ui-system.md` for the token contract.

### G2 — Logo asset shows as a white box against the new dark sidebar
- **Reference element:** N/A directly (the reference's own lockup is presumably a vector asset with no background) — but placing our one approved raster logo on navy exposed a real asset limitation.
- **Current implementation:** `zenward-mobility-logo.png` confirmed (via direct pixel inspection) to be a flat 8-bit RGB PNG with **no alpha channel** — an opaque white background baked into the file. Placed directly on `bg-navy-surface` it rendered as a jarring white rectangle.
- **Discrepancy:** A real, visible defect introduced by fixing G1 — not present before because the sidebar itself was already white.
- **Severity:** P0 (would have undermined the entire G1 fix).
- **Action:** **FIXED**, without touching the artwork itself (the approved brand rules forbid redesigning/recoloring the logo). The `<Image>` is wrapped in a small plain white rounded badge chip (`bg-white p-1.5/p-2 rounded-sm`) — a standard, non-decorative pattern for a light-background mark on a dark shell, confirmed visually clean in the after-screenshots.

### G3 — Dispatch driver-row/trip-block labels truncating mid-word
- **Reference element:** Driver name + vehicle, and per-block passenger name, both fully legible.
- **Current implementation (before):** `ROW_LABEL_WIDTH_PX = 140` — real driver names plus a vehicle label plus the S7A freshness link were visibly clipped ("Fictional Driver…").
- **Severity:** P1.
- **Action:** **FIXED** — `ROW_LABEL_WIDTH_PX` widened to 168 (no time-semantic cost, unlike the trip-block width). `GRID_BLOCK_WIDTH_PX` (144px) was deliberately left unchanged — widening it would misrepresent elapsed trip duration more than it already approximates (a documented, pre-existing tradeoff — see `dispatch-grid.ts`'s own comment); instead every truncatable label across `AssignmentGrid`/`DriverCapacityPanel` now carries a real `title` attribute as a full-text fallback. Some residual truncation is expected and acceptable for unusually long *fictional test* names ("Fictional Passenger A1") that exceed realistic production name lengths.

---

## 01 — Today's Operations

**Reference:** `01-todays-operations.png`. **Before:** `docs/design/qa/ui-convergence/before/01-todays-operations/`. **After:** `docs/design/qa/ui-convergence/after/01-todays-operations/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | Dark sidebar | (see G1) | — | P0 | FIXED (G1) |
| 2 | 4th summary metric: "completed" (checkmark) | "no current issues" (Trip Assurance `onTrackCount`) | Reference predates Trip Assurance (P1-E3-S8); the metric was intentionally redefined, not regressed — a completed-count and an on-track-count are different, both real facts | JUSTIFIED | Documented (ZD-169/ZD-174 already record this evolution) |
| 3 | Needs Attention "ISSUE" column with "Needs Assignment"/"Running Late"/"Pending Confirmation" | "Reason" column with real derived Assurance conditions | "Running Late"/"Pending Confirmation" have no real derivation (no approved lateness rule — ZD-171); showing only real conditions is the honest choice, not a shortfall | JUSTIFIED | Unchanged — this is the whole point of the Trip Assurance model |
| 4 | Right rail: "Driver Availability" panel | Absent | No Driver Availability taxonomy exists in the schema (GAP-6) — inventing pill states (Available/Break/Unavailable) would be fabricated data, explicitly forbidden (work item §30/§47) | JUSTIFIED | Unchanged; documented at GAP-6 |
| 5 | Action column verbs: Assign / Review / Call | Assign / Open Trip | "Review"/"Call" implied fabricated workflows (no real "pending confirmation" or "call to resolve" action exists); the real system's binary Assign-or-Open-Trip is honest, not simplified for convenience | JUSTIFIED | Unchanged |

**Verdict:** No P0/P1 remaining beyond the already-fixed systemic sidebar (G1). Screen: **VISUAL READY**.

---

## 02 — Trip Detail

**Reference:** `02-trip-detail.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/02-trip-detail/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | Dark sidebar | (see G1) | — | P0 | FIXED (G1) |
| 2 | Breadcrumb + header show a Trip reference code ("ZW-240829-018") | Breadcrumb shows passenger name; no reference code anywhere | No `trips.reference_code` (or equivalent) field exists in the schema — the reference's own code is a fabricated illustrative value (already documented in `stitch-reference-index.md`'s own "Ambiguous concepts" note for this screen) | JUSTIFIED | Unchanged — inventing a fake reference code would violate work item §47/§48 |
| 3 | "Trip Type: One way", "Companion: None recorded" | Absent | Same class of gap — no schema field for either (documented in the gap register since P1-E3-S0) | JUSTIFIED | Unchanged |
| 4 | Compact "No open exceptions." inline note | A more generous empty-state block (heading + subtext + button) | A real, if minor, density difference — QA'd, judged acceptable: the Trip Exceptions panel is a right-rail card among 2 others (Current Status, Trip Notes), not competing for space the same way the reference's own tighter 3-panel column does | P2 | Not touched this phase — noted for a future refinement pass, not blocking |

**Verdict:** **VISUAL READY**.

---

## 03 — Dispatch Board

**Reference:** `03-dispatch-board.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/03-dispatch-board/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | Dark sidebar | (see G1) | — | P0 | FIXED (G1) |
| 2 | Driver-row/trip-block label truncation | (see G3) | — | P1 | FIXED (G3) |
| 3 | 5 summary metrics (trips/unassigned/active/drivers available/require attention) | 3 metrics (trips/unassigned/active) | "Drivers available" has no real taxonomy (same GAP-6 as row 1 above) — JUSTIFIED absence. "Require attention" (real open-exception count) WAS available from already-fetched data and not surfaced | P1 for the missing "require attention" count | **FIXED** — `DispatchBoardData.summary.attentionCount` added (reusing the already-fetched `openExceptionTripIds` set, no new query), rendered as a 4th, conditional (only shown when >0) summary metric matching Today's Operations' own restrained pattern |
| 4 | Needs Assignment cards show varied badges + a secondary "Return trip confirmation pending" advisory | Single "Needs Assignment" badge, no secondary advisory | The reference's "REVIEW"/return-confirmation workflow has no backend concept (no confirmation-pending state) | JUSTIFIED | Unchanged |
| 5 | Driver Capacity: AVAILABLE/BREAK/CONFLICT pills | Only "On Trip" (or no pill) | Same GAP-6 — deliberately, explicitly NOT fabricated (component's own header comment already documents this, reused verbatim this phase) | JUSTIFIED | Unchanged |
| 6 | Live location + map | External OpenStreetMap link (S7A) | See the dedicated embedded-map decision below | See below | See below |

### Embedded-map decision (work item §29)
Evaluated switching from the external-link MVP (ZD-166, P1-E3-S7A) to an embedded read-only Leaflet+OpenStreetMap view. **Decision: retain the external link this phase.** Reasoning: (1) the phase's own explicit conditions require this NOT to "materially expand scope" — a real embedded map (marker rendering, pan/zoom, tile-provider configuration, a genuine bundle-size/performance measurement per work item §52) is a meaningfully-sized addition on top of an already-large convergence pass touching 7 screens; (2) no paid API key or new tracking capability would be needed either way, so the privacy/dependency profile is not the blocker — it is pure effort/scope discipline; (3) the current external link already surfaces the real coordinate, is zero-dependency, and was itself only established one phase ago (P1-E3-S8A came after it) with no new product signal since then that the link is materially insufficient. This is a **JUSTIFIED, documented remaining deviation**, not an oversight — recorded as ZD-1xx below, with an explicit re-evaluation trigger.

**Verdict:** **VISUAL READY**.

---

## 04 — Driver Active Trip

**Reference:** `04-driver-active-trip.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/04-driver-active-trip/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | Header shows brand ("Zenward Mobility") + "On Shift" status | Header shows page title ("Trip") + Driver name; no shift status | Two considered differences: (a) page-title-first is consistent across all 3 Driver screens already (a deliberate prior-phase pattern, not new); (b) "On Shift" has no backend concept — Driver has no shift-status field (same GAP-6 family) | JUSTIFIED (b) / considered-and-kept (a) | Not changed — (a) is an existing, internally-consistent pattern across Driver Today/Trips/Active Trip; relitigating it was judged lower value than the fixes actually made this phase, and changing only Active Trip's header would itself create a NEW cross-screen inconsistency |
| 2 | "Report Issue" / "Trip Details" secondary row above the primary CTA | Neither existed | Report Issue: reference shows a clear, natural affordance, and the backend (post-P1-E3-S8A hardening: current-assignment-only, non-terminal-only, the same controlled RPC, no Driver resolve, no broad exception read) now safely supports exactly this scope — the work item's own explicit condition for building it (§37) is met. "Trip Details" has no defined destination even in the reference's own documented ambiguity note (`stitch-reference-index.md`) | P1 (Report Issue) / JUSTIFIED omission (Trip Details) | **FIXED** (Report Issue) — `DriverReportIssueButton`/`DriverReportIssueDialog` added, calling `report_trip_exception` through the same Server Action layering as every other Driver mutation; verified end-to-end (button renders, dialog submits, real DB row created, correct actor). "Trip Details" intentionally not built — no real destination to wire it to |
| 3 | Drop-off shows a full street address | Shows only a short facility name for the fixture trip inspected | Checked directly against the database: this specific seed Trip's `destination_description` genuinely contains only "Fictional Clinic A" (no `destination_facility_id`, no street text ever captured) — a **seed-data characteristic**, not a rendering bug. The component renders `destination_description` verbatim, exactly as it renders `pickup_description` (which for THIS trip happens to include a full address) | Not a code defect | No code change — confirmed via direct query before concluding anything, per this project's own "verify before fixing" discipline |
| 4 | Location-sharing status region | `DriverLocationTracker` (P1-E3-S7A) | Already integrated in-flow (not a separate diagnostic-looking widget) — reviewed again this phase, no change needed | — | Unchanged, already converged |

**Verdict:** **VISUAL READY**.

---

## 05 — Internal New Trip

**Reference:** `05-internal-new-trip.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/05-internal-new-trip/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | Dark sidebar | (see G1) | — | P0 | FIXED (G1) |
| 2 | "Request Source" panel: requester-type radio group + editable requester name/org/phone/email fields | Absent — replaced by a "Related Request" linked-TransportationRequest selector | A pre-existing, already-documented P1-E3-S7 architectural decision (ZD-153–159): the reference's own inline requester-editor fields have no `create_trip` parameter and no schema backing — building them would fabricate data `create_trip` cannot accept. Re-verified this phase, not newly discovered | JUSTIFIED (carried forward, re-confirmed) | Unchanged |
| 3 | Passenger: free-text search input → distinct selected-passenger card (avatar initials, name, phone, ✕ remove) | A native `<select>` dropdown (P1-E3-S7's own documented temporary choice, explicitly flagged for this phase in work item §20) | The single largest remaining, explicitly-named convergence item in the whole work item | **P0** | **FIXED** — new `Combobox` primitive built (`src/components/ui/Combobox.tsx`), a real WAI-ARIA "combobox with list autocomplete" implementation (keyboard Up/Down/Home/End/Enter/Escape, `aria-activedescendant`, a real empty state, search matches name AND phone). Wired into `NewTripForm`'s Passenger field; on selection, renders the exact reference composition (Avatar initials circle + name + phone + a real Remove control) via a hidden form field for submission. Verified: 5/5 accessibility/keyboard assertions, 3/3 end-to-end trip-creation assertions (real DB row, real passenger, real addresses) |
| 4 | Right rail: single amber "Needs Attention — Driver not assigned" advisory | "Related Request" card + a separate blue informational advisory ("Assign a driver after creating this trip") | A real, considered tone choice: the Trip doesn't exist yet, so there is no real Assurance condition to derive yet (Assurance only evaluates existing Trips) — presenting this as neutral info rather than a pre-emptive warning is arguably more honest, not merely different | P2 / JUSTIFIED | Not changed this phase — noted as a legitimate future refinement, not a defect |
| 5 | Section icon+label header pattern | Same icon+label pattern already used (Passenger/Trip Schedule/Pickup/etc.) | Good existing convergence | — | No change needed |

**Verdict:** **VISUAL READY** (the one P0 item — the combobox — is the item this phase treats as most consequential across the entire audit).

---

## 06 — Driver Today

**Reference:** `06-driver-today.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/06-driver-today/`.

| # | Reference element | Current implementation | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | "NEXT TRIP" section label above the featured card | Present (`<SectionLabel text="Next Trip" />`) | **No discrepancy** — this was flagged in this audit's own first-pass notes, then found to be a mis-observation on re-verification against the actual screenshot; the label was already there. Recorded here explicitly so the correction itself is auditable, not silently dropped | — | No change (confirmed already correct) |
| 2 | Featured card includes an inline advisory note + Navigate/Call Passenger buttons directly on Today | Featured card shows time/status/route + "View Trip" only (advisory + quick actions live one tap away, on Active Trip) | A real content-density difference. Navigate/Call already exist as real capabilities (Active Trip) — bringing them onto Today's own featured card is technically low-risk, but is judged **scope-adjacent feature surface growth** in an already-large convergence pass whose own explicit non-goal is "not a feature-expansion phase" (work item §0) | P2 | **DEFERRED** — a reasonable candidate for a future, dedicated pass, not folded into this phase to keep the addition itself deliberate and reviewed on its own, not incidental |
| 3 | "COMPLETED TODAY" section | Absent for this fixture (no completed trips today) | Conditionally rendered, correctly absent when empty — matches reference's own conditional pattern (reference happens to have a completed trip to show; ours doesn't for this particular seed state) | JUSTIFIED | Unchanged |

**Verdict:** **VISUAL READY**.

---

## 07 — Driver Trips

**Reference:** `07-driver-trips.png`. **Before/After:** `docs/design/qa/ui-convergence/{before,after}/07-driver-trips/`.

| # | Reference element | Current implementation (before) | Discrepancy | Severity | Action |
|---|---|---|---|---|---|
| 1 | One "TODAY" header covering every trip scheduled today (featured + later-today rows together) | **Two** separate "TODAY" headers — one for the featured trip's own section, a second, duplicate one for the remaining same-day trips | A real bug: the featured trip was pulled OUT of the day-grouping loop entirely and given its own always-present header, so any additional same-day trip re-triggered a second "Today" group | **P0/P1** (a real, visibly broken date-grouping bug, not merely a style gap) | **FIXED** — `page.tsx` rewritten to group ALL scheduled trips (including the featured one) by calendar day first; the featured trip renders with `DriverNextTripCard` INSIDE its own group's single section, every other trip (same day or later) renders with the compact `DriverTripCard` under the correct shared header. Verified visually: exactly one "TODAY" header now covers all 3 same-day fixture trips, one "TOMORROW" header covers the 4th |
| 2 | Featured/compact card tiering (larger dark-badge card first, plain rows after) | Already matched | — | — | No change needed — already converged before this phase |

**Verdict:** **VISUAL READY**.

---

## Second (cross-screen) comparison pass — systemic consistency (work item §55)

Reviewed all 7 after-screenshots together, not just individually:
- **Same shell:** all 4 Operations screens now share the identical dark sidebar, header height/alignment, content gutters — confirmed via direct screenshot comparison, not assumed from shared-component usage alone.
- **Same radii/typography/spacing:** unchanged this phase (already using the shared `--radius-*`/`typography.*`/`--spacing-zw-*` token system established in prior phases — spot-checked across all 7 screens, no ad hoc values found in the files touched this phase).
- **Same status logic:** lifecycle badges (Scheduled/En Route/etc.) and Assurance badges (Open issue/Needs assignment/etc.) remain visually and semantically distinct — Assurance never overloads a lifecycle `StatusBadge` instance, confirmed by re-reading `presentation.ts`'s `assuranceStatusCategory()` (unchanged this phase) against `trip-presentation.ts`'s lifecycle labels (also unchanged).
- **Same action hierarchy:** one dominant teal primary action per screen preserved everywhere (New Trip/Create Trip, I'VE ARRIVED, Assign) — no new competing primary buttons were introduced by any fix this phase (Report Issue on Driver Active Trip is deliberately `variant="outline"`, secondary to the primary lifecycle CTA).
- **Same density:** the Operations screens remain information-dense without added whitespace; the Driver screens remain single-column, large-touch-target mobile-first — no fix this phase widened, padded, or decorated anything beyond what each specific finding required.

No new cross-screen inconsistency was introduced by this phase's fixes.
