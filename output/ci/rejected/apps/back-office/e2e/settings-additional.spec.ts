import { expect, expectDocumentLocale, signIn, test } from "./fixtures";

const HAWALLY = "00000000-0000-4000-a000-000000000004";

test("owner manages branch closures", async ({ page, s, appLocale }) => {
  const suffix = `${appLocale}-${Date.now().toString(36)}`;
  const closureName = `${suffix}`;

  await page.goto("/login");
  await signIn(page, s, "setup-owner@spacorner.test");
  await expect(page).not.toHaveURL(/\/login/);

  // Navigate to settings -> branches -> Hawally -> closures tab.
  await page.goto(`/settings/branches/${HAWALLY}/closures`);
  await expect(page).toHaveURL(/\/settings\/branches\/[^/]+\/closures(\?.*)?$/);
  await expectDocumentLocale(page, s);

  // The closures tab renders (empty state or table).
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();

  // Click "Add closure" and verify the drawer opens.
  await page.getByRole("button", { name: s.addClosure }).click();
  const drawer = page.getByRole("dialog");
  await expect(drawer).toBeVisible();

  // Fill closure name and dates.
  const nameField = drawer.getByLabel("Name (English)");
  await nameField.fill(closureName);
  const firstDayField = drawer.getByLabel("First day closed");
  await firstDayField.fill("2026-12-25");
  const lastDayField = drawer.getByLabel("Last day closed");
  await lastDayField.fill("2026-12-26");

  // Save the closure.
  await drawer.getByRole("button", { name: s.saveClosure }).click();
  await expect(page.getByText(s.closureSaved)).toBeVisible();

  // The closure appears in the table.
  await page.reload();
  const table = page.getByRole("table");
  await expect(table.getByRole("row", { name: new RegExp(closureName) })).toBeVisible();
});

test("owner visits cancellation reasons page", async ({ page, s, appLocale }) => {
  await page.goto("/login");
  await signIn(page, s, "setup-owner@spacorner.test");
  await expect(page).not.toHaveURL(/\/login/);

  // Navigate to settings -> cancellation reasons.
  await page.goto("/settings/cancellation-reasons");
  await expect(page).toHaveURL(/\/settings\/cancellation-reasons(\?.*)?$/);
  await expectDocumentLocale(page, s);

  await expect(page.getByRole("heading", { level: 1, name: s.cancellationReasons })).toBeVisible();

  // The page has an "Add reason" button.
  await expect(page.getByRole("button", { name: s.addReason })).toBeVisible();
});