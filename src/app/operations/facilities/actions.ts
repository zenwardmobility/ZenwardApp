"use server";

import { revalidatePath } from "next/cache";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface FacilityRecord {
  id: string;
  name: string;
  addressLine1: string | null;
  addressLine2: string | null;
  city: string | null;
  state: string | null;
  postalCode: string | null;
  status: string;
}

export interface FacilityActionState {
  status: "idle" | "success" | "error";
  facility?: FacilityRecord;
}

function stringField(formData: FormData, name: string): string | null {
  const value = formData.get(name);
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : null;
}

function toRecord(row: {
  id: string;
  name: string;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state: string | null;
  postal_code: string | null;
  status: string;
}): FacilityRecord {
  return {
    id: row.id,
    name: row.name,
    addressLine1: row.address_line1,
    addressLine2: row.address_line2,
    city: row.city,
    state: row.state,
    postalCode: row.postal_code,
    status: row.status,
  };
}

const SELECT_COLUMNS = "id, name, address_line1, address_line2, city, state, postal_code, status";

/**
 * Facility create/edit (P1-E3-S9, work item §8 — closes GAP-13). A
 * direct, RLS-protected `facilities` INSERT/UPDATE — `facilities_insert_
 * org_operations`/`_update_org_operations` were already confirmed safe
 * (org+role-scoped) before this phase built anything against them
 * (ui-backend-gap-register.md GAP-13). Facility remains a distinct
 * entity from Organization throughout — this never touches the
 * `organizations` table.
 */
export async function createFacilityAction(
  _prevState: FacilityActionState,
  formData: FormData,
): Promise<FacilityActionState> {
  const name = stringField(formData, "name");
  const addressLine1 = stringField(formData, "addressLine1");
  const addressLine2 = stringField(formData, "addressLine2");
  const city = stringField(formData, "city");
  const state = stringField(formData, "state");
  const postalCode = stringField(formData, "postalCode");

  if (!name) {
    return { status: "error" };
  }

  const pathname = await getCurrentPathname("/operations/facilities");
  const organization = await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("facilities")
    .insert({
      organization_id: organization.organizationId,
      name,
      address_line1: addressLine1,
      address_line2: addressLine2,
      city,
      state,
      postal_code: postalCode,
    })
    .select(SELECT_COLUMNS)
    .single();

  if (error || !data) {
    return { status: "error" };
  }

  revalidatePath("/operations/facilities");
  return { status: "success", facility: toRecord(data) };
}

export async function updateFacilityAction(
  _prevState: FacilityActionState,
  formData: FormData,
): Promise<FacilityActionState> {
  const facilityId = formData.get("facilityId");
  const name = stringField(formData, "name");
  const status = formData.get("status");

  if (typeof facilityId !== "string" || !name) {
    return { status: "error" };
  }
  if (status !== "active" && status !== "inactive") {
    return { status: "error" };
  }

  const pathname = await getCurrentPathname("/operations/facilities");
  await requireOperationsAccess(pathname);

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("facilities")
    .update({
      name,
      address_line1: stringField(formData, "addressLine1"),
      address_line2: stringField(formData, "addressLine2"),
      city: stringField(formData, "city"),
      state: stringField(formData, "state"),
      postal_code: stringField(formData, "postalCode"),
      status,
    })
    .eq("id", facilityId)
    .select(SELECT_COLUMNS)
    .single();

  if (error || !data) {
    return { status: "error" };
  }

  revalidatePath("/operations/facilities");
  return { status: "success", facility: toRecord(data) };
}
