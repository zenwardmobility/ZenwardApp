/**
 * Pure positioning math for the "Today's Assignments" time-axis grid
 * (P1-E3-S5) — no JSX, independently testable. The grid's window is a
 * FIXED 6:00 AM – 8:00 PM org-local span, not dynamically computed from
 * real Trip times: `trips` has no duration/expected-dropoff field
 * (`scheduled_pickup_at`/`appointment_at` only — confirmed against
 * `database.types.ts`), so there is no real end-time to size a
 * proportional block against. Rendering every block at the same fixed
 * width, positioned only by its real start time, is the honest
 * simplification recorded in decision-register.md — not a fabricated
 * duration.
 */

export const GRID_START_HOUR = 6;
export const GRID_END_HOUR = 20;
export const GRID_HOUR_WIDTH_PX = 64;
export const GRID_BLOCK_WIDTH_PX = 144;
export const GRID_ROW_HEIGHT_PX = 68;

export const GRID_TOTAL_WIDTH_PX = (GRID_END_HOUR - GRID_START_HOUR) * GRID_HOUR_WIDTH_PX;

export function gridHourLabels(): { hour: number; label: string }[] {
  const labels: { hour: number; label: string }[] = [];
  for (let hour = GRID_START_HOUR; hour <= GRID_END_HOUR; hour++) {
    const period = hour < 12 ? "AM" : "PM";
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
    labels.push({ hour, label: `${displayHour}:00 ${period}` });
  }
  return labels;
}

/**
 * The horizontal pixel offset (left edge) for a Trip block, given its
 * `scheduled_pickup_at` decomposed into org-local hour/minute (callers
 * derive those via `Intl` against the organization timezone, this
 * function takes plain numbers so it stays timezone-agnostic and
 * trivially testable). Clamped to the visible window — a Trip scheduled
 * before 6 AM or after 8 PM still renders, pinned to the nearest edge,
 * rather than disappearing or breaking layout.
 */
export function gridBlockLeftPx(hour: number, minute: number): number {
  const decimalHour = hour + minute / 60;
  const clamped = Math.min(Math.max(decimalHour, GRID_START_HOUR), GRID_END_HOUR);
  return (clamped - GRID_START_HOUR) * GRID_HOUR_WIDTH_PX;
}

/** Org-local 24h hour/minute for an ISO instant — the one place the grid reads a timestamp apart from its own timezone, so positioning never depends on the runtime's own local time. */
export function orgLocalHourMinute(iso: string, timezone: string): { hour: number; minute: number } {
  const date = new Date(iso);
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    hourCycle: "h23",
    hour: "2-digit",
    minute: "2-digit",
  }).formatToParts(date);
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((p) => p.type === "minute")?.value ?? "0");
  return { hour, minute };
}
