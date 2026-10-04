// Usage:
//   node login.mjs           password login if DASHBOARD_PASS is set, otherwise interactive (OTP/SSO)
//   node login.mjs --headed  always interactive: log in yourself in a visible browser
//   node login.mjs --check   exit 0 if the saved session in auth.json is still logged in, 1 if not
import { chromium } from 'playwright';
import { readFileSync, existsSync } from 'node:fs';
import { createInterface } from 'node:readline/promises';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));
const STATE = `${DIR}/auth.json`;
const INTERACTIVE_TIMEOUT_MS = 10 * 60 * 1000;

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
const dashboardUrl = env.DASHBOARD_URL;
const loginUrl = env.DASHBOARD_LOGIN_URL || dashboardUrl;
if (!dashboardUrl) throw new Error(`Set DASHBOARD_URL in ${DIR}/.env`);

const args = process.argv.slice(2);
const mode = args.includes('--check')
  ? 'check'
  : args.includes('--headed') || !env.DASHBOARD_PASS
    ? 'interactive'
    : 'password';

const USER_SEL = [
  'input[autocomplete="username"]',
  'input[type="email"]',
  'input[type="tel"]',
  'input[name*="email" i]',
  'input[name*="phone" i]',
  'input[name*="user" i]',
  'input[id*="email" i]',
  'input[id*="user" i]',
  'input[name*="login" i]',
].join(', ');
const PASS_SEL = 'input[type="password"]';
const LOGIN_GATE_SEL = 'input[type="password"], input[autocomplete="one-time-code"], input[type="email"], input[type="tel"]';
const LOGIN_PATH_RE = /(log-?in|sign-?in|sign-?up|auth|otp|verif|session)/i;

async function isLoggedIn(page) {
  if (LOGIN_PATH_RE.test(new URL(page.url()).pathname)) return false;
  return !(await page.locator(LOGIN_GATE_SEL).first().isVisible().catch(() => false));
}

async function saveAndExit(browser, context, page) {
  await context.storageState({ path: STATE, indexedDB: true });
  console.log(`Saved session to ${STATE} (landed on ${page.url()})`);
  await browser.close();
  process.exit(0);
}

if (mode === 'check') {
  if (!existsSync(STATE)) process.exit(1);
  const browser = await chromium.launch();
  const context = await browser.newContext({ storageState: STATE });
  const page = await context.newPage();
  await page.goto(dashboardUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
  const ok = await isLoggedIn(page);
  console.log(ok ? `Session valid (${page.url()})` : `Session expired or missing (${page.url()})`);
  await browser.close();
  process.exit(ok ? 0 : 1);
}

const browser = await chromium.launch({ headless: mode !== 'interactive' });
const context = await browser.newContext();
const page = await context.newPage();
await page.goto(loginUrl, { waitUntil: 'domcontentloaded' });

if (mode === 'interactive') {
  if (env.DASHBOARD_USER) {
    await page.locator(USER_SEL).first().fill(env.DASHBOARD_USER, { timeout: 10000 }).catch(() => {});
  }
  console.log('Log in in the browser window (enter the OTP when it arrives).');
  console.log('The session is saved automatically once the dashboard loads, or press Enter here to save now.');

  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const manual = rl.question('').then(() => 'enter');
  const auto = (async () => {
    const deadline = Date.now() + INTERACTIVE_TIMEOUT_MS;
    let streak = 0;
    while (Date.now() < deadline) {
      await page.waitForTimeout(2000);
      streak = (await isLoggedIn(page).catch(() => false)) ? streak + 1 : 0;
      if (streak >= 3) return 'auto';
    }
    return 'timeout';
  })();

  const result = await Promise.race([manual, auto]);
  rl.close();
  if (result === 'timeout') {
    await browser.close();
    throw new Error('Timed out waiting for login (10 minutes).');
  }
  await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
  await saveAndExit(browser, context, page);
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
    throw new Error(`Login did not complete (still on ${page.url()}). Check credentials, or run: node login.mjs --headed`);
  });
await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
await saveAndExit(browser, context, page);
