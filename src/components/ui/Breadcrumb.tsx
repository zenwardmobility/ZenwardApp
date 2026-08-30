import Link from "next/link";
import { CaretRight } from "@phosphor-icons/react/dist/ssr";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface BreadcrumbItem {
  label: string;
  href?: string;
}

export interface BreadcrumbProps {
  items: BreadcrumbItem[];
  className?: string;
}

export function Breadcrumb({ items, className }: BreadcrumbProps) {
  return (
    <nav aria-label="Breadcrumb" className={className}>
      <ol className="flex flex-wrap items-center gap-1.5">
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          return (
            <li key={`${item.label}-${index}`} className="flex items-center gap-1.5">
              {item.href && !isLast ? (
                <Link
                  href={item.href}
                  className={cn(typography.bodySmall, "text-text-secondary hover:text-text-primary")}
                >
                  {item.label}
                </Link>
              ) : (
                <span
                  aria-current={isLast ? "page" : undefined}
                  className={cn(typography.bodySmall, isLast ? "text-text-primary" : "text-text-secondary")}
                >
                  {item.label}
                </span>
              )}
              {!isLast && <CaretRight className="size-3 text-text-disabled" aria-hidden />}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
