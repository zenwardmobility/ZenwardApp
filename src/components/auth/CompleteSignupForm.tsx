"use client";

import { useActionState } from "react";
import { completeSignupManualAction, type CompleteSignupState } from "@/app/complete-signup/actions";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { AUTH_ERROR_MESSAGE } from "@/lib/auth/errors";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

const INITIAL_STATE: CompleteSignupState = {};

export interface CompleteSignupFormProps {
  defaultFullName?: string;
  defaultBusinessName?: string;
}

/**
 * P1-E4-S0A1 §9 — the explicit recovery form for a zero-Membership
 * account with no traceable pending-signup metadata. Same calm, minimal
 * shape as SignUpForm, deliberately smaller (no email/password — this
 * person is already authenticated).
 */
export function CompleteSignupForm({ defaultFullName = "", defaultBusinessName = "" }: CompleteSignupFormProps) {
  const [state, formAction, pending] = useActionState(completeSignupManualAction, INITIAL_STATE);

  return (
    <form action={formAction} className="flex w-full flex-col gap-zw-lg" noValidate>
      <div className="flex w-full flex-col gap-zw-md">
        <Input
          label="Full name"
          name="fullName"
          type="text"
          autoComplete="name"
          required
          disabled={pending}
          size="lg"
          defaultValue={defaultFullName}
        />
        <Input
          label="Business name"
          name="businessName"
          type="text"
          autoComplete="organization"
          required
          disabled={pending}
          size="lg"
          helpText="You can change this later."
          defaultValue={defaultBusinessName}
        />
      </div>

      {state.error && (
        <p role="alert" className={cn(typography.bodySmall, "text-critical-text")}>
          {AUTH_ERROR_MESSAGE[state.error]}
        </p>
      )}

      <Button type="submit" variant="primary" size="lg" loading={pending} disabled={pending} className="w-full">
        {pending ? "Setting up your business…" : "Continue"}
      </Button>
    </form>
  );
}
