# Zenward Mobility

Non-emergency medical transportation. Care that gets you there.

This is a Next.js (App Router) + TypeScript + Tailwind CSS application. Product and design documentation lives in [/docs](./docs) — read that before making product or visual decisions; this README only covers running the code.

## Getting started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). The `/foundation` route is an internal component showcase for the shared UI foundation (not a product screen).

## Structure

- `src/app/` — routes, split by surface: `(public)` route group (public site, unprefixed URLs), `operations/` (operations console), `driver/` (driver PWA)
- `src/components/ui/` — shared primitives used across all surfaces
- `src/components/operations/`, `src/components/driver/`, `src/components/public/` — surface-specific shells and components
- `src/components/scaffold/` — temporary route-stub components for structural-only routes; delete each call site as its canonical screen is implemented
- `src/design/` — typography and icon tokens (color/spacing/radius tokens live in `src/app/globals.css`)
- `docs/product/` — product definition, decision register, scope register
- `docs/design/` — visual system, design tokens reference, interface principles

## Conventions

- Colors, spacing, radii, shadows, and fonts are defined once in `src/app/globals.css` (Tailwind v4 `@theme`) — see `docs/design/design-tokens.md` for the source values. Don't add ad hoc hex/px values in components.
- Icons come from Phosphor Icons (`@phosphor-icons/react`) via the centralized mapping in `src/design/icons.ts` for navigation — don't import icons ad hoc for nav use.
- Trip/driver status labels shown via `TripStatus`/`DriverStatus` are illustrative presentation only, not a state machine — see `docs/product/decision-register.md` (ZD-015).
