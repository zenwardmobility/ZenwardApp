import type { HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface PanelProps extends HTMLAttributes<HTMLDivElement> {
  /** Adds shadow-sm. Panels default to no shadow — hierarchy should come from borders/spacing first. */
  elevated?: boolean;
  children: ReactNode;
}

/**
 * Standard operational panel: white background, subtle border, ~10px
 * radius, little/no shadow. Not every grouping needs to be a Panel — see
 * the card rule in interface-principles.md §1 before reaching for this.
 */
export function Panel({ elevated = false, className, children, ...props }: PanelProps) {
  return (
    <div
      className={cn(
        "rounded-md border border-border-subtle bg-surface-elevated p-lg",
        elevated && "shadow-sm",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}
