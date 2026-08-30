import { StatusBadge, type StatusCategory } from "./StatusBadge";

/**
 * Illustrative label → visual category mapping for driver availability
 * states seen in canonical references. NOT a state machine — see TripStatus
 * for the same caveat. Unknown labels fall back to "neutral".
 */
const DRIVER_STATUS_MAP: Record<string, StatusCategory> = {
  Available: "positive",
  "On Trip": "active",
  Break: "neutral",
  Unavailable: "warning",
};

export interface DriverStatusProps {
  status: string;
  className?: string;
}

export function DriverStatus({ status, className }: DriverStatusProps) {
  return (
    <StatusBadge
      label={status}
      category={DRIVER_STATUS_MAP[status] ?? "neutral"}
      className={className}
    />
  );
}
