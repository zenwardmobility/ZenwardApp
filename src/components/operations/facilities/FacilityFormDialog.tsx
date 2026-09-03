"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Button } from "@/components/ui/Button";
import {
  createFacilityAction,
  updateFacilityAction,
  type FacilityActionState,
  type FacilityRecord,
} from "@/app/operations/facilities/actions";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: FacilityActionState = { status: "idle" };

export interface FacilityFormDialogProps {
  mode: "create" | "edit";
  facility?: FacilityRecord;
  onClose: () => void;
  onSaved?: (facility: FacilityRecord) => void;
}

/** One dialog, two modes (P1-E3-S9, work item §8 — closes GAP-13). */
export function FacilityFormDialog({ mode, facility, onClose, onSaved }: FacilityFormDialogProps) {
  const action = mode === "create" ? createFacilityAction : updateFacilityAction;
  const [state, formAction, pending] = useActionState(action, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "success" && state.facility) {
      if (onSaved) {
        onSaved(state.facility);
      } else {
        router.refresh();
      }
      onClose();
    }
  }, [state, router, onClose, onSaved]);

  return (
    <Dialog open onClose={onClose} title={mode === "create" ? "Add Facility" : "Edit Facility"}>
      <form action={formAction} className="flex flex-col gap-zw-md">
        {mode === "edit" && facility && <input type="hidden" name="facilityId" value={facility.id} />}
        <Input label="Facility Name" name="name" required placeholder="e.g. Cascade Dialysis Center" defaultValue={facility?.name} disabled={pending} />
        <Input label="Address Line 1" name="addressLine1" placeholder="e.g. 4200 Millbrook Commons Dr" defaultValue={facility?.addressLine1 ?? undefined} disabled={pending} />
        <Input label="Address Line 2" name="addressLine2" defaultValue={facility?.addressLine2 ?? undefined} disabled={pending} />
        <div className="grid grid-cols-3 gap-zw-sm">
          <Input label="City" name="city" defaultValue={facility?.city ?? undefined} disabled={pending} />
          <Input label="State" name="state" defaultValue={facility?.state ?? undefined} disabled={pending} />
          <Input label="ZIP" name="postalCode" defaultValue={facility?.postalCode ?? undefined} disabled={pending} />
        </div>
        {mode === "edit" && (
          <Select
            label="Status"
            name="status"
            required
            defaultValue={facility?.status ?? "active"}
            disabled={pending}
            options={[
              { value: "active", label: "Active" },
              { value: "inactive", label: "Inactive" },
            ]}
          />
        )}

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            Couldn&apos;t save this facility. Check the name and try again.
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Saving…" : mode === "create" ? "Add Facility" : "Save Changes"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
