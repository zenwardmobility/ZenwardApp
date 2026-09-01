import { StatusBadge, type StatusCategory } from "./StatusBadge";

/**
 * Illustrative label → visual category mapping for the statuses seen in
 * canonical references. NOT a state machine. The real trip state machine is
 * established during transportation workflow/domain modelling (see
 * decision-register.md ZD-015 addendum) — this mapping exists purely so the
 * same labels render consistently wherever they currently appear in mockups.
 * Unknown labels fall back to "neutral" rather than guessing a category.
 */
const TRIP_STATUS_MAP: Record<string, StatusCategory> = {
  Requested: "informational",
  "Pending Confirmation": "informational",
  Scheduled: "informational",
  "Needs Assignment": "warning",
  Assigned: "active",
  "En Route": "active",
  "Running Late": "warning",
  Arrived: "active",
  "Passenger Onboard": "active",
  /** Added P1-E3-S2 — Driver-facing leg-disambiguated labels (see src/lib/driver/trip-presentation.ts). */
  "Heading to Pickup": "active",
  "At Pickup": "active",
  "Heading to Destination": "active",
  "At Destination": "active",
  "Attention Required": "critical",
  "No Show": "critical",
  Completed: "completed",
  Cancelled: "cancelled",
};

export interface TripStatusProps {
  status: string;
  className?: string;
}

export function TripStatus({ status, className }: TripStatusProps) {
  return (
    <StatusBadge
      label={status}
      category={TRIP_STATUS_MAP[status] ?? "neutral"}
      className={className}
    />
  );
}
