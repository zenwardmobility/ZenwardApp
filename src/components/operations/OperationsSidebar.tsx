"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { MapPin } from "@phosphor-icons/react/dist/ssr";
import { navIcons } from "@/design/icons";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { Avatar } from "@/components/ui/Avatar";

// P1-E3-S8B1 (work item §26/§32): Billing and Reports are removed from
// visible navigation — both routes remain real Next.js pages on disk
// (still reachable directly if ever needed for internal testing), but
// neither has real product behavior yet, and a visible sidebar entry
// leading to it would be exactly the "convincing-looking dead
// navigation" this phase exists to close. Restore once each has a real
// screen, not merely to fill this list back out.
const NAV_ITEMS: { key: keyof typeof navIcons; label: string; href: string }[] = [
  { key: "overview", label: "Overview", href: "/operations" },
  { key: "trips", label: "Trips", href: "/operations/trips" },
  { key: "dispatch", label: "Dispatch", href: "/operations/dispatch" },
  { key: "passengers", label: "Passengers", href: "/operations/passengers" },
  { key: "facilities", label: "Facilities", href: "/operations/facilities" },
  { key: "drivers", label: "Drivers", href: "/operations/drivers" },
  { key: "fleet", label: "Fleet", href: "/operations/fleet" },
];

export interface OperationsSidebarProps {
  /**
   * Sample operating context to render in the bottom rail — not a product
   * decision about the actual launch territory. That remains ZD-016
   * UNKNOWN; callers supply whatever the real operating unit is.
   */
  location: string;
  orgUnit: string;
  dispatcherName: string;
  dispatcherRole?: string;
}

/**
 * The one OperationsSidebar. Do not fork per-route copies (TripsSidebar,
 * DispatchSidebar, etc.) — the active route changes state, the shell doesn't.
 * Full labels at lg+, icon-only rail at md–lg (tablet). Hidden below md — see
 * OperationsShell for the narrow-width guard state that replaces it there.
 */
export function OperationsSidebar({
  location,
  orgUnit,
  dispatcherName,
  dispatcherRole,
}: OperationsSidebarProps) {
  const pathname = usePathname();

  return (
    <aside className="hidden shrink-0 flex-col bg-navy-surface md:flex md:w-16 lg:w-64">
      <div className="flex h-16 items-center border-b border-navy-border px-4 lg:px-6">
        {/*
          P1-E3-S4A: the approved Zenward Mobility logo — the same asset
          already used on /sign-in (P1-E3-S2A), reused here rather than the
          legacy plain-text "Zenward"/"Z" treatment this sidebar previously
          rendered. One <Image>, sized responsively (constrained at lg+ so
          it doesn't dominate navigation; smaller still in the md
          icon-only rail) rather than a fabricated compact-only mark — no
          second approved asset exists, so the same artwork is simply
          rendered smaller, never cropped or distorted (natural aspect
          ratio preserved via `h-auto`). See docs/reports/
          P1-E3-S4A-operations-brand-consistency-report.txt.

          P1-E3-S8B: the sidebar itself converges to the canonical Stitch
          references' dark Care Navy treatment (docs/design/stitch/
          references/01-todays-operations.png etc.) — every prior phase
          left it light, an accepted-but-unconverged deviation this phase's
          own mandate exists to close. The logo asset is unchanged (still
          the one approved PNG, natural aspect ratio); only the
          surrounding chrome (background, nav text/hover/active tokens,
          borders) moved to the new --color-navy-* set added in
          globals.css, reserved for this sidebar alone.

          The logo file itself is a flat RGB PNG with an opaque white
          background baked in (no alpha channel) — confirmed directly,
          not assumed. Placed straight on navy it shows as a jarring
          white rectangle. Per the brand rules, the artwork itself is
          never redesigned/cropped/recolored — the fix is a small,
          plain white badge chip behind it (a genuinely common, accepted
          pattern for a light-background mark on a dark shell, not a
          decorative device), never touching the PNG's own pixels.
        */}
        <span className="inline-flex items-center rounded-sm bg-white p-1.5 lg:p-2">
          <Image
            src="/images/zenward-mobility-logo.png"
            alt="Zenward Mobility"
            width={217}
            height={72}
            priority
            className="h-auto w-7 lg:w-24"
          />
        </span>
      </div>

      <nav aria-label="Primary" className="flex-1 overflow-y-auto px-2 py-3 lg:px-3">
        <ul className="flex flex-col gap-1">
          {NAV_ITEMS.map((item) => {
            const Icon = navIcons[item.key];
            const isActive =
              item.href === "/operations" ? pathname === item.href : pathname.startsWith(item.href);
            return (
              <li key={item.key}>
                <Link
                  href={item.href}
                  aria-current={isActive ? "page" : undefined}
                  title={item.label}
                  className={cn(
                    typography.bodySmall,
                    "flex items-center gap-3 rounded-sm px-3 py-2 font-medium transition-colors duration-base",
                    isActive
                      ? "bg-navy-active-bg text-navy-active-text"
                      : "text-navy-text-muted hover:bg-navy-hover-bg hover:text-white",
                  )}
                >
                  <Icon className="size-5 shrink-0" weight={isActive ? "fill" : "regular"} aria-hidden />
                  <span className="hidden lg:inline">{item.label}</span>
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="border-t border-navy-border px-3 py-3 lg:px-4">
        <div className="hidden items-center gap-2 px-1 pb-3 text-navy-text-muted lg:flex">
          <MapPin className="size-4 shrink-0" aria-hidden />
          <div className={typography.metadata}>
            <p>{location}</p>
            <p>{orgUnit}</p>
          </div>
        </div>

        <div className="flex items-center gap-3 px-1">
          <Avatar name={dispatcherName} size="sm" />
          {/*
            P1-E3-S8C1 (work item §2): `min-w-0` is required here — without
            it, a flex child with no explicit width never actually shrinks
            below its content's natural size, so `truncate` on the <p>s
            below had nothing to truncate AGAINST and a long identity value
            (a full email address, in Harmony's own case before real
            `user_profiles.display_name` rows existed — see supabase/
            seed.sql) simply overflowed the fixed-width sidebar instead of
            ellipsizing cleanly. `title` restores the full value on hover
            for anyone who needs it, since the visible text itself is now
            deliberately allowed to clip.
          */}
          <div className="hidden min-w-0 flex-1 lg:block">
            <p className={cn(typography.bodySmall, "truncate font-medium text-white")} title={dispatcherName}>
              {dispatcherName}
            </p>
            {dispatcherRole && (
              <p className={cn(typography.metadata, "truncate text-navy-text-muted")} title={dispatcherRole}>
                {dispatcherRole}
              </p>
            )}
          </div>
        </div>
      </div>
    </aside>
  );
}
