import type { ReactNode } from "react";
import { WarningCircle, WarningOctagon, Info } from "@phosphor-icons/react/dist/ssr";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface AttentionStateProps {
  level?: "warning" | "critical" | "info";
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

const levelStyles = {
  warning: {
    container: "border-warning-border bg-warning-bg",
    icon: "text-warning-strong",
    IconComponent: WarningCircle,
  },
  critical: {
    container: "border-critical-border bg-critical-bg",
    icon: "text-critical-strong",
    IconComponent: WarningOctagon,
  },
  /** Calm, non-alarming variant (P1-E3-S7) — for a genuine forward-looking note that isn't a problem (e.g. "you'll assign a Driver after creating this trip"), distinct from warning/critical, which both imply something needs fixing. Uses the existing `--color-info-*` tokens (globals.css), already defined for `StatusBadge`'s `informational` category but unused here until now. */
  info: {
    container: "border-info-border bg-info-bg",
    icon: "text-info-strong",
    IconComponent: Info,
  },
} as const;

/**
 * Inline banner for something that needs a person's attention (a required
 * assignment, an exception) — distinct from EmptyState, which is neutral.
 */
export function AttentionState({
  level = "warning",
  title,
  description,
  action,
  className,
}: AttentionStateProps) {
  const styles = levelStyles[level];
  const Icon = styles.IconComponent;

  return (
    <div
      role="status"
      className={cn(
        "flex items-start gap-3 rounded-md border px-zw-lg py-zw-md",
        styles.container,
        className,
      )}
    >
      <Icon className={cn("mt-0.5 size-5 shrink-0", styles.icon)} weight="fill" aria-hidden />
      <div className="flex-1">
        <p className={cn(typography.subsectionHeading, "text-text-primary")}>{title}</p>
        {description && (
          <p className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}
