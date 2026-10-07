# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: staff.spec.ts >> an owner adds a staff member without a login at two branches, found in both lists and by Arabic search
- Location: e2e/staff.spec.ts:8:1

# Error details

```
Test timeout of 30000ms exceeded.
```

```
Error: locator.fill: Test timeout of 30000ms exceeded.
Call log:
  - waiting for getByLabel('Email')

```

# Test source

```ts
  1  | import { test as base, expect, type Page } from "@playwright/test";
  2  | import { strings, type AppLocale, type Strings } from "./strings";
  3  | 
  4  | export type AppLocaleOptions = { appLocale: AppLocale };
  5  | 
  6  | type Fixtures = {
  7  |   /** UI strings of the project's language. */
  8  |   s: Strings;
  9  |   /** UI strings of the other language (after switching). */
  10 |   other: Strings;
  11 | };
  12 | 
  13 | export const test = base.extend<Fixtures & AppLocaleOptions>({
  14 |   appLocale: ["en", { option: true }],
  15 |   page: async ({ page, appLocale }, use) => {
  16 |     // Starts the device in the project language; a later in-app switch still wins.
  17 |     await page.addInitScript((locale) => {
  18 |       if (window.localStorage.getItem("glowdesk.locale") === null) {
  19 |         window.localStorage.setItem("glowdesk.locale", locale);
  20 |       }
  21 |     }, appLocale);
  22 |     await use(page);
  23 |   },
  24 |   s: async ({ appLocale }, use) => {
  25 |     await use(strings[appLocale]);
  26 |   },
  27 |   other: async ({ appLocale }, use) => {
  28 |     await use(strings[appLocale === "en" ? "ar" : "en"]);
  29 |   },
  30 | });
  31 | 
  32 | export { expect };
  33 | 
  34 | export const PASSWORD = "password123";
  35 | 
  36 | export async function expectDocumentLocale(page: Page, s: Strings) {
  37 |   await expect(page.locator("html")).toHaveAttribute("lang", s.lang);
  38 |   await expect(page.locator("html")).toHaveAttribute("dir", s.dir);
  39 | }
  40 | 
  41 | /** The shell topbar's account menu button; the sign-in page's header has none. */
  42 | const accountMenu = (page: Page) => page.getByRole("banner").locator('button[aria-haspopup="dialog"]');
  43 | 
  44 | /**
  45 |  * Signs in from the login page and waits until the session has landed: the shell's topbar, or with
  46 |  * `shell: false` (a login without a membership, sent to a standalone page) the sign-in form gone.
  47 |  */
  48 | export async function signIn(page: Page, s: Strings, email: string, password = PASSWORD, { shell = true } = {}) {
  49 |   const emailField = page.getByLabel(s.email);
  50 |   const passwordField = page.getByLabel(s.password, { exact: true });
  51 |   const submit = page.getByRole("button", { name: s.signIn });
> 52 |   await emailField.fill(email);
     |                    ^ Error: locator.fill: Test timeout of 30000ms exceeded.
  53 |   await passwordField.fill(password);
  54 |   await expect(emailField).toHaveValue(email);
  55 |   await expect(passwordField).toHaveValue(password);
  56 |   await submit.click();
  57 |   await (shell ? expect(accountMenu(page)).toBeVisible() : expect(submit).toHaveCount(0));
  58 | }
  59 | 
  60 | /** Opens the topbar account menu (theme switcher, sign out) if it is closed. */
  61 | export async function openAccountMenu(page: Page) {
  62 |   const trigger = accountMenu(page);
  63 |   if ((await trigger.getAttribute("aria-expanded")) !== "true") await trigger.click();
  64 | }
  65 | 
  66 | export async function signOut(page: Page, s: Strings) {
  67 |   // Inside the shell, sign out lives in the account menu; standalone pages show it directly.
  68 |   if ((await accountMenu(page).count()) > 0) {
  69 |     await openAccountMenu(page);
  70 |   }
  71 |   await page.getByRole("button", { name: s.signOut }).click();
  72 |   await expect(page).toHaveURL(/\/login/);
  73 | }
  74 | 
```