# Zenward Mobility — UI Foundation Implementation

**Work item:** P0-E2-S3 — UI Foundation Implementation
**Status:** Draft, pending review
**Last updated:** 2026-08-30

This documents the actual code that implements the approved [visual-system.md](./visual-system.md), [design-tokens.md](./design-tokens.md), and [interface-principles.md](./interface-principles.md). Those three remain the specification; this document is the map from spec to code. No canonical product screens were built — this is foundation only (see the P0-E2-S3 completion report for the full account).

**Stack:** Next.js (App Router) + TypeScript, single app with route groups per surface, Tailwind CSS v4 (CSS-first `@theme` tokens). This was a genuinely new decision at this work item — nothing was previously specified or built — and was confirmed with the user before scaffolding began.

## 1. Design tokens

All color, spacing, radius, shadow, and motion tokens live in one place: `src/app/globals.css`, inside a Tailwind v4 `@theme` block. Every value there traces to [design-tokens.md](./design-tokens.md) — nothing was invented at implementation time. Tailwind auto-generates utility classes from these (`bg-brand-care-navy`, `text-text-secondary`, `border-border-strong`, `rounded-md`, `shadow-sm`, `duration-base`, `ease-standard`, etc.). Components must use these utilities — never raw hex/px values.

One naming note: because our neutral tokens use category names that match Tailwind's own utility prefixes (e.g. token `text-primary` under Tailwind's `text-*` color utility), some classes stutter (`text-text-primary`, `bg-text-primary`). This is cosmetic, not a defect — it was accepted to keep token names identical to the approved documentation rather than renaming them for implementation convenience.

## 2. Typography

`src/design/typography.ts` exports a `typography` object mapping every token from [design-tokens.md](./design-tokens.md) §4 (`display`, `pageTitleMarketing`, `pageTitleOperational`, `sectionHeading`, `subsectionHeading`, `body`, `bodySmall`, `label`, `metadata`, `button`, `tableHeader`, `tableCell`, `numericDisplay`) to a fixed Tailwind class string (family + size + line-height + weight together). Components import from here rather than composing font classes inline — this is what "do not allow individual pages to improvise font families" means in code.

Manrope and Inter are loaded once in `src/app/layout.tsx` via `next/font/google` and exposed as CSS variables (`--font-manrope`, `--font-inter`) that the `font-display`/`font-sans` theme tokens reference.

## 3. Icons

`src/design/icons.ts` holds the single `navIcons` map used by the operations Sidebar. Approved direction: Phosphor Icons (ZD-031), imported from `@phosphor-icons/react/dist/ssr` (the SSR-safe entry point, since nav icons render inside server components).

**Implementation note — one substitution:** the reference mapping specified `Trips — Route`, but the installed Phosphor package has no icon literally named `Route`. `Path` was used instead as the closest official equivalent (a traced line/route glyph). Recorded as a decision-register item for design review, not applied silently.

Icons elsewhere (buttons, empty states, status indicators) are imported directly where used — the centralized map is specifically for navigation, per the work item's instruction ("create one centralized navigation icon mapping").

## 4. Component primitives (`src/components/ui/`)

Every component the work item listed was built: `Button`, `IconButton`, `Input`, `Textarea`, `Select`, `SearchInput`, `StatusBadge`, `Panel`, `SectionHeader`, `SummaryStrip`, `DataTable`, `EmptyState`, `AttentionState`, `DefinitionList`, `Breadcrumb`, `PageHeader`, `Avatar`, `DriverStatus`, `TripStatus`. One addition beyond the list: `LinkButton` — a navigation-styled-as-button primitive (needed because `Button` renders a native `<button>` and cannot correctly wrap a `<Link>`; header/nav CTAs need an anchor, not a button, for correct semantics and middle-click/right-click behavior). `buttonStyles.ts` holds the shared variant/size class maps so `Button` and `LinkButton` don't duplicate markup or drift apart.

**Button hierarchy:** `primary` (Interactive Teal fill), `secondary` (Care Navy fill), `outline`, `text` (ghost), `destructive` — all five states (default/hover/pressed/focus/disabled/loading) implemented. Focus uses the global `:focus-visible` ring, not a per-component style.

**Status system:** `StatusBadge` implements the eight visual categories from [interface-principles.md](./interface-principles.md) §4 (neutral/informational/active/positive/warning/critical/completed/cancelled) — always label + subtle background + a restrained dot (or a check mark for "completed"), never color alone. `TripStatus` and `DriverStatus` are thin label→category lookup wrappers around it for the illustrative labels seen in references — explicitly not a state machine (see ZD-015 addendum). Unknown labels fall back to `neutral` rather than guessing.

**DataTable:** generic `<T>` component, semantic `<table>` markup, sticky-style header row, hover/selected row states, keyboard-activatable rows (`Enter`/`Space`) when `onRowClick` is supplied, and a required-shape `emptyState` slot rather than a bare "no data" default.

## 5. OperationsShell (`src/components/operations/`)

