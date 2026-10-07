# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: blocked-time.spec.ts >> a manager adds time off at every branch on a person's behalf; it shows at both branches and on their My day
- Location: e2e/blocked-time.spec.ts:80:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('تم إرسال الدعوة إلى block-ar-muxpejib01q@spacorner.test.')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" getByText('تم إرسال الدعوة إلى block-ar-muxpejib01q@spacorner.test.') with timeout 5000ms
  - waiting for getByText('تم إرسال الدعوة إلى block-ar-muxpejib01q@spacorner.test.')

```

```yaml
- link "الانتقال إلى المحتوى الرئيسي":
  - /url: "#main"
- complementary:
  - navigation "القائمة الرئيسية":
    - list:
      - listitem:
        - link "الرئيسية":
          - /url: /?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "يومي":
          - /url: /my-day?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "التقويم":
          - /url: /calendar?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "العملاء":
          - /url: /clients?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "الفريق":
          - /url: /team?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "قائمة الخدمات":
          - /url: /catalogue?branch=00000000-0000-4000-a000-000000000004
      - listitem: المبيعات
      - listitem: التقارير
      - listitem:
        - link "الإعدادات":
          - /url: /settings?branch=00000000-0000-4000-a000-000000000004
- banner:
  - paragraph: ستوديو الإعداد
  - text: المالك الفرع
  - combobox "الفرع":
    - option "جميع الفروع"
    - option "حولي" [selected]
    - option "الجهراء"
    - option "سلوى"
  - button "البحث عن العملاء والمواعيد": بحث Ctrl K
  - button "English"
  - button "Salma Setup"
- main:
  - link "العودة إلى الموظفين":
    - /url: /team/staff?branch=00000000-0000-4000-a000-000000000004
  - heading "سارة ar-muxpejib01q" [level=1]
  - heading "التفاصيل" [level=2]
  - text: الاسم الكامل (بالإنجليزية)
  - textbox "الاسم الكامل (بالإنجليزية)": Sara ar-muxpejib01q
  - text: الاسم الكامل (بالعربية)
  - textbox "الاسم الكامل (بالعربية)": سارة ar-muxpejib01q
  - text: المسمى الوظيفي (بالإنجليزية)
  - textbox "المسمى الوظيفي (بالإنجليزية)"
  - text: المسمى الوظيفي (بالعربية)
  - textbox "المسمى الوظيفي (بالعربية)"
  - text: الهاتف
  - textbox "الهاتف"
  - text: البريد الإلكتروني
  - textbox "البريد الإلكتروني": block-ar-muxpejib01q@spacorner.test
  - text: مطلوب فقط إذا كان سيسجل الدخول.
  - checkbox "متاح للحجز" [checked]
  - text: متاح للحجز أوقفه لأعضاء الفريق الذين لا يستقبلون مواعيد.
  - checkbox "نشط" [checked]
  - text: نشط يبقى الموظف غير النشط في السجلات لكن لا يمكن جدولته أو حجزه.
  - group "الفروع":
    - text: الفروع
    - paragraph: اختر أين يعمل. سيظهر في قائمة موظفي كل فرع وجدوله.
    - checkbox "حولي" [checked]
    - text: حولي
    - checkbox "متاح للحجز في حولي" [checked]
    - text: متاح للحجز في حولي
    - checkbox "الجهراء" [checked]
    - text: الجهراء
    - checkbox "متاح للحجز في الجهراء" [checked]
    - text: متاح للحجز في الجهراء
    - checkbox "سلوى"
    - text: سلوى الفرع الافتراضي
    - combobox "الفرع الافتراضي":
      - option "حولي" [selected]
      - option "الجهراء"
  - button "حفظ التغييرات" [disabled]
  - heading "حساب الدخول" [level=2]
  - text: بدون حساب دخول
  - paragraph: لا يحتاج الموظف إلى حساب دخول لجدولته أو حجزه. ادعه إذا كان يجب أن يسجل الدخول ليرى يومه.
  - button "دعوة لتسجيل الدخول" [disabled]
