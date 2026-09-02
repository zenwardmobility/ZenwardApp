"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { MapPin, MapPinLine, LockSimple, WifiSlash, CircleNotch } from "@phosphor-icons/react/dist/ssr";
import { Button } from "@/components/ui/Button";
import { recordLocationAction } from "@/app/driver/trips/[tripId]/actions";
import { isTerminalLocationError } from "@/lib/driver/location-errors";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

export interface DriverLocationTrackerProps {
  tripId: string;
}

type TrackerStatus =
  | "not-started"
  | "requesting"
  | "sharing"
  | "denied"
  | "unavailable"
  | "stopped";

/** Throttle: at most one submission every 20s, regardless of how often `watchPosition` itself fires (work item §20 — a restrained middle of the suggested 10-30s range). */
const SUBMIT_THROTTLE_MS = 20_000;

const STATUS_COPY: Record<TrackerStatus, { label: string; icon: React.ReactNode; tone: "muted" | "active" | "warning" }> = {
  "not-started": { label: "Location sharing off", icon: <MapPinLine className="size-4" aria-hidden />, tone: "muted" },
  requesting: { label: "Requesting location permission…", icon: <CircleNotch className="size-4 animate-spin" aria-hidden />, tone: "muted" },
  sharing: { label: "Location sharing on", icon: <MapPin className="size-4" aria-hidden weight="fill" />, tone: "active" },
  denied: { label: "Location permission needed", icon: <LockSimple className="size-4" aria-hidden />, tone: "warning" },
  unavailable: { label: "Location unavailable", icon: <WifiSlash className="size-4" aria-hidden />, tone: "warning" },
  stopped: { label: "Location sharing stopped", icon: <MapPinLine className="size-4" aria-hidden />, tone: "muted" },
};

/**
 * Driver-side location tracker (P1-E3-S7A, work item §46) — isolated
 * geolocation side effects, kept out of the Active Trip page component
 * itself. Responsibilities: permission state, `watchPosition` lifecycle,
 * submission throttling, cleanup, and a restrained status display. Only
 * ever mounted by the parent page while the Trip is genuinely in the
 * eligible tracking window (`ELIGIBLE_TRACKING_STATES`,
 * driver-location-architecture.md) — unmounting (Trip advances to a
 * terminal state, or becomes inaccessible after reassignment) is itself
 * the cleanup trigger, on top of the server's own independent
 * authorization checks on every submission (defense in depth, never
 * relied on alone).
 *
 * Permission is requested only from an explicit tap on "Share My
 * Location" here on the active-trip screen — never automatically on
 * mount, sign-in, or app launch (work item §17). Denial never blocks
 * Trip lifecycle actions (work item §18) — this component renders
 * alongside `DriverLifecycleAction`, never in front of it.
 */
export function DriverLocationTracker({ tripId }: DriverLocationTrackerProps) {
  const [status, setStatus] = useState<TrackerStatus>("not-started");
  const watchIdRef = useRef<number | null>(null);
  const lastSubmitAtRef = useRef<number>(0);
  const submittingRef = useRef(false);

  const clearWatch = useCallback(() => {
    if (watchIdRef.current !== null && typeof navigator !== "undefined" && navigator.geolocation) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
  }, []);

  // Always clear the watch on unmount (work item §47) — covers the Trip
  // becoming terminal/reassigned-away (this component unmounts along with
  // the rest of the eligible-state view) and ordinary navigation away.
  useEffect(() => clearWatch, [clearWatch]);

  const handlePosition = useCallback(
    (position: GeolocationPosition) => {
      setStatus((prev) => (prev === "sharing" ? prev : "sharing"));

      const now = Date.now();
      if (now - lastSubmitAtRef.current < SUBMIT_THROTTLE_MS || submittingRef.current) {
        return; // throttled — this watchPosition reading is simply not submitted
      }
      lastSubmitAtRef.current = now;
      submittingRef.current = true;

      recordLocationAction(
        tripId,
        position.coords.latitude,
        position.coords.longitude,
        position.coords.accuracy ?? null,
      )
        .then((result) => {
          if (result.status === "error" && result.errorCode && isTerminalLocationError(result.errorCode)) {
            // The Trip is no longer eligible (progressed past the window,
            // completed/cancelled, or reassigned away) — stop watching
            // rather than continuing to poll a browser API for no reason.
            clearWatch();
            setStatus("stopped");
          }
          // A transient failure (network blip, UNKNOWN) is NOT surfaced as
          // an error state — the next watchPosition reading simply tries
          // again on its own schedule (work item §21: never crash the
          // workflow, never queue unbounded history, degrade quietly).
        })
        .catch(() => {
          // Network failure — same quiet degradation, no thrown error, no
          // crash, no unbounded local queueing (work item §21/§22).
        })
        .finally(() => {
          submittingRef.current = false;
        });
    },
    [tripId, clearWatch],
  );

  const startSharing = useCallback(() => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setStatus("unavailable");
      return;
    }
    if (watchIdRef.current !== null) {
      return; // already watching — avoid a duplicate watch (work item §47/§48)
    }

    setStatus("requesting");
    watchIdRef.current = navigator.geolocation.watchPosition(
      handlePosition,
      (error) => {
        if (error.code === error.PERMISSION_DENIED) {
          // Fatal — the browser will not produce further positions until
          // permission is re-granted (outside this component's control).
          // Clearing the watch here avoids an idle watch the browser can
          // never satisfy.
          clearWatch();
          setStatus("denied");
          return;
        }
        // POSITION_UNAVAILABLE / TIMEOUT are ordinarily TRANSIENT (a real
        // GPS can briefly lose signal — a tunnel, dense buildings, cold
        // start — without the underlying watch itself failing; the
        // browser is expected to keep calling back once a position is
        // available again). Reflecting this as a temporary status without
        // clearing the watch is deliberate: found and fixed via this
        // phase's own real testing, where an initial implementation
        // treated every error as fatal and silently killed tracking for
        // the rest of the Trip after the very first transient blip.
        setStatus((prev) => (prev === "sharing" ? prev : "unavailable"));
      },
      { enableHighAccuracy: true, maximumAge: 15_000, timeout: 20_000 },
    );
  }, [handlePosition, clearWatch]);

  const copy = STATUS_COPY[status];

  return (
    <div
      className={cn(
        "flex items-center justify-between gap-3 rounded-md border px-zw-md py-zw-sm",
        copy.tone === "active" && "border-success-border bg-success-bg",
        copy.tone === "warning" && "border-warning-border bg-warning-bg",
        copy.tone === "muted" && "border-border-subtle bg-surface-secondary",
      )}
    >
      <div className="flex items-center gap-2">
        <span
          className={cn(
            copy.tone === "active" && "text-success-strong",
            copy.tone === "warning" && "text-warning-strong",
            copy.tone === "muted" && "text-text-muted",
          )}
        >
          {copy.icon}
        </span>
        <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{copy.label}</p>
      </div>

      {status === "not-started" && (
        <Button type="button" variant="outline" size="sm" onClick={startSharing}>
          Share My Location
        </Button>
      )}
      {status === "denied" && (
        <p className={cn(typography.metadata, "max-w-[55%] text-right text-text-muted")}>
          Allow location access in your browser to share it with dispatch.
        </p>
      )}
    </div>
  );
}
