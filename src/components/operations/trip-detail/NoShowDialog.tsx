"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { recordNoShowAction, type TripDetailActionState } from "@/app/operations/trips/[tripId]/actions";
import { tripDetailErrorMessage } from "@/lib/operations/trip-detail-errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: TripDetailActionState = { status: "idle" };

export interface NoShowDialogProps {
  tripId: string;
  passengerName: string;
  onClose: () => void;
}

/**
 * No-show is a deliberate Operations human decision (work item §23/§24)
 * — never derived from elapsed time, driver location, or any client-side
 * heuristic. The backend (`record_no_show`) remains the sole authority on
 * eligibility (en_route_to_pickup/arrived_at_pickup only); this dialog
 * only ever appears when the page's own already-loaded Trip state made it
 * eligible, and the RPC re-validates regardless.
 */
export function NoShowDialog({ tripId, passengerName, onClose }: NoShowDialogProps) {
  const [state, formAction, pending] = useActionState(recordNoShowAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    router.refresh();
    if (state.status === "success") {
      onClose();
    }
  }, [state, router, onClose]);

  return (
    <Dialog
      open
      onClose={onClose}
      title="Record No-Show"
      description={`This will mark ${passengerName}'s trip as a no-show and end the active driver assignment. This cannot be undone.`}
    >
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="tripId" value={tripId} />

        <Textarea
          label="Reason / notes"
          name="reason"
          required
          placeholder="e.g. Driver waited 10 minutes, passenger did not appear"
          disabled={pending}
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {tripDetailErrorMessage(state.errorCode ?? "UNKNOWN")}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" variant="destructive" loading={pending} disabled={pending}>
            {pending ? "Recording…" : "Record No-Show"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
