# Zenward — Demo Script

**Audience:** a prospective NEMT operator (owner, dispatch manager, or ops lead) seeing Zenward for the first time.
**Prerequisites:** read `demo-navigation-map.md` first — two browser sessions (dispatcher + one driver), fresh `supabase db reset`, signed in as `dispatch@harmonytransport.test`.
**Golden rule:** every "WHAT TO SAY" line is grounded in something real on screen. Every "WHAT NOT TO CLAIM" line exists because the honest version of that sentence is easy to oversell in the moment. When in doubt, say less — `sales-claims-boundary.md` is the tie-breaker.

The narrative in one sentence: **a dispatcher always knows what needs attention, assigns it to a real person, watches it move, handles the problem that comes up, and keeps a record of the whole thing — without touching a spreadsheet or a phone tree.**

---

## 5-minute version — "the pitch in one screen"

Use when: a hallway conversation, a trade-show booth, the first 5 minutes before someone asks for more.

### Step 1 — Today's Operations
**WHAT TO CLICK:** Nothing yet — you're already signed in and land here.
**WHAT BUYER SEES:** Harmony Medical Transport's real day: "12 trips today," a "Needs Attention" table with 4 real rows (an open issue, an unassigned trip, two location-freshness flags), an "Active Trips" panel showing 3 trips genuinely in progress right now.
**WHAT TO SAY:** "This is what a dispatcher sees the moment they log in — not a report they have to go generate, the actual state of today's transportation, right now."
**WHY IT MATTERS:** This answers the first and most basic operator question: do I know what's going on right now without calling three drivers?
**WHAT NOT TO CLAIM:** Don't call this "AI-powered" or "predictive" — every row here is a direct, literal database fact (a trip is unassigned, a location ping is 12 minutes old), never a model's guess.

### Step 2 — Assign the unassigned trip
**WHAT TO CLICK:** In the Needs Attention table, click **Assign** on Willie Thompson's row → in the dialog, pick a driver and vehicle → **Assign Driver**.
**WHAT BUYER SEES:** The row disappears from Needs Attention; the trip now shows a real driver and vehicle.
**WHAT TO SAY:** "One click, and that trip has a name and a vehicle attached to it — not a note on a whiteboard."
**WHY IT MATTERS:** Assignment is the core dispatcher action, and it's fast.
**WHAT NOT TO CLAIM:** Don't claim the system "recommends" a driver — the dispatcher chooses; nothing here is automated matching.

### Step 3 — Close the loop
**WHAT TO CLICK:** Open that same trip's Trip Detail (click the trip anywhere in the app).
**WHAT BUYER SEES:** A single page with pickup/destination, current status, driver, vehicle, and (if any exist) exceptions — one place, not five systems.
**WHAT TO SAY:** "Everything about this ride lives on one page, and it's the same page whether the trip is still scheduled or already complete."
**WHY IT MATTERS:** No operator wants to reconstruct a trip's story from three different tools after the fact.
**WHAT NOT TO CLAIM:** Don't claim billing or invoicing lives here — Trip Detail is operational record only.

