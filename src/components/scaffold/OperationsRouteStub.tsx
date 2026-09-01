import { PageHeader } from "@/components/ui/PageHeader";
import { Panel } from "@/components/ui/Panel";
import { EmptyState } from "@/components/ui/EmptyState";
import type { BreadcrumbItem } from "@/components/ui/Breadcrumb";

export interface OperationsRouteStubProps {
  title: string;
  description: string;
  breadcrumb?: BreadcrumbItem[];
  /** For dynamic routes — shows the sample identifier the route was reached with, no data fetching involved. */
  sampleId?: string;
}

/**
 * Structural route scaffolding, not a canonical screen (P0-E2-S3A §2). Used
 * by every /operations/* placeholder route so the same route hasn't got 11
 * copies of the same PageHeader/Panel/EmptyState markup. Delete call sites
 * as each canonical operations screen is actually implemented.
 */
export function OperationsRouteStub({ title, description, breadcrumb, sampleId }: OperationsRouteStubProps) {
  return (
    <div className="flex flex-col gap-zw-lg">
      <PageHeader title={title} description={description} breadcrumb={breadcrumb} />
      <Panel>
        <EmptyState
          title={`${title} is not yet implemented`}
          description={
            sampleId
              ? `This route exists to verify the operations shell renders for a dynamic segment. Sample identifier: ${sampleId}.`
              : "This route exists to verify the operations shell foundation renders correctly."
          }
        />
      </Panel>
    </div>
  );
}
