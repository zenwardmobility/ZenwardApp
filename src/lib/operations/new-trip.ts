import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { NewTripPassengerOption, NewTripFacilityOption, NewTripRequestOption } from "./new-trip-options";

/**
 * Server-side data access boundary for New Trip (P1-E3-S7, work item §10/
 * §18/§13) — organization-scoped, explicit columns, no `select("*")`, no
 * service role. Three independent option lists (Passenger/Facility/
 * TransportationRequest), never a Trip query — this screen creates a Trip,
 * it doesn't read one. Same query-shape convention as
 * `getDispatchBoardData`'s driver/vehicle options (dispatch-board.ts):
 * `.eq("organization_id", ...)` explicit on every query, never relying on
 * RLS alone, and `status = 'active'` where the table has that column
 * (matching the exact filter `create_trip` itself re-applies server-side —
 * this is a UX convenience, not the authority).
 *
 * Types + presentation formatting live in `new-trip-options.ts` instead of
 * here — that module has no `server-only`/Supabase import, so the
 * client-side `NewTripForm` can share the same shapes/formatters without
 * pulling this server-only module into the browser bundle.
 */

export interface NewTripFormData {
  passengers: NewTripPassengerOption[];
  facilities: NewTripFacilityOption[];
  requests: NewTripRequestOption[];
}

const REQUEST_ELIGIBLE_STATES = ["pending", "accepted"];

export async function getNewTripFormData(organizationId: string): Promise<NewTripFormData> {
  const supabase = await createServerSupabaseClient();

  const [passengersResult, facilitiesResult, requestsResult] = await Promise.all([
    supabase
      .from("passengers")
      .select("id, display_name, phone")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .order("display_name", { ascending: true }),
    supabase
      .from("facilities")
      .select("id, name, address_line1, address_line2, city, state, postal_code")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .order("name", { ascending: true }),
    // Eligible candidates only (work item §14) — the exact same states
    // create_trip's own p_request_id validation accepts
    // (20260831120000_controlled_trip_creation.sql); declined/cancelled
    // requests are excluded here as a UX convenience, not the authority —
    // the RPC re-validates regardless of what this list ever contained.
    // Oldest first, matching the table's own "ops queue" index intent
    // (transportation_requests_org_state_created_idx).
    supabase
      .from("transportation_requests")
      .select(
        "id, requester_name, requester_relationship, passenger_id, pickup_description, destination_description, preferred_date, preferred_time, assistance_notes",
      )
      .eq("organization_id", organizationId)
      .in("state", REQUEST_ELIGIBLE_STATES)
      .order("created_at", { ascending: true }),
  ]);

  if (passengersResult.error) {
    throw new Error(`Failed to load passenger options: ${passengersResult.error.message}`);
  }
  if (facilitiesResult.error) {
    throw new Error(`Failed to load facility options: ${facilitiesResult.error.message}`);
  }
  if (requestsResult.error) {
    throw new Error(`Failed to load request options: ${requestsResult.error.message}`);
  }

  const passengers: NewTripPassengerOption[] = (passengersResult.data ?? []).map((p) => ({
    id: p.id,
    displayName: p.display_name,
    phone: p.phone,
  }));

  const facilities: NewTripFacilityOption[] = (facilitiesResult.data ?? []).map((f) => ({
    id: f.id,
    name: f.name,
    addressLine1: f.address_line1,
    addressLine2: f.address_line2,
    city: f.city,
    state: f.state,
    postalCode: f.postal_code,
  }));

  const requests: NewTripRequestOption[] = (requestsResult.data ?? []).map((r) => ({
    id: r.id,
    requesterName: r.requester_name,
    requesterRelationship: r.requester_relationship,
    passengerId: r.passenger_id,
    pickupDescription: r.pickup_description,
    destinationDescription: r.destination_description,
    preferredDate: r.preferred_date,
    preferredTime: r.preferred_time,
    assistanceNotes: r.assistance_notes,
  }));

  return { passengers, facilities, requests };
}
