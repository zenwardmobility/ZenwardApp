import type { ReactNode } from "react";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface DriverHeaderProps {
  title: string;
  leading?: ReactNode;
  trailing?: ReactNode;
}

/** Simple top bar for the driver PWA — a title plus optional back/action controls. */
export function DriverHeader({ title, leading, trailing }: DriverHeaderProps) {
  return (
    <header className="flex h-14 shrink-0 items-center justify-between border-b border-border-subtle bg-surface-elevated px-4">
      <div className="flex items-center gap-2">
        {leading}
        <h1 className={cn(typography.pageTitleOperational, "text-xl text-text-primary")}>{title}</h1>
      </div>
      {trailing}
    </header>
  );
}
