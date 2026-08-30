# Zenward Mobility — Interface Principles

**Work item:** P0-E2-S1 — Visual System Specification
**Status:** Draft, pending design review
**Last updated:** 2026-08-29

Component-level behavioral patterns for the Zenward interface. These are patterns to follow when screens are eventually built — no components were built under this work item. Token values referenced here live in [design-tokens.md](./design-tokens.md); overall direction and rationale is in [visual-system.md](./visual-system.md).

---

## 1. Card Rule

Cards are **not** the default solution for every piece of content. Use a card only when information genuinely belongs to a distinct, grouped object (a single trip, a single driver, a single facility).

Prefer, where more appropriate: sections, rows, tables, lists, dividers, panels. A list of trips is a table, not a grid of trip cards. A page's content areas are sections separated by spacing and dividers, not cards nested inside cards.

This rule exists specifically to prevent the generic "repeated card grid" pattern (see §8) from becoming the default answer to "how do I lay this out."

## 2. Button System

**Hierarchy:**

| Level | Typical color | Use |
|---|---|---|
| Primary | `color.interactive.teal` fill, white label | The single main action on a screen |
| Secondary / Strong | Care Navy or neutral outline, depending on context | A strong but non-primary action |
| Tertiary | Neutral, low-emphasis | Supporting action, lower visual weight than secondary |
| Ghost | Text-only or minimal treatment | Navigation or supporting action where a full button would compete for attention |
| Destructive | Critical red family | Reserved only for genuinely destructive operations (e.g., cancel trip, remove driver) |

**Required states for every button:** default, hover, pressed, focus, disabled, loading. Focus must use `border.width.focus` (2px) with `color.interactive.teal` or an equivalent visible ring — never rely on browser default alone, and never remove focus styling.

**Rule:** never place multiple competing primary buttons on the same operational screen. One primary action per screen/panel context; everything else is secondary, tertiary, or ghost.

## 3. Form System

Applies to: text input, textarea, select, autocomplete, date/time input, search, checkbox, radio, toggle.

- Inputs use `radius.sm` (8px) and `color.border.strong` by default — the border is essential to the input's legibility as a field, so it must use the accessible border token, not the decorative one.
- Every field has a visible label (`type.label`) — placeholder text is never a substitute for a label.
- **Required state:** marked on the label itself (e.g., a subtle indicator), not conveyed by color alone.
- **Error state:** border switches to `color.critical.border`/`color.critical.strong`, and an explicit error message appears in `color.critical.text` beneath the field — the message is the primary signal, the red border reinforces it.
- **Disabled state:** `color.text.disabled` and `color.border.subtle`, and disabled fields are excluded from tab order.
- **Help text:** `type.metadata` in `color.text.muted`, placed below the field, always present when a field's expected format isn't self-evident (e.g., phone number format, date format).
- Forms optimize for operational speed and accessibility over decorative styling — this matters most in the Operations Console and any facility-facing intake form, where a dispatcher or facility staffer may fill the same form repeatedly under time pressure.

## 4. Status System

Zenward will eventually contain meaningful trip and operational statuses. A possible status list was sketched in product discovery (Requested, Scheduled, Assigned, En Route, Arrived, Passenger Onboard, Completed, Cancelled, No Show, Attention Required) — **this list is not finalized** and remains subject to product/workflow validation (see [decision-register.md](../product/decision-register.md) ZD-015). Design review (P0-E2-S1 gate) reaffirmed this: the visual system may define status *presentation* categories, but the actual Zenward trip state machine is established during transportation workflow/domain modelling. This document does not treat the sketched list as a state machine implementation, and it must not be converted into application logic ahead of that domain work.

Instead, this establishes a **visual status system** — a set of visual categories any eventual status can be mapped onto:

| Category | Maps to semantic family | Example (illustrative, not final) |
|---|---|---|
| Neutral | Neutral surface, `color.text.secondary` | Draft/unscheduled |
| Informational | Info | Requested, Scheduled |
| Active | Interactive teal | En Route, In Progress |
| Positive | Success | Arrived, Passenger Onboard |
| Warning | Warning | Delayed, Attention Required |
| Critical | Critical | No Show, exception blocking the trip |
| Completed | Success (distinct treatment from "Positive" in-progress states — e.g. filled vs. outlined indicator) | Completed |
| Cancelled | Neutral/muted, not critical red | Cancelled — a cancellation is not necessarily an error, so it should not visually alarm the same way a critical exception does |