*(Stop here for a 5-minute conversation. If there's more time, continue into the 10-minute version below — Steps 1–3 above are literally the first 3 steps of it.)*

---

## 10-minute version — the primary demo (default choice)

This is the full narrative: **know → assign → watch → handle a problem → confirm it's done and recorded.** It has been run end-to-end as real clicks against a real local database (not simulated) — every step below produces an actual state change you can verify by refreshing the page.

Setup: dispatcher session open to `/operations`. Driver session (any browser/device, signed in as one of the three Harmony drivers) ready but not yet shown.

### 1. Today's Operations — know what needs attention *(dispatcher, ~90 sec)*
**WHAT TO CLICK:** Nothing — this is the landing screen.
**WHAT BUYER SEES:** Real counts ("12 trips today," "3 active," "4 need attention"), a Needs Attention table (an open issue on one trip, an unassigned trip, two trips whose driver-location signal has aged), and an Active Trips list of trips genuinely en route right now.
**WHAT TO SAY:** "Before anything else, a dispatcher needs one honest answer to 'what do I need to deal with right now' — that's this table. Nothing here is summarized or rounded; it's the literal set of trips that need a human decision."
**WHY IT MATTERS:** This is the operator's single biggest daily pain point — knowing what's wrong before a patient or a facility calls to tell them.
**WHAT NOT TO CLAIM:** Don't say "we monitor this 24/7 with alerts" — there is no push notification or paging system yet; this is a screen a dispatcher looks at, not an alerting product.

*(P1-E3-S8C1: if a buyer flips to Dispatch and notices its own "open trips today" count is lower than this screen's "trips today," that's not a bug — Dispatch's count deliberately excludes trips already completed, since it's a board about what still needs action; Today's Operations counts the full day. The two labels are worded differently on purpose so this never needs an explanation mid-demo.)*

### 2. Assign responsibility *(dispatcher, ~60 sec)*
**WHAT TO CLICK:** Needs Attention → **Assign** on the unassigned trip → choose a driver and vehicle in the dialog → **Assign Driver**. (Or: open **Dispatch** in the left nav first, to show the fuller board — the same unassigned trip appears there too, alongside every driver's schedule for the day.)
**WHAT BUYER SEES:** The trip leaves the unassigned queue; the Dispatch board's driver-capacity panel shows that driver now "On Trip"; the trip's row updates immediately, no page reload needed to see it reflected.
**WHAT TO SAY:** "Assigning a trip is one dialog — pick the driver, pick the vehicle, done. And it's safe: if two dispatchers tried to assign the same trip at the same moment, the system would only let one succeed, not silently overwrite the other."
**WHY IT MATTERS:** Fast, unambiguous assignment with no double-booking risk is the second core operator need after visibility.
**WHAT NOT TO CLAIM:** Don't claim automatic/suggested assignment — a human always makes this choice.

### 3. See transportation progressing *(switch to the driver session, ~2 min)*
**WHAT TO CLICK:** On the driver's device/session: **Trips** → tap the newly-assigned trip → **Start to Pickup**.
**WHAT BUYER SEES:** The trip status changes to "Heading to Pickup" in real time — you can flip back to the dispatcher screen and refresh to show the same trip now marked active there too.
**WHAT TO SAY:** "This is the exact screen a driver uses — no separate app to install, it's a phone browser. Every step of the trip — heading to pickup, arrived, passenger onboard, heading to destination, arrived, complete — is a deliberate tap, and every tap is recorded server-side. A driver can't skip a step or fake one."
**WHY IT MATTERS:** Operators need to trust that "en route" means someone actually tapped "en route," not that a phone app assumed it.
**WHAT NOT TO CLAIM:** Don't claim this requires no driver training — it's simple, but it is a new habit for a driver used to a paper manifest or a phone call.

**Now tap "Share My Location"** on the driver screen (grant location permission if prompted).
**WHAT BUYER SEES:** A "Location sharing on" indicator appears on the driver's screen.
**WHAT TO SAY:** "The driver chooses to share location for this trip — it's never silent or automatic."
**WHAT NOT TO CLAIM:** This is **not** a live map and does not track the driver anywhere except during this specific trip. Never call it "GPS tracking" or imply background/always-on location — say "a location freshness signal," not "live tracking."

### 4. Dispatch sees freshness *(back to dispatcher, ~30 sec)*
**WHAT TO CLICK:** Refresh the Dispatch board.
**WHAT BUYER SEES:** That trip's freshness indicator updates to reflect the just-received location ping.
**WHAT TO SAY:** "Dispatch now has a live signal that this trip is actually moving — not a guess, an actual reading from the driver's device, and it visibly ages if it stops updating."
**WHY IT MATTERS:** This is the "trust but verify" layer operators consistently ask for — is the driver actually en route.
**WHAT NOT TO CLAIM:** Don't claim precision beyond what's shown — no ETA, no map pin, no route.

### 5. Handle a problem *(driver session, then dispatcher, ~2 min)*
**WHAT TO CLICK (driver):** On the active trip screen, tap **Report Issue** → choose an issue type → describe it → **Report Issue**.
**WHAT BUYER SEES (driver):** Confirmation the issue was reported.
**WHAT TO CLICK (dispatcher):** Refresh Today's Operations or the trip's own Trip Detail page — the new issue appears in Needs Attention / the Trip Exceptions panel. Click into the trip, then **Resolve** on the exception, add a short resolution note, submit.
**WHAT TO SAY:** "Problems happen on real transportation — a locked gate, a delay, a detour. The point isn't to prevent that; it's that dispatch finds out immediately instead of after the fact, and closing it out takes seconds, not a phone call chain."
**WHY IT MATTERS:** This is Trip Assurance — the product's answer to "how do I know when something's gone wrong before it becomes a bigger problem."
**WHAT NOT TO CLAIM:** Don't call this "incident management" or imply escalation/paging — it's a shared, visible issue-and-resolution record, not an alerting system.

### 6. Preserve accountability *(dispatcher, ~30 sec)*
**WHAT TO CLICK (driver, finish the trip):** Continue tapping through the remaining lifecycle steps to **Complete Trip**. **WHAT TO CLICK (dispatcher):** Open that trip's Trip Detail (or its entry under Today's Operations, now moved to completed).
**WHAT BUYER SEES:** A full, timestamped activity trail for the trip — assigned, en route, the issue flagged, the issue resolved, arrived, completed — in order, with real times.
**WHAT TO SAY:** "This is the record you'd want if a family member or a facility ever asked 'what actually happened with this ride.' It's not reconstructed after the fact — it's exactly what happened, in order, because every step was a real action in the system."
**WHY IT MATTERS:** Accountability and auditability are what separates a real operations system from a group chat.
**WHAT NOT TO CLAIM:** Don't call this a compliance/audit certification of any kind — it is an accurate operational record, not a regulatory attestation. See `sales-claims-boundary.md`.

---

## 15-minute version — adds the operational backbone

Everything in the 10-minute version, plus a tour of the master-data screens that make the above possible day to day. Insert this block between Steps 2 and 3 above, or run it at the end if the buyer asks "what else is in here."

### Passengers, Facilities, Drivers, Fleet *(dispatcher, ~4 min)*
**WHAT TO CLICK:** Each item in the left nav in turn — Passengers, Facilities, Drivers, Fleet.
**WHAT BUYER SEES:** Real lists — passengers with assistance notes ("uses a wheelchair, needs ramp access"), referring facilities with full addresses, the driver roster, the vehicle fleet — each grounded in the same data every other screen already used.
**WHAT TO SAY:** "Everything you saw on Today's Operations and Dispatch comes from records that live here — passengers, the facilities that refer them, your drivers, your vehicles. Nothing is a spreadsheet living outside the system."
**WHY IT MATTERS:** Operators want to know their whole roster lives in one place, not that Zenward is only a dispatch board bolted onto their existing spreadsheets.
**WHAT NOT TO CLAIM:** Be direct that **adding** a new facility, vehicle, or driver account is not yet self-serve in this build — see `product-capability-matrix.md`. Say: "Today, standing up a new facility, vehicle, or driver account happens with our team during onboarding; self-serve creation for these is on our near-term roadmap." Never imply it's already a button in the product.

**WHAT TO CLICK:** From Trips, open a completed trip (e.g. one of the morning's already-finished dialysis runs).
**WHAT BUYER SEES:** The same one-page Trip Detail as an active trip, just in its finished state.
**WHAT TO SAY:** "A completed trip isn't archived somewhere else — it's the same record, same page, same level of detail."

---

## After the demo — anticipated first questions

Keep `operator-objections.md` and `operator-discovery-questions.md` open in a second tab. Do not improvise an answer to a compliance or pricing question live — see `sales-claims-boundary.md` and `founding-operator-program.md` respectively.
