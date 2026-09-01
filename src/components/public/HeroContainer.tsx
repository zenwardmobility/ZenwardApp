import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

export interface HeroContainerProps {
  tone?: "app" | "mist";
  children: ReactNode;
  className?: string;
}

const toneClasses = {
  app: "bg-surface-app",
  mist: "bg-brand-calm-mist",
} as const;

/** Plain, generous hero wrapper — deliberately no gradient, no glow, no imagery treatment baked in. */
export function HeroContainer({ tone = "app", children, className }: HeroContainerProps) {
  return (
    <div className={cn(toneClasses[tone], className)}>
      <div className="mx-auto max-w-6xl px-zw-md py-zw-3xl lg:px-zw-xl lg:py-zw-4xl">{children}</div>
    </div>
  );
}
