import "server-only";
import { cookies } from "next/headers";
import { getActiveMemberships } from "./membership";
import type { OrganizationResolution } from "./types";

/**
 * The organization-context cookie holds only a REQUESTED context — which
 * of the caller's own active Memberships to use when they have more than
 * one — never authorization itself (work item §22). Every read below
 * re-validates it against a fresh, live `getActiveMemberships()` call; a
 * value that does not match one of the caller's own active Memberships is
 * treated exactly like no cookie at all, never a foreign-tenant grant.
 */
export const ORG_CONTEXT_COOKIE = "zw_org_context";

export async function getRequestedOrganizationId(): Promise<string | null> {
  const store = await cookies();
  return store.get(ORG_CONTEXT_COOKIE)?.value ?? null;
}

/**
 * Resolves the authoritative organization context for the current
 * request. Single active Membership → auto-selected (work item §20).
 * Multiple → requires the cookie to match one of them, else
 * `select-required`. Zero → `none`. Never infers "the strongest role
 * across all organizations" (work item §19) — each organization's role is
 * independent.
 */
export async function resolveOrganizationContext(): Promise<OrganizationResolution> {
  const memberships = await getActiveMemberships();

  if (memberships.length === 0) {
    return { status: "none" };
  }

  if (memberships.length === 1) {
    const [only] = memberships;
    return { status: "single", context: only };
  }

  const requestedId = await getRequestedOrganizationId();
  const match = requestedId ? memberships.find((m) => m.organizationId === requestedId) : undefined;

  if (match) {
    return { status: "selected", context: match };
  }

  return { status: "select-required", memberships };
}
