# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.ts >> a receptionist is sent to 403 for an owner/manager page
- Location: e2e/smoke.spec.ts:59:1

# Error details

```
Error: expect(page).toHaveURL(expected) failed

Expected pattern: /\/\?branch=[\w-]+$/
Received string:  "http://127.0.0.1:5173/login"
Timeout: 5000ms

Call log:
  - Expect "toHaveURL" with timeout 5000ms
    14 × locator resolved to <html lang="ar" dir="rtl">…</html>
       - unexpected value "http://127.0.0.1:5173/login"

```

```yaml
- banner:
  - text: GlowDesk
  - button "English"
- main:
  - heading "تسجيل الدخول" [level=1]
  - paragraph: مرحبًا بعودتك. سجّل الدخول لإدارة السبا.
  - text: البريد الإلكتروني
  - textbox "البريد الإلكتروني" [invalid]
  - text: أدخل بريدك الإلكتروني. كلمة المرور
  - textbox "كلمة المرور" [invalid]
  - text: أدخل كلمة المرور.
  - button "تسجيل الدخول"
  - link "نسيت كلمة المرور؟":
    - /url: /forgot-password
- status
- alert
```

# Test source

```ts
  1  | import { expect, expectDocumentLocale, signIn, signOut, test } from "./fixtures";
  2  | 
  3  | test("owner signs in, sees the shell, switches language and signs out", async ({ page, s, other }, testInfo) => {
  4  |   await page.goto("/");
  5  |   await expect(page).toHaveURL(/\/login\?redirect=%2F$/);
  6  |   await expectDocumentLocale(page, s);
  7  | 
  8  |   await signIn(page, s, "owner@spacorner.test");
  9  | 
  10 |   await expect(page).toHaveURL(/\/\?branch=[\w-]+$/);
  11 |   await expect(page.getByRole("heading", { level: 1, name: s.welcome("Sara Owner") })).toBeVisible();
  12 |   const topbar = page.getByRole("banner");
  13 |   await expect(topbar.getByText(s.tenantName, { exact: true })).toBeVisible();
  14 |   await expect(topbar.getByText(s.ownerRole, { exact: true })).toBeVisible();
  15 |   await expectDocumentLocale(page, s);
  16 |   await page.screenshot({ path: testInfo.outputPath(`shell-${s.lang}.png`), fullPage: true });
  17 | 
  18 |   await page.getByRole("button", { name: s.languageButton }).click();
  19 |   await expectDocumentLocale(page, other);
  20 |   await expect(page.getByRole("heading", { level: 1, name: other.welcome("Sara Owner") })).toBeVisible();
  21 |   await expect(page.getByRole("banner").getByText(other.tenantName, { exact: true })).toBeVisible();
  22 | 
  23 |   // The choice survives a reload.
  24 |   await page.reload();
  25 |   await expectDocumentLocale(page, other);
  26 | 
  27 |   await page.getByRole("button", { name: other.languageButton }).click();
  28 |   await expectDocumentLocale(page, s);
  29 | 
  30 |   await signOut(page, s);
  31 |   await expectDocumentLocale(page, s);
  32 | });
  33 | 
  34 | test("a user without a membership sees the no-access screen", async ({ page, s }) => {
  35 |   await page.goto("/login");
  36 |   await signIn(page, s, "nobody@spacorner.test");
  37 | 
  38 |   await expect(page).toHaveURL(/\/no-access$/);
  39 |   await expect(page.getByRole("heading", { level: 1, name: s.noAccess })).toBeVisible();
  40 |   await expect(page.getByText("nobody@spacorner.test")).toBeVisible();
  41 | 
  42 |   // The shell stays out of reach.
  43 |   await page.goto("/");
  44 |   await expect(page).toHaveURL(/\/no-access$/);
  45 | 
  46 |   await signOut(page, s);
  47 | });
  48 | 
  49 | test("an unauthenticated deep link returns to the page after sign-in", async ({ page, s }) => {
  50 |   await page.goto("/settings");
  51 |   await expect(page).toHaveURL(/\/login\?redirect=%2Fsettings$/);
  52 | 
  53 |   await signIn(page, s, "owner@spacorner.test");
  54 | 
  55 |   await expect(page).toHaveURL(/\/settings\?branch=[\w-]+$/);
  56 |   await expect(page.getByRole("heading", { level: 1, name: s.settings })).toBeVisible();
  57 | });
  58 | 
  59 | test("a receptionist is sent to 403 for an owner/manager page", async ({ page, s }) => {
  60 |   await page.goto("/login");
  61 |   await signIn(page, s, "reception@spacorner.test");
> 62 |   await expect(page).toHaveURL(/\/\?branch=[\w-]+$/);
     |                      ^ Error: expect(page).toHaveURL(expected) failed
  63 |   await expect(page.getByRole("link", { name: s.settings })).toHaveCount(0);
  64 | 
  65 |   await page.goto("/settings");
  66 |   await expect(page).toHaveURL(/\/forbidden$/);
  67 |   await expect(page.getByRole("heading", { level: 1, name: s.forbidden })).toBeVisible();
  68 | });
  69 | 
  70 | test("an unknown address shows the 404 page", async ({ page, s }) => {
  71 |   await page.goto("/no-such-page");
  72 |   await expect(page.getByRole("heading", { level: 1, name: s.notFound })).toBeVisible();
  73 |   await expectDocumentLocale(page, s);
  74 | });
  75 | 
```