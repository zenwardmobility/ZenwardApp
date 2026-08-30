"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { ArrowLeft } from "@phosphor-icons/react/dist/ssr";
import { DriverShell } from "@/components/driver/DriverShell";
import { DriverHeader } from "@/components/driver/DriverHeader";

function getDriverHeaderTitle(pathname: string) {
  if (pathname === "/driver") return "Today";
  if (pathname === "/driver/trips") return "Trips";
  if (pathname.startsWith("/driver/trips/")) return "Trip";
  if (pathname === "/driver/history") return "History";
  if (pathname === "/driver/profile") return "Profile";
  return "Zenward Driver";
}

/**
 * One DriverShell instance for the whole /driver subtree — the layout
 * persists across navigation (so DriverBottomNavigation doesn't remount on
 * every tap) while the header title tracks the active route, since each
 * driver screen needs its own title unlike the ops AppHeader's generic
 * context label.
 */
export default function DriverLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const isTripDetail = pathname.startsWith("/driver/trips/") && pathname !== "/driver/trips";

  return (
    <DriverShell
      header={
        <DriverHeader
          title={getDriverHeaderTitle(pathname)}
          leading={
            isTripDetail ? (
              <Link
                href="/driver/trips"
                aria-label="Back to Trips"
                className="flex size-8 items-center justify-center rounded-sm text-text-secondary hover:bg-surface-hover"
              >
                <ArrowLeft className="size-5" aria-hidden />
              </Link>
            ) : undefined
          }
        />
      }
    >
      {children}
    </DriverShell>
  );
}
