-- P1-E3-S9 — Business Basics (work item §6): a plain free-text service-
-- area description, no geofencing/structured market data. A real column,
-- not an AuditEvent write — audit_events has NO INSERT grant to any
-- ordinary role, by design (authorization-model.md security invariant
-- #12, "no actor other than Sys ever gets a direct write to AuditEvent")
-- — this is ordinary organization-profile data, not a security-relevant
-- mutation history entry.

alter table public.organizations
  add column service_area_description text;

alter table public.organizations
  add constraint organizations_service_area_description_length
  check (service_area_description is null or length(service_area_description) <= 1000);

comment on column public.organizations.service_area_description is
  'Free-text "what area/market do you serve" description (work item §6). Descriptive only — no geofencing, no structured coverage data. Never read by any RLS policy or authorization check.';

grant update (service_area_description) on public.organizations to authenticated;
