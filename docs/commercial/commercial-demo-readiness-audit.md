# Zenward — Commercial Demo Readiness Audit

**Work item:** P1-E3-S8C — Commercial Demo Polish & Sales Readiness
**Method:** direct, live inspection of every buyer-facing screen in the primary demo path (Today's Operations, Dispatch, Trips, Trip Detail, Passengers, Facilities, Drivers, Fleet, Driver Today/Trips, Driver Active Trip), signed in as `dispatch@harmonytransport.test` / three `driver.*@harmonytransport.test` accounts, using the real seeded Harmony Medical Transport organization, across 3 consecutive fresh `supabase db reset` cycles. Screenshots backing this audit: `docs/design/qa/commercial-demo/`. Checked for: development wording, test/QA names, placeholder content, dead links/404s, confusing labels, bad empty states, internal ID exposure, generic/unhelpful errors, and slow or awkward interactions.

**Classification:** BLOCKER (must fix before any buyer demo) / HIGH-FRICTION (fix before demo if feasible; materially hurts the story) / MEDIUM-FRICTION (worth fixing, doesn't derail a demo) / POLISH (cosmetic) / TRUTHFUL-LIMITATION (a real, honest gap — not a bug, don't "fix" by faking it).

---

## Findings

### BLOCKER
None found. No screen in the primary demo path showed QA-style names, a 404, a crash, or a dev-only artifact when signed in as a Harmony account.

### HIGH-FRICTION
None found that were within this phase's scope to fix. (See TRUTHFUL-LIMITATION below for real gaps that were deliberately not "fixed" by fabricating functionality.)

### MEDIUM-FRICTION

1. **Account-menu email truncation.** The signed-in email in the sidebar footer (e.g. `dispatch@harmonytransport...`) truncates with an ellipsis at the current sidebar width — legible enough (the visible prefix is unambiguous) but slightly untidy in a screen-share. Not fixed this phase — a one-line CSS width/truncation tweak, low risk, but out of scope for a demo-content-focused phase; flagged for a future UI polish pass rather than touched here to keep this phase's diff limited to `supabase/seed.sql` plus documentation.
2. **Dispatch board's "trips today" count (10) differs from Today's Operations' "trips today" count (12).** Not a bug — confirmed by reading `dispatch-board.ts`: Dispatch board deliberately scopes to non-terminal trips only (it's a board for trips still needing action), while Today's Operations counts the full day including completed trips. Both are correct for what they measure, but a buyer glancing between the two screens could momentarily wonder why the numbers differ. **Recommendation:** the demo script does not put these two screens side by side in the same breath, and if a buyer asks, the honest answer ("Dispatch shows trips still in progress or needing action; Today's Operations shows the full day including what's already finished") is a good answer, not a defect to hide.

### POLISH

3. Trip Detail and other detail routes carry the record's UUID in the URL bar (e.g. `/operations/trips/80000000-...`). Normal for a web application and not a security concern (RLS-enforced regardless of what a URL says), but worth being deliberate about: reach Trip Detail by clicking through the UI during a demo, never by typing or reading a raw UUID aloud.

### TRUTHFUL-LIMITATION (confirmed real, correctly not faked)

4. Driver Availability panel does not exist (GAP-6) — Dispatch board's Driver Capacity panel shows "On Trip" only, never a fabricated Available/Break/Unavailable status.
5. "Export Day Sheet" button is visibly present but honestly disabled (GAP-9) — not hidden, not a fake working control.
6. Passenger/Facility/Vehicle create-or-edit and Driver onboarding are not self-serve (GAP-12/13/14/15) — the demo script and `operator-value-map.md` both address this directly rather than avoiding the topic.
7. No live map, no ETA, no background location — the location-freshness signal is exactly what it claims to be, nothing more; verified directly (a seeded "fresh" location naturally ages to "needs update" purely from wall-clock time passing since reset, which is correct, expected behavior, not a defect — see finding in the live verification below).

---

## Demo data quality

Verified live (not assumed) across 3 consecutive fresh resets, signed in as Harmony accounts only:
- No QA-style name (`Org A`, `Org B`, `Fictional Passenger A1`, `example.test`, etc.) appeared on any screen in the primary demo path.
- No real PHI, no medical diagnosis data — passenger records carry only mobility/assistance notes (e.g. "uses a wheelchair, needs ramp access"), consistent with the RPCs' own minimum-necessary projections.
- No implied Vehicle capability beyond what the schema supports — vehicle records are plain label + status, nothing implying wheelchair-lift/capacity features the schema does not model.
- All summary counts (trip counts, active counts, attention counts) are derived from the real seeded rows via the existing production query paths (`getTodaysOperations()`, `getDispatchBoardData()`) — nothing is hard-coded for the demo.

## Simulated skeptical-prospect self-assessment

1. **"Is this actually a working product, or a mockup?"** Working — every action taken in the verification run (assign, start trip, share location, report/resolve an issue, complete a trip) produced a real, verified database state change, not a staged transition.
2. **"Does the data look like a real transportation company, or obviously fake test data?"** Real-looking — plausible names, real Atlanta-area addresses, professional facility names, phone numbers in a consistent format. No QA fixture artifacts leaked into the Harmony organization's own screens.
3. **"What happens if I click something you didn't plan to show me?"** Reasonably safe — the 5 master-data screens (Passengers/Facilities/Drivers/Fleet), Trips list with search/filter, and Trip Detail for both active and completed trips were all separately verified, not just the scripted happy path.
4. **"Can I tell what's real versus aspirational?"** Yes, if the presenter follows `product-capability-matrix.md` and `sales-claims-boundary.md` — the product itself doesn't editorialize (no "Coming Soon" banners cluttering the UI), so this discipline lives in the script and the presenter, not the product chrome.
5. **"Would I trust this with my drivers' and patients' data?"** The honest answer available today is "here's exactly how isolation and access control work" (`security-overview.md`) — not a compliance certification, and the demo script is explicit about not overclaiming this.
6. **"Does the assignment/lifecycle flow feel like real operations software, or a toy?"** Feels real — the assignment dialog, lifecycle buttons, and issue-report/resolve dialogs all behave like a considered operations tool (loading states, disabled-while-submitting, confirmation feedback), not a demo-only shortcut.
7. **"If I ask a hard question about what's NOT built, will I get a straight answer?"** Yes, by design — `product-capability-matrix.md`'s PLANNED-NOT-AVAILABLE section and `operator-objections.md` exist specifically so the answer is prepared and honest rather than improvised defensively.
8. **"Does the 10-minute demo feel like a coherent story, or a feature tour?"** Coherent — verified structurally: every step in `zenward-demo-script.md`'s 10-minute version causally follows from the previous one (the exact trip assigned in Step 2 is the trip started/shared/completed in Steps 3-6), not a sequence of unrelated screen visits.

## Verdict

No BLOCKER or unaddressed HIGH-FRICTION finding exists in the current buyer path. The 2 MEDIUM-FRICTION findings are cosmetic/explainable, not correctness or trust issues, and are recorded rather than silently fixed outside this phase's scope. See the bottom verdict block of `docs/reports/P1-E3-S8C-commercial-demo-sales-readiness-report.txt` for the phase's overall gate decision.
