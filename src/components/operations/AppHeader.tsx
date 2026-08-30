import type { ReactNode } from "react";
import { Bell } from "@phosphor-icons/react/dist/ssr";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { IconButton } from "@/components/ui/IconButton";

export interface AppHeaderProps {
  /** Short current-context label (e.g. the active nav section) — page-level titles belong in PageHeader. */
  contextLabel?: string;
  actions?: ReactNode;
}

/**
 * Persistent chrome header, always visible above PageContent. Distinct from
 * PageHeader, which lives inside the scrollable content area per page.
 */
export function AppHeader({ contextLabel, actions }: AppHeaderProps) {
  return (
    <header className="flex h-16 items-center justify-between border-b border-border-subtle bg-surface-elevated px-4 lg:px-6">
      <p className={cn(typography.bodySmall, "font-medium text-text-secondary")}>{contextLabel}</p>
      <div className="flex items-center gap-2">
        {actions}
        <IconButton label="Notifications" icon={<Bell className="size-5" aria-hidden />} />
      </div>
    </header>
  );
}
