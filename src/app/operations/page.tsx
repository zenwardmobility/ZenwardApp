import { SquaresFour } from "@phosphor-icons/react/dist/ssr";
import { PageHeader } from "@/components/ui/PageHeader";
import { Panel } from "@/components/ui/Panel";
import { EmptyState } from "@/components/ui/EmptyState";
import { DefinitionList } from "@/components/ui/DefinitionList";
import { getUser } from "@/lib/auth/session";
import { resolveOrganizationContext } from "@/lib/auth/organization";

/**
 * Still a placeholder — the real Overview screen (docs/design/stitch/
 * references/01-todays-operations.png) is a later, canonical-screen work
 * item, not part of P1-E3-S1. What changed this phase: the session
 * context below is real, live-resolved data (work item §44), not sample
 * text — proof the auth/authorization gate in the parent layout actually
 * ran and resolved the correct organization/role/identity, not merely
 * that a page rendered.
 */
export default async function OperationsOverviewPage() {
  const user = await getUser();
  const resolution = await resolveOrganizationContext();
  const organization = resolution.status === "single" || resolution.status === "selected" ? resolution.context : null;

  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader
        title="Overview"
        description="This screen is a UI foundation placeholder — the canonical Overview experience is built in a later phase."
      />
      <Panel>
        <DefinitionList
          items={[
            { label: "Signed in as", value: user?.email ?? "—" },
            { label: "Organization", value: organization?.organizationName ?? "—" },
            { label: "Role", value: organization?.role ?? "—" },
          ]}
        />
      </Panel>
      <Panel>
        <EmptyState
          icon={<SquaresFour className="size-8" aria-hidden />}
          title="Overview is not yet implemented"
          description="This route exists to verify the operations shell foundation (OperationsSidebar, AppHeader, PageHeader, Panel) and the auth/session/role-routing gate render correctly."
        />
      </Panel>
    </div>
  );
}
