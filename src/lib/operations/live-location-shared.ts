/**
 * Client-safe types + helpers for live Driver location (P1-E3-S7A) — split
 * out from `live-location.ts` (which is `server-only`, since it queries
 * Supabase directly) so client components (AssignmentGrid) can import the
 * shape/helpers they need without pulling a server-only module into the
 * browser bundle. Same split rationale as `new-trip-options.ts`.
 */

export interface DispatchTripLocation {
  latitude: number;
  longitude: number;
  accuracyMeters: number | null;
  recordedAt: string;
  assignmentId: string;
}

/** A plain, no-API-key external map link — the MVP map-provider decision (work item §25/§26, see decision-register.md). No SDK, no billing, no privacy-implicated third-party embed. */
export function externalMapUrl(latitude: number, longitude: number): string {
  return `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=16/${latitude}/${longitude}`;
}
