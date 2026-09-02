# Zenward Platform — UI System Implementation Guide

**Work item:** P1-E3-S8B — Full Product UI/UX Design Convergence
**Status:** Canonical, concise implementation reference. Complements, does not duplicate, [design-tokens.md](./design-tokens.md) (raw color/type/spacing/radius/shadow values and their contrast rationale) — this document is the "how to build a screen" companion: what each token is *for*, and the component/pattern-level rules design-tokens.md doesn't cover.
**Last updated:** 2026-09-02

---

## 1. Color — what each token is for

Raw values and contrast ratios: [design-tokens.md §1-3](./design-tokens.md). In practice:

- **Care Navy** (`--color-brand-care-navy`) — the Operations sidebar background only (as of P1-E3-S8B). Also used for the Avatar initials-circle fill and section-header teal-navy accents established in earlier phases. Never a body-content background.
- **Route Teal / Interactive Teal** — the one primary-action color everywhere (buttons, active nav state, links). Route Teal (`#21A89A`) for larger/decorative treatments; Interactive Teal (`#178577`) for text/icons needing real contrast — see design-tokens.md §1.1 for exactly when each applies.
- **Calm Mist** — light selected/highlighted backgrounds (active sidebar item on light surfaces, selected-passenger card background in the new Combobox).
- **Arrival Gold / warning family** — the ONE tone for every active Trip Assurance condition (Open issue, Needs assignment, Location needs update/unavailable). Never escalated to red/critical — critical is reserved for genuine destructive-action contexts (Cancel/No-Show confirmations), not operational attention items. See ZD-174.

### On-navy tokens (new, P1-E3-S8B)

Added specifically for the sidebar — never use these outside `OperationsSidebar.tsx`:

| Token | Purpose |
|---|---|
| `--color-navy-surface` | Sidebar background (= Care Navy) |
| `--color-navy-text-muted` | Default (non-active) nav item text |
| `--color-navy-border` | Sidebar's own internal dividers (header/footer rules) |
| `--color-navy-hover-bg` | Nav item hover background |
| `--color-navy-active-bg` | Active nav item background (a translucent Route Teal tint) |
| `--color-navy-active-text` | Active nav item text/icon color |

Plain `text-white` is used directly (not a dedicated token) for the sidebar's highest-emphasis text (dispatcher name, hover state) — a real, valid Tailwind color, not worth a bespoke token.

**Logo-on-dark rule:** `zenward-mobility-logo.png` is a flat RGB PNG with an opaque white background (no alpha channel — confirmed by direct inspection, not assumed). On any dark surface, wrap it in a plain white badge chip (`bg-white`, rounded, padded to the logo's own size) rather than placing it directly — this is the ONLY approved way to reconcile a light-background asset with a dark shell; the artwork itself is never recolored, cropped, or redrawn.

## 2. Typography

Family assignment (design-tokens.md §4): **Manrope** for major headings (`h1`/page titles) only; **Inter** for everything else — body, nav, forms, tables, buttons, operational labels. Both are already wired through `typography.ts`'s named scale (`pageTitleOperational`, `sectionHeading`, `subsectionHeading`, `body`, `bodySmall`, `metadata`, `label`, `button`) — use those names, never a raw `text-[Npx]` or `font-[weight]` value. If a screen seems to need a size that scale doesn't have, that's a signal to extend `typography.ts` itself, not to introduce a one-off.

## 3. Spacing, radius, shadow

Use `--spacing-zw-*` exclusively (`gap-zw-md`, `p-zw-lg`, …) — never Tailwind's bare `gap-md`/`p-lg` (reserved keyword collision, see globals.css's own comment and ZD-11x). Radius: `rounded-xs`/`sm`/`md`/`lg` per design-tokens.md §6 — cards and panels use `sm`, dialogs/larger surfaces `md`, pills/avatars `rounded-full`. Shadows: two levels only (`shadow-sm`/`shadow-md`) — most surfaces (cards, table containers) use a border, not a shadow; shadow is reserved for genuinely elevated/floating elements (dialogs, the Combobox's own listbox popup, dropdown menus). Never stack both a heavy shadow and a heavy border on the same element, and never introduce a shadow merely for "SaaS card" visual novelty (work item §17).

## 4. Buttons

One system (`Button.tsx`/`buttonStyles.ts`), variants `primary | outline | destructive | ghost`\* and sizes `sm | md | lg` (\*exact variant set per `buttonStyles.ts` — check there before assuming a name). Rules audited and confirmed consistent this phase:
- One dominant primary action per screen (teal `primary` variant) — everything else `outline`.
- `destructive` reserved for Cancel Trip/Record No-Show confirmations only — never for "Report Issue" (an informational report, not a destructive act) or Remove/Clear actions on a form field (those use a plain icon button, see §6).
- Loading state (`loading` prop) shows an inline spinner + a present-tense label change ("Creating…", "Reporting…") — every mutating button in the app already follows this; keep it that way for any new one.
- Icon-only buttons (`IconButton.tsx`) always carry a real `label` prop (rendered as `aria-label`) — never an icon with no accessible name.

## 5. Inputs, Select, Textarea, and the new Combobox

`Input`/`Textarea`/`Select` share one visual contract: `h-10` (single-line controls), `rounded-sm`, `border-border-strong`, a `typography.label` field label above, optional `helpText`/`error` below. Native date/time inputs (`type="date"`/`type="time"`) intentionally use the browser's own chrome — no custom date-picker was built (would be new scope, not convergence).

**`Combobox`** (new, `src/components/ui/Combobox.tsx`, P1-E3-S8B) — the accessible search-select primitive for cases where a plain `<select>` is materially worse than the reference's own richer search UX (currently: New Trip's Passenger field). Implements the WAI-ARIA "combobox with list autocomplete" pattern (input `role="combobox"` + `aria-expanded`/`aria-controls`/`aria-autocomplete`/`aria-activedescendant`, a `role="listbox"` popup with `role="option"` rows) — DOM focus never leaves the input; the highlighted option is tracked via `aria-activedescendant`, not real focus. It represents ONLY the searching state — callers render their own "selected" treatment once `onSelect` fires (see NewTripForm's selected-passenger card: Avatar + name + phone + a Remove `IconButton`) and stop rendering the `Combobox` itself. **Do not reach for this by default** — a short, small option list (Vehicle, Facility with few rows) is still better served by the plain `Select`; the combobox is for a genuinely large/searchable option set where the reference itself shows search behavior (work item §20's own caution: "do not replace a simple short select merely for novelty").

