import { Button, type ButtonProps } from "@/components/ui/Button";
import { cn } from "@/lib/cn";

export type DriverPrimaryActionProps = Omit<ButtonProps, "size" | "variant">;

/**
 * The one dominant next action on a driver screen (e.g. "Mark Arrived").
 * Full-width, large touch target. Never pair two of these on one screen.
 */
export function DriverPrimaryAction({ className, ...props }: DriverPrimaryActionProps) {
  return <Button variant="primary" size="lg" className={cn("w-full", className)} {...props} />;
}
