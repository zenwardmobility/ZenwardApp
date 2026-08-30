import type { ReactNode } from "react";
import { PublicHeader } from "@/components/public/PublicHeader";
import { PublicFooter } from "@/components/public/PublicFooter";

/**
 * Shared shell for every public-site route (/, /request-transportation,
 * /healthcare-providers, ...). A route group ("(public)") so these stay
 * unprefixed URLs while sharing one PublicHeader/PublicFooter instance
 * instead of each page wrapping itself individually.
 *
 * Nav links are intentionally empty until the real site structure is
 * decided — PublicHeader doesn't assume pages that haven't been authorized.
 */
export default function PublicLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col">
      <PublicHeader
        links={[{ label: "For Healthcare Providers", href: "/healthcare-providers" }]}
        ctaLabel="Request Transportation"
        ctaHref="/request-transportation"
      />
      <main className="flex-1">{children}</main>
      <PublicFooter
        links={[
          { label: "Request Transportation", href: "/request-transportation" },
          { label: "For Healthcare Providers", href: "/healthcare-providers" },
        ]}
      />
    </div>
  );
}
