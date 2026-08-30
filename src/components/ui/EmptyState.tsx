import type { ReactNode } from "react";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

/**
 * A real explanation of why a list/table is empty, and where relevant, the
 * next action to take — never a bare "No data".
 */
export function EmptyState({ icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center gap-3 px-lg py-3xl text-center", className)}>
      {icon && (
        <div className="text-text-disabled" aria-hidden>
          {icon}
        </div>
      )}
      <div>
        <p className={cn(typography.subsectionHeading, "text-text-primary")}>{title}</p>
        {description && (
          <p className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}
