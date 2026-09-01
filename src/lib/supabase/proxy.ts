import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseUrl, getSupabasePublishableKey } from "./env";

/**
 * Session-refresh helper for the root proxy.ts (renamed from middleware.ts
 * in P1-E3-S1A — Next.js 16 deprecated the `middleware` file convention in
 * favor of `proxy`; see https://nextjs.org/docs/messages/middleware-to-proxy)
 * — the standard @supabase/ssr pattern for keeping the auth cookie fresh
 * on every request, so a Server Component reading the session never sees
 * a stale/about-to-expire token. This is SESSION REFRESH ONLY — it does
 * not perform route authorization (work item §31/§9 from P1-E3-S1: that
 * lives in src/lib/auth/*, evaluated per-layout, not duplicated here, and
 * this rename changes none of that — P1-E3-S1A is a file-convention
 * migration only).
 */
export async function updateSession(request: NextRequest) {
  // Propagates the requested pathname to Server Components via a request
  // header — layouts have no direct "current URL" API otherwise, and this
  // is what lets requireOperationsAccess/requireDriverAccess build an
  // accurate `next=` redirect back to the page the user actually asked
  // for (rather than always falling back to the section root).
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-zw-pathname", request.nextUrl.pathname);

  let response = NextResponse.next({ request: { headers: requestHeaders } });

  const supabase = createServerClient(getSupabaseUrl(), getSupabasePublishableKey(), {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value);
        }
        response = NextResponse.next({ request: { headers: requestHeaders } });
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options);
        }
      },
    },
  });

  // Triggers a token refresh if the current session is close to expiry —
  // the return value itself is intentionally unused here; route-level
  // guards (src/lib/auth) resolve the actual user/authorization.
  await supabase.auth.getUser();

  return response;
}
