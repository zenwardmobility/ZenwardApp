/**
 * Directions action (P1-E3-S3, work item §14). A safe, provider-agnostic
 * external maps URL — Google Maps' public web search endpoint, which
 * requires no API key, no SDK, and no dependency, and opens the native
 * app via universal link on iOS/Android or the web on desktop. Sends only
 * the permitted address/description text already visible to the Driver on
 * this screen — never a Passenger name, phone, or any other field.
 *
 * Provider choice: Google Maps was picked over an Apple Maps-specific
 * scheme (`maps://`) specifically because it works identically across
 * platforms with one URL shape, rather than needing user-agent detection
 * to choose between competing schemes — the simplest option that covers
 * every Driver device without added complexity. Revisit only if a real
 * product need for a different provider emerges (decision-register.md).
 */
export function directionsUrl(address: string): string {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;
}
