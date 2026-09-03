"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Button } from "@/components/ui/Button";
import { createVehicleAction, updateVehicleAction, type VehicleActionState } from "@/app/operations/fleet/actions";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: VehicleActionState = { status: "idle" };

export interface VehicleFormDialogProps {
  mode: "create" | "edit";
  vehicle?: { id: string; label: string; status: string };
  onClose: () => void;
  /** Only used by the onboarding flow, which needs to know the created row without a page reload — the ordinary Fleet screen use (router.refresh()) doesn't need this. */
  onSaved?: (vehicle: { id: string; label: string; status: string }) => void;
}

/**
 * One dialog, two modes (P1-E3-S9, work item §7 — closes GAP-14) — same
 * shape as `AssignmentDialog`'s own assign/reassign duality. Only real
 * schema fields (`label`, `status`) — never a fabricated wheelchair/
 * stretcher/ambulatory capability field.
 */
export function VehicleFormDialog({ mode, vehicle, onClose, onSaved }: VehicleFormDialogProps) {
  const action = mode === "create" ? createVehicleAction : updateVehicleAction;
  const [state, formAction, pending] = useActionState(action, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "success" && state.vehicle) {
      if (onSaved) {
        onSaved(state.vehicle);
      } else {
        router.refresh();
      }
      onClose();
    }
  }, [state, router, onClose, onSaved]);

  return (
    <Dialog open onClose={onClose} title={mode === "create" ? "Add Vehicle" : "Edit Vehicle"}>
      <form action={formAction} className="flex flex-col gap-zw-md">
        {mode === "edit" && vehicle && <input type="hidden" name="vehicleId" value={vehicle.id} />}
        <Input
          label="Vehicle"
          name="label"
          required
          placeholder="e.g. Ford Transit 12"
          defaultValue={vehicle?.label}
          disabled={pending}
          helpText="A name or plate you'll recognize on Dispatch — not a make/model spec."
        />
        {mode === "edit" && (
          <Select
            label="Status"
            name="status"
            required
            defaultValue={vehicle?.status ?? "active"}
            disabled={pending}
            options={[
              { value: "active", label: "Active" },
              { value: "inactive", label: "Inactive" },
            ]}
          />
        )}

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            Couldn&apos;t save this vehicle. Check the name and try again.
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Saving…" : mode === "create" ? "Add Vehicle" : "Save Changes"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
