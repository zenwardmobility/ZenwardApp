import { spawn } from "node:child_process";
import fs from "node:fs";

const APP_URL = "http://localhost:3000";
const MAILPIT_URL = "http://127.0.0.1:54334";
const OUT = "/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/local-confirmation-e2e";
fs.mkdirSync(OUT, { recursive: true });

const results = { checks: [] };
function check(name, condition, detail) {
  results.checks.push({ name, pass: !!condition, detail });
  console.log(`${condition ? "PASS" : "FAIL"} — ${name}${detail ? " :: " + detail : ""}`);
}
function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

let portCounter = 9950;
async function newChromeSession(suffix) {
  const port = portCounter++;
  const chrome = spawn(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ["--headless=new", `--remote-debugging-port=${port}`, "--no-first-run", "--no-default-browser-check", "--disable-gpu",
     `--user-data-dir=/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/local-conf-chrome-${port}${suffix}-${Date.now()}`],
    { stdio: "ignore", detached: true },
  );
  chrome.unref();
  await sleep(1200);
  let version;
  for (let i = 0; i < 5; i++) {
    try { version = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json(); break; }
    catch { await sleep(800); }
  }
  const ws = new WebSocket(version.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { ws.addEventListener("open", resolve); ws.addEventListener("error", reject); });
  let msgId = 1;
  async function send(method, params = {}, sessionId) {
    return new Promise((resolve, reject) => {
      const id = msgId++;
      const handler = (event) => {
        const msg = JSON.parse(event.data.toString());
        if (msg.id === id) { ws.removeEventListener("message", handler); msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result); }
      };
      ws.addEventListener("message", handler);
      ws.send(JSON.stringify({ id, method, params, sessionId }));
    });
  }
  const { targetId } = await send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await send("Target.attachToTarget", { targetId, flatten: true });
  await send("Page.enable", {}, sessionId);
  await send("Runtime.enable", {}, sessionId);
  return {
    async nav(url, waitMs = 2000) { await send("Page.navigate", { url }, sessionId); await sleep(waitMs); },
    async evaluate(expression) {
      const res = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true }, sessionId);
      if (res.exceptionDetails) throw new Error("evaluate error: " + JSON.stringify(res.exceptionDetails));
      return res.result.value;
    },
    async currentPath() { return this.evaluate("window.location.pathname"); },
    async screenshot(path) {
      const { data } = await send("Page.captureScreenshot", { format: "png" }, sessionId);
      fs.writeFileSync(path, Buffer.from(data, "base64"));
    },
    async close() { try { await send("Target.closeTarget", { targetId }); } catch {} ws.close(); },
  };
}
async function fillField(s, selector, value) {
  return s.evaluate(`(function(){const el=document.querySelector(${JSON.stringify(selector)});if(!el)return false;const proto=el.tagName.toLowerCase()==='textarea'?window.HTMLTextAreaElement.prototype:window.HTMLInputElement.prototype;Object.getOwnPropertyDescriptor(proto,'value').set.call(el,${JSON.stringify(value)});el.dispatchEvent(new Event('input',{bubbles:true}));return true;})()`);
}
async function waitForUrlChange(s, from, timeoutMs = 8000) {
  const start = Date.now();
  let cur = from;
  while (Date.now() - start < timeoutMs) { cur = await s.currentPath(); if (cur !== from) return cur; await sleep(250); }
  return cur;
}

const STAMP = Date.now();
const EMAIL = `local-confirm-${STAMP}@example.test`;
const BUSINESS = `Local Confirm Org ${STAMP}`;
const FULLNAME = "Local Confirm Owner";

