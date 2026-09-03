"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Dialog } from "@/components/ui/Dialog";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { createDriverInviteAction, type DriverInviteActionState } from "@/app/operations/drivers/actions";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: DriverInviteActionState = { status: "idle" };

export interface InviteDriverDialogProps {
  onClose: () => void;
}

/**
 * Invite Driver (P1-E3-S9, work item §10 — closes GAP-15). Creates a
 * `driver_invites` row only — never an auth user, never a Membership,
 * never a Driver row directly. The invitee signs up (or signs in) with
 * this exact email and redeems the link themselves
 * (docs/product/driver-invite-linkage-model.md).
 */
export function InviteDriverDialog({ onClose }: InviteDriverDialogProps) {
  const [state, formAction, pending] = useActionState(createDriverInviteAction, INITIAL_STATE);
  const router = useRouter();

  useEffect(() => {
    if (state.status === "success") {
      router.refresh();
    }
  }, [state, router]);

  if (state.status === "success" && state.invite) {
    return (
      <Dialog open onClose={onClose} title="Invite sent">
        <div className="flex flex-col gap-zw-md">
          <p className={cn(typography.body, "text-text-primary")}>
            {state.invite.reused ? "Refreshed the existing invite for" : "Invited"} <strong>{state.invite.email}</strong> to
            join as a driver.
          </p>
          <p className={cn(typography.bodySmall, "text-text-secondary")}>
            They&apos;ll sign up (or sign in) with this exact email address, then follow the invite link to complete
            setup.
          </p>
          <div className="flex justify-end pt-zw-sm">
            <Button type="button" onClick={onClose}>
              Done
            </Button>
          </div>
        </div>
      </Dialog>
    );
  }

  return (
    <Dialog open onClose={onClose} title="Invite Driver" description="They'll receive access to sign up and start receiving trips.">
      <form action={formAction} className="flex flex-col gap-zw-md">
        <Input label="Full Name" name="displayName" required placeholder="e.g. Leon Whitfield" disabled={pending} />
        <Input label="Email" name="email" type="email" required placeholder="e.g. leon@example.com" disabled={pending} />
        <Input label="Phone" name="phone" type="tel" disabled={pending} />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {state.error}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-zw-sm">
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Cancel
          </Button>
          <Button type="submit" loading={pending} disabled={pending}>
            {pending ? "Sending…" : "Send Invite"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
