"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireDriverAccess } from "@/lib/auth/authorization";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { DRIVER_NEXT_ACTION, type DriverLifecycleRpc } from "@/lib/driver/trip-presentation";
import { mapDriverActionError, type DriverActionErrorCode } from "@/lib/driver/errors";

export interface ProgressTripState {
  status: "idle" | "success" | "error";
  errorCode?: DriverActionErrorCode;
  changed?: boolean;
  newState?: string;
}

const ALLOWED_RPCS = new Set<string>(Object.values(DRIVER_NEXT_ACTION).map((a) => a.rpc));

/**
 * The single Server Action backing every Driver lifecycle progression
 * button (P1-E3-S3, work item §42). No service role — runs entirely under
 * the caller's own authenticated session via `createServerSupabaseClient()`,
 * exactly like every other mutation this application performs.
 *
 * Authorization is layered, matching ZD-105's established relationship
 * between this application layer and the database:
 *   1. `requireDriverAccess()` — re-derived fresh on every call (never
 *      trusted from a prior page render) — confirms the caller is still an
 *      active Driver in an active Membership right now (work item §52/§53).
 *   2. The RPC itself — the actual, final authority on whether THIS caller
 *      may act on THIS specific Trip right now (currently active
 *      assignment, correct from-state). This action never attempts to
 *      duplicate that check; it exists only to invoke the RPC under a real
 *      session and translate its result into safe UI state.
 *
 * `rpc` is validated against the fixed 6-name allowlist derived from
 * `DRIVER_NEXT_ACTION` — never passed through as an arbitrary client-
 * supplied function name (trip ID and expected-state values are untrusted
 * form input; the RPC name must be even more tightly constrained, since an
 * unvalidated dynamic RPC name would be a far more dangerous injection
 * surface than a wrong string parameter).
 */
export async function progressTripAction(
  _prevState: ProgressTripState,
  formData: FormData,
): Promise<ProgressTripState> {
  const tripId = formData.get("tripId");
  const expectedCurrentState = formData.get("expectedCurrentState");
  const rpc = formData.get("rpc");

  if (typeof tripId !== "string" || typeof expectedCurrentState !== "string" || typeof rpc !== "string") {
    return { status: "error", errorCode: "UNKNOWN" };
  }
  if (!ALLOWED_RPCS.has(rpc)) {
    return { status: "error", errorCode: "UNKNOWN" };
  }

  const access = await requireDriverAccess(`/driver/trips/${tripId}`);
  if (access.status !== "ok") {
    // Membership/Driver linkage failed closed on this very attempt — same
    // safe outcome as any other inaccessible-Trip case, no extra detail.
    return { status: "error", errorCode: "NOT_FOUND" };
  }

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.rpc(rpc as DriverLifecycleRpc, {
    p_trip_id: tripId,
    p_expected_current_state: expectedCurrentState,
  });

  if (error || !data) {
    return { status: "error", errorCode: mapDriverActionError(error?.code) };
  }

  // Server-side revalidation (work item §28) — the database response is
  // authoritative; every surface that could show this Trip's state is
  // invalidated so the next render anywhere reflects it, never a
  // client-guessed optimistic value.
  revalidatePath(`/driver/trips/${tripId}`);
  revalidatePath("/driver/trips");
  revalidatePath("/driver");

  if (rpc === "driver_complete_trip") {
    // `driver_complete_trip` closes the active assignment in the same
    // transaction (docs/data/mutation-api.md) — this detail page becomes
    // inaccessible on its very next `driver_get_trip_detail` call, which
    // is exactly what the `revalidatePath` calls above would trigger on
    // this same route next. Redirecting SERVER-SIDE, from within the
    // action itself, avoids a real race that a client-side
    // `router.push()` after the fact loses: Next.js automatically
    // re-renders the current route's Server Component tree once a Server
    // Action completes (to reflect its own `revalidatePath` calls) —
    // that automatic re-render would otherwise show this now-inaccessible
    // Trip's "Trip unavailable" state before a client `useEffect`-driven
    // push ever gets a chance to run (found and reproduced via the real
    // end-to-end lifecycle test, not assumed — see docs/reports/
    // P1-E3-S3-completion-report.txt). `redirect()` thrown here pre-empts
    // that race entirely (work item §29).
    redirect("/driver");
  }

  return {
    status: "success",
    changed: data.changed ?? false,
    newState: data.current_state ?? undefined,
  };
}
