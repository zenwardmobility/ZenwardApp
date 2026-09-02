import { Car } from "@phosphor-icons/react/dist/ssr";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getVehiclesList, type VehiclesListRow } from "@/lib/operations/vehicles-list";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";

/**
 * The canonical Fleet directory (P1-E3-S8B1) — replaces the "Structural
 * placeholder" that previously sat here. Read-only — see
 * vehicles-list.ts for the mutation-deferral reasoning. Never claims an
 * accessibility capability the schema doesn't model.
 */
export default async function FleetListPage() {
  const pathname = await getCurrentPathname("/operations/fleet");
  const organization = await requireOperationsAccess(pathname);
  const rows = await getVehiclesList(organization.organizationId);

  const columns: DataTableColumn<VehiclesListRow>[] = [
    { key: "label", header: "Vehicle", primary: true, render: (row) => row.label },
    {
      key: "current",
      header: "Current Driver",
      render: (row) => row.currentDriverName ?? <span className="text-text-muted">Unassigned</span>,
    },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge label={row.status === "active" ? "Active" : "Inactive"} category={row.status === "active" ? "positive" : "neutral"} />,
    },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader title="Fleet" description="Your organization's vehicles and their current assignment." />

      <DataTable
        columns={columns}
        rows={rows}
        getRowId={(row) => row.id}
        emptyState={<EmptyState icon={<Car className="size-8" aria-hidden />} title="No vehicles yet" description="Vehicles in your fleet will appear here." />}
      />
    </div>
  );
}
