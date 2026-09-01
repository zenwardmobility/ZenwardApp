/**
 * Explicit types for every security-relevant object this layer produces —
 * no `any` (work item §62). Role values must exactly match
 * `memberships.role`'s CHECK constraint (docs/data/schema.md) — never
 * aliased at this layer; friendly labels belong in presentation code, not
 * here.
 */

/** Canonical organization roles. Never `operations_staff`/`manager`/`supervisor`/`staff` (ZD-072). */
export type MembershipRole = "organization_admin" | "dispatcher" | "driver";

/** One of the caller's own active Memberships, live-resolved from `memberships` (RLS-protected, own row only). */
export interface ActiveMembership {
  organizationId: string;
  organizationName: string;
  /** IANA timezone identifier (e.g. "America/New_York") — the Organization's own operational timezone, read live via the same join as organizationName. Never derived from a cookie, browser, or server locale (P1-E3-S2C, ZD-11x). */
  organizationTimezone: string;
  role: MembershipRole;
}

/** The authoritative organization + role a request is being evaluated under. Never trusted from a cookie alone — see resolveOrganizationContext. */
export interface OrganizationContext {
  organizationId: string;
  organizationName: string;
  /** See ActiveMembership.organizationTimezone — this is the SAME field, carried through unchanged once a context is selected. */
  organizationTimezone: string;
  role: MembershipRole;
}

/** Result of resolving which organization context (if any) applies to the current request. */
export type OrganizationResolution =
  | { status: "none" }
  | { status: "single" | "selected"; context: OrganizationContext }
  | { status: "select-required"; memberships: ActiveMembership[] };

/**
 * Result of requireDriverAccess — a discriminated union, never a redirect
 * loop for the "role exists, no linked Driver row" case (work item §26/§60).
 * The "ok" branch carries the display fields `driver_get_profile` already
 * returned (P1-E3-S2) — reused for header/identity presentation rather than
 * issuing a second RPC call for the same row (work item §12/§30).
 */
export type DriverAccessResult =
  | {
      status: "ok";
      organization: OrganizationContext;
      driverId: string;
      displayName: string;
      phone: string | null;
      driverStatus: string | null;
    }
  | { status: "link-missing"; organization: OrganizationContext };
