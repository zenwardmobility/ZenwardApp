"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

/** Restrained polling cadence (work item §20/§32) — matches the Driver-side submission throttle (20s) closely enough that a fresh location rarely waits more than one interval to appear, without hammering the server. */
const REFRESH_INTERVAL_MS = 20_000;

/**
 * Realtime was explicitly evaluated and deliberately DEFERRED this phase
 * (P1-E3-S7A, work item §30-§32, ZD-1xx) — this local Supabase CLI
 * version's `postgres_changes` RLS behavior could not be proven tenant-
 * safe with real adversarial tests in the time this phase allows, and
 * "security beats animation" is explicit. This component is the
 * documented fallback: a restrained `router.refresh()` interval, reusing
 * the EXACT same re-fetch mechanism every mutation on this board already
 * triggers on success (`AssignmentDialog`) — no new data-fetching path,
 * no new security surface. Renders nothing — it deliberately does NOT
 * paint a permanently-glowing "LIVE" badge (work item §29): polling being
 * active is not proof that any location data is actually fresh: the real
 * freshness indicator lives per-row in `AssignmentGrid`, driven by real
 * `recorded_at` timestamps, not by this component's own activity.
 */
export function DispatchLiveRefresh() {
  const router = useRouter();

  useEffect(() => {
    const interval = setInterval(() => {
      router.refresh();
    }, REFRESH_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [router]);

  return null;
}
