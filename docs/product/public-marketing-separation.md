# Zenward Mobility — Public Marketing Site Separation

**Status:** Architecture decision confirmed. **Analysis and planning only — no code moved, no new repository created, nothing deleted.**
**Last updated:** 2026-08-30

## Confirmed decision

The public Zenward marketing/acquisition website becomes a **separate Next.js project in an independently deployable repository.** This repository (`ZenWard`) remains **the product application** — going forward it contains only:

```
/operations/...     — the operations console
/driver/...          — the driver PWA
(plus minimal application-level routes, e.g. authentication, once designed)
```

The standalone marketing repository (not yet created) will own:

```
/                    — homepage
/request-transportation
/healthcare-providers
/services
/about
/contact
+ required public/legal pages
```

**Reason:** the marketing site needs to launch and evolve independently while the operational platform remains under development, and separation reduces the public-facing application's proximity to operational systems and gives each surface its own deployment lifecycle.

This document identifies what the eventual move involves. **No routes are deleted and no new project is created in this task** — that happens only after the standalone marketing repository exists and this plan has been reviewed.

---

## 1. What should eventually move

### Routes (`src/app/(public)/`)
| Current file | Destination |
|---|---|
| `src/app/(public)/layout.tsx` | Marketing repo's root layout |
| `src/app/(public)/page.tsx` | Marketing repo homepage (currently a placeholder — the real homepage is still a later, unbuilt canonical screen per P0-E2-S3) |
| `src/app/(public)/request-transportation/page.tsx` | Marketing repo |
| `src/app/(public)/healthcare-providers/page.tsx` | Marketing repo |

`/services`, `/about`, `/contact`, and legal pages don't exist yet anywhere in this repo — they're net-new in the marketing repo, not a move.

### Components (`src/components/public/`)
All seven files move as a unit: `PublicHeader.tsx`, `PublicFooter.tsx`, `MarketingButton.tsx`, `SectionContainer.tsx`, `HeroContainer.tsx`, `PublicFormInput.tsx`, `index.ts`.

### Nothing else references these
Verified by static import analysis: no file under `src/app/operations/`, `src/app/driver/`, or `src/app/foundation/` imports anything from `src/components/public/` or `src/app/(public)/`, and the `/foundation` QA showcase page (`src/app/foundation/page.tsx`) does not currently demonstrate any public/marketing component — it only exercises `ui/` and `driver/` primitives. The move is a clean lift with no reverse dependencies to untangle.

## 2. Genuinely shared brand tokens that need replication

Public code depends on the token system but never the reverse. The marketing repo needs its own full copy of:

- **`src/app/globals.css`** — the entire Tailwind v4 `@theme` block: all five brand colors, the neutral scale, all four semantic families, spacing/radius/shadow/motion tokens. This is the actual source of Zenward's visual identity and must be byte-for-byte consistent with the product app's copy, not reinterpreted.
- **Font loading** — Manrope + Inter via `next/font/google`, wired to `--font-manrope`/`--font-inter` exactly as in `src/app/layout.tsx`.
- **`src/design/typography.ts`** — the typography token map (marketing uses `pageTitleMarketing`, `display`, `body`, etc. directly).
- **Tooling that renders those tokens correctly:** `tailwindcss`, `@tailwindcss/postcss`, and the `postcss.config.mjs` wiring — without these, the `@theme` block does nothing.
- **`@phosphor-icons/react`** and **`clsx`** — if the marketing site uses any icons or conditional classes, which a real homepage/services/about page will.

**This is a real, ongoing drift risk, not a one-time cost.** Once there are two independent copies of `globals.css`, a color or spacing change made in one repo does not propagate to the other. `docs/design/design-tokens.md` should be treated as the canonical cross-repo source of truth, and any token change must be manually applied to both repos' `globals.css` until/unless a shared, versioned design-token package is worth building — not recommended now, at two repos and pre-launch, but worth naming as the eventual escalation if drift becomes a recurring problem.

## 3. Is any UI-foundation component coupled to the public routes?

**No component in `src/components/ui/`, `src/components/operations/`, or `src/components/driver/` imports anything from `src/components/public/` or `src/app/(public)/`.** The dependency runs one way only:

```
components/public/*  →  components/ui/{Button, LinkButton, Input}, design/typography, lib/cn
```

