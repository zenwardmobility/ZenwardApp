import type { ReactNode } from "react";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface SectionHeaderProps {
  title: string;
  description?: string;
  actions?: ReactNode;
  className?: string;
}

/**
 * Separates a section of content via typography and spacing, not a card.
 * Use inside a Panel, or directly on a page between grouped content.
 */
export function SectionHeader({ title, description, actions, className }: SectionHeaderProps) {
  return (
    <div className={cn("flex items-start justify-between gap-4", className)}>
      <div>
        <h2 className={cn(typography.subsectionHeading, "text-text-primary")}>{title}</h2>
        {description && (
          <p className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>{description}</p>
        )}
      </div>
      {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
    </div>
  );
}
