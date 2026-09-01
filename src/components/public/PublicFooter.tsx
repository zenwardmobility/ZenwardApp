import Link from "next/link";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface PublicFooterLink {
  label: string;
  href: string;
}

export interface PublicFooterProps {
  links?: PublicFooterLink[];
  /** Only rendered if supplied — public contact information is unresolved (ZD-027). Do not hardcode a placeholder here. */
  contactPhone?: string;
  contactEmail?: string;
}

export function PublicFooter({ links = [], contactPhone, contactEmail }: PublicFooterProps) {
  const hasContact = Boolean(contactPhone || contactEmail);

  return (
    <footer className="border-t border-border-subtle bg-surface-elevated">
      <div className="mx-auto max-w-6xl px-zw-md py-zw-xl lg:px-zw-xl">
        <div className="flex flex-col gap-6 md:flex-row md:items-start md:justify-between">
          <div>
            <p className={cn(typography.subsectionHeading, "text-brand-care-navy")}>Zenward Mobility</p>
            <p className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>Care that gets you there.</p>
          </div>

          {links.length > 0 && (
            <nav aria-label="Footer" className="flex flex-wrap gap-x-6 gap-y-2">
              {links.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={cn(typography.bodySmall, "text-text-secondary hover:text-text-primary")}
                >
                  {link.label}
                </Link>
              ))}
            </nav>
          )}

          {hasContact && (
            <div className={cn(typography.bodySmall, "text-text-secondary")}>
              {contactPhone && <p>{contactPhone}</p>}
              {contactEmail && <p>{contactEmail}</p>}
            </div>
          )}
        </div>

        <p className={cn(typography.metadata, "mt-8 text-text-muted")}>
          © {new Date().getFullYear()} Zenward Mobility
        </p>
      </div>
    </footer>
  );
}
