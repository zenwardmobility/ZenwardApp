import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getVehiclesList } from "@/lib/operations/vehicles-list";
import { PageHeader } from "@/components/ui/PageHeader";
import { FleetPageClient } from "@/components/operations/fleet/FleetPageClient";

/**
 * The canonical Fleet directory (P1-E3-S8B1, real Create/Edit added
 * P1-E3-S9 — closes GAP-14). Never claims an accessibility capability
 * the schema doesn't model.
 */
export default async function FleetListPage() {
  const pathname = await getCurrentPathname("/operations/fleet");
  const organization = await requireOperationsAccess(pathname);
  const rows = await getVehiclesList(organization.organizationId);

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader title="Fleet" description="Your organization's vehicles and their current assignment." />
      <FleetPageClient rows={rows} />
    </div>
  );
}
