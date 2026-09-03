"use server";

import { revalidatePath } from "next/cache";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface PassengerActionState {
  status: "idle" | "success" | "error";
  passenger?: { id: string; displayName: string; phone: string | null; status: string; assistanceNotes: string | null };
}

/**
 * Passenger edit/deactivate (P1-E3-S9, work item §9 — closes GAP-12). A
 * direct, RLS-protected `passengers` UPDATE — `passengers_update_org_
 * operations`'s narrowed column grant (display_name/phone/assistance_
 * notes/status only) was already confirmed safe before this phase built
 * anything against it (ui-backend-gap-register.md GAP-12). Deactivate is
 * the same action with `status` set to `inactive` — never a hard DELETE
 * (authorization-model.md §S: history matters more than tidiness).
 * Preserves minimum-necessary handling: no new medical/diagnosis field is
 * introduced — `assistance_notes` is the exact same free-text mobility/
 * assistance field every other Passenger surface already uses.
 */
export async function updatePassengerAction(
  _prevState: PassengerActionState,
  formData: FormData,
): Promise<PassengerActionState> {
  const passengerId = formData.get("passengerId");
  const displayName = formData.get("displayName");
  const phone = formData.get("phone");
  const assistanceNotes = formData.get("assistanceNotes");
  const status = formData.get("status");

  if (typeof passengerId !== "string" || typeof displayName !== "string" || displayName.trim().length === 0) {
    return { status: "error" };
  }
  if (status !== "active" && status !== "inactive") {
    return { status: "error" };
  }

  const pathname = await getCurrentPathname("/operations/passengers");
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("passengers")
    .update({
      display_name: displayName.trim(),
      phone: typeof phone === "string" && phone.trim().length > 0 ? phone.trim() : null,
      assistance_notes: typeof assistanceNotes === "string" && assistanceNotes.trim().length > 0 ? assistanceNotes.trim() : null,
      status,
    })
    .eq("id", passengerId)
    .select("id, display_name, phone, status, assistance_notes")
    .single();

  if (error || !data) {
    return { status: "error" };
  }

  revalidatePath("/operations/passengers");
  return {
    status: "success",
    passenger: {
      id: data.id,
      displayName: data.display_name,
      phone: data.phone,
      status: data.status,
      assistanceNotes: data.assistance_notes,
    },
  };
}
