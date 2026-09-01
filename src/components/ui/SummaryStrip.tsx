import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface SummaryItem {
  label: string;
  value: string | number;
  tone?: "default" | "warning" | "critical";
}

export interface SummaryStripProps {
  items: SummaryItem[];
  className?: string;
}

const toneClasses: Record<NonNullable<SummaryItem["tone"]>, string> = {
  default: "text-text-primary",
  warning: "text-warning-text",
  critical: "text-critical-text",
};

/**
 * A row of real operational figures — never decorative KPI cards. Each item
 * is a caller-supplied count (e.g. today's scheduled trips), not a fabricated
 * statistic. No per-item card wrapper; a single divided row instead.
 */
export function SummaryStrip({ items, className }: SummaryStripProps) {
  return (
    <div
      className={cn(
        "flex flex-wrap divide-x divide-border-subtle rounded-md border border-border-subtle bg-surface-elevated",
        className,
      )}
    >
      {items.map((item) => (
        <div key={item.label} className="flex-1 px-zw-lg py-zw-md">
          <p className={cn(typography.sectionHeading, toneClasses[item.tone ?? "default"])}>
            {item.value}
          </p>
          <p className={cn(typography.metadata, "mt-1 text-text-muted")}>{item.label}</p>
        </div>
      ))}
    </div>
  );
}
