# Zenward — Demo Video Shot List

**Purpose:** shot lists for recording future demo videos of Zenward, at three lengths. **No video has been recorded as part of this work item** — this is planning only, so that whenever recording happens, it follows a consistent, honest, pre-reviewed structure rather than an improvised screen capture. Every shot below maps directly to a step in `zenward-demo-script.md` — narration should reuse that script's WHAT TO SAY lines, and must respect every WHAT NOT TO CLAIM line.

**Recording prerequisites (for whenever this is actually shot):** fresh `supabase db reset` immediately before recording (clean, deterministic Harmony Medical Transport state); signed in as `dispatch@harmonytransport.test`; a second device or window for the driver-side shots, signed in as one Harmony driver account; screen resolution at least 1440×900 for legibility.

---

## 60-second cut — social/landing-page teaser

Fast, visual, no narration required (captions instead). Goal: convey "real product, real screens" in under a minute.

1. (0:00–0:08) Today's Operations, full screen — let the real counts and Needs Attention table register.
2. (0:08–0:16) Click Assign on the unassigned trip — quick dialog, quick submit.
3. (0:16–0:26) Cut to driver screen — tap through 2-3 lifecycle steps quickly (Start to Pickup → Arrived).
4. (0:26–0:34) Cut to Dispatch board showing the driver now "On Trip" with a fresh location indicator.
5. (0:34–0:46) Quick cut: driver reports an issue → dispatcher resolves it (compress the dialog interactions).
6. (0:46–0:56) Trip Detail's completed activity trail, scrolling through the timestamped log.
7. (0:56–1:00) End card: Zenward wordmark + one line ("Operations built for NEMT.")

## 2-minute cut — landing page / first-touch sales asset

Light voiceover, following the 5-minute demo script's structure compressed further.

1. (0:00–0:15) Cold open on Today's Operations — voiceover: "This is what a dispatcher sees the moment they log in."
2. (0:15–0:35) Assign the unassigned trip — voiceover covers the "one dialog, protected against double-booking" point.
3. (0:35–1:00) Driver session — starting the trip, sharing location — voiceover covers "every step is a real, recorded action."
4. (1:00–1:20) Dispatch board reflecting the freshness update.
5. (1:20–1:45) Issue reported and resolved — voiceover covers Trip Assurance framing from the demo script.
6. (1:45–2:00) Completed trip's activity trail — voiceover closes on the accountability point, end card.

## 5-minute cut — sales-enablement / follow-up asset

Full narration, following the 10-minute demo script's 6 steps but at a brisker pace (skip dead air between clicks, trim dialog-filling to the essentials). Structure exactly mirrors `zenward-demo-script.md`'s 10-minute version:

1. (0:00–0:45) Step 1 — Today's Operations.
2. (0:45–1:30) Step 2 — Assign responsibility.
3. (1:30–2:30) Step 3 — Driver starts trip + shares location.
4. (2:30–3:00) Step 4 — Dispatch sees freshness.
5. (3:00–4:00) Step 5 — Issue reported and resolved.
6. (4:00–4:45) Step 6 — Completed trip's accountability trail.
7. (4:45–5:00) Close: one line on the founding operator program, pointing to a follow-up conversation — not a pricing claim (see `sales-claims-boundary.md`).

## Production notes (for whichever cut is recorded first)

- Record at the browser viewport sizes documented in `docs/design/qa/commercial-demo/` for visual consistency with the screenshot set.
- Never record over a QA/test organization by mistake — confirm the signed-in email is `@harmonytransport.test` before hitting record (see `demo-navigation-map.md`).
- Do not speed up or edit out a loading state in a way that implies something is faster than it actually is — minor trims for pacing are fine; misrepresenting responsiveness is not.
- Every narration line must trace back to a WHAT TO SAY line in `zenward-demo-script.md`, or be reviewed against `sales-claims-boundary.md` before use.
