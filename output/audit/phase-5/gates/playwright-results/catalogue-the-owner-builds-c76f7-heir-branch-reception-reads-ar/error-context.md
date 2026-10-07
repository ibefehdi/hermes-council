# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: catalogue.spec.ts >> the owner builds the menu; one branch opts out; the manager changes only their branch; reception reads
- Location: e2e/catalogue.spec.ts:20:1

# Error details

```
Error: expect(page).not.toHaveURL(expected) failed

Expected pattern: not /\/login/
Received string: "http://127.0.0.1:5173/login"
Timeout: 5000ms

Call log:
  - Expect "not toHaveURL" with timeout 5000ms
    10 × locator resolved to <html lang="ar" dir="rtl">…</html>
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
  - textbox "البريد الإلكتروني": setup-owner@spacorner.test
  - text: كلمة المرور
  - textbox "كلمة المرور": password123
  - button "تسجيل الدخول" [disabled]
  - link "نسيت كلمة المرور؟":
    - /url: /forgot-password
- status
- alert
```

# Test source

```ts
  1  | import type { Page } from "@playwright/test";
  2  | import { expect } from "./fixtures";
  3  | import type { Strings } from "./strings";
  4  | 
  5  | // Staff journeys shared by staff.spec.ts and the Phase 2 evidence run.
  6  | 
  7  | export const SETUP_BRANCH = {
  8  |   hawally: "00000000-0000-4000-a000-000000000004",
  9  |   jahra: "00000000-0000-4000-a000-000000000005",
  10 | } as const;
  11 | 
  12 | export async function openStaffList(page: Page, s: Strings, branchId?: string) {
  13 |   if (branchId) {
  14 |     // A just-submitted sign-in must land before a full page load.
> 15 |     await expect(page).not.toHaveURL(/\/login/);
     |                            ^ Error: expect(page).not.toHaveURL(expected) failed
  16 |     await page.goto(`/team/staff?branch=${branchId}`);
  17 |   } else {
  18 |     await page.getByRole("link", { name: s.team, exact: true }).click();
  19 |   }
  20 |   await expect(page.getByRole("heading", { level: 1, name: s.teamMembers })).toBeVisible();
  21 | }
  22 | 
  23 | export type NewStaff = {
  24 |   nameEn: string;
  25 |   nameAr: string;
  26 |   email?: string;
  27 |   /** Branch labels to tick; the active branch starts ticked. */
  28 |   branches: string[];
  29 |   defaultBranch?: string;
  30 | };
  31 | 
  32 | /** Fills the new-staff form from the list page and saves; ends on the new staff member's editor. */
  33 | export async function addStaff(page: Page, s: Strings, staff: NewStaff) {
  34 |   await page.getByRole("link", { name: s.addStaffMember }).click();
  35 |   await expect(page.getByRole("heading", { level: 1, name: s.addStaffMember })).toBeVisible();
  36 |   await page.getByLabel(s.fullNameEn).fill(staff.nameEn);
  37 |   await page.getByLabel(s.fullNameAr).fill(staff.nameAr);
  38 |   if (staff.email) await page.getByLabel(s.email).fill(staff.email);
  39 |   for (const branch of staff.branches) {
  40 |     await page.getByRole("checkbox", { name: branch, exact: true }).check();
  41 |   }
  42 |   if (staff.defaultBranch) await page.getByLabel(s.defaultBranch).selectOption({ label: staff.defaultBranch });
  43 |   await page.getByRole("button", { name: s.addStaffMember }).click();
  44 |   await expect(page.getByText(s.staffAdded)).toBeVisible();
  45 |   await expect(page).toHaveURL(/\/team\/staff\/[0-9a-f-]{36}/);
  46 | }
  47 | 
  48 | export const staffRow = (page: Page, marker: string) => page.getByRole("row", { name: new RegExp(marker) });
  49 | 
```