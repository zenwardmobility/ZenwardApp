"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Select } from "@/components/ui/Select";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { driverReportIssueAction, type DriverReportIssueState } from "@/app/driver/trips/[tripId]/actions";
import { tripExceptionErrorMessage, EXCEPTION_TYPE_OPTIONS } from "@/lib/operations/trip-exception-errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: DriverReportIssueState = { status: "idle" };

export interface DriverReportIssueDialogProps {
  tripId: string;
  onClose: () => void;
}

/**
 * Driver-facing "Report Issue" (P1-E3-S8B, work item §37) — same
 * `report_trip_exception` RPC and same restrained issue-type list
 * (`EXCEPTION_TYPE_OPTIONS`) as the Operations dialog, reused rather
 * than re-invented. No resolve affordance exists here, and no existing
 * exception is ever shown — this is a write-only report, matching the
 * work item's own explicit scope.
 */
export function DriverReportIssueDialog({ tripId, onClose }: DriverReportIssueDialogProps) {
  const [state, formAction, pending] = useActionState(driverReportIssueAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    if (state.status === "success") {
      router.refresh();
      onClose();
    }
  }, [state, router, onClose]);

  return (
    <Dialog open onClose={onClose} title="Report Issue" description="Let dispatch know about a problem with this trip.">
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
          placeholder="e.g. Flat tire, waiting for a backup vehicle."
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
