// Usage:
//   node login.mjs           password login if DASHBOARD_PASS is set, otherwise interactive (OTP/SSO)
//   node login.mjs --headed  always interactive: log in yourself in a visible browser
//   node login.mjs --check   exit 0 if the saved session in auth.json is still logged in, 1 if not
import { chromium } from 'playwright';
import { readFileSync, existsSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline/promises';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));
const STATE = `${DIR}/auth.json`;
const CHROME_PROFILE = `${DIR}/chrome-profile`;
const CDP_PORT = 9333;
const INTERACTIVE_TIMEOUT_MS = 10 * 60 * 1000;
const CHROME_PATHS = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
].filter(Boolean);

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

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function cdpTabs() {
  const res = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`);
  return (await res.json()).filter((t) => t.type === 'page');
}

// Real Chrome, started as a normal process: no automation flags and nothing attached to the page
// while the user logs in, so reCAPTCHA sees an ordinary browser. Tabs are watched over the plain
// HTTP /json endpoint; Playwright only connects after login to export the session.
async function interactiveLoginWithRealChrome(chromePath) {
  const chrome = spawn(
    chromePath,
    [
      `--remote-debugging-port=${CDP_PORT}`,
      `--user-data-dir=${CHROME_PROFILE}`,
      '--no-first-run',
      '--no-default-browser-check',
      loginUrl,
    ],
    { stdio: 'ignore' },
  );

  for (let i = 0; i < 30; i++) {
    if (await cdpTabs().then(() => true, () => false)) break;
    await sleep(500);
  }

  const host = new URL(dashboardUrl).host;
  console.log('Log in in the Chrome window (enter the OTP when it arrives).');
  console.log('The session is saved automatically once the dashboard loads, or press Enter here to save now.');

  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const manual = rl.question('').then(() => 'enter');
  const auto = (async () => {
    const deadline = Date.now() + INTERACTIVE_TIMEOUT_MS;
    let streak = 0;
    while (Date.now() < deadline) {
      await sleep(2000);
      const tabs = await cdpTabs().catch(() => []);
      const inDashboard = tabs.some((t) => {
        try {
          const u = new URL(t.url);
          return u.host === host && !LOGIN_PATH_RE.test(u.pathname);
        } catch {
          return false;
        }
      });
      streak = inDashboard ? streak + 1 : 0;
      if (streak >= 3) return 'auto';
    }
    return 'timeout';
  })();

  const result = await Promise.race([manual, auto]);
  rl.close();
  if (result === 'timeout') {
    chrome.kill();
    throw new Error('Timed out waiting for login (10 minutes).');
  }

  const browser = await chromium.connectOverCDP(`http://127.0.0.1:${CDP_PORT}`);
  const context = browser.contexts()[0];
  await context.storageState({ path: STATE, indexedDB: true });
  const landed = context.pages().map((p) => p.url()).find((u) => u.includes(host)) || '';
  console.log(`Saved session to ${STATE} (landed on ${landed})`);
  await browser.close().catch(() => {});
  chrome.kill();
  process.exit(0);
}

if (mode === 'interactive') {
  const chromePath = CHROME_PATHS.find((p) => existsSync(p));
  if (chromePath) await interactiveLoginWithRealChrome(chromePath);
  console.log('Google Chrome not found (set CHROME_PATH); falling back to Playwright Chromium.');
}

const browser = await chromium.launch({
  headless: mode !== 'interactive',
  ignoreDefaultArgs: ['--enable-automation'],
  args: ['--disable-blink-features=AutomationControlled'],
});
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
