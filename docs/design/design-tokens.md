# Zenward Mobility — Design Tokens

**Work item:** P0-E2-S1 — Visual System Specification
**Status:** Draft, pending design review
**Last updated:** 2026-08-29

This is the concrete token reference for the Zenward visual system. It is documentation, not code — no CSS variables, Tailwind config, or component files have been created or modified. Token names here are the recommended source of truth when tokens are eventually implemented.

All contrast ratios below were computed against the WCAG 2.1 relative-luminance formula, not estimated. See §7 for methodology notes.

See [visual-system.md](./visual-system.md) for usage guidance and rationale, and [interface-principles.md](./interface-principles.md) for component-level patterns.

---

## 1. Brand Color Anchors (approved, fixed)

| Token | Hex | Role |
|---|---|---|
| `color.brand.care-navy` | `#123447` | Primary brand color |
| `color.brand.route-teal` | `#21A89A` | Primary interaction/accent color |
| `color.brand.calm-mist` | `#DDF4F0` | Supporting brand surface |
| `color.brand.arrival-gold` | `#F4B860` | Limited accent color |
| `color.brand.white` | `#FFFFFF` | Primary clean surface |

These five are fixed brand anchors from product direction. Do not alter these hex values without a design decision. §2 and §3 derive a full interface palette from them.

### 1.1 Brand Teal vs. Interactive Teal (approved, P0-E2-S1 design gate — [ZD-029](../product/decision-register.md), [ZD-030](../product/decision-register.md))

Route Teal (`#21A89A`) measures **2.94:1** against white — it fails WCAG AA for text (4.5:1) and is marginal even for large/bold UI text (3:1). It cannot be used as body text, link text, or as a button fill with white text and still pass AA.

Design review approved a two-token distinction rather than compromising either the brand anchor or accessibility:

| Token | Hex | Contrast vs. white | Use |
|---|---|---|---|
| `color.brand.route-teal` | `#21A89A` | 2.94:1 | **Brand Teal.** Larger graphical treatments, selected indicators, decorative brand treatments, illustration, progress bars, icon accents ≥3px, selected-state backgrounds paired with dark text — any context where WCAG contrast is independently satisfied. Remains part of the core visual identity; not silently replaced elsewhere. |
| `color.interactive.teal` | `#178577` | 4.51:1 | **Interactive Teal.** Anywhere stronger contrast is required: buttons, links, interactive text, controls, selected application states — any use where teal carries text or must independently pass 3:1+. |

Both tokens are approved and permanent. `color.interactive.teal` is not a private substitute for the brand color — it is the documented, correct token to reach for whenever teal is doing interactive/text work. `color.brand.route-teal` stays the token for graphical/decorative brand expression.

---

## 2. Neutrals

| Token | Hex | Contrast vs. white | Use |
|---|---|---|---|
| `color.text.primary` | `#101F27` | 16.84:1 | Primary text, headings |
| `color.text.secondary` | `#3E535C` | 8.09:1 | Secondary text, supporting copy |
| `color.text.muted` | `#64777E` | 4.69:1 | Metadata, timestamps, captions (still real text — passes AA) |
| `color.text.disabled` | `#9AACB2` | 2.35:1 | Disabled labels only (WCAG exempts disabled content from contrast requirements) |
| `color.border.subtle` | `#D5DEE1` | 1.37:1 | Decorative dividers, table row separators — not for essential boundaries (see below) |
| `color.border.strong` | `#7C8E93` | 3.42:1 | Input borders, essential UI boundaries — meets WCAG 1.4.11 non-text 3:1 |
| `color.surface.app` | `#F6F9FA` | — | Application background |
| `color.surface.secondary` | `#EEF3F4` | — | Secondary/recessed surface |
| `color.surface.elevated` | `#FFFFFF` | — | Elevated surface (cards, panels, modals) |
| `color.surface.hover` | `#E7EEF0` | — | Hover state background |

**Rule:** `color.border.subtle` is decorative only. Any border that is the *sole* indicator of an interactive boundary (text input, select, essential grouping) must use `color.border.strong` or be paired with a fill/label — not `color.border.subtle` alone.

## 3. Semantic Colors

Each family provides text, background, border, and a strong indicator (for dots/icon fill). Text-on-background pairs below all pass WCAG AA (≥4.5:1). Borders are intentionally soft — badges must always carry a text label and are never color-only (see [interface-principles.md](./interface-principles.md) §4).

### Success
| Token | Hex | Note |
|---|---|---|
| `color.success.text` | `#1C7A4D` | 4.70:1 on `success.bg` |
| `color.success.bg` | `#E6F4EC` | |
| `color.success.border` | `#A9D9BE` | decorative |
| `color.success.strong` | `#1C7A4D` | icon fill / dot |

### Warning
| Token | Hex | Note |
|---|---|---|
| `color.warning.text` | `#8A5A12` | 5.21:1 on `warning.bg` |
| `color.warning.bg` | `#FCEFD9` | derived from `color.brand.arrival-gold` |
| `color.warning.border` | `#EBC888` | decorative |
| `color.warning.strong` | `#F4B860` (`color.brand.arrival-gold`) | icon fill / dot only, never text |

Warning is the one semantic family deliberately tied to the brand accent (Arrival Gold), consistent with its documented "attention states where semantically appropriate" role. It stays restrained: light tint background + dark text, gold reserved for the indicator only.

