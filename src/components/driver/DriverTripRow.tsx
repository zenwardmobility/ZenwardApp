import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { TripStatus } from "@/components/ui/TripStatus";

export interface DriverTripRowProps {
  passengerName: string;
  time: string;
  status: string;
  onClick?: () => void;
  className?: string;
}

/** Condensed single-line trip entry — for History, where density matters more than glance-detail. */
export function DriverTripRow({ passengerName, time, status, onClick, className }: DriverTripRowProps) {
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
        "flex items-center justify-between gap-3 border-b border-border-subtle px-1 py-3 last:border-b-0",
        interactive && "cursor-pointer active:bg-surface-hover",
        className,
      )}
    >
      <div className="min-w-0">
        <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{passengerName}</p>
        <p className={cn(typography.metadata, "text-text-muted")}>{time}</p>
      </div>
      <TripStatus status={status} />
    </div>
  );
}
