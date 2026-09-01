"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";
import { OperationsShell } from "@/components/operations/OperationsShell";
import type { OrganizationContext } from "@/lib/auth/types";

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

const ROLE_LABEL: Record<OrganizationContext["role"], string> = {
  organization_admin: "Organization Admin",
  dispatcher: "Dispatcher",
  driver: "Driver",
};

export interface OperationsLayoutClientProps {
  organization: OrganizationContext;
  userEmail: string;
  children: ReactNode;
}

/**
 * The pathname-driven chrome logic extracted unchanged from the original
 * (pre-auth) layout.tsx — this component's own behavior is identical to
 * before, only its inputs changed: `organization`/`userEmail` now come
 * from the live-resolved session (via the new server-side
 * OperationsLayout parent) instead of the P0-E2-S3-era hardcoded sample
 * data ("Sample Dispatcher"). Multi-org role-per-organization is
 * preserved — `organization.role` reflects the CURRENT organization
 * context only, never a global role.
 */
export function OperationsLayoutClient({ organization, userEmail, children }: OperationsLayoutClientProps) {
  const pathname = usePathname();

  return (
    <OperationsShell
      sidebar={{
        location: organization.organizationName,
        orgUnit: ROLE_LABEL[organization.role],
        dispatcherName: userEmail,
        dispatcherRole: ROLE_LABEL[organization.role],
      }}
      header={{ contextLabel: getContextLabel(pathname) }}
    >
      {children}
    </OperationsShell>
  );
}
