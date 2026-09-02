/**
 * The one centralized Trip Assurance evaluator (P1-E3-S8, work item §10).
 * Every surface (Today's Operations, Dispatch, Trip Detail) derives its
 * assurance answer from this SAME pure function — none re-implements its
 * own version of "what needs attention" (work item §10/§12).
 *
 * Assurance is a DERIVED operational layer, never a new Trip lifecycle
 * state (work item §3) — nothing here is persisted, nothing here is
 * written back to `trips.state`. It answers one narrow question:
 * "does this Trip currently need a human's attention, and why?" — from
 * already-authoritative facts (Trip state, active-assignment presence,
 * assignment-scoped location freshness, open-exception count), never
 * from a fabricated score or an unapproved lateness threshold (work item
 * §5/§9).
 *
 * Pure function: `facts, now → condition` (work item §12/§38) — no DB
 * access, no `new Date()` inside. Every caller supplies its own already-
 * resolved `now` once, so a single query result set (e.g. Today's
 * Operations' own trip list) evaluates every Trip against the exact same
 * instant, never a slightly-different clock read per Trip.
 */

import { classifyLocationFreshness } from "./location-freshness";

export type TripAssuranceCode =
  | "TERMINAL"
  | "OPEN_EXCEPTION"
  | "NEEDS_ASSIGNMENT"
  | "LOCATION_STALE"
  | "LOCATION_UNAVAILABLE"
  | "ON_TRACK";

export interface TripAssuranceFacts {
  /** The canonical Trip lifecycle state — never re-derived, always the real `trips.state`. */
  state: string;
  /** Whether a `trip_assignments` row with `ended_at IS NULL` currently exists for this Trip — the sole assignment source of truth (ZD-051), never inferred from Driver availability (work item §13). */
  hasActiveAssignment: boolean;
  /** Whether `state` is one of the 5 states location tracking is ever eligible in (`ELIGIBLE_LOCATION_TRACKING_STATES`, P1-E3-S7A) — passed in explicitly rather than re-checked here, so this module never needs to duplicate that set. */
  isEligibleTrackingState: boolean;
  /** The CURRENT active assignment's own latest recorded location timestamp — already assignment-scoped by the caller (P1-E3-S7A's own established merge discipline: a former Driver's location must never reach this field after reassignment, work item §15). Null when no location has ever been recorded under the current assignment. */
  latestLocationRecordedAt: string | null;
  /** Count of real, currently OPEN `trip_exceptions` rows — never derived from lateness/GPS/missing-note heuristics (work item §16). */
  openExceptionCount: number;
}

export interface TripAssuranceResult {
  code: TripAssuranceCode;
  /** Short, calm, Operations-facing label — never an internal code, never alarmist (work item §61). */
  label: string;
  /** One sentence explaining WHY, in plain language — the explainability contract (work item §8). */
  explanation: string;
  /** Which facts actually drove this result — for debugging/testing, not necessarily rendered verbatim in the UI (work item §8's "source facts"). */
  sourceFacts: string[];
}

const TERMINAL_STATES = new Set(["completed", "cancelled", "no_show"]);

const TERMINAL_LABEL: Record<string, string> = {
  completed: "Completed",
  cancelled: "Cancelled",
  no_show: "No-show recorded",
};

/**
 * The single deterministic priority ordering (work item §7): a Trip may
 * satisfy multiple conditions at once (e.g. unassigned AND — impossible,
 * see below — but genuinely possible: stale location AND an open
 * exception). Exactly ONE condition is ever returned, never a random or
 * insertion-order pick.
 *
 *   1. TERMINAL         — overrides everything; a finished Trip is not an
 *                          active operational risk (work item §17).
 *   2. OPEN_EXCEPTION    — a human/system already explicitly flagged a
 *                          real problem; this is always the most
 *                          important thing to show, ahead of a merely
 *                          derived condition.
 *   3. NEEDS_ASSIGNMENT  — a Trip that cannot even begin is more urgent
 *                          than one already underway with a location
 *                          concern.
 *   4. LOCATION_STALE / LOCATION_UNAVAILABLE — only ever evaluated once
 *                          the Trip actually has an active assignment AND
 *                          is inside the eligible tracking window
 *                          (work item §14).
 *   5. ON_TRACK          — no current issue found (work item §18 — this
 *                          means exactly that, never a delivery
 *                          guarantee).
 */
export function evaluateTripAssurance(facts: TripAssuranceFacts, now: Date): TripAssuranceResult {
  if (TERMINAL_STATES.has(facts.state)) {
    return {
      code: "TERMINAL",
      label: TERMINAL_LABEL[facts.state] ?? "Completed",
      explanation: "This trip has already reached a final outcome.",
      sourceFacts: [`state=${facts.state}`],
    };
  }

  if (facts.openExceptionCount > 0) {
    return {
      code: "OPEN_EXCEPTION",
      label: "Open issue",
      explanation:
        facts.openExceptionCount === 1
          ? "A reported issue on this trip has not been resolved yet."
          : `${facts.openExceptionCount} reported issues on this trip have not been resolved yet.`,
      sourceFacts: [`openExceptionCount=${facts.openExceptionCount}`],
    };
  }

  if (facts.state === "scheduled" && !facts.hasActiveAssignment) {
    return {
      code: "NEEDS_ASSIGNMENT",
      label: "Needs assignment",
      explanation: "This trip is scheduled but has no driver assigned yet.",
      sourceFacts: [`state=${facts.state}`, "hasActiveAssignment=false"],
    };
  }

  if (facts.isEligibleTrackingState && facts.hasActiveAssignment) {
    if (!facts.latestLocationRecordedAt) {
      return {
        code: "LOCATION_UNAVAILABLE",
        label: "Location unavailable",
        explanation: "The assigned driver has not shared a location for this trip yet.",
        sourceFacts: [`state=${facts.state}`, "hasActiveAssignment=true", "latestLocationRecordedAt=null"],
      };
    }
    // Reuses the SAME central threshold Dispatch's own freshness
    // indicator already uses (work item §14/§39) — never a second,
    // independently-drifting notion of "stale."
    if (classifyLocationFreshness(facts.latestLocationRecordedAt, now) === "stale") {
      return {
        code: "LOCATION_STALE",
        label: "Location needs update",
        explanation: "The driver's location hasn't updated recently.",
        sourceFacts: [
          `state=${facts.state}`,
          "hasActiveAssignment=true",
          `latestLocationRecordedAt=${facts.latestLocationRecordedAt}`,
        ],
      };
    }
  }

  return {
    code: "ON_TRACK",
    label: "No current issues",
    explanation: "No attention condition is currently detected for this trip.",
    sourceFacts: [`state=${facts.state}`],
  };
}

/** Whether a Trip's assurance code belongs in an ACTIVE attention queue (work item §17/§29) — TERMINAL and ON_TRACK are both excluded; every other code represents something a Dispatcher may want to act on. */
export function needsAttention(code: TripAssuranceCode): boolean {
  return code !== "TERMINAL" && code !== "ON_TRACK";
}