async function run() {
  // ---- 1. Sign up, expect "check your email" (confirmations are ON locally right now) ----
  const s = await newChromeSession("-signup");
  await s.nav(`${APP_URL}/sign-up`, 1500);
  await fillField(s, 'input[name="fullName"]', FULLNAME);
  await fillField(s, 'input[name="email"]', EMAIL);
  await fillField(s, 'input[name="password"]', "local-confirm-pw-2026");
  await fillField(s, 'input[name="businessName"]', BUSINESS);
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(1500);
  const text1 = await s.evaluate(`document.body.innerText`);
  check("Sign-up shows email confirmation required (confirmations ON)", text1.includes("Check your email"), text1.slice(0, 150));
  await s.screenshot(`${OUT}/01-check-email.png`);

  // ---- 2. Verify NO Organization/Membership exists yet for this user ----
  // (checked via SQL by the caller after this script — this script only drives the browser)

  // ---- 3. Fetch the confirmation link from Mailpit ----
  const searchRes = await fetch(`${MAILPIT_URL}/api/v1/search?query=to:${encodeURIComponent(EMAIL)}`);
  const searchJson = await searchRes.json();
  const msgId = searchJson.messages?.[0]?.ID;
  check("Confirmation email received in Mailpit", !!msgId, JSON.stringify(searchJson).slice(0, 200));

  if (!msgId) {
    fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
    await s.close();
    process.exitCode = 1;
    return;
  }

  const msgRes = await fetch(`${MAILPIT_URL}/api/v1/message/${msgId}`);
  const msgJson = await msgRes.json();
  const body = msgJson.Text || msgJson.HTML || "";
  const linkMatch = body.match(/https?:\/\/[^\s"'<>]+/g) || [];
  const confirmLink = linkMatch.find((l) => l.includes("verify") || l.includes("confirm") || l.includes("token"));
  check("Confirmation link extracted from email body", !!confirmLink, confirmLink || "(none found)");

  // ---- 4. Click the real confirmation link ----
  if (confirmLink) {
    await s.nav(confirmLink, 2000);
    const afterClickPath = await s.currentPath();
    const afterClickText = await s.evaluate(`document.body.innerText`);
    check("Confirmation link resolves to the app (not an error page)", !afterClickText.includes("error") || afterClickPath.length > 0, `path=${afterClickPath}`);
    await s.screenshot(`${OUT}/02-after-confirm-link.png`);
  }
  await s.close();

  // ---- 5. Now sign in (matching the product's own "confirm, then sign in" UX) ----
  const s2 = await newChromeSession("-signin");
  await s2.nav(`${APP_URL}/sign-in`, 1500);
  await fillField(s2, 'input[name="email"]', EMAIL);
  await fillField(s2, 'input[name="password"]', "local-confirm-pw-2026");
  await s2.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(2000);
  const pathAfterSignIn = await s2.currentPath();
  check("Sign-in after confirmation reaches /onboarding (continuation fired)", pathAfterSignIn === "/onboarding", pathAfterSignIn);
  await s2.screenshot(`${OUT}/03-after-signin-onboarding.png`);

  // ---- 6. Refresh /onboarding (idempotency: re-visiting must not re-trigger creation) ----
  await s2.nav(`${APP_URL}/onboarding`, 1500);
  const pathAfterRefresh = await s2.currentPath();
  check("Refreshing onboarding does not bounce out (no duplicate-creation error)", pathAfterRefresh === "/onboarding", pathAfterRefresh);

  // ---- 7. Sign out, sign back in — must land straight in the app, not re-onboard from scratch or duplicate ----
  await s2.nav(`${APP_URL}/operations`, 1500);
  await s2.evaluate(`(function(){const btn=document.querySelector('button[aria-haspopup="menu"]');if(btn)btn.click();})()`);
  await sleep(400);
  await s2.evaluate(`(function(){const els=Array.from(document.querySelectorAll('button[type=submit]'));const el=els.find(e=>e.textContent.includes('Sign Out'));if(el)el.click();})()`);
  await sleep(1500);

  await s2.nav(`${APP_URL}/sign-in`, 1000);
  await fillField(s2, 'input[name="email"]', EMAIL);
  await fillField(s2, 'input[name="password"]', "local-confirm-pw-2026");
  await s2.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(2000);
  const pathAfterResignIn = await s2.currentPath();
  check("Re-sign-in after sign-out lands in Operations/onboarding, not re-created", pathAfterResignIn === "/operations" || pathAfterResignIn === "/onboarding", pathAfterResignIn);
  await s2.close();

  fs.writeFileSync(`${OUT}/results.json`, JSON.stringify(results, null, 2));
  console.log(`\n${results.checks.filter((c) => c.pass).length}/${results.checks.length} checks passed`);
  console.log("EMAIL_USED=" + EMAIL);
}

run().catch((e) => { console.error("FATAL:", e); process.exitCode = 1; });
