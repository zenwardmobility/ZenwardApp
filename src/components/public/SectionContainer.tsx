import type { HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface SectionContainerProps extends HTMLAttributes<HTMLElement> {
  children: ReactNode;
}

/** Max-width, responsive-gutter wrapper for a marketing page section. */
export function SectionContainer({ className, children, ...props }: SectionContainerProps) {
  return (
    <section className={cn("py-2xl lg:py-3xl", className)} {...props}>
      <div className="mx-auto max-w-6xl px-md lg:px-xl">{children}</div>
    </section>
  );
}
