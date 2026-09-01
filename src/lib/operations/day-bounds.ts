import "server-only";

/**
 * Organization-local "today" boundary, expressed as UTC instants — the
 * Operations-console counterpart to src/lib/driver/trip-presentation.ts's
 * per-instant `operationalDateKey`/`isSameOperationalDay` helpers. Driver
 * Today never needed a range query (it filters an already-small RPC result
 * set client-side, one instant at a time); Today's Operations does — it
 * queries `trips`/`trip_events` directly with an explicit `gte`/`lt` bound,
 * so it needs the actual UTC start/end instants of "today, in the
 * organization's own timezone" to hand to PostgREST, not just a same-day
 * boolean check (P1-E3-S4).
 *
 * Never the runtime's local timezone, never a hardcoded Georgia timezone —
 * same rule as P1-E3-S2C/ZD-11x, extended to a bounded range instead of a
 * single-instant comparison.
 */

/**
 * The IANA timezone's current UTC offset, in milliseconds, AT the given
 * instant — positive for zones ahead of UTC (e.g. does not apply to any US
 * zone), negative for zones behind (e.g. America/New_York in EDT is
 * -4 hours). Computed by reading the wall-clock time `timezone` shows at
 * `date` (via Intl, which already resolves the correct DST-aware offset
 * for that specific instant) and comparing it against `date` itself — the
 * standard, library-free technique for this; there is no direct
 * `Intl`/`Date` API that returns an offset number.
 */
function timezoneOffsetMs(date: Date, timezone: string): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  })
    .formatToParts(date)
    .reduce<Record<string, string>>((acc, part) => {
      acc[part.type] = part.value;
      return acc;
    }, {});

  const asUtc = Date.UTC(
    Number(parts.year),
    Number(parts.month) - 1,
    Number(parts.day),
    Number(parts.hour),
    Number(parts.minute),
    Number(parts.second),
  );
  return asUtc - date.getTime();
}

/**
 * [startUtc, endUtc) — the UTC instants of midnight-to-midnight "today", in
 * `timezone`, relative to `now`. `endUtc` is exclusive (the following
 * midnight), so callers filter with `gte(startUtc)` + `lt(endUtc)`. Offset
 * is computed once from `now` and applied to both boundaries — correct for
 * the ordinary case; a query issued in the exact minutes of a DST
 * transition could see the offset shift within the same org-day, an
 * accepted edge case at this precision (same tolerance already accepted by
 * `operationalDayLabel`'s tomorrow-probe in trip-presentation.ts).
 */
export function organizationDayBoundsUtc(now: Date, timezone: string): { startUtc: Date; endUtc: Date } {
  const dateKey = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const [year, month, day] = dateKey.split("-").map(Number);
  const offsetMs = timezoneOffsetMs(now, timezone);
  const startUtc = new Date(Date.UTC(year, month - 1, day, 0, 0, 0) - offsetMs);
  const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);
  return { startUtc, endUtc };
}
