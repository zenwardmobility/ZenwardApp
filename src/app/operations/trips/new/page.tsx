import { OperationsRouteStub } from "@/components/scaffold/OperationsRouteStub";

export default function NewTripPage() {
  return (
    <OperationsRouteStub
      title="New Trip"
      description="Structural placeholder — the canonical internal trip-intake form is built in a later phase."
      breadcrumb={[{ label: "Trips", href: "/operations/trips" }, { label: "New Trip" }]}
    />
  );
}
