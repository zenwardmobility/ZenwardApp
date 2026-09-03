import { redirect } from "next/navigation";
import { getUser } from "@/lib/auth/session";
import { resolveOrganizationContext } from "@/lib/auth/organization";

/**
 * Root route behavior (work item §27). This repository is the Zenward
 * Platform application — the public marketing homepage lives entirely in
 * the separate Zenward-Web repository (ZD-079); this route was previously
 * a placeholder verifying shared public-site primitives before that
 * separation was fully wired up (see docs/reports/
 * P1-E3-S1-completion-report.txt for the full history of this change).
 * `/` now resolves the authenticated landing destination server-side —
 * never a flash of placeholder/public content first.
 *
 * P1-E4-S0A1 §6: a zero-Membership visitor is no longer sent straight to
 * `/access-unavailable` — `/` is the one place ALL authenticated traffic
 * already passes through (including a session Supabase's own email
 * confirmation link established directly, which never touches the
 * sign-in Server Action at all), so it is also the one correct place to
 * route a possible pending-signup/invite continuation. `/complete-signup`
 * makes the actual determination (auto-complete, redeem, or fall through
 * to `/access-unavailable`/a recovery form) — this route does not
 * duplicate that logic, it only decides WHETHER to look.
 */
export default async function RootPage() {
  const user = await getUser();
  if (!user) {
    redirect("/sign-in");
  }

  const resolution = await resolveOrganizationContext();

  if (resolution.status === "none") {
    redirect("/complete-signup");
  }
  if (resolution.status === "select-required") {
    redirect("/select-organization");
  }

  const { role } = resolution.context;
  redirect(role === "driver" ? "/driver" : "/operations");
}
