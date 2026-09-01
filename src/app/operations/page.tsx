import Link from "next/link";
import { WarningCircle, ArrowRight } from "@phosphor-icons/react/dist/ssr";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getTodaysOperations, type TodaysOperationsTrip } from "@/lib/operations/todays-operations";
import { formatOperationsTime } from "@/lib/operations/presentation";
import { SummaryStrip } from "@/components/ui/SummaryStrip";
import { Panel } from "@/components/ui/Panel";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { DataTable, type DataTableColumn } from "@/components/ui/DataTable";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { TripStatus } from "@/components/ui/TripStatus";
import { LinkButton } from "@/components/ui/LinkButton";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

/**
 * Today's Operations (P1-E3-S4) —
 * docs/design/stitch/references/01-todays-operations.png, treated as the
 * canonical visual specification (work item §1). Deliberately omits the
 * reference's "Driver Availability" panel entirely (GAP-6,
 * ui-backend-gap-register.md — no schema concept exists for
 * Available/Break/Unavailable) and narrows "Needs Attention" to
 * Needs-Assignment rows only (Running Late/Pending Confirmation have no
 * defined product rule — see ui-backend-gap-register.md "PRODUCT DECISIONS
 * REQUIRED"). See docs/product/todays-operations-data-map.md for the full
 * field-level rationale behind every value and every omission on this page.
 */
