-- P1-E3-S9 — the Business Stage onboarding step (work item §3) needs an
-- ordinary Organization Admin UPDATE on organizations.business_stage.
-- 20260901100000_organization_operational_timezone.sql already
-- established the pattern of adding a narrow column grant on top of the
-- existing organizations_update_org_admin policy for a new self-service
-- field — same treatment here. Safe: the existing policy already
-- restricts this to the org's own organization_admin, and the column's
-- own CHECK constraint (organizations_business_stage_valid,
-- 20260903100000) rejects anything outside starting/growing/established/
-- null regardless of what a client sends.

grant update (business_stage) on public.organizations to authenticated;
