"use server";

import { revalidatePath } from "next/cache";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface DriverInviteActionState {
  status: "idle" | "success" | "error";
  error?: string;
  invite?: { inviteId: string; email: string; reused: boolean };
}

/**
 * Driver invite (P1-E3-S9, work item §10 — closes GAP-15). A thin
 * wrapper over `create_driver_invite` — the RPC itself is the actual
 * authorization boundary (Organization Admin, own org only) and re-
 * checks it live regardless of what this Server Action's own
 * `requireOperationsAccess` call already confirmed, matching the
 * "re-derive authorization fresh on every mutation" discipline every
 * other action in this codebase already follows.
 */
export async function createDriverInviteAction(
  _prevState: DriverInviteActionState,
  formData: FormData,
): Promise<DriverInviteActionState> {
  const email = formData.get("email");
  const displayName = formData.get("displayName");
  const phone = formData.get("phone");

  if (typeof email !== "string" || email.trim().length === 0 || typeof displayName !== "string" || displayName.trim().length === 0) {
    return { status: "error", error: "Enter a name and email to invite." };
  }

  const pathname = await getCurrentPathname("/operations/drivers");
  const organization = await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.rpc("create_driver_invite", {
    p_organization_id: organization.organizationId,
    p_email: email.trim(),
    p_display_name: displayName.trim(),
    p_phone: typeof phone === "string" && phone.trim().length > 0 ? phone.trim() : undefined,
  });

  if (error || !data || !data.invite_id || !data.email) {
    if (error?.code === "ZW002") {
      return { status: "error", error: "Only an Organization Admin can invite drivers." };
    }
    return { status: "error", error: "Enter a valid name and email address." };
  }

  revalidatePath("/operations/drivers");
  return { status: "success", invite: { inviteId: data.invite_id, email: data.email, reused: data.reused ?? false } };
}

export interface RevokeInviteState {
  status: "idle" | "success" | "error";
}

export async function revokeDriverInviteAction(inviteId: string): Promise<RevokeInviteState> {
  const pathname = await getCurrentPathname("/operations/drivers");
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.rpc("revoke_driver_invite", { p_invite_id: inviteId });

  if (error) {
    return { status: "error" };
  }

  revalidatePath("/operations/drivers");
  return { status: "success" };
}
