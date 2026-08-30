# Zenward Mobility — Visual System

**Work item:** P0-E2-S1 — Visual System Specification
**Phase:** P0 — Product Foundation · **Epic:** P0-E2 — Brand & Interface System
**Status:** Draft, pending design review
**Last updated:** 2026-08-29

This document establishes the visual language future Zenward screens must follow. It is **specification, not implementation** — no screens, components, or libraries were built or installed for this work item. See [design-tokens.md](./design-tokens.md) for exact token values and [interface-principles.md](./interface-principles.md) for component-level behavioral patterns.

---

## 1. Design Principle

> **Healthcare calm with transportation precision.**

**Healthcare calm** means: reassuring, readable, human, accessible, non-intimidating.

**Transportation precision** means: clear timing, clear location, clear status, clear assignment, clear next action, dense information when operationally necessary.

Neither side should overpower the other. A public page that only feels calm but never tells someone clearly what happens next has failed. An operations screen that is precise but cold, cramped, or intimidating has also failed. Every screen should be judged against both halves of this principle.

Zenward should feel: calm, dependable, operational, human, modern, trustworthy, accessible, restrained. It must not look like a generic AI-generated SaaS product — see [interface-principles.md](./interface-principles.md) §8 for the explicit anti-AI rules this implies.

---

## 2. Brand Colors

Four fixed anchors plus white — see [design-tokens.md](./design-tokens.md) §1 for hex values and derived tokens.

| Color | Role | Use with restraint |
|---|---|---|
| Care Navy | Primary brand color | Primary navigation, brand typography, high-emphasis surfaces, strong secondary actions, important structural elements. Not a general-purpose fill. |
| Route Teal | Primary interaction/accent | Primary actions, active controls, selected navigation, links, progress, selected operational states. **Do not let the interface become teal-heavy** — it marks interaction, it doesn't decorate. See the Brand Teal / Interactive Teal distinction below. |
| Calm Mist | Supporting brand surface | Subtle backgrounds, selected informational states, low-emphasis highlights, marketing sections. Not the default background behind every card. |
| Arrival Gold | Limited accent | Restrained highlights, attention states where semantically appropriate, selective brand moments. **Never a universal CTA color** — Route Teal owns primary actions. |
| White | Primary clean surface | Default surface for content and operational density. |

A full neutral and semantic palette is derived from these four anchors in [design-tokens.md](./design-tokens.md) §2–3.

**Brand Teal vs. Interactive Teal (approved at the P0-E2-S1 design gate):** the raw brand teal (`#21A89A`) fails WCAG AA as text/button-label color. Two tokens are now approved and permanent — `color.brand.route-teal` (`#21A89A`) for larger graphical/decorative/brand treatments, and `color.interactive.teal` (`#178577`) for anywhere teal carries text or must independently pass 3:1+ contrast: buttons, links, interactive text, controls, selected application states. Neither replaces the other; see [design-tokens.md](./design-tokens.md) §1.1 and [ZD-029](../product/decision-register.md)/[ZD-030](../product/decision-register.md).

---

## 3. Typography

**Manrope** (brand/display) and **Inter** (application/UI). Full scale in [design-tokens.md](./design-tokens.md) §4.

- **Manrope** is for brand moments: marketing hero headlines, marketing page titles, and selective large numerical displays (a genuine operational figure shown large, never a decorative stat). It should read as occasional, not structural.
- **Inter** is the working typeface: navigation, forms, tables, operational screens, body copy, metadata, labels, buttons, the mobile driver interface, dense data displays.
- **Operational page titles use Inter, not Manrope**, even though marketing page titles use Manrope at the same size. Console and driver screens should never feel like they're wearing a marketing typeface — Manrope inside operational interfaces should be avoided entirely except the one narrow numeric-display case above.

## 4. Spacing

Full scale in [design-tokens.md](./design-tokens.md) §5. The system must support both spacious customer-facing pages and dense operational interfaces from the same scale — it does this by giving operational surfaces a tighter working range rather than a separate scale.

| Context | Working range | Notes |
|---|---|---|
| Public website page gutters/sections | `space.xl`–`space.4xl` | Generous room to read and convert |
| Marketing cards | `space.lg`–`space.xl` internal padding | |
| Forms (any surface) | `space.md` between fields | Consistent regardless of surface |
| Standard cards/panels | `space.lg` internal padding | |
| Table rows | `space.sm` vertical, `space.md` horizontal | Never `space.lg` — rows must stay dense and scannable |
| Navigation | `space.sm`–`space.md` between items | |
| Mobile driver interface | `space.md`–`space.lg` around primary actions | Large touch targets take priority over information density here |
| Desktop operations interfaces | `space.xs`–`space.lg` | Default to the tighter end; density is a feature, not a flaw, in dispatch |

