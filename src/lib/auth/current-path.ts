import "server-only";
import { headers } from "next/headers";

/**
 * Reads the pathname middleware.ts propagates via `x-zw-pathname` — the
 * only reliable way to know the current URL from inside a Server
 * Component layout in this Next.js version. Falls back to a sane default
 * if the header is somehow absent (e.g. a direct render path middleware
 * never saw), never throws.
 */
export async function getCurrentPathname(fallback: string): Promise<string> {
  const headerList = await headers();
  return headerList.get("x-zw-pathname") ?? fallback;
}
