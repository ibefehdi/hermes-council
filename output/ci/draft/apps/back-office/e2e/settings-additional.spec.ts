import { expect, expectDocumentLocale, signIn, test } from "./fixtures";

const HAWALLY = "00000000-0000-4000-a000-000000000004";

// A single-day closure on a random future date, so repeated runs and the en/ar projects don't overlap.
function randomFutureDay(): string {
  const offsetDays = Math.floor(Math.random() * 1400);
  return new Date(Date.UTC(2027, 0, 1) + offsetDays * 86_400_000).toISOString().slice(0, 10);
}

test("owner manages branch closures", async ({ page, s, appLocale }) => {
  const closureName = `closure-${appLocale}-${Date.now().toString(36)}`;
  const day = randomFutureDay();

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
  await drawer.getByLabel(s.closureNameEn).fill(closureName);
  await drawer.getByLabel(s.firstDayClosed).fill(day);
  await drawer.getByLabel(s.lastDayClosed).fill(day);

  // Save the closure.
  await drawer.getByRole("button", { name: s.saveClosure }).click();
  await expect(page.getByText(s.closureSaved)).toBeVisible();

  // The closure is still listed after a reload.
  await page.reload();
  const table = page.getByRole("table");
  await expect(table.getByRole("row", { name: new RegExp(closureName) })).toBeVisible();
});

test("owner visits cancellation reasons page", async ({ page, s }) => {
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
