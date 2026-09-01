import { Van } from "@phosphor-icons/react/dist/ssr";
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
      <div className="w-full max-w-sm rounded-md bg-surface-elevated p-8 shadow-sm">
        <div className="mb-8 flex flex-col items-center gap-3 text-center">
          <span className="flex size-12 items-center justify-center rounded-full bg-brand-route-teal text-white">
            <Van className="size-6" aria-hidden />
          </span>
          <div>
            <p className={cn(typography.subsectionHeading, "text-text-primary")}>Zenward</p>
            <p className={cn(typography.metadata, "font-medium uppercase tracking-wide text-text-muted")}>
              Mobility
            </p>
          </div>
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
