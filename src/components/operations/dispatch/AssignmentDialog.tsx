"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Select } from "@/components/ui/Select";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { DefinitionList } from "@/components/ui/DefinitionList";
import { assignmentAction, type AssignmentActionState } from "@/app/operations/dispatch/actions";
import { dispatchErrorMessage } from "@/lib/operations/dispatch-errors";
import type { DispatchDriverOption, DispatchVehicleOption, DispatchTrip } from "@/lib/operations/dispatch-board";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: AssignmentActionState = { status: "idle" };

export interface AssignmentDialogProps {
  trip: DispatchTrip;
  mode: "assign" | "reassign";
  driverOptions: DispatchDriverOption[];
  vehicleOptions: DispatchVehicleOption[];
  onClose: () => void;
}

/**
 * The one Assign/Reassign dialog (P1-E3-S5, work item §23) — a real
 * `<form>` + Server Action, matching `DriverLifecycleAction`'s established
 * pattern exactly (never a client-side Supabase call, never an
 * optimistic update before the server confirms). The caller mounts this
 * component only while a dialog should be open and unmounts it to close —
 * `useActionState`'s own state is therefore always fresh per trip/mode,
 * never carried over from a previous dialog.
 *
 * No driver/vehicle is pre-selected — the Dispatcher must make an
 * affirmative choice before the submit button does anything (work item
 * §24: "do not reassign merely by changing a dropdown value").
 */
export function AssignmentDialog({ trip, mode, driverOptions, vehicleOptions, onClose }: AssignmentDialogProps) {
  const [state, formAction, pending] = useActionState(assignmentAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    // Refresh the board on BOTH success and error — a conflict (ZW005,
    // e.g. another dispatcher just assigned/reassigned this same Trip)
    // needs the same authoritative re-fetch a success does, so the board
    // never shows a stale unassigned/previous-driver row after this
    // dialog closes (work item §28/§29/§37).
    router.refresh();
    if (state.status === "success") {
      onClose();
    }
  }, [state, router, onClose]);

  const driverSelectOptions = driverOptions.map((d) => ({ value: d.id, label: d.displayName }));
  const vehicleSelectOptions = vehicleOptions.map((v) => ({ value: v.id, label: v.label }));

  return (
    <Dialog
      open
      onClose={onClose}
      title={mode === "assign" ? "Assign Driver" : "Reassign Trip"}
      description={`${trip.passengerName} — ${trip.pickupDescription} → ${trip.destinationDescription}`}
    >
      {mode === "reassign" && (
        <div className="mb-zw-lg">
          <DefinitionList
            items={[
              { label: "Currently assigned to", value: trip.driverName ?? "—" },
              { label: "Vehicle", value: trip.vehicleLabel ?? "None" },
            ]}
          />
        </div>
      )}

      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="mode" value={mode} />
        <input type="hidden" name="tripId" value={trip.id} />
        {/*
          P1-E3-S5A: the assignment the Dispatcher actually reviewed —
          submitted as the optimistic-concurrency precondition
          `reassign_trip` now requires for a real (non-idempotent)
          reassignment. Never rendered/shown to the Dispatcher (work item
          §7 — "do not expose the UUID visually"); the backend, not this
          hidden field's mere presence, is what verifies it still matches
          the active assignment.
        */}
        {mode === "reassign" && (
          <input type="hidden" name="expectedAssignmentId" value={trip.activeAssignmentId ?? ""} />
        )}

        <Select
          label="Driver"
          name="driverId"
          required
          placeholder="Choose a driver"
          options={driverSelectOptions}
          disabled={pending}
        />

        <Select
          label="Vehicle"
          name="vehicleId"
          placeholder="No vehicle"
          helpText="Optional — assign_trip and reassign_trip both accept a Trip with no vehicle."
          options={vehicleSelectOptions}
          disabled={pending}
        />

        {mode === "reassign" && (
          <Textarea
            label="Reason (optional)"
            name="reason"
            placeholder="e.g. Original driver called out"
            disabled={pending}
          />
        )}

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {dispatchErrorMessage(state.errorCode ?? "UNKNOWN")}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Saving…" : mode === "assign" ? "Assign Driver" : "Confirm Reassignment"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
