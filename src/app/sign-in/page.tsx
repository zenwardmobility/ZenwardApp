import Image from "next/image";
import { getUser } from "@/lib/auth/session";
import { isSafeRedirectPath } from "@/lib/auth/redirect";
import { SignInForm } from "@/components/auth/SignInForm";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";
import { redirect } from "next/navigation";

export const metadata = { title: "Sign in — Zenward Mobility" };

/**
 * The smallest secure login foundation (work item §10/§12) — not an
 * authentication marketing page. An already-signed-in visitor is sent to
 * `/`, which resolves the real destination (role/org context) rather than
 * duplicating that resolution here.
 */
export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const user = await getUser();
  if (user) {
    redirect("/");
  }

  const params = await searchParams;
  const nextParam = typeof params.next === "string" ? params.next : undefined;
  const next = isSafeRedirectPath(nextParam) ? nextParam : undefined;

  return (
    <div className="flex min-h-dvh items-center justify-center bg-brand-care-navy px-4 py-12">
      {/*
        P1-E3-S2A temporarily used max-w-[24rem] here because max-w-sm was
        silently hijacked by a project-defined --spacing-sm token (0.5rem)
        that collided with Tailwind's own --container-sm (24rem) — see
        globals.css and docs/reports/P1-E3-S2B-design-token-driver-visual-report.txt.
        P1-E3-S2B renamed the colliding tokens (--spacing-zw-* now), which
        restored max-w-sm to its correct, compiled 24rem value — confirmed
        directly from the compiled CSS before switching back to it here.
      */}
      <div className="w-full max-w-sm rounded-md bg-surface-elevated p-8 shadow-sm">
        {/*
          P1-E3-S2A: the approved Zenward Mobility logo (Z/route/pin-heart
          mark + wordmark), reused from Zenward-Web's own asset — not
          recreated with icons/CSS. See docs/reports/
          P1-E3-S2A-sign-in-visual-fix-report.txt "Approved logo correction".
        */}
        <div className="mb-8 flex justify-center">
          <Image
            src="/images/zenward-mobility-logo.png"
            alt="Zenward Mobility"
            width={240}
            height={80}
            priority
            className="h-auto w-60"
          />
        </div>

        <h1 className={cn(typography.sectionHeading, "mb-1 text-text-primary")}>Sign in</h1>
        <p className={cn(typography.bodySmall, "mb-6 text-text-secondary")}>
          Sign in to your Zenward account to continue.
        </p>

        <SignInForm next={next} />
      </div>
    </div>
  );
}
