import type { ReactNode } from "react";
import { IdentificationCard } from "@phosphor-icons/react/dist/ssr";
import { requireDriverAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { signOutAction } from "@/lib/auth/sign-out-action";
import { DriverLayoutClient } from "@/components/driver/DriverLayoutClient";
import { EmptyState } from "@/components/ui/EmptyState";
import { Button } from "@/components/ui/Button";

/**
 * Server-side authorization gate for every /driver/* route (work item
 * §9/§25/§26). A Membership with role=driver but no resolvable linked
 * Driver record renders a safe account-configuration state INLINE (never
 * a redirect back into this same guard — that would loop, work item §60).
 */
export default async function DriverLayout({ children }: { children: ReactNode }) {
  const pathname = await getCurrentPathname("/driver");
  const access = await requireDriverAccess(pathname);

  if (access.status === "link-missing") {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center px-6 text-center">
        <EmptyState
          icon={<IdentificationCard className="size-8" aria-hidden />}
          title="Driver account not yet set up"
          description="Your account has driver access in this organization, but it isn't linked to a driver profile yet. Contact your dispatcher to finish setting up your account."
        />
        <form action={signOutAction} className="mt-6">
          <Button type="submit" variant="outline">
            Sign out
          </Button>
        </form>
      </div>
    );
  }

  return <DriverLayoutClient driverName={access.displayName}>{children}</DriverLayoutClient>;
}