export default async function OperationsOverviewPage() {
  const pathname = await getCurrentPathname("/operations");
  const organization = await requireOperationsAccess(pathname);
  const data = await getTodaysOperations(organization.organizationId, organization.organizationTimezone);
  const timezone = organization.organizationTimezone;

  const needsAttentionColumns: DataTableColumn<TodaysOperationsTrip>[] = [
    { key: "time", header: "Time", render: (row) => formatOperationsTime(row.scheduledPickupAt, timezone) },
    { key: "passenger", header: "Passenger", primary: true, render: (row) => row.passengerName },
    {
      key: "route",
      header: "Route",
      render: (row) => (
        <span className="text-text-secondary">
          {row.pickupDescription} <ArrowRight className="inline size-3" aria-hidden /> {row.destinationDescription}
        </span>
      ),
    },
    { key: "issue", header: "Issue", render: () => <TripStatus status="Needs Assignment" /> },
    {
      key: "action",
      header: "Action",
      align: "right",
      render: () => (
        <LinkButton href="/operations/dispatch" variant="outline" size="sm">
          Assign
        </LinkButton>
      ),
    },
  ];

  const upcomingColumns: DataTableColumn<TodaysOperationsTrip>[] = [
    { key: "time", header: "Time", render: (row) => formatOperationsTime(row.scheduledPickupAt, timezone) },
    { key: "passenger", header: "Passenger", primary: true, render: (row) => row.passengerName },
    { key: "pickup", header: "Pickup", render: (row) => row.pickupDescription },
    { key: "destination", header: "Destination", render: (row) => row.destinationDescription },
    { key: "driver", header: "Driver", render: (row) => row.driverName ?? "––" },
    { key: "vehicle", header: "Vehicle", render: (row) => row.vehicleLabel ?? "––" },
    { key: "status", header: "Status", render: (row) => <TripStatus status={row.statusLabel} /> },
  ];

  return (
    <div className="flex flex-col gap-zw-lg">
      <SummaryStrip
        inline
        items={[
          { label: "trips today", value: data.summary.todayCount },
          { label: "active", value: data.summary.activeCount, dot: true },
          { label: "need attention", value: data.summary.needsAssignmentCount, tone: "warning", dot: true },
          { label: "completed", value: data.summary.completedTodayCount, dot: true },
        ]}
      />

      <div className="grid grid-cols-1 gap-zw-lg lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="flex flex-col gap-zw-lg">
          <Panel className="p-0">
            <div className="flex items-start justify-between gap-4 p-zw-lg pb-0">
              <div className="flex items-center gap-2">
                <WarningCircle className="size-5 text-warning-strong" weight="fill" aria-hidden />
                <h2 className={cn(typography.subsectionHeading, "text-text-primary")}>Needs Attention</h2>
              </div>
              {data.needsAssignmentTrips.length > 0 && (
                <StatusBadge
                  label={`${data.needsAssignmentTrips.length} ${data.needsAssignmentTrips.length === 1 ? "Issue" : "Issues"}`}
                  category="warning"
                />
              )}
            </div>
            <div className="p-zw-lg">
              {data.needsAssignmentTrips.length === 0 ? (
                <EmptyState title="Nothing needs attention" description="Every trip scheduled today already has a driver assigned." />
              ) : (
                <DataTable columns={needsAttentionColumns} rows={data.needsAssignmentTrips} getRowId={(row) => row.id} />
              )}
            </div>
          </Panel>

          <Panel className="p-0">
            <div className="p-zw-lg pb-0">
              <SectionHeader title="Upcoming Trips" />
            </div>
            <div className="p-zw-lg">
              {data.todayTrips.length === 0 ? (
                <EmptyState title="No trips scheduled today" description="Trips scheduled for today will appear here." />
              ) : (
                <DataTable columns={upcomingColumns} rows={data.todayTrips} getRowId={(row) => row.id} />
              )}
            </div>
            <div className="border-t border-border-subtle p-zw-md text-center">
              <Link
                href="/operations/trips"
                className={cn(typography.bodySmall, "inline-flex items-center gap-1 font-medium text-brand-interactive-teal hover:underline")}
              >
                View all trips <ArrowRight className="size-4" aria-hidden />
              </Link>
            </div>
          </Panel>
        </div>

        <div className="flex flex-col gap-zw-lg">
          <Panel>
            <SectionHeader
              title="Active Trips"
              actions={
                data.activeTrips.length > 0 ? (
                  <span className={cn(typography.metadata, "text-text-muted")}>{data.activeTrips.length} in progress</span>
                ) : undefined
              }
            />
            <div className="mt-zw-md">
              {data.activeTrips.length === 0 ? (
                <EmptyState title="Nothing in progress" description="Trips currently underway will appear here." />
              ) : (
                <ul className="divide-y divide-border-subtle">
                  {data.activeTrips.map((trip) => (
                    <li key={trip.id} className="flex items-center justify-between gap-3 py-zw-sm first:pt-0 last:pb-0">
                      <div className="flex items-center gap-2">
                        <span className="size-2 shrink-0 rounded-full bg-brand-interactive-teal" aria-hidden />
                        <div>
                          <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{trip.passengerName}</p>
                          <p className={cn(typography.metadata, "text-text-muted")}>
                            {trip.driverName ?? "Unassigned"}
                            {trip.vehicleLabel ? ` • ${trip.vehicleLabel}` : ""}
                          </p>
                        </div>
                      </div>
                      <span className={cn(typography.bodySmall, "shrink-0 font-medium text-brand-interactive-teal")}>
                        {trip.statusLabel}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </Panel>

          <Panel>
            <SectionHeader title="Activity Log" />
            <div className="mt-zw-md">
              {data.activityLog.length === 0 ? (
                <EmptyState title="No activity yet today" description="Trip updates will appear here as they happen." />
              ) : (
                <ul className="divide-y divide-border-subtle">
                  {data.activityLog.map((event) => (
                    <li key={event.id} className="flex items-start justify-between gap-3 py-zw-sm first:pt-0 last:pb-0">
                      <div className="flex items-start gap-2">
                        <span className="mt-1.5 size-2 shrink-0 rounded-full bg-text-muted" aria-hidden />
                        <div>
                          <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{event.label}</p>
                          {event.passengerName && (
                            <p className={cn(typography.metadata, "text-text-muted")}>{event.passengerName}</p>
                          )}
                        </div>
                      </div>
                      <span className={cn(typography.metadata, "shrink-0 text-text-muted")}>
                        {formatOperationsTime(event.occurredAt, timezone)}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </Panel>
        </div>
      </div>
    </div>
  );
}
