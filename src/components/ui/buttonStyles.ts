import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export type ButtonVariant = "primary" | "secondary" | "outline" | "text" | "destructive";
export type ButtonSize = "sm" | "md" | "lg";

export const buttonVariantClasses: Record<ButtonVariant, string> = {
  primary: "bg-brand-interactive-teal text-white hover:brightness-95 active:brightness-90",
  secondary: "bg-brand-care-navy text-white hover:brightness-110 active:brightness-95",
  outline: "border border-border-strong bg-surface-elevated text-text-primary hover:bg-surface-hover",
  text: "bg-transparent text-brand-interactive-teal hover:bg-surface-hover",
  destructive: "bg-critical-strong text-white hover:brightness-95 active:brightness-90",
};

export const buttonSizeClasses: Record<ButtonSize, string> = {
  sm: "h-8 px-3 rounded-xs gap-1.5",
  md: "h-10 px-4 rounded-sm gap-2",
  lg: "h-12 px-6 rounded-md gap-2",
};

export function buttonClassNames(
  variant: ButtonVariant,
  size: ButtonSize,
  disabled: boolean | undefined,
  className?: string,
) {
  return cn(
    "inline-flex items-center justify-center whitespace-nowrap transition-colors duration-base ease-standard",
    disabled && "cursor-not-allowed opacity-50",
    typography.button,
    buttonVariantClasses[variant],
    buttonSizeClasses[size],
    className,
  );
}
