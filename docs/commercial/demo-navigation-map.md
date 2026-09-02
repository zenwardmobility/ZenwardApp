# Zenward — Demo Navigation Map

**Purpose:** exactly which accounts, URLs, and browser setup a Zenward team member uses to run a clean demo — so the demo is repeatable by anyone on the team, not dependent on tribal knowledge.

## The demo organization

All demo data lives in one organization, **Harmony Medical Transport** — a fictional NEMT operator, seeded automatically by `supabase/seed.sql` on every `supabase db reset`. It is not a special "demo mode": it is an ordinary organization row, reached through the exact same application code every other organization uses.

**Important:** the local database also contains older QA/test fixture organizations (visibly named "Org A", "Org B", with fixture data like "Fictional Passenger A1") used for engineering test coverage. These are a different organization entirely — tenant isolation means a Harmony user never sees them and a Harmony session never renders their names. **Always sign in with a `@harmonytransport.test` account for a buyer-facing demo.** Signing in with a QA fixture account by mistake is the single most likely way to accidentally show a buyer engineering-only content — double-check the email in the sign-in form before presenting.

## Demo accounts

| Role | Email | Password | Use for |
|---|---|---|---|
| Dispatcher | `dispatch@harmonytransport.test` | `local-test-only-fictional-pw` | The primary demo seat — Today's Operations, Dispatch, Trip Detail, Passengers/Facilities/Drivers/Fleet |
| Organization Admin | `owner@harmonytransport.test` | `local-test-only-fictional-pw` | Only if a buyer specifically asks about admin/owner-level access; the dispatcher account covers the full primary narrative |
| Driver — Marcus Bell | `driver.marcus@harmonytransport.test` | `local-test-only-fictional-pw` | Driver-side narrative, if Marcus's trips are the ones being demonstrated |
| Driver — Angela Reyes | `driver.angela@harmonytransport.test` | `local-test-only-fictional-pw` | Driver-side narrative for Angela's trips |
| Driver — Leon Whitfield | `driver.leon@harmonytransport.test` | `local-test-only-fictional-pw` | Driver-side narrative for Leon's trips — used in the scripted walkthrough below |

These passwords are placeholder local-only values, clearly labeled as such, never used for a real account and never spoken aloud or shown in a screenshot that leaves the local machine.

## Two browser profiles, not one shared login

The demo narrative crosses from a Dispatcher view to a Driver view and back. **Never use Zenward's own UI to "switch roles"** — there is no such control, and building one would be a real security regression (a role switch belongs to signing out and back in as a different account, not a button). Instead:

- **Profile 1 (primary, screen-shared with the buyer):** signed in as the dispatcher. This is what the buyer watches for most of the demo.
- **Profile 2 (a second browser window, or a phone/tablet held up briefly):** signed in as one driver. Used only for the ~90 seconds of the narrative where "what the driver sees and does" matters (receiving the trip, starting it, sharing location, reporting an issue).

Two ways to get two independent sessions on one machine:
1. Two different browsers (e.g. Chrome for the dispatcher, Firefox or Safari for the driver), or
2. Two Chrome profiles (`chrome://settings/people` → Add), or
3. A real second device (a phone showing the actual mobile-responsive Driver UI is the most compelling option live, if available).

## URLs

Local demo environment: `http://localhost:3000`

| Screen | Path |
|---|---|
| Sign in | `/sign-in` |
| Today's Operations | `/operations` |
| Dispatch | `/operations/dispatch` |
| Trips | `/operations/trips` |
| Trip Detail | `/operations/trips/[tripId]` (reached by clicking a trip — never type a raw UUID in front of a buyer) |
| Passengers | `/operations/passengers` |
| Facilities | `/operations/facilities` |
| Drivers | `/operations/drivers` |
| Fleet | `/operations/fleet` |
| Driver Today/Trips | `/driver` or `/driver/trips` |
| Driver Active Trip | `/driver/trips/[tripId]` (reached by tapping a trip) |

## Resetting between demos

See `docs/commercial/commercial-demo-readiness-audit.md` for the full reliability write-up. In short: `supabase db reset` from the repository root re-seeds Harmony Medical Transport to its exact starting composition — no manual database editing, ever, before or during a demo.
