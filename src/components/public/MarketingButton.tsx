import { Button, type ButtonProps } from "@/components/ui/Button";

export type MarketingButtonProps = Omit<ButtonProps, "size">;

/** Button sized for the public site — same variants/tokens as the console Button, larger touch target. */
export function MarketingButton(props: MarketingButtonProps) {
  return <Button size="lg" {...props} />;
}
