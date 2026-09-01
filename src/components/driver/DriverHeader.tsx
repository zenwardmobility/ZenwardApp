import type { ReactNode } from "react";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface DriverHeaderProps {
  title: string;
  /** Real driver identity (driver_get_profile.display_name), shown as a compact subtitle under the title — never a fabricated "On Shift" status (work item §14/§27). */
  driverName?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
}

/**
 * Compact top bar for the driver PWA — brand/screen context plus optional
 * leading (back button / avatar) and trailing (account affordance)
 * controls. Refined in P1-E3-S2 to carry real driver identity and respect
 * a notched device's top safe-area inset (work item §44) — deliberately
 * still compact, not the Operations desktop header (work item §27).
 */
export function DriverHeader({ title, driverName, leading, trailing }: DriverHeaderProps) {
  return (
    <header
      className="flex shrink-0 items-center justify-between gap-2 border-b border-border-subtle bg-surface-elevated px-4 pb-2"
      style={{ paddingTop: "max(0.5rem, env(safe-area-inset-top))" }}
    >
      <div className="flex min-w-0 items-center gap-2.5">
        {leading}
        <div className="min-w-0">
          <h1 className={cn(typography.pageTitleOperational, "truncate text-xl text-text-primary")}>
            {title}
          </h1>
          {driverName && (
            <p className={cn(typography.metadata, "truncate text-text-muted")}>{driverName}</p>
          )}
        </div>
      </div>
      {trailing}
    </header>
  );
}
