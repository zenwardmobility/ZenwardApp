/**
 * Shared, fail-fast environment accessor for the two public Supabase
 * values every client below needs. Throws at startup rather than letting a
 * missing variable surface later as a confusing runtime Supabase error.
 * See docs/security/application-auth-boundary.md "Environment".
 */
function requireEnv(name: "NEXT_PUBLIC_SUPABASE_URL" | "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}. Copy .env.example to .env.local and fill it in.`);
  }
  return value;
}

export function getSupabaseUrl(): string {
  return requireEnv("NEXT_PUBLIC_SUPABASE_URL");
}

export function getSupabasePublishableKey(): string {
  return requireEnv("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");
}
