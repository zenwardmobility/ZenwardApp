import { SquaresFour } from "@phosphor-icons/react/dist/ssr";
import { PageHeader } from "@/components/ui/PageHeader";
import { Panel } from "@/components/ui/Panel";
import { EmptyState } from "@/components/ui/EmptyState";

/**
 * Placeholder only — demonstrates the OperationsShell/OperationsSidebar/
 * AppHeader/PageHeader foundation rendering correctly. The real Overview
 * screen is a later, canonical-screen work item, not part of P0-E2-S3.
 */
export default function OperationsOverviewPage() {
  return (
    <div className="flex flex-col gap-lg">
      <PageHeader
        title="Overview"
        description="This screen is a UI foundation placeholder — the canonical Overview experience is built in a later phase."
      />
      <Panel>
        <EmptyState
          icon={<SquaresFour className="size-8" aria-hidden />}
          title="Overview is not yet implemented"
          description="This route exists to verify the operations shell foundation (OperationsSidebar, AppHeader, PageHeader, Panel) renders correctly."
        />
      </Panel>
    </div>
  );
}
