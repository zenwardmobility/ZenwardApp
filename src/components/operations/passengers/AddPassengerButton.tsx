"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus } from "@phosphor-icons/react/dist/ssr";
import { Button } from "@/components/ui/Button";
import { AddPassengerDialog } from "@/components/operations/new-trip/AddPassengerDialog";

/**
 * Reuses the exact `AddPassengerDialog`/`addPassengerAction` New Trip
 * already established (P1-E3-S7) — the same safe, org-scoped
 * `passengers` INSERT, the same dialog markup (work item §14: "reuse/
 * consolidate where appropriate," never a second parallel Add-Passenger
 * implementation). New Trip's own dialog appends the created Passenger
 * to its in-memory form state instead of reloading (so in-progress
 * pickup/destination text is never lost); here, on the standalone
 * Passengers page, there is no such in-progress form to protect, so a
 * real `router.refresh()` is the correct completion — the new row
 * should actually appear in the list.
 */
export function AddPassengerButton() {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  return (
    <>
      <Button type="button" leadingIcon={<Plus className="size-4" aria-hidden />} onClick={() => setOpen(true)}>
        Add Passenger
      </Button>
      {open && (
        <AddPassengerDialog
          onClose={() => setOpen(false)}
          onCreated={() => router.refresh()}
        />
      )}
    </>
  );
}
