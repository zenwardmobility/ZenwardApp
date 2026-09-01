import type { Metadata, Viewport } from "next";
import { Manrope, Inter } from "next/font/google";
import "./globals.css";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
  weight: ["600", "700"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  title: "Zenward Mobility",
  description: "Non-emergency medical transportation.",
};

/**
 * `viewportFit: "cover"` lets the Driver shell's fixed header/bottom-nav
 * read `env(safe-area-inset-*)` on notched devices (P1-E3-S2, work item
 * §44). Harmless on Operations/desktop — it only changes behavior on
 * devices that report a safe-area inset at all.
 */
export const viewport: Viewport = {
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${manrope.variable} ${inter.variable} h-full`}>
      <body className="min-h-full font-sans text-text-primary antialiased">
        {children}
      </body>
    </html>
  );
}
