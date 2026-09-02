"use server";

import { revalidatePath } from "next/cache";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getUser } from "@/lib/auth/session";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { mapTripDetailError, type TripDetailErrorCode } from "@/lib/operations/trip-detail-errors";

export interface TripDetailActionState {
  status: "idle" | "success" | "error";
  errorCode?: TripDetailErrorCode;
}

async function revalidateTripDetailRoutes(tripId: string) {
  revalidatePath(`/operations/trips/${tripId}`);
  revalidatePath("/operations/dispatch");
  revalidatePath("/operations");
}

/**
 * Cancel Trip — the real `cancel_trip` RPC only, never a direct
 * `trips.state` write (work item §21). Re-derives Operations
 * authorization fresh on every call, exactly like the Dispatch Server
 * Action (`src/app/operations/dispatch/actions.ts`) — an inactive
 * Membership, a role change, or a foreign-org attempt is caught HERE,
 * not assumed from how the page happened to render.
 */
export async function cancelTripAction(
  _prevState: TripDetailActionState,
  formData: FormData,
): Promise<TripDetailActionState> {
  const tripId = formData.get("tripId");
  const reason = formData.get("reason");

  if (typeof tripId !== "string" || tripId.length === 0) {
    return { status: "error", errorCode: "NOT_FOUND" };
  }
  if (typeof reason !== "string" || reason.trim().length === 0) {
    return { status: "error", errorCode: "INVALID_INPUT" };
  }

  const pathname = await getCurrentPathname(`/operations/trips/${tripId}`);
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.rpc("cancel_trip", { p_trip_id: tripId, p_reason: reason.trim() });

  if (error) {
    return { status: "error", errorCode: mapTripDetailError(error.code) };
  }

  await revalidateTripDetailRoutes(tripId);
  return { status: "success" };
}

/**
 * Record No-Show — the real `record_no_show` RPC only. Backend remains
 * authoritative on eligibility (en_route_to_pickup/arrived_at_pickup
 * only, lifecycle-model.md §J) — this action does not itself gate on
 * state beyond what the RPC already enforces (work item §23/§24: no
 * client-side classification from time/location, ever).
 */
export async function recordNoShowAction(
  _prevState: TripDetailActionState,
  formData: FormData,
): Promise<TripDetailActionState> {
  const tripId = formData.get("tripId");
  const reason = formData.get("reason");

  if (typeof tripId !== "string" || tripId.length === 0) {
    return { status: "error", errorCode: "NOT_FOUND" };
  }
  if (typeof reason !== "string" || reason.trim().length === 0) {
    return { status: "error", errorCode: "INVALID_INPUT" };
  }

  const pathname = await getCurrentPathname(`/operations/trips/${tripId}`);
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.rpc("record_no_show", { p_trip_id: tripId, p_reason: reason.trim() });

  if (error) {
    return { status: "error", errorCode: mapTripDetailError(error.code) };
  }

  await revalidateTripDetailRoutes(tripId);
  return { status: "success" };
}

const NOTE_VISIBILITIES = new Set(["operations_only", "driver_visible"]);

/**
 * Add Note — a direct, RLS-protected `trip_notes` INSERT, not an RPC
 * (component-inventory.md's own pre-existing note: "write action ('Add
 * Note') is a direct-table INSERT per the data-action map, not an RPC —
 * no special mutation-layer dependency"). Legitimate and safe:
 * `trip_notes_insert_operations` grants Organization Admin/Dispatcher
 * INSERT for either visibility value, scoped by RLS to their own
 * organization — confirmed by reading the actual policy, not assumed
 * because the table exists (work item §33's own explicit caution).
 */
export async function addNoteAction(
  _prevState: TripDetailActionState,
  formData: FormData,
): Promise<TripDetailActionState> {
  const tripId = formData.get("tripId");
  const body = formData.get("body");
  const visibility = formData.get("visibility");

  if (typeof tripId !== "string" || tripId.length === 0) {
    return { status: "error", errorCode: "NOT_FOUND" };
  }
  if (typeof body !== "string" || body.trim().length === 0) {
    return { status: "error", errorCode: "INVALID_INPUT" };
  }
  if (typeof visibility !== "string" || !NOTE_VISIBILITIES.has(visibility)) {
    return { status: "error", errorCode: "INVALID_INPUT" };
  }

  const pathname = await getCurrentPathname(`/operations/trips/${tripId}`);
  const organization = await requireOperationsAccess(pathname);
  const user = await getUser();
  if (!user) {
    return { status: "error", errorCode: "UNAUTHORIZED" };
  }

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.from("trip_notes").insert({
    organization_id: organization.organizationId,
    trip_id: tripId,
    author_user_id: user.id,
    visibility,
    body: body.trim(),
  });

  if (error) {
    // A raw table INSERT surfaces a Postgres/PostgREST error, not one of
    // the ZW codes — RLS denial (wrong org, wrong role) is the only
    // realistic failure mode here (input is already validated above), so
    // it maps to the same safe NOT_FOUND/UNKNOWN treatment rather than
    // ever showing the raw Postgres message.
    return { status: "error", errorCode: "UNKNOWN" };
  }

  await revalidateTripDetailRoutes(tripId);
  return { status: "success" };
}