One `OperationsShell` composing one `OperationsSidebar` and one `AppHeader` — no per-route shell forks. (Renamed from `AppShell`/`Sidebar` at the P0-E2-S3A gate fix, to match the `/operations` route namespace and the surface-prefixed naming pattern already used by `DriverShell`/`PublicHeader`; `AppHeader` was kept as-is per that gate fix's explicit preserve list.) `OperationsSidebar` takes `location`/`orgUnit`/`dispatcherName` as **props**, not hardcoded values; the sample values shown in `src/app/operations/layout.tsx` ("Atlanta, GA" / "Main Operations" / "Sample Dispatcher") are foundation-phase demo data only and do not resolve ZD-016 (exact launch territory, still UNKNOWN) or imply an auth/identity system (none exists yet). `AppHeader`'s `contextLabel` tracks the active nav section from the pathname (Trips/Dispatch/Billing/etc.), computed in the layout.

**Responsive behavior:** full labeled sidebar at `lg+` (≥1024px), icon-only rail at `md`–`lg` (tablet, 768–1023px). Below `md` (phone widths), the shell doesn't just drop the sidebar and leave an orphaned content pane — the entire normal shell (`hidden md:flex`) is replaced by an intentional guard state (`md:hidden`, using the existing `EmptyState` primitive): "Zenward Operations — This workspace is designed for tablet and desktop use." No mobile dispatcher UI or hamburger drawer was built; this is a guard, not a second navigation system. This matches the work item's explicit scope ("large desktop, standard desktop, tablet") — the operations console was not asked to support phone widths, and doesn't attempt to; that's the driver product's job.

## 6. DriverShell (`src/components/driver/`)

`DriverShell` composes a caller-supplied header with `DriverContent` and a fixed `DriverBottomNavigation` (Today / Trips / History / Profile). Entirely separate component tree from the ops shell — no shared sidebar code. Additional components: `DriverHeader`, `DriverTripCard` (richer, multi-line — for Today/Trips), `DriverTripRow` (condensed single-line — for History), `DriverPrimaryAction` (the one dominant next action, full-width), `DriverInstruction` (high-emphasis "what to do next" panel), `DriverRoute` (pickup → destination two-point indicator).

Only the `/driver` (Today) route exists as a placeholder in this phase; Trips/History/Profile routes are not built.

## 7. Public primitives (`src/components/public/`)

> **Planned extraction (ZD-079):** this entire section describes code that still lives in this repository today, but is confirmed to eventually move to a separate, independently deployed marketing repository. Nothing has moved yet — see [public-marketing-separation.md](../product/public-marketing-separation.md) for what moves, what gets replicated (not shared) into the new repo, and what cleanup follows in this repo once that repository exists.

`PublicHeader`, `PublicFooter`, `MarketingButton`, `SectionContainer`, `HeroContainer`, `PublicFormInput` — primitives only, no homepage. `PublicHeader`/`PublicFooter` take nav links and contact info as props with no defaults; **`PublicFooter` renders contact info only if explicitly supplied** — public contact information is still UNKNOWN (ZD-027), so nothing is fabricated. `HeroContainer` has two flat background tones (`app`, `mist`) and deliberately no gradient option.

**PublicLayout** (`src/app/(public)/layout.tsx`, added at the P0-E2-S3A gate fix): a `(public)` route group renders `PublicHeader`/`PublicFooter` once for every public route (`/`, `/request-transportation`, `/healthcare-providers`) instead of each page wrapping itself individually, as the original single homepage did. Route groups don't affect the URL, so these stay unprefixed.

## 8. Accessibility conventions implemented

- Global `:focus-visible` ring (`globals.css`) — no component overrides it.
- Every form primitive (`Input`, `Textarea`, `Select`, `SearchInput`) requires or defaults to a label, wires `aria-describedby`/`aria-invalid`, and renders errors as text, never color-only.
- `IconButton` requires a `label` prop at the type level — an icon-only control cannot be built without an accessible name.
- `StatusBadge` always renders a text label alongside its color/dot.
- `DataTable` rows are keyboard-operable when clickable.
- `prefers-reduced-motion` is handled globally in `globals.css`, not per component.
- Minimum touch targets: `IconButton` is 44px (`size-11`); `DriverPrimaryAction` uses the `lg` button size (48px height).

## 9. Responsive conventions implemented

| Surface | Approach |
|---|---|
| Public primitives | Mobile-first; `SectionContainer`/`HeroContainer` scale padding up at `lg` |
| Ops `AppShell` | Desktop-first; sidebar degrades to icon rail at tablet width, hidden below `md` |
| Driver `DriverShell` | Mobile-first; full-height flex column, fixed bottom nav |

## 10. Verification

`npm run lint` (ESLint via `eslint.config.mjs`) and `npx tsc --noEmit` both pass clean. `npm run build` completes a full production build with all five routes statically prerendered. See the P0-E2-S3 completion report for the full account, including the internal `/foundation` QA route used to visually verify every primitive against the token system.

---

**Related documents:** [visual-system.md](./visual-system.md) · [design-tokens.md](./design-tokens.md) · [interface-principles.md](./interface-principles.md)
