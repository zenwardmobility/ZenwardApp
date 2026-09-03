import { spawn } from "node:child_process";
function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }
async function newChromeSession(port, profileSuffix) {
  const chrome = spawn(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ["--headless=new", `--remote-debugging-port=${port}`, "--no-first-run", "--no-default-browser-check", "--disable-gpu",
     `--user-data-dir=/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/verify-detailed-${port}-${profileSuffix}-${Date.now()}`],
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
const EMAIL = process.argv[2];
const PASSWORD = process.argv[3] || "local-confirm-pw-2026";
async function run() {
  const s = await newChromeSession(9995, "fresh");
  await s.nav("http://localhost:3000/sign-in", 2000);
  console.log("initial path:", await s.currentPath());
  const hasForm = await s.evaluate("!!document.querySelector('form')");
  console.log("has form:", hasForm);
  if (!hasForm) { console.log("body:", (await s.evaluate("document.body.innerText")).slice(0,200)); s.close(); return; }
  await fillField(s, 'input[name="email"]', EMAIL);
  await fillField(s, 'input[name="password"]', PASSWORD);
  await s.evaluate(`document.querySelector('form').requestSubmit(); true;`);

  for (let i = 0; i < 20; i++) {
    await sleep(300);
    const p = await s.currentPath();
    const h1 = await s.evaluate("document.querySelector('h1')?.textContent || ''");
    console.log(`t+${(i + 1) * 300}ms: path=${p} h1="${h1}"`);
  }
  s.close();
  process.exit(0);
}
run().catch((e) => { console.error("FATAL", e); process.exit(1); });
