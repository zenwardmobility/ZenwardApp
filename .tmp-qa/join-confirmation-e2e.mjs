import { spawn } from "node:child_process";
function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }
async function newChromeSession(port) {
  const chrome = spawn(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ["--headless=new", `--remote-debugging-port=${port}`, "--no-first-run", "--no-default-browser-check", "--disable-gpu",
     `--user-data-dir=/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/join-conf-chrome-${port}-${Date.now()}`],
    { stdio: "ignore", detached: true },
  );
  chrome.unref();
  await sleep(1200);
  const version = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json();
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
    async nav(url, waitMs = 1500) { await send("Page.navigate", { url }, sessionId); await sleep(waitMs); },
    async evaluate(expression) {
      const res = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true }, sessionId);
      if (res.exceptionDetails) throw new Error(JSON.stringify(res.exceptionDetails));
      return res.result.value;
    },
    async currentPath() { return this.evaluate("window.location.pathname"); },
    close() { try { chrome.kill(); } catch {} ws.close(); },
  };
}
async function fillField(s, selector, value) {
  return s.evaluate(`(function(){const el=document.querySelector(${JSON.stringify(selector)});if(!el)return false;const proto=el.tagName.toLowerCase()==='textarea'?window.HTMLTextAreaElement.prototype:window.HTMLInputElement.prototype;Object.getOwnPropertyDescriptor(proto,'value').set.call(el,${JSON.stringify(value)});el.dispatchEvent(new Event('input',{bubbles:true}));return true;})()`);
}

const TOKEN = process.argv[2];
const EMAIL = "driverinvite-target@example.test";
const PASSWORD = "join-confirm-pw-2026";

async function run() {
  const results = [];
  function check(name, cond, detail) { results.push({ name, pass: !!cond }); console.log(`${cond ? "PASS" : "FAIL"} — ${name}${detail ? " :: " + detail : ""}`); }

  const s = await newChromeSession(9998);
  await s.nav(`http://localhost:3000/join/${TOKEN}`, 1500);
  const hasForm = await s.evaluate("!!document.querySelector('form')");
  check("Join page renders a form", hasForm);
  if (!hasForm) { console.log(await s.evaluate("document.body.innerText")); s.close(); return; }

  await fillField(s, 'input[name="fullName"]', "DI Target Driver Real Name");
  await fillField(s, 'input[name="password"]', PASSWORD);
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(1500);
  const bodyAfterSubmit = await s.evaluate("document.body.innerText");
  check("Join signup shows email confirmation required", bodyAfterSubmit.includes("Check your email") || bodyAfterSubmit.includes("confirm"), bodyAfterSubmit.slice(0, 150));
  s.close();

  // Fetch + follow the confirmation link
  await sleep(1500);
  const searchRes = await fetch(`http://127.0.0.1:54334/api/v1/search?query=to:${encodeURIComponent(EMAIL)}`);
  const searchJson = await searchRes.json();
  const msgId = searchJson.messages?.[0]?.ID;
  check("Confirmation email received for invitee", !!msgId);
  if (!msgId) return;
  const msgRes = await fetch(`http://127.0.0.1:54334/api/v1/message/${msgId}`);
  const msgJson = await msgRes.json();
  const body = msgJson.Text || msgJson.HTML || "";
  const link = (body.match(/https?:\/\/[^\s"'<>]+/g) || []).find((l) => l.includes("verify"));
  check("Confirmation link extracted", !!link, link);
  if (link) await fetch(link);

  // Sign in as the invitee, fresh session
  const s2 = await newChromeSession(9999);
  await s2.nav("http://localhost:3000/sign-in", 1500);
  await fillField(s2, 'input[name="email"]', EMAIL);
  await fillField(s2, 'input[name="password"]', PASSWORD);
  await s2.evaluate(`document.querySelector('form').requestSubmit(); true;`);
  await sleep(2500);
  const pathAfterSignIn = await s2.currentPath();
  check("Sign-in after confirmation reaches /driver (invite redeemed via continuation)", pathAfterSignIn === "/driver", pathAfterSignIn);

  // Operations must be denied for this Driver
  await s2.nav("http://localhost:3000/operations", 1500);
  const pathAfterOpsAttempt = await s2.currentPath();
  check("Driver denied Operations access", pathAfterOpsAttempt !== "/operations", pathAfterOpsAttempt);
  s2.close();

  console.log(`\n${results.filter((c) => c.pass).length}/${results.length} passed`);
}
run().catch((e) => { console.error("FATAL", e); process.exit(1); });
