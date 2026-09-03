"use client";

import { useState } from "react";
import { Car, Plus } from "@phosphor-icons/react/dist/ssr";
import { Button } from "@/components/ui/Button";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { VehicleFormDialog } from "./VehicleFormDialog";
import type { VehiclesListRow } from "@/lib/operations/vehicles-list";

export interface FleetPageClientProps {
  rows: VehiclesListRow[];
}

/**
 * Client wrapper for Fleet's own Add/Edit affordances (P1-E3-S9, work
 * item §7 — closes GAP-14). The list itself stays server-rendered
 * (`getVehiclesList`, unchanged) — only the interactive "Add Vehicle"
 * button and click-a-row-to-edit dialog live here.
 */
export function FleetPageClient({ rows }: FleetPageClientProps) {
  const [dialog, setDialog] = useState<{ mode: "create" } | { mode: "edit"; vehicle: { id: string; label: string; status: string } } | null>(null);

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
      render: (row) => (
        <StatusBadge label={row.status === "active" ? "Active" : "Inactive"} category={row.status === "active" ? "positive" : "neutral"} />
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <div className="flex justify-end">
        <Button type="button" leadingIcon={<Plus className="size-4" aria-hidden />} onClick={() => setDialog({ mode: "create" })}>
          Add Vehicle
        </Button>
      </div>

      <DataTable
        columns={columns}
        rows={rows}
        getRowId={(row) => row.id}
        onRowClick={(row) => setDialog({ mode: "edit", vehicle: { id: row.id, label: row.label, status: row.status } })}
        emptyState={
          <EmptyState icon={<Car className="size-8" aria-hidden />} title="No vehicles yet" description="Vehicles in your fleet will appear here." />
        }
      />

      {dialog?.mode === "create" && <VehicleFormDialog mode="create" onClose={() => setDialog(null)} />}
      {dialog?.mode === "edit" && <VehicleFormDialog mode="edit" vehicle={dialog.vehicle} onClose={() => setDialog(null)} />}
    </div>
  );
}
