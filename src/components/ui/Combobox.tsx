"use client";

import { useId, useMemo, useRef, useState } from "react";
import type { KeyboardEvent } from "react";
import { MagnifyingGlass } from "@phosphor-icons/react/dist/ssr";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";

export interface ComboboxOption {
  value: string;
  /** Primary label — also what's matched against the typed query. */
  label: string;
  /** Secondary, de-emphasized line (e.g. a phone number) — shown in the
   * option row and also matched against the typed query, so searching
   * "555-0184" finds a Passenger by phone, not just by name. */
  secondaryLabel?: string;
}

export interface ComboboxProps {
  label: string;
  options: ComboboxOption[];
  onSelect: (option: ComboboxOption) => void;
  placeholder?: string;
  noResultsText?: string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
}

/**
 * A real, accessible search-select primitive (P1-E3-S8B, work item §20) —
 * replaces the native `<select>` this project's own New Trip Passenger
 * field temporarily used since P1-E3-S7 (the reference's own richer
 * search/select behavior, work item §21). Implements the WAI-ARIA
 * "combobox with list autocomplete, manual selection" pattern:
 * https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ — `role="combobox"`
 * on the input, a `role="listbox"` popup, `role="option"` rows,
 * `aria-activedescendant` tracking the highlighted row (not DOM focus
 * itself, which stays on the input), full keyboard support (Up/Down/
 * Home/End/Enter/Escape), and a real empty state.
 *
 * Deliberately uncontrolled about "the current selection" — this
 * component only ever represents the SEARCHING state. Once a caller's
 * `onSelect` fires, the caller is expected to stop rendering this
 * component and show its own selected-item treatment instead (e.g. an
 * Avatar + name + a Remove control) — decoupled because what "selected"
 * looks like varies by use case (Passenger vs. a future Facility/Request
 * use), while the search/filter/keyboard logic here does not.
 */
export function Combobox({
  label,
  options,
  onSelect,
  placeholder = "Search…",
  noResultsText = "No matches",
  required,
  disabled,
  id,
}: ComboboxProps) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const listboxId = `${inputId}-listbox`;
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter(
      (o) => o.label.toLowerCase().includes(q) || o.secondaryLabel?.toLowerCase().includes(q),
    );
  }, [options, query]);

  function commitSelection(option: ComboboxOption) {
    onSelect(option);
    setQuery("");
    setOpen(false);
    setActiveIndex(-1);
  }

  function handleKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      if (!open) {
        setOpen(true);
        setActiveIndex(0);
        return;
      }
      setActiveIndex((i) => (filtered.length === 0 ? -1 : Math.min(i + 1, filtered.length - 1)));
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setActiveIndex((i) => (filtered.length === 0 ? -1 : Math.max(i - 1, 0)));
    } else if (event.key === "Home" && open) {
      event.preventDefault();
      setActiveIndex(filtered.length > 0 ? 0 : -1);
    } else if (event.key === "End" && open) {
      event.preventDefault();
      setActiveIndex(filtered.length > 0 ? filtered.length - 1 : -1);
    } else if (event.key === "Enter") {
      if (open && activeIndex >= 0 && filtered[activeIndex]) {
        event.preventDefault();
        commitSelection(filtered[activeIndex]);
      }
    } else if (event.key === "Escape") {
      if (open) {
        event.preventDefault();
        setOpen(false);
        setActiveIndex(-1);
      }
    }
  }

  const activeOptionId = activeIndex >= 0 && filtered[activeIndex] ? `${listboxId}-option-${activeIndex}` : undefined;

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={inputId} className={cn(typography.label, "text-text-primary")}>
        {label}
        {required && (
          <span className="text-critical-text" aria-hidden>
            {" "}
            *
          </span>
        )}
      </label>
      <div className="relative">
        <MagnifyingGlass className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-text-muted" aria-hidden />
        <input
          ref={inputRef}
          id={inputId}
          type="text"
          role="combobox"
          aria-expanded={open}
          aria-controls={listboxId}
          aria-autocomplete="list"
          aria-activedescendant={activeOptionId}
          autoComplete="off"
          required={required}
          disabled={disabled}
          placeholder={placeholder}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
            setActiveIndex(0);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => {
            // Let a click on an option register (onMouseDown below commits
            // the selection) before the listbox unmounts on blur.
            window.setTimeout(() => setOpen(false), 120);
          }}
          onKeyDown={handleKeyDown}
          className={cn(
            typography.body,
            "h-10 w-full rounded-sm border border-border-strong bg-surface-elevated pl-9 pr-3 text-text-primary disabled:cursor-not-allowed disabled:bg-surface-secondary disabled:text-text-disabled",
          )}
        />
        {open && (
          <ul
            id={listboxId}
            role="listbox"
            aria-label={label}
            className="absolute z-10 mt-1 max-h-64 w-full overflow-y-auto rounded-sm border border-border-subtle bg-surface-elevated py-1 shadow-md"
          >
            {filtered.length === 0 ? (
              <li className={cn(typography.bodySmall, "px-3 py-2 text-text-muted")}>{noResultsText}</li>
            ) : (
              filtered.map((option, index) => (
                <li
                  key={option.value}
                  id={`${listboxId}-option-${index}`}
                  role="option"
                  aria-selected={index === activeIndex}
                  onMouseDown={(e) => {
                    // mousedown (not click) fires before the input's own
                    // onBlur — this is what lets a click-to-select work
                    // instead of losing to the blur-close timeout above.
                    e.preventDefault();
                    commitSelection(option);
                  }}
                  onMouseEnter={() => setActiveIndex(index)}
                  className={cn(
                    "flex cursor-pointer flex-col px-3 py-2",
                    index === activeIndex ? "bg-brand-calm-mist" : "hover:bg-surface-hover",
                  )}
                >
                  <span className={cn(typography.bodySmall, "font-medium text-text-primary")}>{option.label}</span>
                  {option.secondaryLabel && (
                    <span className={cn(typography.metadata, "text-text-muted")}>{option.secondaryLabel}</span>
                  )}
                </li>
              ))
            )}
          </ul>
        )}
      </div>
    </div>
  );
}
