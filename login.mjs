import { chromium } from 'playwright';
import { readFileSync, existsSync } from 'node:fs';
import { createInterface } from 'node:readline/promises';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));
const STATE = `${DIR}/auth.json`;

function loadEnv(path) {
  if (!existsSync(path)) return {};
  return Object.fromEntries(
    readFileSync(path, 'utf8')
      .split('\n')
      .filter((l) => l.trim() && !l.trim().startsWith('#') && l.includes('='))
      .map((l) => {
        const i = l.indexOf('=');
        return [l.slice(0, i).trim(), l.slice(i + 1).trim().replace(/^['"]|['"]$/g, '')];
      }),
  );
}

const env = { ...loadEnv(`${DIR}/.env`), ...process.env };
const url = env.DASHBOARD_LOGIN_URL || env.DASHBOARD_URL;
const headed = process.argv.includes('--headed');
if (!url) throw new Error(`Set DASHBOARD_URL in ${DIR}/.env`);

const USER_SEL = [
  'input[autocomplete="username"]',
  'input[type="email"]',
  'input[name*="email" i]',
  'input[name*="user" i]',
  'input[id*="email" i]',
  'input[id*="user" i]',
  'input[name*="login" i]',
].join(', ');
const PASS_SEL = 'input[type="password"]';

const browser = await chromium.launch({ headless: !headed });
const context = await browser.newContext();
const page = await context.newPage();
await page.goto(url, { waitUntil: 'domcontentloaded' });

if (headed) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  await rl.question('Log in in the browser window, then press Enter here to save the session... ');
  rl.close();
} else {
  if (!env.DASHBOARD_USER || !env.DASHBOARD_PASS) {
    throw new Error(`Set DASHBOARD_USER and DASHBOARD_PASS in ${DIR}/.env`);
  }
  const user = page.locator(USER_SEL).first();
  await user.waitFor({ state: 'visible', timeout: 20000 });
  await user.fill(env.DASHBOARD_USER);

  const pass = page.locator(PASS_SEL).first();
  if (!(await pass.isVisible().catch(() => false))) {
    await user.press('Enter');
  }
  await pass.waitFor({ state: 'visible', timeout: 20000 });
  await pass.fill(env.DASHBOARD_PASS);
  await pass.press('Enter');

  await page
    .waitForFunction(() => !document.querySelector('input[type="password"]'), null, { timeout: 30000 })
    .catch(() => {
      throw new Error(
        `Login did not complete (still on ${page.url()}). Check credentials, or run: node ${DIR}/login.mjs --headed`,
      );
    });
  await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
}

await context.storageState({ path: STATE });
console.log(`Saved session to ${STATE} (landed on ${page.url()})`);
await browser.close();
