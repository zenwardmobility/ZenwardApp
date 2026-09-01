import Link from "next/link";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { LinkButton } from "@/components/ui/LinkButton";

export interface PublicNavLink {
  label: string;
  href: string;
}

export interface PublicHeaderProps {
  links?: PublicNavLink[];
  ctaLabel?: string;
  ctaHref?: string;
}

/**
 * Shared public-site header primitive. Callers supply real nav links —
 * this component doesn't assume a page structure that hasn't been decided.
 */
export function PublicHeader({ links = [], ctaLabel, ctaHref }: PublicHeaderProps) {
  return (
    <header className="border-b border-border-subtle bg-surface-elevated">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-zw-md lg:px-zw-xl">
        <Link href="/" className={cn(typography.subsectionHeading, "text-brand-care-navy")}>
          Zenward Mobility
        </Link>
        {links.length > 0 && (
          <nav aria-label="Primary" className="hidden items-center gap-6 md:flex">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={cn(typography.bodySmall, "font-medium text-text-secondary hover:text-text-primary")}
              >
                {link.label}
              </Link>
            ))}
          </nav>
        )}
        {ctaLabel && ctaHref && (
          <LinkButton href={ctaHref} size="sm">
            {ctaLabel}
          </LinkButton>
        )}
      </div>
    </header>
  );
}
