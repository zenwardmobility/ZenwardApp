"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Gear, MapPin } from "@phosphor-icons/react/dist/ssr";
import { navIcons } from "@/design/icons";
import { cn } from "@/lib/cn";
import { typography } from "@/design/typography";
import { Avatar } from "@/components/ui/Avatar";

const NAV_ITEMS: { key: keyof typeof navIcons; label: string; href: string }[] = [
  { key: "overview", label: "Overview", href: "/operations" },
  { key: "trips", label: "Trips", href: "/operations/trips" },
  { key: "dispatch", label: "Dispatch", href: "/operations/dispatch" },
  { key: "passengers", label: "Passengers", href: "/operations/passengers" },
  { key: "facilities", label: "Facilities", href: "/operations/facilities" },
  { key: "drivers", label: "Drivers", href: "/operations/drivers" },
  { key: "fleet", label: "Fleet", href: "/operations/fleet" },
  { key: "billing", label: "Billing", href: "/operations/billing" },
  { key: "reports", label: "Reports", href: "/operations/reports" },
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
  settingsHref?: string;
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
  settingsHref = "/operations/settings",
}: OperationsSidebarProps) {
  const pathname = usePathname();

  return (
    <aside className="hidden shrink-0 flex-col border-r border-border-subtle bg-surface-elevated md:flex md:w-16 lg:w-64">
      <div className="flex h-16 items-center border-b border-border-subtle px-4 lg:px-6">
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
        */}
        <Image
          src="/images/zenward-mobility-logo.png"
          alt="Zenward Mobility"
          width={217}
          height={72}
          priority
          className="h-auto w-9 lg:w-28"
        />
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
                      ? "bg-brand-calm-mist text-brand-interactive-teal"
                      : "text-text-secondary hover:bg-surface-hover hover:text-text-primary",
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

      <div className="border-t border-border-subtle px-3 py-3 lg:px-4">
        <div className="hidden items-center gap-2 px-1 pb-3 text-text-muted lg:flex">
          <MapPin className="size-4 shrink-0" aria-hidden />
          <div className={typography.metadata}>
            <p>{location}</p>
            <p>{orgUnit}</p>
          </div>
        </div>

        <Link
          href={settingsHref}
          title="Settings"
          className={cn(
            typography.bodySmall,
            "flex items-center gap-3 rounded-sm px-3 py-2 font-medium text-text-secondary hover:bg-surface-hover hover:text-text-primary",
          )}
        >
          <Gear className="size-5 shrink-0" aria-hidden />
          <span className="hidden lg:inline">Settings</span>
        </Link>

        <div className="mt-2 flex items-center gap-3 px-1">
          <Avatar name={dispatcherName} size="sm" />
          <div className="hidden lg:block">
            <p className={cn(typography.bodySmall, "font-medium text-text-primary")}>{dispatcherName}</p>
            {dispatcherRole && <p className={cn(typography.metadata, "text-text-muted")}>{dispatcherRole}</p>}
          </div>
        </div>
      </div>
    </aside>
  );
}
