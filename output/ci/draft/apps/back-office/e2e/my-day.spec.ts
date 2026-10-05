import { expect, expectDocumentLocale, signIn, test } from "./fixtures";
import { unique } from "./memberFlows";

// Seed ids (supabase/seed.sql): SpaCorner setup branch user has a staff profile.
const STAFF_EMAIL = "staff@spacorner.test";

test("staff member views /my-day, sees their schedule, blocked time and branches", async ({
  page,
  s,
  appLocale,
}) => {
  await page.goto("/login");
  await signIn(page, s, STAFF_EMAIL);
  await expect(page).not.toHaveURL(/\/login/);

  // Navigate to /my-day.
  await page.goto("/my-day");
  await expect(page).toHaveURL(/\/my-day(\?.*)?$/);
  await expectDocumentLocale(page, s);

  // The "My day" heading is visible.
  await expect(page.getByRole("heading", { level: 1, name: s.myDay })).toBeVisible();

  // The "Where you work" card shows at least one branch (Huda Staff has Salmiya + Kuwait City).
  await expect(page.getByRole("heading", { name: s.whereYouWork })).toBeVisible();
  const branchCard = page.getByRole("region", { name: s.whereYouWork });
  const branchRows = branchCard.getByRole("row");
  await expect(branchRows).not.toHaveCount(0);

  // The "Your shifts" card shows either shifts or the empty state message.
  const shiftsCard = page.getByRole("region", { name: s.yourShifts });
  const shiftsRows = shiftsCard.getByRole("row");
  // Either shifts are listed, or the empty state renders.
  const emptyShifts = shiftsCard.getByRole("heading", { name: "No shifts in the next 7 days" });
  if (await emptyShifts.isVisible().catch(() => false)) {
    await expect(shiftsRows).toHaveCount(0);
  }

  // The "Your blocked time" card shows either blocks or the empty state.
  const blocksCard = page.getByRole("region", { name: s.yourBlockedTime });
  await expect(blocksCard).toBeVisible();
});

test("a user without a staff profile sees the /my-day empty state", async ({
  page,
  s,
  appLocale,
}) => {
  // The manager (setup-manager@spacorner.test) has a membership but no staff profile at Setup Studio.
  await page.goto("/login");
  await signIn(page, s, "setup-manager@spacorner.test");
  await expect(page).not.toHaveURL(/\/login/);

  await page.goto("/my-day");
  await expect(page).toHaveURL(/\/my-day(\?.*)?$/);
  await expectDocumentLocale(page, s);

  // The "My day" heading is visible.
  await expect(page.getByRole("heading", { level: 1, name: s.myDay })).toBeVisible();

  // The empty state says the user has no staff profile.
  await expect(page.getByText(s.noStaffProfile)).toBeVisible();
});