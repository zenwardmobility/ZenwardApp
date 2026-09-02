# Trip Assurance Model

**Phase:** P1-E3-S8 — Trip Assurance & Operational Exceptions
**Status:** Implemented and verified — see `docs/reports/P1-E3-S8-trip-assurance-operational-exceptions-report.txt`.

This document is the canonical definition of "Trip Assurance" as
implemented — the foundation of the commercial concept ZENWARD TRIP
ASSURANCE (§10 below), but this document describes only what actually
exists in code today.

---

## 1. Purpose

Trip Assurance is a **deterministic operational assurance model** that
helps a Dispatcher identify which Trips genuinely need human
intervention, right now, from real operational data — never a
predictive/AI system, never a fabricated risk score. It answers exactly
one question, for exactly one Trip, at exactly one instant: *"does this
Trip currently need attention, and why?"*

## 2. Non-goals (work item §0/§5/§9/§18)

- **Not a new Trip lifecycle.** No `at_risk`/`running_late`/
  `needs_attention`/`on_track`/`awaiting_confirmation` state exists on
  `trips.state`. The canonical 9 states are completely unchanged.
- **Not predictive.** No AI, no machine learning, no forecasted outcome.
  Every condition is derived from data that already, authoritatively
  exists right now (Trip state, assignment presence, a real recorded
  location timestamp, a real open exception row) — never a probability
  or an inference about the future.
- **Not a numeric score.** No "Trip Assurance Score: 84/100," no
  "Reliability: 92%." A categorical condition + a plain-language
  explanation, nothing else.
- **Not a lateness detector.** No approved Running Late threshold exists
  in this product. This phase does NOT compare `scheduled_pickup_at`/
  `appointment_at` against the current clock to derive any condition —
  that remains a genuinely separate, not-yet-approved product decision
  (still recorded as open in `ui-backend-gap-register.md`).
- **Not an audit/compliance system** (though it happens to reuse
  `TripEvent` for genuine operational history — see §10).
- **Not built for Facility/Passenger-facing surfaces yet** — see §9.

## 3. Condition vocabulary

Exactly 6 codes, in this exact deterministic priority order (highest
first):

| Code | Priority | User-facing label | Meaning |
|---|---|---|---|
| `TERMINAL` | 1 (overrides all) | "Completed" / "Cancelled" / "No-show recorded" | The Trip has already reached a final outcome — no longer an active operational risk. |
| `OPEN_EXCEPTION` | 2 | "Open issue" | One or more real `trip_exceptions` rows with `status='open'` exist for this Trip. |
| `NEEDS_ASSIGNMENT` | 3 | "Needs assignment" | `state='scheduled'` AND no active `TripAssignment` exists. |
| `LOCATION_STALE` | 4 | "Location needs update" | The Trip is in the eligible tracking window, has an active assignment, and the CURRENT assignment's latest recorded location is older than the central "stale" threshold (>5 minutes, `location-freshness.ts`). |
| `LOCATION_UNAVAILABLE` | 4 (same tier as STALE) | "Location unavailable" | Same eligibility, but no location has EVER been recorded under the current assignment. |
| `ON_TRACK` | — (not an attention condition) | "No current issues" | None of the above apply. |

`LOCATION_UNAVAILABLE` is kept distinct from `LOCATION_STALE` (work item
§6) because they mean genuinely different things operationally: "never
posted" (permission not granted, tracker not started, or a very recent
assignment with no reading yet) versus "posted, but that reading is now
old" (a real staleness concern, e.g. the Driver's app lost connectivity).

## 4. Condition priority (work item §7)

