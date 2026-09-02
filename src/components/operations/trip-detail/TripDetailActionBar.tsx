"use client";

import { useState } from "react";
import { Phone } from "@phosphor-icons/react/dist/ssr";
import { Button } from "@/components/ui/Button";
import { LinkButton } from "@/components/ui/LinkButton";
import { CancelTripDialog } from "./CancelTripDialog";
import { NoShowDialog } from "./NoShowDialog";

export interface TripDetailActionBarProps {
  tripId: string;
  passengerName: string;
  driverPhone: string | null;
  eligibleForCancel: boolean;
  eligibleForNoShow: boolean;
}

/**
 * The action cluster from the reference's top-right corner (Edit Trip /
 * More / Contact Driver) — reworked as direct, individually-labeled
 * buttons rather than an overflow "More" menu (ZD-1xx, decision-register.md):
 * no dropdown-menu primitive exists yet in the design system, and hiding
 * a destructive action (Cancel) or a rare one (Report No-Show) behind an
 * unlabeled "More" button is arguably less discoverable/accessible than
 * showing them directly — composition/hierarchy (a small cluster of
 * secondary actions beside the page title) is preserved, only the exact
 * interaction shape differs.
 *
 * "Edit Trip" is rendered, real, and disabled — the New Trip/Edit form is
 * explicitly out of scope this phase (work item §54).
 */
export function TripDetailActionBar({
  tripId,
  passengerName,
  driverPhone,
  eligibleForCancel,
  eligibleForNoShow,
}: TripDetailActionBarProps) {
  const [activeDialog, setActiveDialog] = useState<"cancel" | "noshow" | null>(null);

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        <Button variant="outline" disabled title="Editing a trip's own details is not available yet.">
          Edit Trip
        </Button>
        {eligibleForNoShow && (
          <Button variant="outline" onClick={() => setActiveDialog("noshow")}>
            Record No-Show
          </Button>
        )}
        {eligibleForCancel && (
          <Button variant="outline" onClick={() => setActiveDialog("cancel")}>
            Cancel Trip
          </Button>
        )}
        {driverPhone && (
          <LinkButton href={`tel:${driverPhone}`} leadingIcon={<Phone className="size-4" aria-hidden />}>
            Contact Driver
          </LinkButton>
        )}
      </div>

      {activeDialog === "cancel" && (
        <CancelTripDialog tripId={tripId} passengerName={passengerName} onClose={() => setActiveDialog(null)} />
      )}
      {activeDialog === "noshow" && (
        <NoShowDialog tripId={tripId} passengerName={passengerName} onClose={() => setActiveDialog(null)} />
      )}
    </>
  );
}
