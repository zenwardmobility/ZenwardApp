"use client";

import { useState } from "react";
import { WarningCircle } from "@phosphor-icons/react/dist/ssr";
import { Button } from "@/components/ui/Button";
import { DriverReportIssueDialog } from "./DriverReportIssueDialog";

export interface DriverReportIssueButtonProps {
  tripId: string;
  className?: string;
}

/** Thin client wrapper so the Server Component page above it stays server-rendered — only the open/close dialog state needs a client boundary. */
export function DriverReportIssueButton({ tripId, className }: DriverReportIssueButtonProps) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button
        type="button"
        variant="outline"
        size="md"
        leadingIcon={<WarningCircle className="size-4" aria-hidden />}
        className={className}
        onClick={() => setOpen(true)}
      >
        Report Issue
      </Button>
      {open && <DriverReportIssueDialog tripId={tripId} onClose={() => setOpen(false)} />}
    </>
  );
}
