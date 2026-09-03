import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface OnboardingChecklistItem {
  key: "business" | "vehicle" | "driver" | "facility" | "passenger" | "trip";
  label: string;
  complete: boolean;
  href: string;
}

export interface OnboardingChecklist {
  items: OnboardingChecklistItem[];
  completedCount: number;
  totalCount: number;
  /** True once every item is complete — the checklist stops rendering at this point (work item §11: "visible until the business is operational"). */
  isComplete: boolean;
}

/**
 * Real, derived onboarding completion (P1-E3-S9, work item §11) — every
 * item is a genuine count against real tenant data, never a persisted
 * "X% complete" field that could drift from reality. "Business profile"
 * is the one item that's always true by the time this ever renders (an
 * Organization exists — you can't reach /operations without one), kept
 * in the list anyway so the checklist reads as a complete, honest picture
 * of the whole setup journey rather than silently skipping its own first
 * step.
 */
export async function getOnboardingChecklist(organizationId: string): Promise<OnboardingChecklist> {
  const supabase = await createServerSupabaseClient();

  const [vehicles, drivers, facilities, passengers, trips] = await Promise.all([
    supabase.from("vehicles").select("id", { count: "exact", head: true }).eq("organization_id", organizationId),
    supabase
      .from("drivers")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", organizationId)
      .eq("status", "active"),
    supabase.from("facilities").select("id", { count: "exact", head: true }).eq("organization_id", organizationId),
    supabase.from("passengers").select("id", { count: "exact", head: true }).eq("organization_id", organizationId),
    supabase.from("trips").select("id", { count: "exact", head: true }).eq("organization_id", organizationId),
  ]);

  const items: OnboardingChecklistItem[] = [
    { key: "business", label: "Business profile", complete: true, href: "/onboarding/basics" },
    { key: "vehicle", label: "First vehicle", complete: (vehicles.count ?? 0) > 0, href: "/onboarding/vehicle" },
    { key: "driver", label: "Driver setup", complete: (drivers.count ?? 0) > 0, href: "/onboarding/driver" },
    { key: "facility", label: "First facility", complete: (facilities.count ?? 0) > 0, href: "/onboarding/facility" },
    { key: "passenger", label: "First passenger", complete: (passengers.count ?? 0) > 0, href: "/onboarding/passenger" },
    { key: "trip", label: "First trip", complete: (trips.count ?? 0) > 0, href: "/operations/trips/new" },
  ];

  const completedCount = items.filter((item) => item.complete).length;

  return {
    items,
    completedCount,
    totalCount: items.length,
    isComplete: completedCount === items.length,
  };
}
