import { requireOperationsAccess } from "@/lib/auth/authorization";
import { getCurrentPathname } from "@/lib/auth/current-path";
import { getNewTripFormData } from "@/lib/operations/new-trip";
import { NewTripForm } from "@/components/operations/new-trip/NewTripForm";

/**
 * Internal New Trip (P1-E3-S7) —
 * docs/design/stitch/references/05-internal-new-trip.png. See
 * docs/product/new-trip-data-map.md for the full field-level rationale.
 * Backend-ready since P1-E3-S0A (`create_trip`) — this phase is UI-only.
 * Organization Admin/Dispatcher only, via the same `requireOperationsAccess`
 * every other Operations route uses (work item §6) — a Driver-role
 * Membership is redirected before this component ever runs.
 */
export default async function NewTripPage() {
  const pathname = await getCurrentPathname("/operations/trips/new");
  const organization = await requireOperationsAccess(pathname);

  const { passengers, facilities, requests } = await getNewTripFormData(organization.organizationId);

  return (
    <NewTripForm
      passengers={passengers}
      facilities={facilities}
      requests={requests}
      organizationTimezone={organization.organizationTimezone}
    />
  );
}
