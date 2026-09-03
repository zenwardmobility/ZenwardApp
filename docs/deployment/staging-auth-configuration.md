# Zenward Platform — Staging Auth Configuration

**Work item:** P1-E4-S0A1 — Cloud Signup Continuation Fix, §8 (supersedes P1-E4-S0A §7)
**Status:** The staging URL is now confirmed reachable end to end at a real custom domain. See §Confirmed staging URL.
**Last updated:** 2026-09-03

## Confirmed staging URL

**`https://app.zenwardmobility.com`** — a real custom domain now attached to the Vercel staging project, confirmed directly via `curl`: `/sign-in` returns HTTP 200 with the real page (`<title>Sign in — Zenward Mobility</title>`), server header confirms Vercel/Next.js. This supersedes the earlier `https://zenward-app-staging.vercel.app` (itself a replacement for an abandoned, permanently-`NOT_FOUND` earlier project — see `docs/reports/P1-E4-S0-cloud-staging-foundation-report.txt` §10/§25) — `zenward-app-staging.vercel.app` most likely remains reachable as the underlying Vercel project's own default domain, but **`app.zenwardmobility.com` is now the one to configure Supabase Auth against and the one to use for all further staging work.**

## What the application code actually does (verified, not assumed)

Confirmed by direct code search (`grep -rn "emailRedirectTo\|redirectTo\|resetPasswordForEmail\|inviteUserByEmail" src/`):

- `supabase.auth.signUp({ email, password })` is called with **no `emailRedirectTo` option**, in both `/sign-up` and `/join/[token]` (driver-invite redemption signup). This means any confirmation email Supabase sends is built entirely from the Supabase project's own **Site URL** setting — there is no code-level override to configure.
- **No password-recovery flow exists in the application yet** — `resetPasswordForEmail` is never called anywhere in `src/`. This is a real, honest gap, not a staging-configuration issue: even with Supabase Auth URLs configured correctly, there is currently no "Forgot password?" link or route in the UI. Documented here so it is not silently assumed to work.
- **No Supabase-native invite email is used for Driver invites.** S9's own design (`docs/product/driver-invite-linkage-model.md`, ZD-196) deliberately never calls `inviteUserByEmail` or any other Supabase Admin-API email path — the organization admin shares the `/join/[token]` link directly. Driver invites therefore have **no dependency on Supabase's email configuration at all.**

## Required Supabase Dashboard settings (staging project: "ZenwardApp Staging", ref `wyocbivzgrbekuyqdfts`)

Authentication → URL Configuration:

| Setting | Required value |
|---|---|
| **Site URL** | `https://app.zenwardmobility.com` — this is what every auth email's link is built from, since the app never overrides it per-call. |
| **Redirect URLs** (allow-list) | `https://app.zenwardmobility.com`, `https://app.zenwardmobility.com/**` (wildcard, so `/join/[token]` and any future callback path are covered), plus `http://localhost:3000` and `http://127.0.0.1:3000` (kept for local development — work item's own explicit instruction: "Retain localhost development support"). |

**Not independently re-confirmed this phase** whether these exact values are LIVE on the Supabase Dashboard for the staging project (ref `wyocbivzgrbekuyqdfts`) — this document specifies what they must be; applying/confirming them via the Dashboard itself requires access this environment does not have (see the phase report's own blockers section). See §Email confirmation reality below for what WAS directly tested against this project.

**Applied via the Supabase Dashboard directly** (Authentication → URL Configuration), never via `supabase config push` — that command pushes the ENTIRE local `supabase/config.toml`, including settings (SMS providers, storage, edge-function config, local Docker ports) that were never reviewed for staging-safety and have no business being pushed to a hosted project at all. A two-field Dashboard edit is the correct, minimum-blast-radius mechanism for this specific change (ZD-198).

## Email confirmation reality on staging (directly tested, not assumed)

Local dev has `enable_confirmations = false` (`supabase/config.toml`) — no verification gate. The staging Supabase project (ref `wyocbivzgrbekuyqdfts`) has confirmations **ON**, confirmed directly:

- A raw `POST /auth/v1/signup` against the staging project's own Auth API (using its publishable key, no app code involved) returned `{"code":429,"error_code":"over_email_send_rate_limit","msg":"email rate limit exceeded"}`. This is Supabase's own built-in email sender actively ATTEMPTING to send a confirmation email — which is itself proof confirmations are genuinely enabled (an already-confirmed-by-default project wouldn't try to send anything) — and that its default test-appropriate sending quota (a handful of emails per hour, not production volume — flagged as a known risk in the P1-E4-S0 report) had already been exhausted by the time of this test.
- **EMAIL CONFIRMATION status: LIMITED**, not PASS or FAIL: the application's own code-level handling of the confirmation-required branch is proven correct (`docs/product/operator-onboarding-model.md` §4/§4A — this phase's own local proof used a REAL confirmation email via Mailpit, a REAL link click, and confirmed the continuation completes Organization/Membership/UserProfile exactly once), but a REAL confirmation email could not be sent from the staging PROJECT itself during this phase due to the rate limit above. This is a Supabase-project-configuration limitation (no custom SMTP provider attached), not an application defect.
- **Recommended before any further staging signup testing, and required before production:** configure a real SMTP provider (Supabase Dashboard → Authentication → Emails → SMTP Settings) — e.g. Postmark, Resend, SendGrid — so staging (and eventually production) email sending isn't limited to Supabase's own low-volume test sender. Not done this phase (no such provider account/credential was available).

## What this phase did NOT do

- Did not call `supabase config push` against staging. That command pushes the ENTIRE local `supabase/config.toml` — including `site_url = "http://127.0.0.1:3000"` — which would have been actively wrong for a cloud deployment. Auth URL configuration for staging must be set directly in the Supabase Dashboard (or via a deliberately staging-specific config file/profile, not attempted this phase) — never via a blind `config push` of the local file.
- Did not enable a password-recovery flow (doesn't exist in the app yet — an application gap, not a staging-configuration one — see the phase report's own PASSWORD RECOVERY verdict).
- Did not configure any Driver-invite-related Supabase email setting, since the feature has no dependency on one.
- Did not configure a custom SMTP provider for staging (see §Email confirmation reality — the rate-limit finding above is the direct consequence of not having one).
- Did not disable email confirmations on the staging project to work around the rate limit — the work item's own explicit, verbatim prohibition ("Do NOT disable email confirmation").
