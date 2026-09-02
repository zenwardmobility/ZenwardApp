import { Panel } from "@/components/ui/Panel";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatOperationsTime, humanizeExceptionType } from "@/lib/operations/presentation";
import type { TripDetailException } from "@/lib/operations/trip-detail";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

export interface TripExceptionsPanelProps {
  openExceptions: TripDetailException[];
  timezone: string;
}

/**
 * "Trip Exceptions" (docs/design/stitch/references/02-trip-detail.png) —
 * real open `trip_exceptions` rows only, never manufactured from
 * lateness/GPS/time thresholds (work item §34 — no such derivation
 * exists anywhere in this codebase). "Report Issue" is rendered, real,
 * and disabled — creating a new exception-reporting surface (and its own
 * resolve workflow) is a deliberate deferral matching the exact
 * reasoning already established for the Driver-side "Report Issue"
 * button (ZD-125, P1-E3-S3): a new write surface disproportionate to
 * this phase's primary mandate, not something the reference or work item
 * explicitly required building this phase (work item §35 gates only
 * RESOLVING on an existing safe path — it does not mandate the CREATE
 * action either).
 */
export function TripExceptionsPanel({ openExceptions, timezone }: TripExceptionsPanelProps) {
  return (
    <Panel>
      <h3 className={cn(typography.subsectionHeading, "text-text-primary")}>Trip Exceptions</h3>
      <div className="mt-zw-md">
        {openExceptions.length === 0 ? (
          <EmptyState title="No open exceptions" />
        ) : (
          <ul className="flex flex-col gap-zw-sm">
            {openExceptions.map((exception) => (
              <li key={exception.id} className="rounded-sm border border-warning-border bg-warning-bg px-zw-md py-zw-sm">
                <div className="flex items-center justify-between gap-2">
                  <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>
                    {exception.exceptionType ? humanizeExceptionType(exception.exceptionType) : "Exception"}
                  </p>
                  <span className={cn(typography.metadata, "shrink-0 text-text-muted")}>
                    {formatOperationsTime(exception.createdAt, timezone)}
                  </span>
                </div>
                {exception.description && (
                  <p className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>{exception.description}</p>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
      <Button
        variant="outline"
        className="mt-zw-md w-full"
        disabled
        title="Reporting a new issue from Operations is not available yet."
      >
        Report Issue
      </Button>
    </Panel>
  );
}
