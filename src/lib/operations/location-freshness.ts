/**
 * Central location-freshness thresholds (P1-E3-S7A, work item §28/§29) —
 * the ONE place "how old is too old" is decided, so every surface that
 * shows a Driver's location (Dispatch now, Trip Detail potentially later)
 * agrees. Never fabricates "Live" for an old timestamp (work item §29) —
 * every label is derived from a real `recorded_at` compared against `now`.
 */

export type LocationFreshness = "live" | "recent" | "stale" | "none";

/** ≤ this many seconds old reads as "Live". */
const LIVE_THRESHOLD_MS = 45 * 1000;
/** ≤ this many seconds old reads as a specific "Updated Xm ago" — older than this reads as "stale" (still shown, but flagged as no longer trustworthy as a current position). */
const STALE_THRESHOLD_MS = 5 * 60 * 1000;

export function classifyLocationFreshness(recordedAt: string | null, now: Date): LocationFreshness {
  if (!recordedAt) return "none";
  const recorded = new Date(recordedAt);
  if (Number.isNaN(recorded.getTime())) return "none";
  const ageMs = now.getTime() - recorded.getTime();
  if (ageMs < 0) return "recent"; // clock skew guard — never claim "live" for a future timestamp, but don't error either
  if (ageMs <= LIVE_THRESHOLD_MS) return "live";
  if (ageMs <= STALE_THRESHOLD_MS) return "recent";
  return "stale";
}

/** "Updated just now" / "Updated 2 min ago" / "Location stale" / "No recent location" — matches work item §28's own suggested vocabulary exactly. The full-length wording — used as a tooltip/title text wherever space allows. */
export function formatLocationFreshnessLabel(recordedAt: string | null, now: Date): string {
  const freshness = classifyLocationFreshness(recordedAt, now);
  if (freshness === "none") return "No recent location";
  if (freshness === "stale") return "Location stale";
  const ageMs = now.getTime() - new Date(recordedAt as string).getTime();
  const ageMinutes = Math.round(ageMs / 60000);
  if (ageMinutes < 1) return "Updated just now";
  return `Updated ${ageMinutes} min ago`;
}

/** "Just now" / "2 min ago" / "Stale" / "No location" — same real thresholds as `formatLocationFreshnessLabel`, shortened for the Dispatch grid's own narrow row-label column (140px), which already holds the Driver's name and vehicle above it. The full label remains available as this same element's `title` tooltip. */
export function formatLocationFreshnessLabelCompact(recordedAt: string | null, now: Date): string {
  const freshness = classifyLocationFreshness(recordedAt, now);
  if (freshness === "none") return "No location";
  if (freshness === "stale") return "Stale";
  const ageMs = now.getTime() - new Date(recordedAt as string).getTime();
  const ageMinutes = Math.round(ageMs / 60000);
  if (ageMinutes < 1) return "Just now";
  return `${ageMinutes} min ago`;
}
