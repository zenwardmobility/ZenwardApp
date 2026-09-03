"use server";

import { revalidatePath } from "next/cache";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface VehicleActionState {
  status: "idle" | "success" | "error";
  vehicle?: { id: string; label: string; status: string };
}

/**
 * Vehicle create/edit (P1-E3-S9, work item §7 — closes GAP-14). A direct,
 * RLS-protected `vehicles` INSERT/UPDATE, not an RPC — `vehicles_insert_
 * org_admin`/`_update_org_admin` were already confirmed safe (org+role-
 * scoped, and the only mutable columns are `label`/`status`) before this
 * phase built anything against them (ui-backend-gap-register.md GAP-14).
 * Only real schema fields — never a fabricated wheelchair/stretcher/
 * ambulatory capability column (work item §7's own explicit prohibition;
 * `vehicles` genuinely has no such columns).
 */
export async function createVehicleAction(
  _prevState: VehicleActionState,
  formData: FormData,
): Promise<VehicleActionState> {
  const label = formData.get("label");
  if (typeof label !== "string" || label.trim().length === 0) {
    return { status: "error" };
  }

  const pathname = await getCurrentPathname("/operations/fleet");
  const organization = await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("vehicles")
    .insert({ organization_id: organization.organizationId, label: label.trim() })
    .select("id, label, status")
    .single();

  if (error || !data) {
    return { status: "error" };
  }

  revalidatePath("/operations/fleet");
  return { status: "success", vehicle: data };
}

export async function updateVehicleAction(
  _prevState: VehicleActionState,
  formData: FormData,
): Promise<VehicleActionState> {
  const vehicleId = formData.get("vehicleId");
  const label = formData.get("label");
  const status = formData.get("status");

  if (typeof vehicleId !== "string" || typeof label !== "string" || label.trim().length === 0) {
    return { status: "error" };
  }
  if (status !== "active" && status !== "inactive") {
    return { status: "error" };
  }

  const pathname = await getCurrentPathname("/operations/fleet");
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("vehicles")
    .update({ label: label.trim(), status })
    .eq("id", vehicleId)
    .select("id, label, status")
    .single();

  if (error || !data) {
    return { status: "error" };
  }

  revalidatePath("/operations/fleet");
  return { status: "success", vehicle: data };
}
