"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { resolveExceptionAction, type TripExceptionActionState } from "@/app/operations/trips/[tripId]/actions";
import { tripExceptionErrorMessage } from "@/lib/operations/trip-exception-errors";
import { humanizeExceptionType } from "@/lib/operations/presentation";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: TripExceptionActionState = { status: "idle" };

export interface ResolveExceptionDialogProps {
  tripId: string;
  exceptionId: string;
  exceptionType: string | null;
  onClose: () => void;
}

/**
 * "Resolve" (P1-E3-S8) — the real `resolve_trip_exception` RPC. Never
 * deletes the exception row — resolving preserves the full history
 * (work item §23/§25). A stale/duplicate resolve (another dispatcher
 * already resolved it) is a safe, documented no-op — see the RPC's own
 * comment.
 */
export function ResolveExceptionDialog({ tripId, exceptionId, exceptionType, onClose }: ResolveExceptionDialogProps) {
  const [state, formAction, pending] = useActionState(resolveExceptionAction, INITIAL_STATE);
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
      title="Resolve Issue"
      description={`Mark this ${exceptionType ? humanizeExceptionType(exceptionType).toLowerCase() : "issue"} as resolved. It stays visible in this trip's history.`}
    >
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="tripId" value={tripId} />
        <input type="hidden" name="exceptionId" value={exceptionId} />

        <Textarea
          label="Resolution Note"
          name="resolutionNote"
          placeholder="e.g. Backup vehicle arrived, trip continued."
          helpText="Optional."
          disabled={pending}
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {tripExceptionErrorMessage(state.errorCode ?? "UNKNOWN")}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Resolving…" : "Resolve"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
