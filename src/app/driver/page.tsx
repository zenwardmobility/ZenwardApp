import { getUser } from "@/lib/auth/session";
import { requireDriverAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { DefinitionList } from "@/components/ui/DefinitionList";
import { Panel } from "@/components/ui/Panel";
import { DriverRouteStub } from "@/components/scaffold/DriverRouteStub";

/**
 * Still a placeholder — the real Driver Today screen (docs/design/stitch/
 * references/06-driver-today.png) is a later, canonical-screen work item.
 * The session context below is real, live-resolved data (work item §44),
 * not sample text — proof of a valid, actively-linked Driver record, not
 * merely a rendered page. (This second `requireDriverAccess` call is
 * cheap and safe here: the parent layout has already run the same guard
 * and would have redirected/rendered the account-setup state before this
 * page ever renders, so this call is guaranteed "ok" by construction —
 * re-deriving rather than threading props keeps each server function
 * independently correct.)
 */
export default async function DriverTodayPage() {
  const user = await getUser();
  const pathname = await getCurrentPathname("/driver");
  const access = await requireDriverAccess(pathname);
  const driverId = access.status === "ok" ? access.driverId : "—";

  return (
    <div className="flex flex-col gap-4">
      <Panel>
        <DefinitionList
          items={[
            { label: "Signed in as", value: user?.email ?? "—" },
            { label: "Organization", value: access.organization.organizationName },
            { label: "Driver ID", value: driverId },
          ]}
        />
      </Panel>
      <DriverRouteStub screenName="Today" />
    </div>
  );
}