### Critical / Error
| Token | Hex | Note |
|---|---|---|
| `color.critical.text` | `#B3261E` | 5.58:1 on `critical.bg` |
| `color.critical.bg` | `#FBE9E7` | |
| `color.critical.border` | `#F3B7B0` | decorative |
| `color.critical.strong` | `#B3261E` | icon fill / dot |

### Informational
| Token | Hex | Note |
|---|---|---|
| `color.info.text` | `#1D5F91` | 5.93:1 on `info.bg` |
| `color.info.bg` | `#E7F1FA` | |
| `color.info.border` | `#AFD3EC` | decorative |
| `color.info.strong` | `#1D5F91` | icon fill / dot |

All four semantic hues are deliberately desaturated relative to Tailwind-default equivalents, to stay within "restrained, suitable for healthcare/operations software."

---

## 4. Typography

**Brand/display family:** Manrope
**Application/UI family:** Inter

| Token | Family | Size | Line height | Weight | Use |
|---|---|---|---|---|---|
| `type.display` | Manrope | 48px / 3rem | 56px | 700 | Marketing hero headlines only |
| `type.page-title.marketing` | Manrope | 32px / 2rem | 40px | 600 | Public website page titles |
| `type.page-title.operational` | Inter | 32px / 2rem | 40px | 600 | Console/driver page titles — Inter substituted for Manrope here (see §5) |
| `type.section-heading` | Inter | 24px / 1.5rem | 32px | 600 | Section headings, all surfaces |
| `type.subsection-heading` | Inter | 18px / 1.125rem | 26px | 600 | Subsection headings |
| `type.body` | Inter | 16px / 1rem | 24px | 400 | Default body copy |
| `type.body-small` | Inter | 14px / 0.875rem | 20px | 400 | Secondary body copy, dense contexts |
| `type.label` | Inter | 13px / 0.8125rem | 18px | 500 | Form labels, field/section labels |
| `type.metadata` | Inter | 12px / 0.75rem | 16px | 400 | Timestamps, captions, muted metadata |
| `type.button` | Inter | 14px / 0.875rem | 20px | 600 | Button labels |
| `type.table` | Inter | 13px / 0.8125rem | 20px | 400 | Table cell text |
| `type.numeric-display` | Manrope | 40px / 2.5rem | 48px | 700 | Selective large numerical displays only (a genuine operational figure, never decorative) |

Eleven steps total, deliberately capped — no additional sizes without design review.

## 5. Spacing

Base unit: 4px. Semantic tokens layer on top of the raw scale so intent stays legible in code.

| Token | Value | Typical use |
|---|---|---|
| `space.2xs` | 2px | Icon-to-label micro gaps |
| `space.xs` | 4px | Tightest internal padding (badges, chips) |
| `space.sm` | 8px | Compact control padding, table cell vertical padding |
| `space.md` | 16px | Default component padding, form field spacing |
| `space.lg` | 24px | Card/panel padding, spacing between related groups |
| `space.xl` | 32px | Spacing between distinct sections (operational surfaces) |
| `space.2xl` | 48px | Section spacing on spacious/marketing surfaces |
| `space.3xl` | 64px | Major marketing section breaks |
| `space.4xl` | 80px | Marketing hero-level spacing |

**Principles (detail in [visual-system.md](./visual-system.md) §4):** operational/dispatch surfaces should generally stay within `xs`–`xl`; `2xl`–`4xl` are reserved for the public website. Table rows use `sm` vertical / `md` horizontal padding, not `lg`.

## 6. Radius

| Token | Value | Use |
|---|---|---|
| `radius.xs` | 6px | Small controls: checkboxes, small icon buttons, chips |
| `radius.sm` | 8px | Inputs, selects, small buttons |
| `radius.md` | 10px | Standard panels, cards, dialogs |
| `radius.lg` | 14px | Large marketing-only cards/sections |
| `radius.full` | 999px | Pills: status badges, tags, segmented controls — reserved for genuinely pill-shaped elements, not general containers |

## 7. Borders & Shadows

| Token | Value | Use |
|---|---|---|
| `border.width.default` | 1px | Standard borders |
| `border.width.strong` | 1.5px | Selected/active state borders |
| `border.width.focus` | 2px | Focus ring |
| `shadow.sm` | `0 1px 2px rgba(16,31,39,0.06), 0 1px 3px rgba(16,31,39,0.08)` | Menus, popovers, dropdowns |
| `shadow.md` | `0 2px 4px rgba(16,31,39,0.08), 0 4px 12px rgba(16,31,39,0.12)` | Modals, dialogs |

Only two shadow levels are defined. A third level requires design review — hierarchy should come from typography, background, spacing, and borders first (see [interface-principles.md](./interface-principles.md) §1).

## 8. Motion

| Token | Value | Use |
|---|---|---|
| `motion.duration.fast` | 120ms | Hover/press micro-feedback |
| `motion.duration.base` | 200ms | State transitions, menu/dropdown open-close |
| `motion.duration.slow` | 280ms | Drawer/dialog enter-exit |
| `motion.easing.standard` | `cubic-bezier(0.2, 0, 0, 1)` | Default easing for all transitions |

All motion must respect `prefers-reduced-motion` — see [interface-principles.md](./interface-principles.md) §7.

---

## 9. Methodology Note

Contrast figures were computed programmatically from the WCAG 2.1 relative luminance formula, not estimated by eye. Anyone implementing these tokens should re-verify with the actual rendering engine/color space in use before shipping, but the values above are not placeholders — they were chosen specifically to clear AA thresholds where text is involved.

**Related documents:** [visual-system.md](./visual-system.md) · [interface-principles.md](./interface-principles.md)
