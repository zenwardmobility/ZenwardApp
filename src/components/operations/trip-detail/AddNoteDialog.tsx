"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Textarea } from "@/components/ui/Textarea";
import { Select } from "@/components/ui/Select";
import { Button } from "@/components/ui/Button";
import { addNoteAction, type TripDetailActionState } from "@/app/operations/trips/[tripId]/actions";
import { tripDetailErrorMessage } from "@/lib/operations/trip-detail-errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: TripDetailActionState = { status: "idle" };

const VISIBILITY_OPTIONS = [
  { value: "operations_only", label: "Operations only" },
  { value: "driver_visible", label: "Visible to Driver" },
];

export interface AddNoteDialogProps {
  tripId: string;
  onClose: () => void;
}

/**
 * A real, RLS-protected direct `trip_notes` INSERT (via `addNoteAction`)
 * — not an RPC (no special mutation-layer dependency needed here, see
 * component-inventory.md). No default visibility is pre-selected — a
 * Dispatcher must make an affirmative choice about who sees the note,
 * matching the same "no accidental default" principle `AssignmentDialog`
 * already established for Driver/Vehicle selection.
 */
export function AddNoteDialog({ tripId, onClose }: AddNoteDialogProps) {
  const [state, formAction, pending] = useActionState(addNoteAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "idle") return;
    router.refresh();
    if (state.status === "success") {
      onClose();
    }
  }, [state, router, onClose]);

  return (
    <Dialog open onClose={onClose} title="Add Note">
      <form action={formAction} className="flex flex-col gap-zw-md">
        <input type="hidden" name="tripId" value={tripId} />

        <Textarea label="Note" name="body" required placeholder="e.g. Confirmed pickup time with facility" disabled={pending} />

        <Select
          label="Visibility"
          name="visibility"
          required
          placeholder="Choose who can see this note"
          options={VISIBILITY_OPTIONS}
          disabled={pending}
          helpText="Operations only: internal staff. Visible to Driver: shown on the Driver's own Active Trip screen."
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {tripDetailErrorMessage(state.errorCode ?? "UNKNOWN")}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Saving…" : "Add Note"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
