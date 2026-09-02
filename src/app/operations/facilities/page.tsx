import { Buildings } from "@phosphor-icons/react/dist/ssr";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getFacilitiesList, type FacilitiesListRow } from "@/lib/operations/facilities-list";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";

/**
 * The canonical Facility directory (P1-E3-S8B1) — replaces the
 * "Structural placeholder" that previously sat here. Read-only this
 * phase — see facilities-list.ts for the mutation-deferral reasoning.
 * Facility is not Organization: this list is the operator's own
 * referring clinics/dialysis centers/etc., scoped to their tenant only,
 * never the Zenward organization itself.
 */
export default async function FacilitiesListPage() {
  const pathname = await getCurrentPathname("/operations/facilities");
  const organization = await requireOperationsAccess(pathname);
  const rows = await getFacilitiesList(organization.organizationId);

  const columns: DataTableColumn<FacilitiesListRow>[] = [
    { key: "name", header: "Name", primary: true, render: (row) => row.name },
    {
      key: "location",
      header: "Location",
      render: (row) => [row.city, row.state].filter(Boolean).join(", ") || <span className="text-text-muted">Not on file</span>,
    },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge label={row.status === "active" ? "Active" : "Inactive"} category={row.status === "active" ? "positive" : "neutral"} />,
    },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader title="Facilities" description="Clinics and other referring locations your trips connect to." />

      <DataTable
        columns={columns}
        rows={rows}
        getRowId={(row) => row.id}
        emptyState={
          <EmptyState
            icon={<Buildings className="size-8" aria-hidden />}
            title="No facilities yet"
            description="Facilities linked to your trips will appear here."
          />
        }
      />
    </div>
  );
}
