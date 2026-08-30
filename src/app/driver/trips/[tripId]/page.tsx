import { DriverRouteStub } from "@/components/scaffold/DriverRouteStub";

export default async function DriverTripDetailPage({
  params,
}: {
  params: Promise<{ tripId: string }>;
}) {
  const { tripId } = await params;

  return <DriverRouteStub screenName="Trip Detail" sampleId={tripId} />;
}
