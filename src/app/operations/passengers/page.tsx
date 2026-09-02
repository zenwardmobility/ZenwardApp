import { UsersThree } from "@phosphor-icons/react/dist/ssr";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getPassengersList } from "@/lib/operations/passengers-list";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { SearchInput } from "@/components/ui/SearchInput";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { AddPassengerButton } from "@/components/operations/passengers/AddPassengerButton";
import type { PassengersListRow } from "@/lib/operations/passengers-list";

/**
 * The canonical Passenger directory (P1-E3-S8B1) — replaces the
 * "Structural placeholder" that previously sat here. Read-only beyond
 * Add (work item §14/§15): the existing narrow, safe `passengers`
 * UPDATE grant (display_name/phone/assistance_notes/status only) could
 * support an edit flow, but a list/detail-read screen is judged
 * sufficient for pilot operations this phase — see
 * docs/product/operations-surface-map.md for the explicit decision, not
 * a silently-dropped capability. No assistance/medical text is shown
 * here — that stays scoped to Trip Detail's own "Passenger & Trip
 * Information" panel, where it is operationally relevant to one
 * specific Trip, not browsed as a directory field.
 */
export default async function PassengersListPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const pathname = await getCurrentPathname("/operations/passengers");
  const organization = await requireOperationsAccess(pathname);
  const params = await searchParams;
  const search = typeof params.q === "string" ? params.q : "";

  const result = await getPassengersList(organization.organizationId, search);

  const columns: DataTableColumn<PassengersListRow>[] = [
    { key: "name", header: "Name", primary: true, render: (row) => row.displayName },
    { key: "phone", header: "Phone", render: (row) => row.phone ?? <span className="text-text-muted">Not on file</span> },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge label={row.status === "active" ? "Active" : "Inactive"} category={row.status === "active" ? "positive" : "neutral"} />,
    },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader
        title="Passengers"
        description="The people whose transportation your team coordinates."
        actions={<AddPassengerButton />}
      />

      <form method="get" className="max-w-md">
        <SearchInput name="q" label="Search passengers" placeholder="Search by name or phone" defaultValue={search} />
        <Button type="submit" className="sr-only">
          Search
        </Button>
      </form>

      <DataTable
        columns={columns}
        rows={result.rows}
        getRowId={(row) => row.id}
        emptyState={
          <EmptyState
            icon={<UsersThree className="size-8" aria-hidden />}
            title={search ? "No passengers match that search" : "No passengers yet"}
            description={search ? "Try a different name or phone number." : "Passengers you add will appear here."}
          />
        }
      />
    </div>
  );
}
