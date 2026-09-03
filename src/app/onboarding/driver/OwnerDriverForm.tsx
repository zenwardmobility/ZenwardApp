"use client";

import { useActionState } from "react";
import Link from "next/link";
import { setOwnerAlsoDrivesAction, type OnboardingActionState } from "../actions";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

const INITIAL_STATE: OnboardingActionState = { status: "idle" };

export function OwnerDriverForm({ defaultName }: { defaultName: string }) {
  const [state, formAction, pending] = useActionState(setOwnerAlsoDrivesAction, INITIAL_STATE);

  return (
    <form action={formAction} className="flex flex-col gap-zw-md">
      <Input label="Name (as drivers/dispatch will see it)" name="displayName" required defaultValue={defaultName} disabled={pending} />
      <Input label="Phone" name="phone" type="tel" placeholder="e.g. (404) 555-0100" disabled={pending} />

      {state.status === "error" && (
        <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
          {state.error}
        </p>
      )}

      <Button type="submit" variant="primary" size="lg" loading={pending} disabled={pending} className="w-full">
        {pending ? "Setting this up…" : "Yes, I also drive"}
      </Button>
      <Link href="/onboarding/facility" className={cn(typography.bodySmall, "text-center text-text-secondary underline")}>
        Not right now
      </Link>
    </form>
  );
}
