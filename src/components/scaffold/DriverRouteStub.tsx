import { EmptyState } from "@/components/ui/EmptyState";

export interface DriverRouteStubProps {
  screenName: string;
  /** For dynamic routes — shows the sample identifier the route was reached with, no data fetching involved. */
  sampleId?: string;
}

/**
 * Structural route scaffolding, not a canonical screen (P0-E2-S3A §2). The
 * page title itself lives in DriverHeader (set by the layout from the
 * pathname) — this only fills the content area. Delete call sites as each
 * canonical driver screen is actually implemented.
 */
export function DriverRouteStub({ screenName, sampleId }: DriverRouteStubProps) {
  return (
    <EmptyState
      title={`${screenName} is not yet implemented`}
      description={
        sampleId
          ? `This route exists to verify the driver shell renders for a dynamic segment. Sample identifier: ${sampleId}.`
          : "This route exists to verify the driver shell foundation renders correctly."
      }
    />
  );
}
