import { spawn } from "node:child_process";
import fs from "node:fs";

export const APP_URL = process.env.CLOUD_APP_URL || "https://zenward-app.vercel.app";

export function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

let portCounter = 9900;
const RUN_STAMP = Date.now();

export async function newChromeSession(profileSuffix = "") {
  const port = portCounter++;
  const chrome = spawn(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    [
      "--headless=new",
      `--remote-debugging-port=${port}`,
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-gpu",
      `--user-data-dir=/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/cloud-chrome-profile-${RUN_STAMP}-${port}${profileSuffix}`,
    ],
    { stdio: "ignore", detached: true },
  );
  chrome.unref();
  await sleep(1200);

  let version;
  let lastErr;
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const versionRes = await fetch(`http://127.0.0.1:${port}/json/version`);
      version = await versionRes.json();
      lastErr = null;
      break;
    } catch (e) {
      lastErr = e;
      await sleep(800);
    }
  }
  if (lastErr) throw lastErr;

  const ws = new WebSocket(version.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve);
    ws.addEventListener("error", reject);
  });

  let msgId = 1;
  const nextId = () => msgId++;
  async function send(method, params = {}, sessionId) {
    return new Promise((resolve, reject) => {
      const id = nextId();
      const handler = (event) => {
        const msg = JSON.parse(event.data.toString());
        if (msg.id === id) {
          ws.removeEventListener("message", handler);
          if (msg.error) reject(new Error(JSON.stringify(msg.error)));
          else resolve(msg.result);
        }
      };
      ws.addEventListener("message", handler);
      ws.send(JSON.stringify({ id, method, params, sessionId }));
    });
  }

  const { targetId } = await send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await send("Target.attachToTarget", { targetId, flatten: true });
  await send("Network.enable", {}, sessionId);
  await send("Page.enable", {}, sessionId);
  await send("Runtime.enable", {}, sessionId);

  return {
    port,
    pid: chrome.pid,
    async grantGeolocation(latitude, longitude, accuracy = 10) {
      await send("Browser.grantPermissions", { permissions: ["geolocation"], origin: APP_URL }, sessionId);
      await send("Emulation.setGeolocationOverride", { latitude, longitude, accuracy }, sessionId);
    },
    async nav(url, waitMs = 2500) {
      await send("Page.navigate", { url }, sessionId);
      await sleep(waitMs);
    },
    async setViewport(width, height) {
      await send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false }, sessionId);
    },
    async screenshot(path) {
      const { data } = await send("Page.captureScreenshot", { format: "png" }, sessionId);
      fs.writeFileSync(path, Buffer.from(data, "base64"));
      return path;
    },
    async evaluate(expression) {
      const res = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true }, sessionId);
      if (res.exceptionDetails) {
        throw new Error("evaluate error: " + JSON.stringify(res.exceptionDetails));
      }
      return res.result.value;
    },
    async currentUrl() {
      return this.evaluate("window.location.pathname");
    },
    async fullUrl() {
      return this.evaluate("window.location.href");
    },
    async close() {
      try {
        await send("Target.closeTarget", { targetId });
      } catch {}
      ws.close();
    },
  };
}

export async function waitForSelector(session, selector, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const found = await session.evaluate(`!!document.querySelector(${JSON.stringify(selector)})`);
    if (found) return true;
    await sleep(300);
  }
  return false;
}

export async function waitForUrlChange(session, fromPath, timeoutMs = 12000) {
  const start = Date.now();
  let current = fromPath;
  while (Date.now() - start < timeoutMs) {
    current = await session.currentUrl();
    if (current !== fromPath) return current;
    await sleep(300);
  }
  return current;
}

export async function fillField(session, selector, value) {
  return session.evaluate(`
    (function() {
      const el = document.querySelector(${JSON.stringify(selector)});
      if (!el) return false;
      const tag = el.tagName.toLowerCase();
      const proto = tag === 'textarea' ? window.HTMLTextAreaElement.prototype : window.HTMLInputElement.prototype;
      const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
      setter.call(el, ${JSON.stringify(value)});
      el.dispatchEvent(new Event('input', { bubbles: true }));
      return true;
    })()
  `);
}

export async function clickByText(session, selector, text) {
  return session.evaluate(`
    (function() {
      const els = Array.from(document.querySelectorAll(${JSON.stringify(selector)}));
      const el = els.find(e => e.textContent.trim().includes(${JSON.stringify(text)}) && !e.disabled);
      if (!el) return false;
      el.click();
      return true;
    })()
  `);
}
