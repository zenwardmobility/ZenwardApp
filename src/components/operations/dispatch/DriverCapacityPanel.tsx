import { Panel } from "@/components/ui/Panel";
import { EmptyState } from "@/components/ui/EmptyState";
import { Avatar } from "@/components/ui/Avatar";
import { StatusBadge } from "@/components/ui/StatusBadge";
import type { DispatchDriverRow } from "@/lib/operations/dispatch-board";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

export interface DriverCapacityPanelProps {
  driverRows: DispatchDriverRow[];
}

/**
 * The right-column "Driver Capacity" rail
 * (docs/design/stitch/references/03-dispatch-board.png) — deliberately
 * narrower than the reference. Only "On Trip" is derivable from real data
 * (an active-state Trip assignment right now); the reference's other
 * status pills (AVAILABLE / BREAK / CONFLICT) all depend on a Driver
 * Availability taxonomy that has no schema representation (GAP-6,
 * ui-backend-gap-register.md) — this phase's own work item explicitly
 * repeats that prohibition (§14) rather than leaving it to prior-phase
 * precedent alone. A Driver with no active-state Trip right now shows no
 * status pill at all — never a fabricated "Available".
 */
export function DriverCapacityPanel({ driverRows }: DriverCapacityPanelProps) {
  return (
    <div className="flex flex-col gap-zw-md">
      <h2 className={cn(typography.subsectionHeading, "text-text-primary")}>Driver Capacity</h2>

      {driverRows.length === 0 ? (
        <Panel>
          <EmptyState title="No active drivers" description="Active drivers in this organization will appear here." />
        </Panel>
      ) : (
        <div className="flex flex-col gap-zw-sm">
          {driverRows.map(({ driver, trips }) => {
            const onTrip = trips.find((trip) => trip.isActiveState);
            return (
              <Panel key={driver.id} className="flex items-center gap-3">
                <Avatar name={driver.displayName} size="sm" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <p className={cn(typography.bodySmall, "truncate font-medium text-text-primary")}>
                      {driver.displayName}
                    </p>
                    {onTrip && <StatusBadge label="On Trip" category="active" />}
                  </div>
                  <p className={cn(typography.metadata, "truncate text-text-muted")}>
                    {onTrip
                      ? `${onTrip.passengerName}${onTrip.vehicleLabel ? ` · ${onTrip.vehicleLabel}` : ""}`
                      : trips.length > 0
                        ? `${trips.length} trip${trips.length === 1 ? "" : "s"} today, none in progress`
                        : "No trips today"}
                  </p>
                </div>
              </Panel>
            );
          })}
        </div>
      )}
    </div>
  );
}
