/**
 * Typography tokens. See /docs/design/design-tokens.md §4.
 *
 * Each entry is a fixed Tailwind class string covering family, size, line
 * height, and weight together — pages/components consume these instead of
 * improvising font sizes or families.
 */
export const typography = {
  /** Manrope. Marketing hero headlines only. */
  display: "font-display text-5xl font-bold leading-[56px] tracking-tight",
  /** Manrope. Public website page titles. */
  pageTitleMarketing: "font-display text-3xl font-semibold leading-10",
  /** Inter. Console/driver page titles — Inter substituted for Manrope here by design (see visual-system.md §3). */
  pageTitleOperational: "font-sans text-3xl font-semibold leading-10",
  /** Inter. Section headings, all surfaces. */
  sectionHeading: "font-sans text-2xl font-semibold leading-8",
  /** Inter. Subsection headings. */
  subsectionHeading: "font-sans text-lg font-semibold leading-[26px]",
  /** Inter. Default body copy. */
  body: "font-sans text-base font-normal leading-6",
  /** Inter. Secondary/dense body copy. */
  bodySmall: "font-sans text-sm font-normal leading-5",
  /** Inter. Form labels, field/section labels. */
  label: "font-sans text-[13px] font-medium leading-[18px]",
  /** Inter. Timestamps, captions, muted metadata. */
  metadata: "font-sans text-xs font-normal leading-4",
  /** Inter. Button labels. */
  button: "font-sans text-sm font-semibold leading-5",
  /** Inter. Table header cells. */
  tableHeader: "font-sans text-[13px] font-medium leading-[18px]",
  /** Inter. Table body cells. */
  tableCell: "font-sans text-[13px] font-normal leading-5",
  /** Manrope. Selective large numerical displays only — never decorative. */
  numericDisplay: "font-display text-4xl font-bold leading-[48px]",
} as const;

export type TypographyToken = keyof typeof typography;
