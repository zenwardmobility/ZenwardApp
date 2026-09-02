"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { cancelTripAction, type TripDetailActionState } from "@/app/operations/trips/[tripId]/actions";
import { tripDetailErrorMessage } from "@/lib/operations/trip-detail-errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: TripDetailActionState = { status: "idle" };

export interface CancelTripDialogProps {
  tripId: string;
  passengerName: string;
  onClose: () => void;
}

/**
 * Cancellation is a destructive operational action (work item §22) —
 * requires an explicit reason and a deliberate confirm click, never a
 * casual one-click button. Mirrors `AssignmentDialog`'s established
 * pattern exactly: real `<form>` + Server Action, mounted only while
 * open so `useActionState` is always fresh.
 */
export function CancelTripDialog({ tripId, passengerName, onClose }: CancelTripDialogProps) {
  const [state, formAction, pending] = useActionState(cancelTripAction, INITIAL_STATE);
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
      title="Cancel Trip"
      description={`This will cancel ${passengerName}'s trip and end any active driver assignment. This cannot be undone.`}
    >
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="tripId" value={tripId} />

        <Textarea
          label="Reason for cancellation"
          name="reason"
          required
          placeholder="e.g. Passenger requested cancellation"
          disabled={pending}
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {tripDetailErrorMessage(state.errorCode ?? "UNKNOWN")}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Keep Trip
          </Button>
          <Button type="submit" variant="destructive" loading={pending} disabled={pending}>
            {pending ? "Cancelling…" : "Cancel Trip"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
