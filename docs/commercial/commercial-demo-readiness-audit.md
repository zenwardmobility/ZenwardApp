# Zenward — Commercial Demo Readiness Audit

**Work item:** P1-E3-S8C — Commercial Demo Polish & Sales Readiness, closed out by P1-E3-S8C1 — Commercial Trust Closure (account-menu truncation fix, "trips today" label disambiguation, fully fictional demo facility geography — see `docs/reports/P1-E3-S8C1-commercial-trust-closure-report.txt`).
**Method:** direct, live inspection of every buyer-facing screen in the primary demo path (Today's Operations, Dispatch, Trips, Trip Detail, Passengers, Facilities, Drivers, Fleet, Driver Today/Trips, Driver Active Trip), signed in as `dispatch@harmonytransport.test` / three `driver.*@harmonytransport.test` accounts, using the real seeded Harmony Medical Transport organization, across multiple consecutive fresh `supabase db reset` cycles (3 in S8C, additional in S8C1). Screenshots backing this audit: `docs/design/qa/commercial-demo/`. Checked for: development wording, test/QA names, placeholder content, dead links/404s, confusing labels, bad empty states, internal ID exposure, generic/unhelpful errors, and slow or awkward interactions.

**Classification:** BLOCKER (must fix before any buyer demo) / HIGH-FRICTION (fix before demo if feasible; materially hurts the story) / MEDIUM-FRICTION (worth fixing, doesn't derail a demo) / POLISH (cosmetic) / TRUTHFUL-LIMITATION (a real, honest gap — not a bug, don't "fix" by faking it).

---

## Findings

### BLOCKER
None found. No screen in the primary demo path showed QA-style names, a 404, a crash, or a dev-only artifact when signed in as a Harmony account.

### HIGH-FRICTION
None found that were within this phase's scope to fix. (See TRUTHFUL-LIMITATION below for real gaps that were deliberately not "fixed" by fabricating functionality.)

### MEDIUM-FRICTION — both RESOLVED (P1-E3-S8C1)

1. ~~**Account-menu email truncation.**~~ **RESOLVED.** Root cause: `getDisplayName()` fell back to the raw email address whenever a signed-in user had no `user_profiles.display_name` row — true of Harmony's own `owner@`/`dispatch@harmonytransport.test` accounts, so their full email rendered in the sidebar's name slot (a slot sized for a short human name), which is what actually produced the awkward clipping. Fixed at the root: real `user_profiles.display_name` rows now exist for Harmony's staff ("Renata Castillo," "Sam Delgado," `supabase/seed.sql`). The sidebar and account-menu popup layout were ALSO hardened independently (`min-w-0`/`truncate`/`title` on the identity text, `OperationsSidebar.tsx` and `AccountMenu.tsx`) so any future long identity value — a longer name, a longer org name — still degrades gracefully with a clean ellipsis and a hover tooltip, rather than clipping badly. Verified live: the sidebar and popup both read "Sam Delgado / Dispatcher" cleanly at realistic Operations widths.
2. ~~**Dispatch board's "trips today" count (10) differs from Today's Operations' "trips today" count (12).**~~ **RESOLVED.** The two counts measure genuinely different, both-correct scopes (Dispatch = non-terminal trips only; Today's Operations = every trip scheduled today) — the operational logic was correct and was deliberately left unchanged. The label was the actual problem: both screens said "trips today" for two different numbers. Dispatch's label is now **"open trips today"**; Today's Operations keeps **"trips today"** (its own scope is genuinely the full day). See `docs/product/dispatch-board-data-map.md` / `todays-operations-data-map.md` for the full side-by-side definition, and `src/lib/operations/dispatch-board.ts`/`todays-operations.ts` for the in-code definition comments. No salesperson explanation is required — the labels are now self-evident on their own.

### POLISH

3. Trip Detail and other detail routes carry the record's UUID in the URL bar (e.g. `/operations/trips/80000000-...`). Normal for a web application and not a security concern (RLS-enforced regardless of what a URL says), but worth being deliberate about: reach Trip Detail by clicking through the UI during a demo, never by typing or reading a raw UUID aloud.

### TRUTHFUL-LIMITATION (confirmed real, correctly not faked)

4. Driver Availability panel does not exist (GAP-6) — Dispatch board's Driver Capacity panel shows "On Trip" only, never a fabricated Available/Break/Unavailable status.
5. "Export Day Sheet" button is visibly present but honestly disabled (GAP-9) — not hidden, not a fake working control.
6. Passenger/Facility/Vehicle create-or-edit and Driver onboarding are not self-serve (GAP-12/13/14/15) — the demo script and `operator-value-map.md` both address this directly rather than avoiding the topic.
7. No live map, no ETA, no background location — the location-freshness signal is exactly what it claims to be, nothing more; verified directly (a seeded "fresh" location naturally ages to "needs update" purely from wall-clock time passing since reset, which is correct, expected behavior, not a defect — see finding in the live verification below).

