import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface DriverRouteProps {
  pickup: string;
  destination: string;
  className?: string;
}

/** Two-point pickup → destination indicator (dot – line – dot), the standard trip-route glance pattern. */
export function DriverRoute({ pickup, destination, className }: DriverRouteProps) {
  return (
    <div className={cn("flex gap-3", className)}>
      <div className="flex flex-col items-center pt-1">
        <span className="size-2.5 shrink-0 rounded-full bg-brand-interactive-teal" aria-hidden />
        <span className="w-px flex-1 bg-border-strong" aria-hidden />
        <span className="size-2.5 shrink-0 rounded-full bg-brand-care-navy" aria-hidden />
      </div>
      <div className="flex flex-1 flex-col justify-between gap-4 py-0.5">
        <div>
          <p className={cn(typography.metadata, "text-text-muted")}>Pickup</p>
          <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{pickup}</p>
        </div>
        <div>
          <p className={cn(typography.metadata, "text-text-muted")}>Destination</p>
          <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{destination}</p>
        </div>
      </div>
    </div>
  );
}
