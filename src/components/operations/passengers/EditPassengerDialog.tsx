"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Input } from "@/components/ui/Input";
import { Textarea } from "@/components/ui/Textarea";
import { Select } from "@/components/ui/Select";
import { Button } from "@/components/ui/Button";
import { updatePassengerAction, type PassengerActionState } from "@/app/operations/passengers/actions";
import type { PassengersListRow } from "@/lib/operations/passengers-list";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: PassengerActionState = { status: "idle" };

export interface EditPassengerDialogProps {
  passenger: PassengersListRow;
  onClose: () => void;
}

/**
 * Edit/Deactivate (P1-E3-S9, work item §9 — closes GAP-12). Deactivating
 * is the SAME form's Status field, not a separate destructive-looking
 * button — a mis-entered Passenger is corrected here in place, never by
 * deleting and re-creating.
 */
export function EditPassengerDialog({ passenger, onClose }: EditPassengerDialogProps) {
  const [state, formAction, pending] = useActionState(updatePassengerAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "success") {
      router.refresh();
      onClose();
    }
  }, [state, router, onClose]);

  return (
    <Dialog open onClose={onClose} title="Edit Passenger">
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="passengerId" value={passenger.id} />
        <Input label="Full Name" name="displayName" required defaultValue={passenger.displayName} disabled={pending} />
        <Input label="Phone" name="phone" type="tel" defaultValue={passenger.phone ?? undefined} disabled={pending} />
        <Textarea
          label="Assistance Requirements"
          name="assistanceNotes"
          placeholder="e.g. Uses a wheelchair; needs ramp access"
          helpText="Mobility/assistance notes only — never a diagnosis or clinical history."
          defaultValue={passenger.assistanceNotes ?? undefined}
          disabled={pending}
        />
        <Select
          label="Status"
          name="status"
          required
          defaultValue={passenger.status}
          disabled={pending}
          options={[
            { value: "active", label: "Active" },
            { value: "inactive", label: "Inactive (deactivated)" },
          ]}
          helpText="Deactivating keeps the passenger's history — it's never deleted."
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            Couldn&apos;t save these changes. Check the name and try again.
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Saving…" : "Save Changes"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