A Trip may satisfy multiple conditions simultaneously (e.g. an open
exception AND a stale location on the same in-progress Trip). Exactly
ONE condition is ever returned by the evaluator — the highest-priority
one — never a random or database-row-order pick, and never all
simultaneously-true conditions stacked into a list on the primary
surface. The ordering itself (§3's own priority column) reflects real
product meaning, not an arbitrary array order:

1. **TERMINAL first** — a finished Trip is not an active risk regardless
   of what else might technically still be true about its stale data.
2. **OPEN_EXCEPTION next** — a human or Driver already explicitly
   flagged a real problem; this is always more actionable than a merely
   derived signal.
3. **NEEDS_ASSIGNMENT** — a Trip that cannot even begin is more urgent
   than one already underway with a location concern.
4. **LOCATION_STALE / LOCATION_UNAVAILABLE** — only evaluated once the
   Trip genuinely has an active assignment AND is inside the eligible
   tracking window.
5. **ON_TRACK** — the conservative default (§7 below).

Secondary conditions are not hidden — Trip Detail shows the real,
complete exception list and the real assignment/location data directly,
so a Dispatcher who opens the Trip sees everything, not just the primary
reason (work item §29's own "optionally indicate secondary conditions in
Trip Detail").

## 5. Exact derivation rules

Implemented in `src/lib/operations/trip-assurance.ts`,
`evaluateTripAssurance(facts, now)`:

```
if TERMINAL_STATES.has(state) → TERMINAL
else if openExceptionCount > 0 → OPEN_EXCEPTION
else if state === 'scheduled' && !hasActiveAssignment → NEEDS_ASSIGNMENT
else if isEligibleTrackingState && hasActiveAssignment:
    if latestLocationRecordedAt is null → LOCATION_UNAVAILABLE
    else if classifyLocationFreshness(latestLocationRecordedAt, now) === 'stale' → LOCATION_STALE
else → ON_TRACK
```

`isEligibleTrackingState` reuses the exact 5-state set P1-E3-S7A already
established (`ELIGIBLE_LOCATION_TRACKING_STATES` /
`ACTIVE_STATES`) — never re-derived independently. `classifyLocationFreshness`
reuses the exact central threshold `location-freshness.ts` already
established for Dispatch's own freshness indicator — never a second,
independently-drifting notion of "stale."

## 6. Explainability

Every `TripAssuranceResult` carries:
- `code` — the machine-stable category.
- `label` — a short, calm, Operations-facing phrase (never the raw code
  — work item §61: "Do not expose internal codes... directly as ugly
  enum text").
- `explanation` — one plain-language sentence saying WHY.
- `sourceFacts` — the specific input facts that produced this result
  (e.g. `["state=scheduled", "hasActiveAssignment=false"]`), for
  debugging/testing — not necessarily rendered verbatim in the UI, but
  never opaque even to a developer inspecting the result.

No condition is ever returned without all four fields populated — there
is no "black box" code path.

## 7. What "ON_TRACK" means (work item §18)

Deliberately conservative: `ON_TRACK` means *no currently-derived
attention condition was found* — nothing more. It is NOT a delivery
guarantee, NOT a promise of on-time arrival, and NOT a claim that
nothing could possibly go wrong. The user-facing label is "No current
issues" rather than a more confident-sounding word, precisely to avoid
overclaiming (work item §18's own explicit caution).

## 8. Terminal behavior

Once a Trip reaches `completed`/`cancelled`/`no_show`, it is excluded
from the active attention queue entirely (`needsAttention(code)` returns
`false` for `TERMINAL`) — it never appears in Today's Operations' Needs
Attention panel or the Dispatch Board's assurance treatment, regardless
of what its location/exception data looked like right before it
finished. No separate unresolved post-trip workflow is built this phase
(work item §17 explicitly scopes this as a future, separately-designed
concept if ever needed).

## 9. Assignment/location behavior

- **Needs Assignment** is derived ONLY from `trips.state='scheduled'` +
  the real absence of an active `trip_assignments` row — never from
  Driver availability (no such concept exists, GAP-6) and never
  persisted as a stored status anywhere.
- **Location condition** is evaluated ONLY when the Trip is inside the
  eligible tracking window AND has an active assignment. It is always
  **assignment-scoped** — the evaluator receives `latestLocationRecordedAt`
  already filtered by the caller to only ever reflect the CURRENT active
  assignment's own location history (reusing P1-E3-S7A's exact merge
  discipline: `location.assignmentId === trip.activeAssignmentId`). A
  former Driver's fresh location can never make a Trip appear healthy
  after reassignment, and a brand-new assignment with no location posted
  yet correctly reads `LOCATION_UNAVAILABLE`, never a stale/borrowed
  reading from the prior Driver.

## 10. Exception interaction

A real, currently `open` `trip_exceptions` row is the ONLY thing that
can produce `OPEN_EXCEPTION` — never derived from lateness math, GPS
distance, a missing call, or a missing note (work item §16). Exceptions
are created/resolved through the new controlled `report_trip_exception`/
`resolve_trip_exception` RPCs (see `trip-assurance-data-map.md` for the
full mutation contract) — never a direct table write, and never
silently rewritten (a resolved exception's history is preserved forever,
never deleted, never reopened by accident).

`trip_events`' own allow-listed vocabulary already included
`exception_flagged`/`exception_resolved` since the very first schema
migration (unused until this phase) — both RPCs now write these real,
structured events. Reporting/resolving an exception does NOT write an
`AuditEvent` — it does not materially change who is responsible for the
Trip or reach a terminal disposition of the Trip itself (the same test
`ZD-087` already established for what warrants an AuditEvent), matching
the identical precedent already set for `trip_notes`.

## 11. Future expansion (explicitly not built, left open)

- A native embedded map (currently an external OpenStreetMap link only,
  ZD-166).
- A formally-approved Running Late threshold, once a real business rule
  exists (§2's own explicit non-goal).
- Realtime-driven instant assurance updates (currently 20s restrained
  polling, matching P1-E3-S7A's own deferral).
- A sanitized Facility/Passenger-facing status view built on this same
  underlying evaluator (architecture intentionally keeps Operations-only
  wording OUT of persistence — see §12).
- A "why" UI surfacing `sourceFacts` directly to a Dispatcher (currently
  only used internally/for tests).

## 12. What is NOT yet considered "risk"

Explicitly and deliberately NOT modeled as an assurance condition this
phase: passenger no-show risk prediction, driver performance history,
traffic/weather conditions, vehicle maintenance status, appointment-time
proximity (lateness), any condition requiring a threshold this product
has not formally approved. Building any of these without an approved
product rule would be exactly the kind of fabricated predictive
intelligence work item §0 explicitly forbids.

---

## 13. Commercial interpretation (non-marketing, work item §70)

This section documents how the underlying evaluator MAY eventually
support future commercial surfaces — it does not claim any of the
following is built, measured, or ready:

- **Facility visibility:** a sanitized, facility-facing view of a Trip's
  assurance condition (e.g. "on track" / "needs attention," without
  internal Operations codes or Driver-identifying detail) could
  plausibly be built on top of `evaluateTripAssurance()`'s own output —
  the evaluator's `code`/`label` are already free of internal jargon by
  design (work item §61), a deliberate choice that keeps this door open
  without building the surface itself.
- **Service reliability reporting:** an aggregate, org-level rollup of
  assurance-condition history over time (e.g. "% of Trips with zero
  attention conditions") is architecturally possible from the same
  underlying facts (`trip_events`' `exception_flagged`/`exception_resolved`,
  `trip_exceptions` history) but is NOT computed, stored, or reported
  anywhere in this codebase today.
- **Operator SLA measurement:** would require an actually-approved SLA
  definition (response time to an open exception, time-to-assignment,
  etc.) — none exists yet; this document explicitly declines to invent
  one.
- **Recurring-care coordination:** a pattern of repeated assurance
  conditions across a Passenger's recurring Trips could inform future
  scheduling/reliability tooling — not analyzed, not built.

No metric this product cannot currently measure is claimed anywhere in
this codebase or its documentation.
