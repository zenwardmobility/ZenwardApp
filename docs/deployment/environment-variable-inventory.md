# Zenward Platform — Environment Variable Inventory

**Work item:** P1-E4-S0 — Cloud Staging Foundation & S9 Validation, §3 (re-confirmed unchanged by P1-E4-S0A)
**Status:** Audited directly against the current application code (`grep -rn "process\.env\."` across `src/`, plus every `.env*` file and `supabase/config.toml`) — nothing here is assumed from older docs. P1-E4-S0A re-verified this inventory is still exhaustive (no new `process.env.*` reference was introduced by the sign-in polish or any other change this phase) and needed no content change beyond this note.
**Last updated:** 2026-09-03

## The complete set

The current application reads exactly **3** environment variables, plus Next.js's own built-in `NODE_ENV`. This is the full set — confirmed by direct code search, not inferred from `.env.example`.

| Variable | Classification | Read by | Purpose |
|---|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | **BROWSER SAFE** | `src/lib/supabase/env.ts` → browser client, server client, proxy.ts | The Supabase project's API endpoint. Safe for the browser bundle — it names a location, not a credential. |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | **BROWSER SAFE** | Same 3 call sites | The Supabase **publishable** (anon) key — deliberately the ONLY Supabase key this application ever uses, anywhere, browser or server (`docs/security/application-auth-boundary.md`). It grants no privilege by itself; every access decision is enforced by RLS/RPC authorization against the caller's real session. **Never the service-role/secret key** — that key does not appear anywhere in this codebase, `.env.example`, or any doc, and must never be added to a `NEXT_PUBLIC_*` variable if a future phase ever needs it for a genuinely trusted server-only path. |
| `NEXT_PUBLIC_APP_URL` | **BROWSER SAFE** (currently unused) | Declared in `.env.example`/`.env.local` — **confirmed via `grep -rn "NEXT_PUBLIC_APP_URL" src/`: read by ZERO application code right now.** | Reserved for a future absolute-URL need (e.g., building a link inside an email template, or an OG/meta tag) — currently vestigial. Harmless to set correctly in every environment regardless; not a functional dependency today. |
| `NODE_ENV` | **SERVER ONLY** (Next.js built-in, never user-set) | `src/app/select-organization/actions.ts` (`secure: process.env.NODE_ENV === "production"` on the org-context cookie) | Automatically `"production"` on every Vercel deployment (both Preview and Production environments), `"development"` locally — this is what makes the session cookie's `Secure` flag automatically correct in every environment without any code change. |

**That is the entire inventory.** No other `process.env.*` reference exists anywhere in `src/` (confirmed by direct grep, not sampled).

## What does NOT exist in this codebase (confirmed, not assumed)

- **No service-role / secret Supabase key** is read, stored, or referenced anywhere in application code, `.env.example`, or any committed doc.
- **No `NEXT_PUBLIC_*` variable carries anything privileged.** All three public variables are safe by their own design (publishable key + a location string), not merely "safe because nobody looks."
- **No hardcoded `localhost`/`127.0.0.1` string** exists anywhere in `src/` (see `docs/deployment/staging-architecture.md` §Localhost Assumption Audit for the full search).

## Per-environment values required

| Variable | LOCAL (this repo's own dev) | STAGING (Vercel Preview/Production env, ZenwardApp Staging Supabase) | FUTURE PRODUCTION |
|---|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | `http://127.0.0.1:54331` (local Supabase CLI stack) | `https://wyocbivzgrbekuyqdfts.supabase.co` (the linked "ZenwardApp Staging" project's own API URL) | A DIFFERENT, dedicated production Supabase project's URL — **never the staging project's URL.** Not created this phase (work item §15's explicit prohibition). |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | The local stack's own anon key (in `.env.local`, gitignored) | The staging project's own publishable key, set as a Vercel Environment Variable (Project Settings → Environment Variables) — **never committed to git, never placed in a doc or report** | A different production project's own publishable key |
| `NEXT_PUBLIC_APP_URL` | `http://localhost:3000` | `https://zenward-app-staging.vercel.app` — the confirmed, working staging deployment URL (see `docs/deployment/staging-auth-configuration.md` §Confirmed staging URL) | The real production domain, once one exists |

## Where each environment's values actually live

- **LOCAL**: `.env.local` (gitignored via `.gitignore`'s `.env*` pattern — confirmed present and correctly matching before this phase touched anything).
- **STAGING**: Vercel Project Settings → Environment Variables, scoped to the Preview/Staging environment specifically — **not committed to the repository, not written into any doc in this phase.** See `docs/deployment/staging-runbook.md` for the exact steps to set these (values are entered directly in the Vercel dashboard by whoever has access — this document names WHAT to set, never the actual secret value).
- **FUTURE PRODUCTION**: Not created this phase. When it is, it must use its own, separate Vercel environment-variable scope (Vercel supports distinct values per environment for the exact same variable name) — never reusing the staging project's values.

## Secrets audit (work item §3's own explicit requirement)

Confirmed clean before this report was written:
- `git log -p -- '*.env*'` / `git status` — `.env.local` has never been tracked, is not tracked now.
- No secret VALUE (of any kind — Supabase keys, database passwords, Vercel tokens) appears anywhere in this document, any other doc, any report, or any source file in this repository. Every value in this inventory is described by name and classification only.
- The Supabase **publishable** key is the one credential that legitimately does appear in `.env.local` (local only, gitignored) and would appear in Vercel's own environment-variable UI for staging — this is by design (docs/security/application-auth-boundary.md), since it is not a secret in the traditional sense (RLS is the actual authorization boundary), but it is still never hand-copied into a markdown doc or a `.txt` report by this project's own convention.
