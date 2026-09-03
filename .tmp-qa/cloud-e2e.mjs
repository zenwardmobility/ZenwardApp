import { newChromeSession, sleep, APP_URL, waitForSelector, waitForUrlChange, fillField, clickByText } from "./cloud-helper.mjs";
import fs from "node:fs";

const OUT = "/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/cloud-e2e";
fs.mkdirSync(OUT, { recursive: true });

const results = { checks: [], failures: [] };
function check(name, condition, detail) {
  results.checks.push({ name, pass: !!condition, detail });
  console.log(`${condition ? "PASS" : "FAIL"} — ${name}${detail ? " :: " + detail : ""}`);
  if (!condition) results.failures.push(`${name}: ${detail || ""}`);
}

const STAMP = Date.now();
const OWNER_EMAIL = `cloud-e2e-${STAMP}@example.test`;
const BUSINESS_NAME = `Cloud E2E Org ${STAMP}`;

async function run() {
  console.log("APP_URL =", APP_URL);
  const s = await newChromeSession("-cloud-owner");
  await s.setViewport(1440, 900);

  // ---- Reachability ----
  await s.nav(`${APP_URL}/sign-in`, 3000);
  let text = await s.evaluate(`document.body.innerText`);
  check("App reachable, sign-in page renders", text.includes("Sign in") || text.includes("Email"), text.slice(0, 200));
  await s.screenshot(`${OUT}/00-sign-in.png`);

  // ---- Sign up ----
  await s.nav(`${APP_URL}/sign-up`, 3000);
  const hasForm = await waitForSelector(s, 'input[name="fullName"]', 10000);
  check("Sign-up form renders", hasForm, "");
  if (!hasForm) {
    fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
    console.log("FATAL: sign-up form did not render, aborting");
    process.exitCode = 1;
    return;
  }
  await fillField(s, 'input[name="fullName"]', "Cloud Owner");
  await fillField(s, 'input[name="email"]', OWNER_EMAIL);
  await fillField(s, 'input[name="password"]', "cloud-e2e-test-pw-2026");
  await fillField(s, 'input[name="businessName"]', BUSINESS_NAME);
  await sleep(300);
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(3500);
  const urlAfterSignup = await s.currentUrl();
  text = await s.evaluate(`document.body.innerText`);
  await s.screenshot(`${OUT}/01-after-signup.png`);

  const needsEmailConfirmation = text.includes("Check your email") || text.includes("confirm your account");
  check("Sign-up submitted (either onboarding or email-confirmation state)", urlAfterSignup === "/onboarding" || needsEmailConfirmation, `url=${urlAfterSignup} text="${text.slice(0, 200)}"`);

  if (needsEmailConfirmation) {
    console.log("\n=== EMAIL CONFIRMATION IS REQUIRED ON STAGING ===");
    console.log(`A real confirmation email would have been sent to ${OWNER_EMAIL}.`);
    console.log("This script cannot access a real inbox — this step requires human action.");
    check("EMAIL CONFIRMATION GATE — cannot proceed automatically", false, "needs a real inbox to click the confirmation link");
    fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
    await s.close();
    console.log("\n=== SUMMARY ===");
    console.log(`${results.checks.filter((c) => c.pass).length}/${results.checks.length} checks passed`);
    console.log("STOPPED: email confirmation gate reached — see above.");
    process.exitCode = 2;
    return;
  }

  check("No email confirmation required — session established immediately", urlAfterSignup === "/onboarding", urlAfterSignup);

  // ---- Onboarding: business stage ----
  const hasStage = await waitForSelector(s, 'input[name="businessStage"]', 8000);
  check("Business Stage step renders", hasStage, "");
  await s.evaluate(`document.querySelector('input[value="starting"]').click(); true;`);
  await clickByText(s, "button[type=submit]", "Continue");
  let url = await waitForUrlChange(s, "/onboarding");
  check("Business Stage advances to /onboarding/basics", url === "/onboarding/basics", url);

  // ---- Basics ----
  await waitForSelector(s, 'select[name="timezone"]', 8000);
  await clickByText(s, "button[type=submit]", "Continue");
  url = await waitForUrlChange(s, "/onboarding/basics");
  check("Basics advances to /onboarding/vehicle", url === "/onboarding/vehicle", url);

  // ---- Vehicle ----
  await waitForSelector(s, 'input[name="label"]', 8000);
  await fillField(s, 'input[name="label"]', "Cloud Test Van");
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  url = await waitForUrlChange(s, "/onboarding/vehicle");
  check("Vehicle advances to /onboarding/driver", url === "/onboarding/driver", url);

  // ---- Owner-driver ----
  await waitForSelector(s, 'input[name="displayName"]', 8000);
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  url = await waitForUrlChange(s, "/onboarding/driver");
  check("Owner-driver advances to /onboarding/facility", url === "/onboarding/facility", url);

  // ---- Facility ----
  await waitForSelector(s, 'input[name="name"]', 8000);
  await fillField(s, 'input[name="name"]', "Cloud Test Clinic");
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  url = await waitForUrlChange(s, "/onboarding/facility");
  check("Facility advances to /onboarding/passenger", url === "/onboarding/passenger", url);

  // ---- Passenger ----
  await waitForSelector(s, 'input[name="displayName"]', 8000);
  await fillField(s, 'input[name="displayName"]', "Cloud Test Passenger");
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  url = await waitForUrlChange(s, "/onboarding/passenger");
  check("Passenger advances to New Trip", url.startsWith("/operations/trips/new"), url);
  await s.screenshot(`${OUT}/02-new-trip.png`);

  // ---- Owner reaches /driver (Owner-Operator Mode) ----
  await s.nav(`${APP_URL}/driver`, 2500);
  url = await s.currentUrl();
  text = await s.evaluate(`document.body.innerText`);
  check("Owner-driver reaches /driver via relaxed guard", url === "/driver" && !text.includes("Application error"), url);
  await s.screenshot(`${OUT}/03-owner-as-driver.png`);

  // ---- Today's Operations checklist ----
  await s.nav(`${APP_URL}/operations`, 2500);
  text = await s.evaluate(`document.body.innerText`);
  check("Today's Operations reachable, checklist visible", text.includes("Finish setting up") || text.includes("Today's Operations"), "");
  await s.screenshot(`${OUT}/04-operations.png`);

  // ---- Core Operations screens smoke ----
  for (const [name, path] of [
    ["Trips", "/operations/trips"],
    ["Dispatch", "/operations/dispatch"],
    ["Passengers", "/operations/passengers"],
    ["Facilities", "/operations/facilities"],
    ["Drivers", "/operations/drivers"],
    ["Fleet", "/operations/fleet"],
  ]) {
    await s.nav(`${APP_URL}${path}`, 2000);
    text = await s.evaluate(`document.body.innerText`);
    check(`${name} renders without error (cloud)`, !text.includes("Application error"), "");
  }

  // ---- Sign out ----
  await s.nav(`${APP_URL}/operations`, 2000);
  const menuOpened = await s.evaluate(`
    (function() {
      const btn = document.querySelector('button[aria-haspopup="menu"]');
      if (btn) { btn.click(); return true; }
      return false;
    })()
  `);
  check("Account menu opens (cloud)", menuOpened, "");
  await sleep(500);
  const signedOut = await clickByText(s, "button[type=submit]", "Sign Out");
  check("Sign Out clicked (cloud)", signedOut, "");
  await sleep(2000);
  url = await s.currentUrl();
  check("Sign Out redirects to sign-in (cloud)", url.includes("sign-in"), url);

  await s.close();

  fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
  console.log("\n=== SUMMARY ===");
  console.log(`${results.checks.filter((c) => c.pass).length}/${results.checks.length} checks passed`);
  if (results.failures.length) {
    console.log("FAILURES:");
    for (const f of results.failures) console.log(" - " + f);
    process.exitCode = 1;
  }
}

run().catch((e) => {
  console.error("FATAL:", e);
  process.exitCode = 1;
});
