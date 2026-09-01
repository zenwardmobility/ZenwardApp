"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { requireUser } from "@/lib/auth/session";
import { getActiveMemberships } from "@/lib/auth/membership";
import { ORG_CONTEXT_COOKIE } from "@/lib/auth/organization";
import { safeRedirectPath } from "@/lib/auth/redirect";

/**
 * Server-validated selection (work item §21) — the submitted
 * organization_id is checked against a FRESH `getActiveMemberships()`
 * call, never trusted from the form alone. A user cannot select an
 * organization by supplying an arbitrary UUID; only one of their own,
 * currently active Memberships is ever accepted.
 */
export async function selectOrganizationAction(formData: FormData) {
  await requireUser("/sign-in");

  const organizationId = formData.get("organizationId");
  const nextRaw = formData.get("next");

  if (typeof organizationId !== "string" || !organizationId) {
    redirect("/select-organization");
  }

  const memberships = await getActiveMemberships();
  const match = memberships.find((m) => m.organizationId === organizationId);

  if (!match) {
    // Not one of the caller's own active Memberships -- re-render the
    // selector rather than silently accepting it (work item §21).
    redirect("/select-organization");
  }

  const cookieStore = await cookies();
  cookieStore.set(ORG_CONTEXT_COOKIE, organizationId, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });

  redirect(safeRedirectPath(nextRaw, "/"));
}
