/**
 * Client-safe types + presentation helpers for New Trip's option lists
 * (P1-E3-S7) — split out from `new-trip.ts` (which is `server-only`, since
 * it queries Supabase directly) so the client-side `NewTripForm` can import
 * the shapes/formatters it needs without pulling a server-only module into
 * the browser bundle.
 */

export interface NewTripPassengerOption {
  id: string;
  displayName: string;
  phone: string | null;
}

export interface NewTripFacilityOption {
  id: string;
  name: string;
  addressLine1: string | null;
  addressLine2: string | null;
  city: string | null;
  state: string | null;
  postalCode: string | null;
}

export interface NewTripRequestOption {
  id: string;
  requesterName: string;
  requesterRelationship: string;
  passengerId: string | null;
  pickupDescription: string;
  destinationDescription: string;
  preferredDate: string | null;
  preferredTime: string | null;
  assistanceNotes: string | null;
}

/** `Emory Dialysis · Atlanta, GA` style — matches Trip Detail's own Facility annotation format (ZD-152) for visual/product consistency across screens. */
export function formatFacilityOptionLabel(facility: NewTripFacilityOption): string {
  const cityState = [facility.city, facility.state].filter(Boolean).join(", ");
  return cityState ? `${facility.name} · ${cityState}` : facility.name;
}

/** The Facility's own canonical address, formatted as a starting address snapshot when the Facility is selected — the user may still edit it freely afterward (work item §18/§20: populate, don't force). */
export function formatFacilityAddress(facility: NewTripFacilityOption): string {
  const lines = [facility.addressLine1, facility.addressLine2].filter(Boolean);
  const cityStateZip = [facility.city, [facility.state, facility.postalCode].filter(Boolean).join(" ")]
    .filter(Boolean)
    .join(", ");
  return [facility.name, ...lines, cityStateZip].filter(Boolean).join(", ");
}

const REQUESTER_RELATIONSHIP_LABEL: Record<string, string> = {
  self: "Passenger",
  family: "Family",
  caregiver: "Caregiver",
  facility_coordinator: "Facility Coordinator",
  other: "Other",
};

/** `Facility Coordinator — preferred Aug 29` (or just the requester name/relationship when no preferred date was given) — real fields only, never a raw UUID (work item §14). */
export function formatRequestOptionLabel(request: NewTripRequestOption): string {
  const relationship = REQUESTER_RELATIONSHIP_LABEL[request.requesterRelationship] ?? request.requesterRelationship;
  const base = `${request.requesterName} (${relationship})`;
  return request.preferredDate ? `${base} — preferred ${request.preferredDate}` : base;
}
