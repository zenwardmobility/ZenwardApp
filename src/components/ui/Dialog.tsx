"use client";

import { useEffect, useId, useRef } from "react";
import type { ReactNode } from "react";
import { X } from "@phosphor-icons/react/dist/ssr";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { IconButton } from "./IconButton";

export interface DialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  className?: string;
}

/**
 * A minimal, accessible modal built on the native `<dialog>` element
 * rather than a new UI library (work item §53 — "do not introduce a
 * heavyweight UI library solely for one modal"; no Dialog/Modal primitive
 * existed in the design system before this). `showModal()` gives real
 * focus trapping and top-layer stacking for free; the native `close`
 * event (fired by ESC and by `<form method="dialog">`, if ever used)
 * drives `onClose` so React state and DOM state can't drift apart.
 * Clicking the backdrop (a click whose target is the `<dialog>` element
 * itself, not its content) also closes — the same convention most modal
 * libraries use. Backdrop styling lives in globals.css (`dialog::backdrop`)
 * since Tailwind v4's own `backdrop:` variant support isn't relied on.
 */
export function Dialog({ open, onClose, title, description, children, className }: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const descriptionId = useId();

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open]);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    const handleClose = () => onClose();
    dialog.addEventListener("close", handleClose);
    return () => dialog.removeEventListener("close", handleClose);
  }, [onClose]);

  return (
    <dialog
      ref={ref}
      aria-labelledby={titleId}
      aria-describedby={description ? descriptionId : undefined}
      onClick={(event) => {
        if (event.target === ref.current) onClose();
      }}
      onCancel={(event) => {
        // Native ESC handling — let the dialog's own `close` event (above)
        // drive React state instead of duplicating the call here.
        event.preventDefault();
        ref.current?.close();
      }}
      className={cn(
        "m-auto w-full max-w-md rounded-md border border-border-subtle bg-surface-elevated p-0 shadow-lg",
        className,
      )}
    >
      <div className="flex items-start justify-between gap-4 border-b border-border-subtle p-zw-lg">
        <div>
          <h2 id={titleId} className={cn(typography.subsectionHeading, "text-text-primary")}>
            {title}
          </h2>
          {description && (
            <p id={descriptionId} className={cn(typography.bodySmall, "mt-1 text-text-secondary")}>
              {description}
            </p>
          )}
        </div>
        <IconButton label="Close" icon={<X className="size-4" aria-hidden />} onClick={onClose} />
      </div>
      <div className="p-zw-lg">{children}</div>
    </dialog>
  );
}
