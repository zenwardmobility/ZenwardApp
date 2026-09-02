import { IdentificationBadge } from "@phosphor-icons/react/dist/ssr";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getDriversList, type DriversListRow } from "@/lib/operations/drivers-list";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";

/**
 * The canonical Driver directory (P1-E3-S8B1) — replaces the
 * "Structural placeholder" that previously sat here. Read-only — see
 * drivers-list.ts for why "Add Driver" is deliberately not built this
 * phase. Never shows "Available" — only a real current-trip fact
 * ("On [Passenger]'s trip") or nothing, matching the identical
 * restraint DriverCapacityPanel already established on Dispatch
 * (GAP-6, still open).
 */
export default async function DriversListPage() {
  const pathname = await getCurrentPathname("/operations/drivers");
  const organization = await requireOperationsAccess(pathname);
  const rows = await getDriversList(organization.organizationId);

  const columns: DataTableColumn<DriversListRow>[] = [
    { key: "name", header: "Name", primary: true, render: (row) => row.displayName },
    { key: "phone", header: "Phone", render: (row) => row.phone ?? <span className="text-text-muted">Not on file</span> },
    {
      key: "current",
      header: "Current Trip",
      render: (row) =>
        row.currentTripPassengerName ? (
          <StatusBadge label={`On ${row.currentTripPassengerName}'s trip`} category="active" />
        ) : (
          <span className="text-text-muted">No active trip</span>
        ),
    },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge label={row.status === "active" ? "Active" : "Inactive"} category={row.status === "active" ? "positive" : "neutral"} />,
    },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader title="Drivers" description="Your organization's drivers and their current trip status." />

      <DataTable
        columns={columns}
        rows={rows}
        getRowId={(row) => row.id}
        emptyState={
          <EmptyState icon={<IdentificationBadge className="size-8" aria-hidden />} title="No drivers yet" description="Drivers on your team will appear here." />
        }
      />
    </div>
  );
}
