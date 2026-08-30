import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { TripStatus } from "@/components/ui/TripStatus";

export interface DriverTripCardProps {
  passengerName: string;
  time: string;
  pickup: string;
  destination: string;
  status: string;
  onClick?: () => void;
  className?: string;
}

/**
 * Richer trip block for the driver's Today/Trips list — one trip per tap
 * target, large enough to read at a glance while parked or between stops.
 */
export function DriverTripCard({
  passengerName,
  time,
  pickup,
  destination,
  status,
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
        "flex flex-col gap-2 rounded-md border border-border-subtle bg-surface-elevated p-md",
        interactive && "cursor-pointer active:bg-surface-hover",
        className,
      )}
    >
      <div className="flex items-center justify-between gap-2">
        <p className={cn(typography.subsectionHeading, "text-text-primary")}>{time}</p>
        <TripStatus status={status} />
      </div>
      <p className={cn(typography.body, "font-medium text-text-primary")}>{passengerName}</p>
      <div className={cn(typography.bodySmall, "text-text-secondary")}>
        <p className="truncate">From: {pickup}</p>
        <p className="truncate">To: {destination}</p>
      </div>
    </div>
  );
}
