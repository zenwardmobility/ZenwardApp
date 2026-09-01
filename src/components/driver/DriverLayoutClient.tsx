"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, SignOut } from "@phosphor-icons/react/dist/ssr";
import { DriverShell } from "@/components/driver/DriverShell";
import { DriverHeader } from "@/components/driver/DriverHeader";
import { Avatar } from "@/components/ui/Avatar";
import { IconButton } from "@/components/ui/IconButton";
import { signOutAction } from "@/lib/auth/sign-out-action";

function getDriverHeaderTitle(pathname: string) {
  if (pathname === "/driver") return "Today";
  if (pathname === "/driver/trips") return "Trips";
  if (pathname.startsWith("/driver/trips/")) return "Trip";
  if (pathname === "/driver/history") return "History";
  if (pathname === "/driver/profile") return "Profile";
  return "Zenward Driver";
}

export interface DriverLayoutClientProps {
  children: ReactNode;
  /** Real driver identity (driver_get_profile.display_name) — P1-E3-S2, threaded from the server layout's already-resolved access result. */
  driverName?: string;
}

/**
 * Extracted unchanged from the original (pre-auth) layout.tsx — see
 * OperationsLayoutClient's equivalent comment. This component's own
 * pathname/title logic is untouched; the new server-side DriverLayout
 * parent is what adds the auth/authorization gate in front of it.
 *
 * P1-E3-S2: adds a leading avatar (initials only — no photo field exists
 * anywhere in the Driver model) on ordinary routes, swapped for the
 * existing back-button on a trip-detail route, plus a trailing sign-out
 * affordance reusing the existing signOutAction (work item §28 — no
 * second session-clearing mechanism).
 */
export function DriverLayoutClient({ children, driverName }: DriverLayoutClientProps) {
  const pathname = usePathname();
  const isTripDetail = pathname.startsWith("/driver/trips/") && pathname !== "/driver/trips";

  return (
    <DriverShell
      header={
        <DriverHeader
          title={getDriverHeaderTitle(pathname)}
          driverName={driverName}
          leading={
            isTripDetail ? (
              <Link
                href="/driver/trips"
                aria-label="Back to Trips"
                className="flex size-8 shrink-0 items-center justify-center rounded-sm text-text-secondary hover:bg-surface-hover"
              >
                <ArrowLeft className="size-5" aria-hidden />
              </Link>
            ) : driverName ? (
              <Avatar name={driverName} size="sm" />
            ) : undefined
          }
          trailing={
            <form action={signOutAction}>
              <IconButton type="submit" label="Sign out" icon={<SignOut className="size-5" aria-hidden />} />
            </form>
          }
        />
      }
    >
      {children}
    </DriverShell>
  );
}
