# Zenward Platform — Staging Architecture

**Work item:** P1-E4-S0 — Cloud Staging Foundation & S9 Validation
**Status:** Supabase staging project linked and fully migrated. Vercel deployment exists and builds successfully; live browser access is currently blocked (see §5) pending confirmation of the deployment's reachable URL/protection state.
**Last updated:** 2026-09-03

## 1. What "staging" means for Zenward right now

Two pieces of real cloud infrastructure, both already provisioned (neither created by this phase — found already in place during pre-work, confirmed via `supabase projects list` and the GitHub repository's own connected integrations):

```
GitHub (zenwardmobility/ZenwardApp, branch: main)
        │
        │  push triggers an automatic build (Vercel's GitHub App integration)
        ▼
Vercel Project (zenwardmobility/ZenwardApp)
  - Deploys every push to `main`
  - Vercel's own dashboard labels this the "Production" environment
    (this is Vercel's default terminology for whatever branch is
    configured as the Production Branch — it does NOT mean a real,
    customer-facing release; see §2)
  - No custom domain currently attached — the live URL is an
    anonymous, Vercel-assigned `*.vercel.app` address
  - Deployment Protection (Vercel SSO) is enabled by default,
    restricting access to the Vercel team
        │
        │  reads NEXT_PUBLIC_SUPABASE_URL / _PUBLISHABLE_KEY
        │  (Vercel Environment Variables, not committed to the repo)
        ▼
Supabase Cloud Project — "ZenwardApp Staging"
  ref:    wyocbivzgrbekuyqdfts
  region: us-east-1
  - Linked to this repository (`supabase/.temp/project-ref`)
  - Schema is migration-authoritative: every migration in
    `supabase/migrations/` is applied here, confirmed current
    (`supabase migration list --linked` — every local migration has a
    matching remote entry, through 20260903100700, the last S9
    migration)
  - Contains only synthetic/demo data (Harmony Medical Transport,
    same seed convention as local dev) — no real PHI, no real
    operator/customer data
```

A separate Supabase project, `"zenwardmobility's Project"` (ref
`bwqsowlbcuytsjquhxzh`, eu-west-1), also exists in the same
organization but is **not linked** to this repository and was **not
touched** by this phase — most plausibly reserved for a future
production project. This phase does not assume, configure, or seed
it in any way (work item §15's explicit prohibition against creating
Production).

## 2. Why "Production" ≠ a real production release here

Vercel's own environment vocabulary (Production/Preview) is a
per-branch label, not a statement about who can reach the deployment
or whether a real domain points at it. Confirmed directly:
- `app.zenwardmobility.com` does not resolve at all (`curl` returns
  no response — DNS is not configured for this domain against this
  project).
- The actual, only reachable URL for the latest build is an anonymous
  `*.vercel.app` address.
- That URL is protected by Vercel's Deployment Protection (an
  `vercel.com/sso-api` redirect on every request) — not reachable by
  an anonymous visitor at all, by default.

So despite Vercel's own dashboard calling this "Production," it is,
in practical/security terms, exactly the "staging behind an
access gate" the work item asks for — this phase treats it as such,
and deliberately makes NO change that would attach a real domain or
open public access (work item §15).

## 3. Environment separation

See `docs/deployment/environment-variable-inventory.md` for the full
variable-by-variable breakdown. In short: the application code itself
carries zero environment-specific values — everything environment-
specific is either a Vercel Environment Variable (staging Supabase
URL/key) or a Supabase Dashboard setting (Auth Site URL/Redirect
URLs, per `docs/deployment/staging-auth-configuration.md`). No
environment's credentials appear in another environment's
configuration, and none appear in this repository at all.

## 4. Migrations remain authoritative

Per the work item's own explicit instruction, no schema was ever
created or edited directly in the Supabase Dashboard for staging.
`supabase migration list --linked` (read-only) confirmed the staging
project's migration history matches this repository's own
`supabase/migrations/` directory exactly, entry for entry, through
the last S9 migration — the repository, not the dashboard, remains
the single source of truth for schema.

## 5. Current blocker: live browser access to the deployed app

The Vercel deployment (commit `77c5566`, the same S9 commit already
on `main`) built successfully (`gh api .../deployments` shows
`state: success`). Direct HTTP verification from this environment
found the deployment initially protected by Vercel SSO (a 302 to
`vercel.com/sso-api`); a later check (after the user indicated they
would temporarily disable Deployment Protection) returned a plain
Vercel-level 404 (`x-vercel-error: NOT_FOUND`) instead — meaning
either the specific per-deployment URL is no longer the correct one
to reach the current build, or the protection-disable action produced
a different URL/alias than the one this report has on file. This was
NOT resolved as of this report — see the bottom verdict block and
`docs/reports/P1-E4-S0-cloud-staging-foundation-report.txt` §Blockers
for the exact, current state and what's needed to unblock it (the
correct, currently-reachable staging URL, confirmed by the user).

## 6. What this phase deliberately did not do

Per work item §15: no Production Supabase project was created or
touched; no production customer data was connected; `app.
zenwardmobility.com` was not configured; public signup was not
enabled beyond what already exists in the codebase (which has no
"public" gate at all beyond ordinary signup — see
`docs/product/operator-onboarding-model.md`, unchanged this phase);
Zenward-Web's Request Hub was not connected; S10 was not begun;
billing/broker integrations were not configured.
