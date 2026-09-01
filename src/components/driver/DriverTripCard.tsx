import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { TripStatus } from "@/components/ui/TripStatus";

export interface DriverTripCardProps {
  passengerName: string;
  time: string;
  pickup: string;
  destination: string;
  status: string;
  /** e.g. "Appt: 12:30 PM" — omitted entirely when not supplied (P1-E3-S2). */
  appointmentLabel?: string;
  onClick?: () => void;
  className?: string;
}

/**
 * Compact trip block for the driver's Today "Later Today"/Trips list — one
 * trip per tap target. Refined in P1-E3-S2 to match the Stitch reference's
 * denser row treatment (time+name on one line, single arrow-joined route
 * line) — prop shape kept stable so the existing /foundation showcase call
 * site continues to work unchanged (work item §7, avoid unnecessary churn).
 */
export function DriverTripCard({
  passengerName,
  time,
  pickup,
  destination,
  status,
  appointmentLabel,
  onClick,
  className,
}: DriverTripCardProps) {
  const interactive = Boolean(onClick);
  return (
    <div
      role={interactive ? "button" : undefined}
      tabIndex={interactive ? 0 : undefined}
      onClick={onClick}
      onKeyDown={
        interactive
          ? (event) => {
              if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                onClick?.();
              }
            }
          : undefined
      }
      className={cn(
        "flex flex-col gap-1.5 rounded-md border border-border-subtle bg-surface-elevated p-zw-md",
        interactive && "cursor-pointer active:bg-surface-hover",
        className,
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <p className={cn(typography.bodySmall, "text-text-primary")}>
          <span className="font-semibold">{time}</span>
          <span className="mx-1.5 text-text-disabled" aria-hidden>
            |
          </span>
          <span className="font-medium">{passengerName}</span>
        </p>
        <TripStatus status={status} />
      </div>
      <p className={cn(typography.bodySmall, "truncate text-text-secondary")}>
        {pickup} <span aria-hidden>→</span> {destination}
      </p>
      {appointmentLabel && (
        <p className={cn(typography.metadata, "text-text-muted")}>{appointmentLabel}</p>
      )}
    </div>
  );
}
