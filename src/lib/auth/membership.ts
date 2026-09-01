import "server-only";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getUser } from "./session";
import type { ActiveMembership, MembershipRole } from "./types";

interface MembershipRow {
  organization_id: string;
  role: MembershipRole;
  organizations: { name: string } | { name: string }[] | null;
}

/**
 * Live-resolved active Memberships for the CURRENT USER, straight from the
 * database — never cached across requests, never derived from a JWT claim
 * (work item §5/§16, ZD-077's live-check principle applied at the
 * application layer).
 *
 * The `user_id` filter below is explicit and load-bearing, not merely
 * defensive: `memberships` carries a SECOND applicable RLS policy,
 * `memberships_select_org_admin`, which legitimately lets an
 * organization_admin see every membership row in their own organization
 * (their team), additively alongside `memberships_select_self` (RLS
 * policies OR together, they don't narrow each other). Querying this
 * table with only `.eq("status", "active")` and no `user_id` filter — as
 * an earlier version of this function did — silently returns every active
 * Membership in any organization the caller administers, not just their
 * own, for an org_admin caller specifically. That is completely correct
 * behavior for a future "manage my team" screen, and exactly wrong for
 * resolving "which of MY OWN organizations do I have access to" here —
 * caught by `docs/security/application-auth-test-matrix.md` ROLE-1 during
 * this phase's own integration testing, not assumed safe from RLS alone
 * (work item §17's own caution, applied to a subtler case than a simple
 * denial).
 */
export async function getActiveMemberships(): Promise<ActiveMembership[]> {
  const user = await getUser();
  if (!user) {
    return [];
  }

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("memberships")
    .select("organization_id, role, organizations(name)")
    .eq("user_id", user.id)
    .eq("status", "active")
    .returns<MembershipRow[]>();

  if (error) {
    throw new Error(`Failed to resolve active memberships (backend contract mismatch, not an authorization denial — RLS returns zero rows for "no access", not an error): ${error.message}`);
  }

  return (data ?? []).map((row) => {
    const org = Array.isArray(row.organizations) ? row.organizations[0] : row.organizations;
    return {
      organizationId: row.organization_id,
      organizationName: org?.name ?? "",
      role: row.role,
    };
  });
}