## 6. Badges and the status system

Two, deliberately never-blended badge families (work item §44):
- **Lifecycle** (`TripStatus`/`driverTripStateLabel`) — Scheduled, En Route, Passenger Onboard, Completed, etc. Canonical, spelled identically everywhere a Trip's real `state` is shown.
- **Assurance** (`StatusBadge` + `assuranceStatusCategory()`) — Open issue, Needs assignment, Location needs update/unavailable, No current issues. A DERIVED read-time condition, never a lifecycle state (ZD-169), uniformly amber/"warning" toned regardless of which condition (ZD-174) — severity is conveyed by wording and deterministic ordering, never by color escalation.

Never render an Assurance condition inside a lifecycle `TripStatus` badge or vice versa — they answer different questions ("what state is this Trip in" vs. "does this Trip need attention right now").

## 7. Panels, cards, tables

`Panel.tsx` is the one card primitive — `border-border-subtle`, `bg-surface-elevated`, `rounded-sm`, `elevated={false}` by default (a border, not a shadow, per §3). Tables use the existing dense-but-legible row treatment (compact `bodySmall`/`metadata` text, a light header row, no zebra striping) — already established since Today's Operations (P1-E3-S4) and reused, not reinvented, on Dispatch's grid and the New Trip form's own definition-list-style groupings.

## 8. Navigation

**Sidebar** (`OperationsSidebar.tsx`) — the one shared component for every Operations screen; never fork a per-route copy (existing rule, reconfirmed this phase). Full labels at `lg+`, icon-only rail at `md`–`lg`, hidden below `md` (a guard state, not a broken layout — ZD-1xx, P1-E3-S4A). As of P1-E3-S8B, dark Care Navy per §1 above.

**Nav truthfulness** (work item §13): every visible sidebar item must be functional, honestly disabled, or removed — audited this phase against the live app (Overview/Trips/Dispatch/Passengers/Facilities/Drivers/Fleet/Billing/Reports all resolve to real, non-stub routes or a clearly-labelled "not yet built" state; none silently 404s or shows a fake populated screen).

**Driver bottom tab bar** — Today/Trips/History/Profile, unchanged this phase; already mobile-appropriate (large touch targets, active-state fill).

## 9. Operations density principles

Built for a dispatcher who has this screen open all day (work item §24): dense, scannable tables over generous whitespace; a single fixed 6 AM–8 PM grid window on Dispatch (not a scrolling infinite timeline); status conveyed by badge text + restrained color, never relying on a color-only cue; every truncatable label carries a `title` fallback rather than being allowed to silently clip.

## 10. Driver mobile principles

One-handed, thumb-reachable, single dominant action per screen (`DriverPrimaryAction`'s own established "never pair two of these" rule) — secondary actions (Report Issue, Navigate, Call Passenger) are always `outline`-variant and positioned above, never competing visually with, the primary teal CTA. Bottom tab bar is the only persistent chrome; headers are compact and page-title-first (see the considered, kept decision in `ui-convergence-audit.md` §04-1). Large touch targets throughout — never shrunk to match a pixel measurement at the cost of real tap-target size (work item §40).

## 11. What this document deliberately does not cover

Raw token values and their contrast/accessibility rationale (design-tokens.md), the Trip Assurance product model (trip-assurance-model.md), route-level data contracts (the various `*-data-map.md` files), and RLS/mutation authorization (the security docs) — this is a UI-pattern guide only.
