import Link, { type LinkProps } from "next/link";
import type { AnchorHTMLAttributes, ReactNode } from "react";
import { buttonClassNames, type ButtonVariant, type ButtonSize } from "./buttonStyles";

export interface LinkButtonProps
  extends LinkProps,
    Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  leadingIcon?: ReactNode;
  trailingIcon?: ReactNode;
  children: ReactNode;
}

/** A navigation link styled with the same button classes as Button — for CTAs that go somewhere rather than perform an action. */
export function LinkButton({
  variant = "primary",
  size = "md",
  leadingIcon,
  trailingIcon,
  className,
  children,
  ...props
}: LinkButtonProps) {
  return (
    <Link className={buttonClassNames(variant, size, false, className)} {...props}>
      {leadingIcon}
      {children}
      {trailingIcon}
    </Link>
  );
}
