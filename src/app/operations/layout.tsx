import type { ReactNode } from "react";
import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getUser } from "@/lib/auth/session";
import { getDisplayName } from "@/lib/auth/profile";
import { OperationsLayoutClient } from "@/components/operations/OperationsLayoutClient";

/**
 * Server-side authorization gate for every /operations/* route (work item
 * §9/§24) — resolved BEFORE any client component renders, so there is no
 * flash of Operations chrome for a Driver or an unauthenticated visitor.
 * The actual pathname-driven chrome logic (sidebar section highlighting,
 * header title) is unchanged from the pre-auth foundation phase — see
 * OperationsLayoutClient.
 *
 * `dispatcherDisplayName` is real, live-resolved identity (P1-E3-S4,
 * ZD-129) — the raw `user.email` this used to pass straight through as a
 * "name" is gone.
 */
export default async function OperationsLayout({ children }: { children: ReactNode }) {
  const pathname = await getCurrentPathname("/operations");
  const organization = await requireOperationsAccess(pathname);
  const user = await getUser();
  const dispatcherDisplayName = await getDisplayName(user?.id ?? "", user?.email ?? null);

  return (
    <OperationsLayoutClient organization={organization} dispatcherDisplayName={dispatcherDisplayName}>
      {children}
    </OperationsLayoutClient>
  );
}
