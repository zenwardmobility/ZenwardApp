"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { progressTripAction, type ProgressTripState } from "@/app/driver/trips/[tripId]/actions";
import { DriverPrimaryAction } from "@/components/driver/DriverPrimaryAction";
import { DRIVER_ACTION_ERROR_MESSAGE } from "@/lib/driver/errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_PROGRESS_STATE: ProgressTripState = { status: "idle" };

export interface DriverLifecycleActionProps {
  tripId: string;
  /** The Trip's currently-known state, as loaded on this render — sent as `p_expected_current_state` so a stale view is caught server-side (ZW003) rather than silently applied. */
  currentState: string;
  rpc: string;
  label: string;
}

/**
 * The one dominant next-action control on Active Trip (P1-E3-S3, work item
 * §19/§27). A real `<form>` + Server Action (progressive-enhancement-
 * friendly, matches SignInForm's own established pattern) — never a bare
 * client-side fetch. `useFormStatus`-equivalent pending state comes from
 * `useActionState`'s own third tuple member; the button disables
 * immediately on submit and never optimistically advances the displayed
 * state before the server confirms it (work item §27 — "database response
 * is authoritative").
 *
 * On success, `router.refresh()` re-runs this Server Component subtree
 * against the Server Action's own `revalidatePath()` calls, so the newly
 * fetched `driver_get_trip_detail` reflects the real new state — never a
 * locally faked one. On a successful `driver_complete_trip` specifically,
 * the assignment closes server-side in the same transaction (docs/data/
 * mutation-api.md) — this detail page becomes inaccessible on its very
 * next load, so instead of refreshing in place this component navigates
 * back to Driver Today, matching the approved flow (work item §29).
 */
export function DriverLifecycleAction({ tripId, currentState, rpc, label }: DriverLifecycleActionProps) {
  const [state, formAction, pending] = useActionState(progressTripAction, INITIAL_PROGRESS_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    // Refresh on BOTH success and error (work item §22/§28): a stale-state
    // (ZW003), reassignment (ZW001), or lost-access (ZW002) error is
    // handled the same way as a success — re-fetch the authoritative
    // server state. The page's own `driver_get_trip_detail` call
    // independently re-derives whether this Trip is still accessible at
    // all, naturally rendering the "Trip unavailable" state if not.
    // Completion (`driver_complete_trip`) never reaches this effect at
    // all — the Server Action redirects server-side before returning, to
    // avoid a real race this exact client-side approach lost (see
    // src/app/driver/trips/[tripId]/actions.ts).
    router.refresh();
  }, [state, router]);

  return (
    <form action={formAction} className="flex flex-col gap-2">
      <input type="hidden" name="tripId" value={tripId} />
      <input type="hidden" name="expectedCurrentState" value={currentState} />
      <input type="hidden" name="rpc" value={rpc} />

      {state.status === "error" && (
        <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
          {DRIVER_ACTION_ERROR_MESSAGE[state.errorCode ?? "UNKNOWN"]}
        </p>
      )}

      <DriverPrimaryAction type="submit" loading={pending} disabled={pending}>
        {pending ? "Updating…" : label}
      </DriverPrimaryAction>
    </form>
  );
}
