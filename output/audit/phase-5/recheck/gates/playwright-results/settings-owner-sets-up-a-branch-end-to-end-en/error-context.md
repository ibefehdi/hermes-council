# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: settings.spec.ts >> owner sets up a branch end to end
- Location: e2e/settings.spec.ts:12:1

# Error details

```
Error: expect(locator).toBeChecked() failed

Locator: getByLabel('Ask for a tip at checkout')
Expected: checked
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeChecked" getByLabel('Ask for a tip at checkout') with timeout 5000ms
  - waiting for getByLabel('Ask for a tip at checkout')

```

# Test source

```ts
  1   | import type { Page } from "@playwright/test";
  2   | import { expect, signIn, test } from "./fixtures";
  3   | import type { Strings } from "./strings";
  4   | 
  5   | // Setup Studio (supabase/seed.sql) is reserved for these journeys, so the
  6   | // branches they create and archive never touch the switcher tests.
  7   | const HAWALLY = "00000000-0000-4000-a000-000000000004";
  8   | const JAHRA = "00000000-0000-4000-a000-000000000005";
  9   | 
  10  | const branchSwitcher = (page: Page, s: Strings) => page.getByRole("banner").getByRole("combobox", { name: s.branch });
  11  | 
  12  | test("owner sets up a branch end to end", async ({ page, s, appLocale }) => {
  13  |   const suffix = `${appLocale}-${Date.now().toString(36)}`;
  14  |   const nameEn = `Fintas ${suffix}`;
  15  |   const nameAr = `الفنطاس ${suffix}`;
  16  |   const shownName = appLocale === "ar" ? nameAr : nameEn;
  17  | 
  18  |   await page.goto("/login");
  19  |   await signIn(page, s, "setup-owner@spacorner.test");
  20  |   await expect(page.getByRole("heading", { name: s.finishSettingUp })).toBeVisible();
  21  | 
  22  |   // Hub -> branches -> new branch.
  23  |   await page.getByRole("link", { name: s.settings }).click();
  24  |   await page.getByRole("link", { name: s.branches, exact: true }).click();
  25  |   await page.getByRole("link", { name: s.addBranch }).click();
  26  |   await page.getByLabel(s.branchNameEn).fill(nameEn);
  27  |   await page.getByLabel(s.branchNameAr).fill(nameAr);
  28  |   await page.getByLabel(s.address).fill("Block 4, Street 12");
  29  |   await page.getByLabel(s.phone).fill("+965 2222 3333");
  30  |   await page.getByLabel(s.invoicePrefix).fill("FNT");
  31  |   await page.getByRole("button", { name: s.createBranch }).click();
  32  |   await expect(page.getByText(s.branchCreated)).toBeVisible();
  33  |   await expect(page).toHaveURL(/\/settings\/branches\/[\w-]+\/hours/);
  34  |   await expect(page.getByRole("heading", { level: 1, name: shownName })).toBeVisible();
  35  | 
  36  |   // The new branch is in the switcher straight away.
  37  |   await expect(branchSwitcher(page, s).locator("option", { hasText: shownName })).toHaveCount(1);
  38  | 
  39  |   // Thursday: split day 10:00-14:00 plus an overnight 18:00-02:00, shown in the branch's 12-hour format.
  40  |   const thursday = page.getByRole("group", { name: s.thursday });
  41  |   await thursday.getByLabel(s.closes).first().fill("14:00");
  42  |   await thursday.getByRole("button", { name: s.splitDay }).click();
  43  |   await thursday.getByLabel(s.opens).nth(1).fill("18:00");
  44  |   await thursday.getByLabel(s.closes).nth(1).fill("02:00");
  45  |   await expect(thursday.getByTestId("hours-preview").nth(1)).toContainText(s.pm6to2am);
  46  |   await expect(thursday.getByText(s.closesNextDay)).toBeVisible();
  47  | 
  48  |   // A zero-length interval is rejected at the field and blocks saving.
  49  |   const friday = page.getByRole("group", { name: s.friday });
  50  |   await friday.getByLabel(s.closes).first().fill("14:00");
  51  |   await expect(friday.getByText(s.zeroLength)).toBeVisible();
  52  |   await expect(page.getByRole("button", { name: s.saveHours })).toBeDisabled();
  53  |   await friday.getByLabel(s.closes).first().fill("22:00");
  54  |   await expect(friday.getByText(s.zeroLength)).toHaveCount(0);
  55  | 
  56  |   await page.getByRole("button", { name: s.saveHours }).click();
  57  |   await expect(page.getByText(s.hoursSaved)).toBeVisible();
  58  | 
  59  |   // Saved hours come back from the database in branch-local time.
  60  |   await page.reload();
  61  |   const thursdayAfter = page.getByRole("group", { name: s.thursday });
  62  |   await expect(thursdayAfter.getByTestId("hours-preview")).toHaveCount(2);
  63  |   await expect(thursdayAfter.getByTestId("hours-preview").nth(1)).toContainText(s.pm6to2am);
  64  |   await expect(thursdayAfter.getByText(s.closesNextDay)).toBeVisible();
  65  | 
  66  |   // Receipt text, paired English and Arabic.
  67  |   await page.getByRole("link", { name: s.invoicingTab }).click();
  68  |   await page.getByLabel(s.headerEn).fill("Welcome to Fintas");
  69  |   await page.getByLabel(s.headerAr).fill("أهلاً بكم في الفنطاس");
  70  |   await page.getByLabel(s.footerEn).fill("Thank you for visiting");
  71  |   await page.getByLabel(s.footerAr).fill("شكراً لزيارتكم");
  72  |   await page.getByRole("button", { name: s.save }).click();
  73  |   await expect(page.getByText(s.invoicingSaved)).toBeVisible();
  74  | 
  75  |   // Checkout methods.
  76  |   await page.getByRole("link", { name: s.methodsTab }).click();
  77  |   await page.getByLabel(s.bankTransfer).check();
  78  |   await page.getByLabel(s.cash).uncheck();
  79  |   await page.getByRole("button", { name: s.save }).click();
  80  |   await expect(page.getByText(s.methodsSaved)).toBeVisible();
  81  | 
  82  |   // Tips.
  83  |   await page.getByRole("link", { name: s.tipsTab }).click();
  84  |   await page.getByLabel(s.askTip).check();
  85  |   await page.getByLabel(s.tipPresets).fill("5, 10, 15");
  86  |   await page.getByRole("button", { name: s.save }).click();
  87  |   await expect(page.getByText(s.tipsSaved)).toBeVisible();
  88  | 
  89  |   // Everything persisted.
  90  |   await page.reload();
> 91  |   await expect(page.getByLabel(s.askTip)).toBeChecked();
      |                                           ^ Error: expect(locator).toBeChecked() failed
  92  |   await expect(page.getByLabel(s.tipPresets)).toHaveValue("5, 10, 15");
  93  |   await page.getByRole("link", { name: s.methodsTab }).click();
  94  |   await expect(page.getByLabel(s.bankTransfer)).toBeChecked();
  95  |   await expect(page.getByLabel(s.cash)).not.toBeChecked();
  96  |   await page.getByRole("link", { name: s.invoicingTab }).click();
  97  |   await expect(page.getByLabel(s.headerAr)).toHaveValue("أهلاً بكم في الفنطاس");
  98  | 
  99  |   // Archive: gone from the switcher, still listed (badged) in settings.
  100 |   await page.getByRole("button", { name: s.archiveBranch }).click();
  101 |   await page.getByRole("alertdialog").getByRole("button", { name: s.archive, exact: true }).click();
  102 |   await expect(page.getByText(s.branchArchived)).toBeVisible();
  103 |   await expect(branchSwitcher(page, s).locator("option", { hasText: shownName })).toHaveCount(0);
  104 |   await expect(branchSwitcher(page, s).locator("option", { hasText: s.hawally })).toHaveCount(1);
  105 | 
  106 |   await page.getByRole("link", { name: s.branches }).first().click();
  107 |   const row = page.getByRole("row", { name: new RegExp(shownName) });
  108 |   await expect(row).toContainText(s.archived);
  109 | });
  110 | 
  111 | test("a receptionist can't reach settings", async ({ page, s }) => {
  112 |   await page.goto("/login");
  113 |   await signIn(page, s, "setup-reception@spacorner.test");
  114 |   await expect(page.getByRole("heading", { name: s.welcome("Reem Hawally") })).toBeVisible();
  115 |   await expect(page.getByRole("link", { name: s.settings })).toHaveCount(0);
  116 | 
  117 |   await page.goto(`/settings/branches/${HAWALLY}/details`);
  118 |   await expect(page.getByRole("heading", { name: s.forbidden })).toBeVisible();
  119 |   await page.goto("/setup");
  120 |   await expect(page.getByRole("heading", { name: s.forbidden })).toBeVisible();
  121 | });
  122 | 
  123 | test("a manager sees only their branch: details read-only, hours editable", async ({ page, s }) => {
  124 |   await page.goto("/login");
  125 |   await signIn(page, s, "setup-manager@spacorner.test");
  126 |   await page.getByRole("link", { name: s.settings }).click();
  127 |   await page.getByRole("link", { name: s.branches, exact: true }).click();
  128 | 
  129 |   const rows = page.getByRole("row");
  130 |   await expect(rows.filter({ hasText: s.hawally })).toHaveCount(1);
  131 |   await expect(rows.filter({ hasText: s.jahra })).toHaveCount(0);
  132 |   await expect(page.getByRole("link", { name: s.addBranch })).toHaveCount(0);
  133 | 
  134 |   await rows.filter({ hasText: s.hawally }).getByRole("link").click();
  135 |   await expect(page.getByText(s.ownerOnlyDetails)).toBeVisible();
  136 |   await expect(page.getByLabel(s.branchNameEn)).toHaveAttribute("readonly", "");
  137 |   await expect(page.getByRole("button", { name: s.save })).toHaveCount(0);
  138 | 
  139 |   await page.getByRole("link", { name: s.hoursTab }).click();
  140 |   await page.getByRole("button", { name: s.saveHours }).click();
  141 |   await expect(page.getByText(s.hoursSaved)).toBeVisible();
  142 | 
  143 |   // Another branch of the same business is out of scope.
  144 |   await page.goto(`/settings/branches/${JAHRA}/details`);
  145 |   await expect(page.getByRole("heading", { name: s.branchNotFound })).toBeVisible();
  146 | });
  147 | 
```