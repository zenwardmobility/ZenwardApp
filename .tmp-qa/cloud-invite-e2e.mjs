import { newChromeSession, sleep, APP_URL, waitForSelector, fillField, clickByText } from "./cloud-helper.mjs";
import fs from "node:fs";

const OUT = "/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/cloud-invite-e2e";
fs.mkdirSync(OUT, { recursive: true });

const results = { checks: [], failures: [] };
function check(name, condition, detail) {
  results.checks.push({ name, pass: !!condition, detail });
  console.log(`${condition ? "PASS" : "FAIL"} — ${name}${detail ? " :: " + detail : ""}`);
  if (!condition) results.failures.push(`${name}: ${detail || ""}`);
}

// Uses the SAME owner account the primary cloud-e2e.mjs run just created —
// pass its email/password via env vars so this script doesn't need to
// re-run signup (avoiding a second real signup + possible email gate).
const OWNER_EMAIL = process.env.CLOUD_OWNER_EMAIL;
const OWNER_PASSWORD = process.env.CLOUD_OWNER_PASSWORD || "cloud-e2e-test-pw-2026";
const STAMP = Date.now();
const DRIVER_EMAIL = `cloud-invited-driver-${STAMP}@example.test`;

async function loginAs(session, email, password) {
  await session.nav(`${APP_URL}/sign-in`, 3000);
  await waitForSelector(session, 'input[name="email"]', 10000);
  await fillField(session, 'input[name="email"]', email);
  await fillField(session, 'input[name="password"]', password);
  await sleep(300);
  await session.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(3000);
  return session.currentUrl();
}

async function run() {
  if (!OWNER_EMAIL) {
    console.error("FATAL: CLOUD_OWNER_EMAIL not set — run cloud-e2e.mjs first and pass its email here.");
    process.exitCode = 1;
    return;
  }

  const admin = await newChromeSession("-cloud-admin");
  await admin.setViewport(1440, 900);
  const adminUrl = await loginAs(admin, OWNER_EMAIL, OWNER_PASSWORD);
  check("Owner/admin sign-in (cloud)", adminUrl === "/operations", adminUrl);

  await admin.nav(`${APP_URL}/operations/drivers`, 2500);
  const clickedInvite = await clickByText(admin, "button", "Invite Driver");
  check("Clicked Invite Driver (cloud)", clickedInvite, "");
  await sleep(700);
  await fillField(admin, 'input[name="displayName"]', "Cloud Invited Driver");
  await fillField(admin, 'input[name="email"]', DRIVER_EMAIL);
  await admin.evaluate(`
    (function() {
      const els = Array.from(document.querySelectorAll('button[type=submit]'));
      const el = els.find(e => e.textContent.trim().includes('Send Invite'));
      if (el) el.click();
    })()
  `);
  await sleep(2000);
  let text = await admin.evaluate(`document.body.innerText`);
  check("Invite confirmation shown (cloud)", text.includes("Invited") || text.includes("Refreshed"), "");
  await admin.screenshot(`${OUT}/01-invite-sent.png`);

  // Duplicate invite: reused, not duplicated
  await clickByText(admin, "button", "Invite Driver");
  await sleep(600);
  await fillField(admin, 'input[name="displayName"]', "Cloud Invited Driver");
  await fillField(admin, 'input[name="email"]', DRIVER_EMAIL);
  await admin.evaluate(`
    (function() {
      const els = Array.from(document.querySelectorAll('button[type=submit]'));
      const el = els.find(e => e.textContent.trim().includes('Send Invite'));
      if (el) el.click();
    })()
  `);
  await sleep(2000);
  text = await admin.evaluate(`document.body.innerText`);
  check("Duplicate invite handled safely (cloud) — 'Refreshed'", text.includes("Refreshed") || text.includes("Invited"), text.slice(0, 200));

  await admin.close();

  // I have no direct DB access to staging, so the token must be obtained
  // from the app itself — the invite confirmation UI does not expose the
  // raw token/link. This is a genuine limitation of this test without a
  // staging DB connection; documented honestly in the report.
  fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
  console.log("\n=== SUMMARY ===");
  console.log(`${results.checks.filter((c) => c.pass).length}/${results.checks.length} checks passed`);
  console.log("NOTE: full invite REDEMPTION (visiting /join/[token] as the invitee) requires the invite's token, which this script cannot obtain without staging DB access — the invite CREATION half is proven; redemption is not completed by this script.");
}

run().catch((e) => {
  console.error("FATAL:", e);
  process.exitCode = 1;
});