---

## Demo data quality

Verified live (not assumed) across multiple consecutive fresh resets, signed in as Harmony accounts only:
- No QA-style name (`Org A`, `Org B`, `Fictional Passenger A1`, `example.test`, etc.) appeared on any screen in the primary demo path.
- No real PHI, no medical diagnosis data — passenger records carry only mobility/assistance notes (e.g. "uses a wheelchair, needs ramp access"), consistent with the RPCs' own minimum-necessary projections.
- No implied Vehicle capability beyond what the schema supports — vehicle records are plain label + status, nothing implying wheelchair-lift/capacity features the schema does not model.
- All summary counts (trip counts, active counts, attention counts) are derived from the real seeded rows via the existing production query paths (`getTodaysOperations()`, `getDispatchBoardData()`) — nothing is hard-coded for the demo.
- **P1-E3-S8C1:** every facility, pickup, and destination address is now entirely fictional (Ashcombe/Fernvale/Millbrook/Eastfield, GA) — no real Atlanta street, clinic, or business association remains anywhere in the Harmony organization's data. Verified live: Facilities screen and Trip Detail both render the synthetic towns correctly; no real-Atlanta street name (`Cascade Rd`, `Peachtree St`, `Johnson Ferry Rd`, etc.) appears anywhere in the buyer path.

## Simulated skeptical-prospect self-assessment

1. **"Is this actually a working product, or a mockup?"** Working — every action taken in the verification run (assign, start trip, share location, report/resolve an issue, complete a trip) produced a real, verified database state change, not a staged transition.
2. **"Does the data look like a real transportation company, or obviously fake test data?"** Real-looking — plausible names, professionally formatted addresses in an entirely fictional, internally consistent 4-town geography (Ashcombe/Fernvale/Millbrook/Eastfield, GA — P1-E3-S8C1, replacing the original phase's real Atlanta-area street names), professional facility names, phone numbers in a consistent format. No QA fixture artifacts leaked into the Harmony organization's own screens, and no real-world facility/street association remains.
3. **"What happens if I click something you didn't plan to show me?"** Reasonably safe — the 5 master-data screens (Passengers/Facilities/Drivers/Fleet), Trips list with search/filter, and Trip Detail for both active and completed trips were all separately verified, not just the scripted happy path.
4. **"Can I tell what's real versus aspirational?"** Yes, if the presenter follows `product-capability-matrix.md` and `sales-claims-boundary.md` — the product itself doesn't editorialize (no "Coming Soon" banners cluttering the UI), so this discipline lives in the script and the presenter, not the product chrome.
5. **"Would I trust this with my drivers' and patients' data?"** The honest answer available today is "here's exactly how isolation and access control work" (`security-overview.md`) — not a compliance certification, and the demo script is explicit about not overclaiming this.
6. **"Does the assignment/lifecycle flow feel like real operations software, or a toy?"** Feels real — the assignment dialog, lifecycle buttons, and issue-report/resolve dialogs all behave like a considered operations tool (loading states, disabled-while-submitting, confirmation feedback), not a demo-only shortcut.
7. **"If I ask a hard question about what's NOT built, will I get a straight answer?"** Yes, by design — `product-capability-matrix.md`'s PLANNED-NOT-AVAILABLE section and `operator-objections.md` exist specifically so the answer is prepared and honest rather than improvised defensively.
8. **"Does the 10-minute demo feel like a coherent story, or a feature tour?"** Coherent — verified structurally: every step in `zenward-demo-script.md`'s 10-minute version causally follows from the previous one (the exact trip assigned in Step 2 is the trip started/shared/completed in Steps 3-6), not a sequence of unrelated screen visits.

## Verdict

No BLOCKER or unaddressed HIGH-FRICTION finding exists in the current buyer path. Both MEDIUM-FRICTION findings from the original S8C audit are now RESOLVED (P1-E3-S8C1) rather than merely recorded — the account-menu identity fix and the "trips today"/"open trips today" label disambiguation. Demo facility/address geography is now fully fictional. See the bottom verdict blocks of `docs/reports/P1-E3-S8C-commercial-demo-sales-readiness-report.txt` and `docs/reports/P1-E3-S8C1-commercial-trust-closure-report.txt` for the full gate history.
