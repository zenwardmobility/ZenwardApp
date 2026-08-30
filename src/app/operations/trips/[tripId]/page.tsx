import { OperationsRouteStub } from "@/components/scaffold/OperationsRouteStub";

export default async function TripDetailPage({
  params,
}: {
  params: Promise<{ tripId: string }>;
}) {
  const { tripId } = await params;

  return (
    <OperationsRouteStub
      title={`Trip ${tripId}`}
      description="Structural placeholder — the canonical Trip Detail screen is built in a later phase. No data fetching is wired up; this is the route's identifier as received."
      breadcrumb={[{ label: "Trips", href: "/operations/trips" }, { label: tripId }]}
      sampleId={tripId}
    />
  );
}