**Principle:** whitespace is a tool for hierarchy, not a default. Dispatch/data-heavy interfaces should never inherit marketing-page spacing just because the token exists.

## 5. Corner Radius

Full token table in [design-tokens.md](./design-tokens.md) §6: `6px` small controls → `8px` inputs → `10px` standard panels → `14px` large marketing cards → `999px` pill (reserved for badges, tags, segmented controls, and genuinely pill-shaped interactions).

Zenward explicitly avoids the generic AI pattern of heavily rounded cards everywhere. A container does not get a large radius by default — the radius should match the container's actual size and role. Oversized rounded containers require justification, not just availability of a bigger token.

## 6. Borders & Shadows

Operational hierarchy should come primarily from **typography, background, spacing, borders, and grouping** — not shadows. Shadows are the last tool reached for, not the first.

Two shadow levels only (`shadow.sm` for menus/popovers, `shadow.md` for modals/dialogs — see [design-tokens.md](./design-tokens.md) §7). A third level is not defined; adding one requires design review, not just a new value.

Borders split by purpose:
- `color.border.subtle` — decorative dividers and separators only.
- `color.border.strong` — anywhere a border is the essential indicator of an interactive boundary (inputs, required groupings). This distinction exists because the subtle border fails non-text WCAG contrast (1.4.11) on its own — see [design-tokens.md](./design-tokens.md) §2.
- Focus, selected, and divider treatments are specified in [interface-principles.md](./interface-principles.md) §2–3.

## 7. Iconography

**Approved direction (P0-E2-S1 design gate — [ZD-031](../product/decision-register.md)): Phosphor Icons**, primarily Regular and Medium weights.

Rules:
- One coherent icon family — Phosphor throughout, never mixed with another library.
- Icons support comprehension; they do not replace necessary labels. An icon-only control still needs an accessible label.
- Do not place icons in colored circles by default.
- Avoid decorative icons beside every heading.
- Do not use duotone styling throughout operational UI.
- Do not use icons where clear text communicates better.
- Maintain consistent sizing and visual weight.
- **Avoid:** sparkle icons, magic wand icons, rocket icons, decorative AI icons, random emoji, icons inside colored circles beside every section heading, inconsistent icon libraries.

The Phosphor package has **not** been installed under this work item — this is a direction decision, not an implementation action. Installation happens in the implementation phase.

## 8. Imagery

For the public-facing brand: authentic-feeling photography of medical transportation, real environments, drivers, passengers, caregivers, healthcare facilities, vehicle interaction, human assistance. Avoid cliché stock imagery where possible.

**Avoid:** futuristic vehicles, fake HUD graphics, AI-generated medical-technology clichés, glowing maps, holographic interfaces, unrealistic healthcare scenes.

Photography should communicate **dignity, not vulnerability** — this is the operative test for any image candidate: does it show a person being helped with dignity, or does it depict them as merely fragile or pitiable? The former fits the brand; the latter does not.

**Status (P0-E2-S1 design gate — [ZD-033](../product/decision-register.md)):** photography sourcing remains unresolved. Full photographic art direction will be established during the canonical public-site reference design, not as part of visual-system documentation. The general requirements above (realistic, dignified, human, healthcare-appropriate, transportation-relevant, no fabricated operational claims) stand in the meantime. No imagery has been sourced, generated, or added under this work item.

## 9. Motion

Motion is restrained and functional. Recommended uses: state transitions, drawer/dialog transitions, loading feedback, navigation feedback, selective marketing transitions. Token values in [design-tokens.md](./design-tokens.md) §8.

**Avoid:** constant floating animations, unnecessary parallax, exaggerated card movement, glowing CTA animations, motion that interferes with operational speed. `prefers-reduced-motion` must always be respected — see [interface-principles.md](./interface-principles.md) §7.

## 10. Responsive Principles by Surface

| Surface | Direction | Notes |
|---|---|---|
| Public website | Mobile-first | Optimize for fast reading, conversion, large usable controls, straightforward content flow. |
| Operations console | Desktop-first, responsive | Do not simply stack every desktop panel vertically on mobile. A mobile operations view should surface the highest-value tasks only, not a shrunk copy of the desktop layout. |
| Driver experience | Mobile-first | Large touch targets, minimal simultaneous decisions, one dominant next action whenever practical. |

These directions are provisional in the sense that they inherit the provisional platform decisions already recorded in [decision-register.md](../product/decision-register.md) (ZD-011, ZD-012) — the visual system is built to support either direction remaining stable, but the underlying platform choice is still open to product review.

---

**Related documents:** [design-tokens.md](./design-tokens.md) · [interface-principles.md](./interface-principles.md) · [product-definition.md](../product/product-definition.md)
