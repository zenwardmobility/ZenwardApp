import "server-only";
import { redirect } from "next/navigation";
import { requireUser } from "./session";
import { resolveOrganizationContext } from "./organization";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { DriverAccessResult, OrganizationContext } from "./types";

const OPERATIONS_ROLES = new Set(["organization_admin", "dispatcher"]);

function selectOrganizationRedirect(currentPath: string): never {
  redirect(`/select-organization?next=${encodeURIComponent(currentPath)}`);
}

/**
 * Route guard for /operations/*. Narrow and single-purpose (work item
 * §29 — not a giant `authorizeEverything()`): resolves auth, then
 * organization context, then checks the role for THAT organization only.
 * A Driver Membership is redirected to /driver rather than a bare denial
 * — the "wrong surface for this role" case, not "no access at all"
 * (work item §24).
 *
 * This narrows navigation for UX only — it does not replace RLS/RPC
 * authorization (work item §30). Every data read/write this route
 * eventually performs is still independently enforced by the database.
 */
export async function requireOperationsAccess(currentPath: string): Promise<OrganizationContext> {
  await requireUser(`/sign-in?next=${encodeURIComponent(currentPath)}`);

  const resolution = await resolveOrganizationContext();

  if (resolution.status === "none") {
    redirect("/access-unavailable");
  }
  if (resolution.status === "select-required") {
    selectOrganizationRedirect(currentPath);
  }

  const { context } = resolution;
  if (!OPERATIONS_ROLES.has(context.role)) {
    if (context.role === "driver") {
      redirect("/driver");
    }
    redirect("/access-unavailable");
  }

  return context;
}

/**
 * Route guard for /driver/*. Same auth/org-context resolution as
 * Operations, then requires role=driver for the resolved organization,
 * then confirms a genuinely linked, active Driver record by calling the
 * SAME `driver_get_profile` RPC the secure read API already uses
 * (docs/data/read-api.md) — re-deriving that check in TypeScript would
 * duplicate, and risk drifting from, the database's own authoritative
 * current_driver_id() logic (work item §30). A Membership with role=driver
 * but no resolvable Driver row does NOT redirect (redirecting back into
 * /driver's own guard would loop, work item §60) — it returns a
 * discriminated "link-missing" result so the layout can render a safe,
 * non-crashing account-configuration state inline instead.
 */
export async function requireDriverAccess(currentPath: string): Promise<DriverAccessResult> {
  await requireUser(`/sign-in?next=${encodeURIComponent(currentPath)}`);

  const resolution = await resolveOrganizationContext();

  if (resolution.status === "none") {
    redirect("/access-unavailable");
  }
  if (resolution.status === "select-required") {
    selectOrganizationRedirect(currentPath);
  }

  const { context } = resolution;
  if (context.role !== "driver") {
    if (OPERATIONS_ROLES.has(context.role)) {
      redirect("/operations");
    }
    redirect("/access-unavailable");
  }

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.rpc("driver_get_profile", {
    p_organization_id: context.organizationId,
  });

  if (error || !data || !data.driver_id || !data.display_name) {
    return { status: "link-missing", organization: context };
  }

  return {
    status: "ok",
    organization: context,
    driverId: data.driver_id,
    displayName: data.display_name,
    phone: data.phone,
    driverStatus: data.status,
  };
}
