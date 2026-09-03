"use client";

import { useActionState } from "react";
import { setBusinessBasicsAction, type OnboardingActionState } from "../actions";
import { Select } from "@/components/ui/Select";
import { Textarea } from "@/components/ui/Textarea";
import { Button } from "@/components/ui/Button";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: OnboardingActionState = { status: "idle" };

// A practical US timezone list, not an exhaustive IANA catalog — the
// server-side check (is_valid_iana_timezone, P1-E3-S2C) is the real
// authority regardless of what this list offers.
const TIMEZONE_OPTIONS = [
  { value: "America/New_York", label: "Eastern (New York)" },
  { value: "America/Chicago", label: "Central (Chicago)" },
  { value: "America/Denver", label: "Mountain (Denver)" },
  { value: "America/Phoenix", label: "Mountain, no DST (Phoenix)" },
  { value: "America/Los_Angeles", label: "Pacific (Los Angeles)" },
  { value: "America/Anchorage", label: "Alaska" },
  { value: "Pacific/Honolulu", label: "Hawaii" },
];

/**
 * Business Basics (P1-E3-S9, work item §6) — timezone is canonical
 * (Trip scheduling depends on it, P1-E3-S2C), pre-selected to Eastern
 * since Zenward's own initial launch territory is Georgia. Service area
 * is a plain description, not geofencing.
 */
export default function BusinessBasicsPage() {
  const [state, formAction, pending] = useActionState(setBusinessBasicsAction, INITIAL_STATE);

  return (
    <>
      <div>
        <p className={cn(typography.metadata, "text-text-secondary")}>Step 2 of 6</p>
        <h1 className={cn(typography.sectionHeading, "mt-1 text-text-primary")}>Business basics</h1>
        <p className={cn(typography.bodySmall, "mt-2 text-text-secondary")}>
          Your timezone controls how trip times are scheduled and displayed.
        </p>
      </div>

      <form action={formAction} className="flex flex-col gap-zw-md">
        <Select
          label="Timezone"
          name="timezone"
          required
          disabled={pending}
          defaultValue="America/New_York"
          options={TIMEZONE_OPTIONS}
        />
        <Textarea
          label="Service area"
          name="serviceArea"
          placeholder="e.g. Metro Atlanta and surrounding counties"
          helpText="Optional — a plain description for now, not a coverage map."
          disabled={pending}
        />

        {state.status === "error" && (
          <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
            {state.error}
          </p>
        )}

        <Button type="submit" variant="primary" size="lg" loading={pending} disabled={pending} className="w-full">
          Continue
        </Button>
      </form>
    </>
  );
}
