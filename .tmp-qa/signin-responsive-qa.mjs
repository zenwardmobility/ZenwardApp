import { newChromeSession, APP_URL } from "./cloud-helper.mjs";
import fs from "node:fs";

const OUT = "/private/tmp/claude-501/-Users-datamatics-ZenWard/9c849e26-8432-486d-8d64-3dcf5894ae96/scratchpad/signin-qa";
fs.mkdirSync(OUT, { recursive: true });

const viewports = [
  ["390x844", 390, 844],
  ["430x932", 430, 932],
  ["768x1024", 768, 1024],
  ["1280x800", 1280, 800],
  ["1440x900", 1440, 900],
];

async function run() {
  console.log("APP_URL =", APP_URL);
  const s = await newChromeSession("-signin-qa");
  for (const [label, w, h] of viewports) {
    await s.setViewport(w, h);
    await s.nav(`${APP_URL}/sign-in`, 2000);
    const text = await s.evaluate(`document.body.innerText`);
    const hasOverflow = await s.evaluate(`document.documentElement.scrollWidth > document.documentElement.clientWidth`);
    console.log(`${label}: overflow=${hasOverflow} textOk=${text.includes("Welcome back")}`);
    await s.screenshot(`${OUT}/sign-in-${label}.png`);
  }
  await s.close();
  console.log("done");
}

run().catch((e) => {
  console.error("FATAL:", e);
  process.exitCode = 1;
});