**Rules:**
- Status communicates through **label text + subtle background + a restrained indicator** (a small dot or icon), never color alone.
- No rainbow of bright, highly saturated badges — every status badge uses the same restrained semantic palette from [design-tokens.md](./design-tokens.md) §3.
- A badge without a text label is not acceptable anywhere in the product.

## 5. Table System

Given how much of Zenward's operational software will depend on tables:

| Element | Pattern |
|---|---|
| Header | `type.label`, `color.text.secondary`, sits on `color.surface.secondary`, sticky on scroll for long tables |
| Row | `type.table`, `space.sm` vertical padding, `color.border.subtle` divider between rows |
| Hover row | `color.surface.hover` background, no shadow |
| Selected row | `color.surface.hover` background + `color.border.strong` or teal left-edge indicator, not background color alone |
| Status | Uses the status system (§4) inline in a dedicated column, not embedded in prose |
| Primary cell | `color.text.primary`, carries the row's identity (e.g., passenger name, trip ID) |
| Secondary/metadata cell | `color.text.muted`, `type.metadata` or `type.table` depending on density need |
| Actions | Right-aligned, ghost or tertiary buttons/icons, revealed on hover where the table is dense, always reachable via keyboard regardless |
| Filters | Sit above the table, use standard form controls (§3), never invent a separate filter-only style |
| Pagination | Standard, positioned below the table; page size should favor operational scanning over infinite scroll for dispatch-critical tables |
| Empty state | A real explanation of why the table is empty and, where relevant, the action to take next — never a bare "No data" |

**Rule:** do not transform every table row into a large card. Density and scannability are the point of a table; a dispatcher scanning 40 trips needs rows, not cards.

## 6. Iconography Rules (implementation detail)

Approved direction: **Phosphor Icons**, Regular and Medium weights (see [visual-system.md](./visual-system.md) §7, [ZD-031](../product/decision-register.md)). At implementation time: use Phosphor exclusively, keep stroke weight consistent across all sizes, avoid duotone styling in operational UI, and never pair an icon with a colored circle purely for decoration next to a heading — the icon should be doing comprehension work or it shouldn't be there. The package itself has not been installed as part of any documentation work item.

## 7. Accessibility

- **Contrast:** all text/background pairs must meet WCAG AA (4.5:1 normal text, 3:1 large text ≥18.66px or ≥14px bold); UI component boundaries (inputs, focus indicators) must meet the 3:1 non-text threshold. [design-tokens.md](./design-tokens.md) documents verified ratios for every defined pair.
- **Keyboard navigation:** every interactive element reachable and operable via keyboard alone, in a logical order matching visual layout.
- **Focus visibility:** a visible focus ring (§2) on every focusable element — never `outline: none` without a replacement.
- **Touch target sizing:** minimum 44×44px for any tappable control, especially in the driver interface.
- **Error communication:** never color-only (§3) — always paired with text.
- **Form labels:** always present and programmatically associated with their control (§3).
- **Screen reader semantics:** semantic HTML/ARIA roles reflect actual structure — status badges, table headers, and navigation landmarks must be identifiable by assistive technology, not just visually styled.
- **Status communication not based only on color:** enforced by §4.
- **Reduced motion:** all motion (see [visual-system.md](./visual-system.md) §9) must respect `prefers-reduced-motion`, reducing to instant/opacity-only transitions.
- **Mobile legibility:** minimum `type.body-small` (14px) for any essential reading content on mobile; nothing critical smaller than that.

**Driver interface specifically** must anticipate use in daylight, in vehicles, on small mobile screens, and under time pressure. This means: higher-contrast defaults than the baseline minimums where practical, larger touch targets than the 44px floor for primary actions, and never more than one dominant next action on screen. Usability is not traded away for visual minimalism here — clarity under pressure outranks restraint when the two conflict on this surface specifically.

## 8. Anti-AI Design Rules

Zenward must avoid the visual and structural patterns that read as generic, template-generated SaaS:

- Excessive rounded cards
- Giant gradient hero sections
- Glassmorphism used without purpose
- Random KPI cards
- Decorative charts
- Meaningless statistics
- Fake live maps
- Arbitrary glowing elements
- Excessive icon circles
- Generic AI illustrations
- Random purple/blue gradients
- Oversized empty dashboard layouts
- Repeated card grids
- Invented product credibility (fabricated stats, testimonials, customers, trust badges)

**Every interface must originate from a real transportation workflow.** If a screen element can't be traced to an actual operational task or a real piece of information a user needs, it doesn't belong on the screen — regardless of whether it would "look complete."

---

**Related documents:** [visual-system.md](./visual-system.md) · [design-tokens.md](./design-tokens.md) · [product-definition.md](../product/product-definition.md)
