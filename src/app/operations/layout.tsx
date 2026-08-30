"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";
import { OperationsShell } from "@/components/operations/OperationsShell";

const SECTION_LABELS: { prefix: string; label: string }[] = [
  { prefix: "/operations/trips", label: "Trips" },
  { prefix: "/operations/dispatch", label: "Dispatch" },
  { prefix: "/operations/passengers", label: "Passengers" },
  { prefix: "/operations/facilities", label: "Facilities" },
  { prefix: "/operations/drivers", label: "Drivers" },
  { prefix: "/operations/fleet", label: "Fleet" },
  { prefix: "/operations/billing", label: "Billing" },
  { prefix: "/operations/reports", label: "Reports" },
];

function getContextLabel(pathname: string) {
  if (pathname === "/operations") return "Overview";
  return SECTION_LABELS.find((section) => pathname.startsWith(section.prefix))?.label ?? "Operations";
}

/**
 * Every operations route renders through the one OperationsShell. Sidebar
 * context values below are foundation-phase sample data (see
 * OperationsSidebar.tsx) — not a resolution of ZD-016 (launch territory) or
 * any dispatcher identity system, which doesn't exist yet (no auth in this
 * phase).
 */
export default function OperationsLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname();

  return (
    <OperationsShell
      sidebar={{
        location: "Atlanta, GA",
        orgUnit: "Main Operations",
        dispatcherName: "Sample Dispatcher",
        dispatcherRole: "Dispatcher",
      }}
      header={{ contextLabel: getContextLabel(pathname) }}
    >
      {children}
    </OperationsShell>
  );
}