Specifically: `MarketingButton` wraps `ui/Button`, `PublicFormInput` wraps `ui/Input`, and `PublicHeader` uses `ui/LinkButton`. None of `ui/`, `operations/`, or `driver/` would break, shrink, or need modification if `components/public/` were deleted today.

**What this means for the split:** the marketing repo cannot literally import `@/components/ui/Button` — that module won't exist there once the repos are independent. `MarketingButton` and `PublicFormInput` need their own standalone implementation in the marketing repo (most simply, a copy of `Button`/`Input` and the `buttonStyles.ts` helper, or a from-scratch equivalent styled from the same replicated tokens) — not a cross-repo import of any kind. Same for `PublicHeader`'s use of `LinkButton`.

## 4. Cleanup required in the platform app after separation

**Not performed now — this is the follow-up work list for once the marketing repo exists and is live:**

1. Delete `src/app/(public)/` (route group and its four route files).
2. Delete `src/components/public/` (all seven files).
3. **Decide what `/` serves in the product app.** Today `/` renders the marketing placeholder homepage. Once marketing moves out, the product app needs a deliberate answer for its own root route — candidates include a redirect to `/operations`, a redirect to a future login page, or a small chooser between operations/driver sign-in. **This is a product decision, not resolved here** — flagged as an open question (§6) rather than assumed.
4. Revisit `src/app/layout.tsx` metadata (`title`/`description`) — currently "Zenward Mobility" / "Non-emergency medical transportation," which reads like marketing copy for an app that will no longer contain marketing pages. Minor, not urgent.
5. Update `README.md`'s structure section, which currently documents the `(public)` route group and `components/public/` as part of this repo.
6. `src/app/favicon.ico` stays with the product app; the marketing repo needs its own copy (trivial duplication, not a risk).
7. Going forward, do **not** add any public/marketing component demos to `src/app/foundation/page.tsx` — keeping that page free of public-surface coupling (true today, per §1) is what makes this eventual move a clean lift rather than an untangling exercise.

## 5. Routing / build risks

- **Domain/subdomain strategy is undecided and blocks a clean split.** Two independently deployed Next.js apps serving one brand normally live on a root domain (marketing) and a subdomain (e.g., `app.` / `ops.` for the product), or behind an edge-level path-based router if a single domain is required. This repository's production domain is already recorded as UNKNOWN (decision register ZD-027) — that gap now also blocks finalizing this separation's routing shape, not just general launch readiness. **Recommend the subdomain approach** (simplest, most robust, matches "independent deployment lifecycle") but this needs an explicit decision before the marketing repo's DNS/hosting is configured.
- **No hidden coupling found beyond what's stated above**, based on static import analysis of the current codebase — Next.js's module graph is fully statically analyzable from import statements, so this is a high-confidence finding, not a spot check, but it was verified against the code as it exists today and should be re-verified if more public-facing code is added before the actual split happens.
- **The home-directory git anomaly** already documented for this repository (`product-definition.md` §14, `next.config.ts`'s `turbopack.root` workaround) is local to *this* repository's location on disk. When the marketing repo is actually created, it needs its own independent check of where it's placed — it is not automatically safe just because this repository's workaround exists.
- **Cross-repo links:** verified there are currently no links from public/marketing code into `/operations` or `/driver` (and none in the reverse direction). Once split, any future link between the two surfaces (e.g., a marketing-site "Staff Sign In" link) must be a plain absolute URL to the other deployment's domain, never a Next.js `<Link>`/internal route — a routing mistake here would silently 404 in production while appearing to work in local dev if both were ever run on the same origin during testing.
- **Duplicated tooling maintenance:** two `package.json`s, two lockfiles, two CI/build pipelines, two sets of `tailwindcss`/`next`/`react` version bumps to keep roughly in sync — not a technical blocker, but a real ongoing maintenance cost worth the team acknowledging, not just the design-token drift risk in §2.

## 6. Open questions (not resolved here)

1. What does `/` serve in the product app once marketing moves out? (§4.3)
2. Domain/subdomain strategy for the two deployments — compounds the existing ZD-027 unknown. (§5)
3. Should design tokens eventually become a shared, versioned package rather than two manually-synced copies? Not needed now; worth revisiting if drift becomes a recurring real problem.

---

**Stop condition honored:** no new repository was created, no public route or component was deleted, and no destructive change was made. This document is the plan to execute once the standalone marketing repository exists.
