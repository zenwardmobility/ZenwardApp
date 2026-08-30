import type { ReactNode } from "react";
import { DriverBottomNavigation } from "./DriverBottomNavigation";

export interface DriverShellProps {
  header?: ReactNode;
  children: ReactNode;
}

/**
 * DriverShell: DriverHeader (caller-supplied) + DriverContent + fixed
 * DriverBottomNavigation. Mobile-first, large touch targets throughout.
 */
export function DriverShell({ header, children }: DriverShellProps) {
  return (
    <div className="flex h-dvh flex-col bg-surface-app">
      {header}
      <main className="flex-1 overflow-y-auto px-4 py-md">{children}</main>
      <DriverBottomNavigation />
    </div>
  );
}
