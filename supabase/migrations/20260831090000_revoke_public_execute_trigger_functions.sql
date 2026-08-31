-- Corrective migration — P1-E2-S1A SECURITY DEFINER exposure audit.
--
-- FINDING: `set_updated_at()` and `prevent_organization_id_change()`
-- (the two shared trigger-support functions from the very first migration,
-- 20260830130000_extensions_and_shared_functions.sql) still carried
-- PostgreSQL's default PUBLIC EXECUTE grant — every other function in this
-- schema had that default explicitly revoked, but these two were missed
-- because they're plumbing, not RLS-facing helpers.
--
-- EXPLOITABILITY: none found. Both are trigger functions (`RETURNS
-- trigger`); PostgreSQL itself refuses a direct call to a trigger function
-- ("trigger functions can only be called as triggers") regardless of
-- EXECUTE privilege, and PostgREST's schema cache never lists trigger-
-- returning functions as callable RPC routes at all (confirmed: calling
-- either via the local RPC endpoint returns PGRST202 "not found in the
-- schema cache", not a permission error — they were never reachable this
-- way in the first place). This migration closes the unjustified grant
-- anyway, on the "PUBLIC should not receive unnecessary EXECUTE privilege"
-- principle, independent of current exploitability, and as a defense
-- against the day either function's signature changes.
--
-- This is a NEW migration, not an edit to the original — migration
-- history stays append-only.

revoke execute on function public.set_updated_at() from public;
revoke execute on function public.prevent_organization_id_change() from public;

-- Neither needs EXECUTE granted to any other role either: they are invoked
-- exclusively as triggers (by the table owner's trigger machinery, which
-- does not require or check EXECUTE privilege the way a direct call would)
-- and were never meant to be called directly by anon, authenticated, or
-- service_role.
