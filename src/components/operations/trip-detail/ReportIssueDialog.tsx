"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Textarea } from "@/components/ui/Textarea";
import { Select } from "@/components/ui/Select";
import { Button } from "@/components/ui/Button";
import { reportExceptionAction, type TripExceptionActionState } from "@/app/operations/trips/[tripId]/actions";
import { tripExceptionErrorMessage, EXCEPTION_TYPE_OPTIONS } from "@/lib/operations/trip-exception-errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: TripExceptionActionState = { status: "idle" };

export interface ReportIssueDialogProps {
  tripId: string;
  onClose: () => void;
}

/**
 * "Report Issue" (P1-E3-S8) — a real, controlled `report_trip_exception`
 * RPC call, never a direct INSERT (see that migration's own header for
 * why). Operational description only — no medical/clinical data field
 * exists or is collected (work item §21).
 */
export function ReportIssueDialog({ tripId, onClose }: ReportIssueDialogProps) {
  const [state, formAction, pending] = useActionState(reportExceptionAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    router.refresh();
    if (state.status === "success") {
      onClose();
    }
  }, [state, router, onClose]);

  return (
    <Dialog open onClose={onClose} title="Report Issue" description="Record an operational issue on this trip for another dispatcher to review.">
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="tripId" value={tripId} />

        <Select
          label="Issue Type"
          name="exceptionType"
          required
          placeholder="Choose a category"
          options={EXCEPTION_TYPE_OPTIONS}
          disabled={pending}
        />

        <Textarea
          label="Description"
          name="description"
          required
          placeholder="e.g. Vehicle had a flat tire, waiting for the backup vehicle."
          helpText="Enough detail for another dispatcher to understand what happened."
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
            {pending ? "Reporting…" : "Report Issue"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