- status
- alert
```

# Test source

```ts
  1   | import {
  2   |   addDays,
  3   |   blockTable,
  4   |   blockTime,
  5   |   editBlockButtons,
  6   |   fillTimes,
  7   |   freshDay,
  8   |   openBlockedTime,
  9   |   seedAppointment,
  10  |   staffIdFromUrl,
  11  | } from "./blockedTimeFlows";
  12  | import { expect, signIn, test } from "./fixtures";
  13  | import { acceptInvite, newPersonPage, unique } from "./memberFlows";
  14  | import { kuwaitToday } from "./shiftFlows";
  15  | import { SETUP_BRANCH, addStaff, openStaffList } from "./staffFlows";
  16  | 
  17  | // Setup Studio (supabase/seed.sql) gets fresh staff and far-future dates each
  18  | // run. Hawally is Asia/Kuwait; every write goes through the locked RPCs.
  19  | 
  20  | test("a receptionist blocks time at their branch; overlaps and appointments are explained; the block moves and goes", async ({
  21  |   page,
  22  |   browser,
  23  |   request,
  24  |   s,
  25  |   appLocale,
  26  | }) => {
  27  |   const id = unique(appLocale);
  28  |   const day = freshDay();
  29  |   const name = appLocale === "ar" ? `حجب ${id}` : `Block ${id}`;
  30  | 
  31  |   await page.goto("/login");
  32  |   await signIn(page, s, "setup-manager@spacorner.test");
  33  |   await openStaffList(page, s, SETUP_BRANCH.hawally);
  34  |   await addStaff(page, s, { nameEn: `Block ${id}`, nameAr: `حجب ${id}`, branches: [s.hawally] });
  35  |   const staffId = staffIdFromUrl(page);
  36  |   await seedAppointment(request, { staffId, branchId: SETUP_BRANCH.hawally, day, start: "15:00", end: "16:00" });
  37  | 
  38  |   const reception = await newPersonPage(browser, appLocale);
  39  |   await reception.goto("/login");
  40  |   await signIn(reception, s, "setup-reception@spacorner.test");
  41  |   await openBlockedTime(reception, s, SETUP_BRANCH.hawally, { from: day, to: day });
  42  |   await expect(reception.getByText(s.noBlocks)).toBeVisible();
  43  | 
  44  |   // Own-branch block, typed; a receptionist never gets the every-branch option.
  45  |   await reception.getByRole("button", { name: s.blockTime, exact: true }).click();
  46  |   await expect(reception.getByRole("dialog").getByRole("checkbox", { name: s.timeOffEverywhere })).toHaveCount(0);
  47  |   await reception.getByRole("dialog").getByRole("button", { name: s.close }).click();
  48  |   await blockTime(reception, s, { staff: name, type: s.breakType, timed: { day, starts: "13:00", ends: "14:00" } });
  49  |   await expect(reception.getByText(s.timeBlocked)).toBeVisible();
  50  |   const table = blockTable(reception, s);
  51  |   await expect(table.getByRole("row", { name: new RegExp(id) })).toContainText(s.breakType);
  52  |   await expect(table.getByRole("row", { name: new RegExp(id) })).toContainText(s.thisBranch);
  53  | 
  54  |   // The same person can't be blocked twice at once, nor over an appointment.
  55  |   await blockTime(reception, s, { staff: name, type: s.breakType, timed: { day, starts: "13:30", ends: "14:30" } });
  56  |   await expect(reception.getByRole("dialog").getByText(s.blockOverlap)).toBeVisible();
  57  |   await fillTimes(reception, s, { starts: "15:30", ends: "16:30" });
  58  |   await reception.getByRole("dialog").getByRole("button", { name: s.blockTime, exact: true }).click();
  59  |   await expect(reception.getByRole("dialog").getByText(s.blockAppointment)).toBeVisible();
  60  |   await reception.getByRole("dialog").getByRole("button", { name: s.close }).click();
  61  | 
  62  |   // Move: stretching over its own time is fine; onto the appointment is not.
  63  |   await editBlockButtons(reception, s, name).click();
  64  |   await fillTimes(reception, s, { starts: "13:00", ends: "15:30" });
  65  |   await reception.getByRole("dialog").getByRole("button", { name: s.saveBlock }).click();
  66  |   await expect(reception.getByRole("dialog").getByText(s.blockAppointment)).toBeVisible();
  67  |   await fillTimes(reception, s, { starts: "12:30", ends: "14:30" });
  68  |   await reception.getByRole("dialog").getByRole("button", { name: s.saveBlock }).click();
  69  |   await expect(reception.getByText(s.blockSaved)).toBeVisible();
  70  | 
  71  |   // Delete asks first.
  72  |   await editBlockButtons(reception, s, name).click();
  73  |   await reception.getByRole("dialog").getByRole("button", { name: s.deleteBlock }).click();
  74  |   await reception.getByRole("alertdialog").getByRole("button", { name: s.deleteBlock }).click();
  75  |   await expect(reception.getByText(s.blockDeleted)).toBeVisible();
  76  |   await expect(reception.getByText(s.noBlocks)).toBeVisible();
  77  |   await reception.context().close();
  78  | });
  79  | 
  80  | test("a manager adds time off at every branch on a person's behalf; it shows at both branches and on their My day", async ({
  81  |   page,
  82  |   browser,
  83  |   request,
  84  |   s,
  85  |   appLocale,
  86  | }) => {
  87  |   const id = unique(appLocale);
  88  |   const email = `block-${id}@spacorner.test`;
  89  |   const name = appLocale === "ar" ? `سارة ${id}` : `Sara ${id}`;
  90  |   const first = addDays(kuwaitToday(), 1);
  91  |   const last = addDays(kuwaitToday(), 2);
  92  | 
  93  |   // The owner adds someone who works at both branches and invites them.
  94  |   await page.goto("/login");
  95  |   await signIn(page, s, "setup-owner@spacorner.test");
  96  |   await openStaffList(page, s, SETUP_BRANCH.hawally);
  97  |   await addStaff(page, s, { nameEn: `Sara ${id}`, nameAr: `سارة ${id}`, email, branches: [s.hawally, s.jahra] });
  98  |   await page.getByRole("button", { name: s.inviteToSignIn }).click();
> 99  |   await expect(page.getByText(s.invitationSentTo(email))).toBeVisible();
      |                                                           ^ Error: expect(locator).toBeVisible() failed
  100 | 
  101 |   // Hawally's manager books two days off for them, everywhere.
  102 |   const manager = await newPersonPage(browser, appLocale);
  103 |   await manager.goto("/login");
  104 |   await signIn(manager, s, "setup-manager@spacorner.test");
  105 |   await openBlockedTime(manager, s, SETUP_BRANCH.hawally);
  106 |   await blockTime(manager, s, { staff: name, type: s.personalType, everywhere: true, allDay: { first, last } });
  107 |   await expect(manager.getByText(s.timeBlocked)).toBeVisible();
  108 |   const row = blockTable(manager, s).getByRole("row", { name: new RegExp(id) });
  109 |   await expect(row).toContainText(s.personalType);
  110 |   await expect(row).toContainText(s.everyBranch);
  111 |   await manager.context().close();
  112 | 
  113 |   // The owner sees the same time off from Jahra.
  114 |   await openBlockedTime(page, s, SETUP_BRANCH.jahra);
  115 |   await expect(blockTable(page, s).getByRole("row", { name: new RegExp(id) })).toContainText(s.everyBranch);
  116 | 
  117 |   // The person sees it on their own schedule, read-only: no request or approval step (ADR-53).
  118 |   const person = await newPersonPage(browser, appLocale);
  119 |   await acceptInvite(person, request, s, email, `Glow-${id}`);
  120 |   await person.getByRole("link", { name: s.myDay }).click();
  121 |   const mine = person.getByRole("table", { name: s.yourBlockedTime });
  122 |   await expect(mine).toContainText(s.personalType);
  123 |   await expect(mine).toContainText(s.everyBranch);
  124 |   await expect(mine.getByRole("button")).toHaveCount(0);
  125 |   await person.context().close();
  126 | });
  127 | 
```