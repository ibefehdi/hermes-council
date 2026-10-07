# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: calendar.spec.ts >> the front desk books from an empty time on the grid: the drawer starts with that person and time
- Location: e2e/calendar.spec.ts:90:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('تم حجز الموعد.')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" getByText('تم حجز الموعد.') with timeout 5000ms
  - waiting for getByText('تم حجز الموعد.')

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
- banner:
  - paragraph: ستوديو الإعداد
  - text: موظف الاستقبال
  - group "الفرع (مقفل)":
    - paragraph: حولي
  - button "البحث عن العملاء والمواعيد": بحث Ctrl K
  - button "English"
  - button "Reem Hawally"
- main:
  - heading "التقويم" [level=1]
  - button "موعد جديد"
  - radiogroup "عرض التقويم":
    - radio "يوم" [checked]
    - radio "أسبوع"
  - button "اليوم السابق"
  - button "اليوم"
  - button "اليوم التالي"
  - heading "الخميس، 8 أكتوبر" [level=2]
  - button "عضو واحد"
  - text: فئة الخدمة
  - combobox "فئة الخدمة":
    - option "كل التصنيفات" [selected]
    - option "مساج"
    - option "Concurrency muxpc46l2h01"
    - option "Bookings muxpbxfm617y"
    - option "Bookings muxpbv9jv9dz"
    - option "Block fixtures muxpao3qpqjw"
    - option "Concurrency muxpan7hp4g5"
    - option "Block fixtures muxpcfe6xb3e"
    - option "تصنيف en-muxpdmxiv9d"
    - option "Booking fixtures"
  - text: الانتقال إلى تاريخ
  - textbox "الانتقال إلى تاريخ": 2026-10-08
  - button "الانتقال إلى المواعيد"
  - region "المواعيد حسب الموظف":
    - button "موعد جديد مع منى ar-muxpej3dg1d": منى ar-muxpej3dg1d
    - button "لينا ar-muxpej3dg1d 15:00 – 16:00 تنظيف بشرة ar-muxpej3dg1d"
  - status
  - dialog "موعد جديد":
    - heading "موعد جديد" [level=2]
    - paragraph: الأوقات بالمنطقة الزمنية للفرع (Asia/Kuwait).
    - button "إغلاق"
    - group "العميل":
      - text: العميل
      - checkbox "بدون حجز"
      - text: بدون حجز بدون سجل عميل. يمكنك ربط عميل بالموعد لاحقًا. سارة ar-muxpej3dg1d Sara ar-muxpej3dg1d
      - button "تغيير العميل"
    - text: يوم
    - textbox "يوم": 2026-10-08
    - region "الخدمة":
      - heading "الخدمة" [level=3]
      - text: الخدمة
      - combobox "الخدمة":
        - option "اختر خدمة"
      - text: عضو الفريق
      - combobox "عضو الفريق":
        - option "أي شخص متاح"
        - option "منى ar-muxpej3dg1d" [selected]
      - group "الأوقات المتاحة":
        - text: الأوقات المتاحة
        - status "جارٍ تحميل الأوقات المتاحة"
      - text: وقت البدء
      - textbox "وقت البدء": 17:00
      - text: اختر وقتًا متاحًا أعلاه، أو اكتب وقتًا.
      - paragraph: 60 دقيقة · ‏25.000 د.ك.‏
    - button "إضافة خدمة أخرى"
    - text: الإجمالي (60 دقيقة) ‏25.000 د.ك.‏ ملاحظة الموعد
    - textbox "ملاحظة الموعد"
    - text: اختياري. يظهر لموظفي الاستقبال.
    - button "إلغاء"
    - button "احجز الموعد" [disabled]
- status
- alert
```

# Test source

```ts
  29  | /** A fresh 60-minute facial and Mona, who does it, on shift `shift` that day. */
  30  | async function facialWithMona(request: Request, id: string, day: string, shift = { starts: "09:00", ends: "22:00" }) {
  31  |   const serviceId = await createService(request, { en: `Facial ${id}`, ar: `تنظيف بشرة ${id}` }, { duration: 60, price: 25_000 });
  32  |   const monaId = await createStaff(request, {
  33  |     name: { en: `Mona ${id}`, ar: `منى ${id}` },
  34  |     branchId: SETUP_BRANCH.hawally,
  35  |     serviceIds: [serviceId],
  36  |     shifts: [{ day, ...shift }],
  37  |   });
  38  |   return { serviceId, monaId };
  39  | }
  40  | 
  41  | async function signInTo(page: Page, s: Strings, email: string) {
  42  |   await page.goto("/login");
  43  |   await signIn(page, s, email);
  44  |   await expect(page).toHaveURL(/\?branch=/);
  45  | }
  46  | 
  47  | /** Drops this tab's session only: signing out revokes that login's sessions in parallel workers too. */
  48  | async function dropSession(page: Page) {
  49  |   await page.evaluate(() => {
  50  |     for (const key of Object.keys(window.localStorage)) if (key.startsWith("sb-")) window.localStorage.removeItem(key);
  51  |   });
  52  | }
  53  | 
  54  | /** Resolves once Realtime confirms the page's Hawally appointments subscription; call before navigating. */
  55  | function appointmentsLive(page: Page): Promise<void> {
  56  |   const topic = `"realtime:appointments:${SETUP_TENANT}:${SETUP_BRANCH.hawally}"`;
  57  |   return new Promise((resolve) => {
  58  |     page.on("websocket", (socket) => {
  59  |       socket.on("framereceived", ({ payload }) => {
  60  |         const frame = typeof payload === "string" ? payload : payload.toString();
  61  |         if (frame.includes(topic) && frame.includes('"Subscribed to PostgreSQL"') && frame.includes('"status":"ok"')) resolve();
  62  |       });
  63  |     });
  64  |   });
  65  | }
  66  | 
  67  | async function openDay(page: Page, s: Strings, day: string, staff: string[]) {
  68  |   await page.goto(`/calendar?branch=${SETUP_BRANCH.hawally}&date=${day}&staff=${encodeURIComponent(JSON.stringify(staff))}`);
  69  |   return page.getByRole("region", { name: s.appointmentsByStaff });
  70  | }
  71  | 
  72  | const columnOf = (byStaff: Locator, staffId: string) => byStaff.locator(`.gd-resource-column[data-resource-id="${staffId}"]`);
  73  | 
  74  | async function box(locator: Locator) {
  75  |   const found = await locator.boundingBox();
  76  |   if (!found) throw new Error("not on screen");
  77  |   return found;
  78  | }
  79  | 
  80  | /** Fills the new-booking drawer for one service with a typed start time. */
  81  | async function fillBooking(drawer: Locator, s: Strings, booking: { client: string; service: string; staff: string; time: string }) {
  82  |   await drawer.getByLabel(s.findClient).fill(booking.client);
  83  |   await drawer.getByRole("button", { name: new RegExp(booking.client) }).click();
  84  |   const item = drawer.getByRole("region", { name: s.service, exact: true });
  85  |   await item.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: booking.service });
  86  |   await item.getByRole("combobox", { name: s.teamMember }).selectOption({ label: booking.staff });
  87  |   await item.getByLabel(s.startTime).fill(booking.time);
  88  | }
  89  | 
  90  | test("the front desk books from an empty time on the grid: the drawer starts with that person and time", async ({
  91  |   page,
  92  |   request,
  93  |   s,
  94  |   appLocale,
  95  | }) => {
  96  |   const id = unique(appLocale);
  97  |   const day = addDays(kuwaitToday(), 1);
  98  |   const { serviceId, monaId } = await facialWithMona(request, id, day);
  99  |   const linaId = await createClient(request, { firstName: "Lina", lastName: id, firstNameAlt: "لينا", lastNameAlt: id });
  100 |   await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  101 |   // Lina at 15:00 pins the grid's scale to a known time.
  102 |   await book(request, RECEPTION, {
  103 |     branchId: SETUP_BRANCH.hawally,
  104 |     clientId: linaId,
  105 |     items: [{ service_id: serviceId, staff_id: monaId, starts_at: kuwait(day, "15:00") }],
  106 |   });
  107 | 
  108 |   await signInTo(page, s, RECEPTION);
  109 |   const column = columnOf(await openDay(page, s, day, [monaId]), monaId);
  110 |   const lina = column.locator(EVENT).filter({ hasText: named(appLocale, "Lina", "لينا", id) });
  111 |   await expect(lina).toBeVisible();
  112 | 
  113 |   // Two hours below Lina's start is 17:00 in Mona's column.
  114 |   await lina.scrollIntoViewIfNeeded();
  115 |   const [linaBox, columnBox] = [await box(lina), await box(column)];
  116 |   await column.click({ position: { x: columnBox.width / 2, y: linaBox.y - columnBox.y + 120 * PX_PER_MINUTE + 4 } });
  117 | 
  118 |   const drawer = page.getByRole("dialog", { name: s.newAppointment });
  119 |   const item = drawer.getByRole("region", { name: s.service, exact: true });
  120 |   await expect(item.getByRole("combobox", { name: s.teamMember })).toHaveValue(monaId);
  121 |   await expect(item.getByLabel(s.startTime)).toHaveValue("17:00");
  122 | 
  123 |   await drawer.getByLabel(s.findClient).fill(`Sara ${id}`);
  124 |   await drawer.getByRole("button", { name: new RegExp(`Sara ${id}`) }).click();
  125 |   await item.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: named(appLocale, "Facial", "تنظيف بشرة", id) });
  126 |   await expect(item.getByRole("combobox", { name: s.teamMember })).toHaveValue(monaId);
  127 |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  128 | 
> 129 |   await expect(page.getByText(s.appointmentBooked)).toBeVisible();
      |                                                     ^ Error: expect(locator).toBeVisible() failed
  130 |   await expect(drawer).toBeHidden();
  131 |   const sara = column.locator(EVENT).filter({ hasText: named(appLocale, "Sara", "سارة", id) });
  132 |   await expect(timeOf(sara)).toHaveText(hours("17:00", "18:00"));
  133 | });
  134 | 
  135 | test("outside a shift the front desk is sent to a manager and the function refuses its override; the manager books it and the reason is recorded", async ({
  136 |   page,
  137 |   request,
  138 |   s,
  139 |   appLocale,
  140 | }) => {
  141 |   const id = unique(appLocale);
  142 |   const day = addDays(kuwaitToday(), 1);
  143 |   // Mona works 15:00–17:00; 18:00 is inside opening hours but outside her shift.
  144 |   const { serviceId, monaId } = await facialWithMona(request, id, day, { starts: "15:00", ends: "17:00" });
  145 |   const saraId = await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  146 |   const booking = {
  147 |     client: `Sara ${id}`,
  148 |     service: named(appLocale, "Facial", "تنظيف بشرة", id),
  149 |     staff: named(appLocale, "Mona", "منى", id),
  150 |     time: "18:00",
  151 |   };
  152 | 
  153 |   await signInTo(page, s, RECEPTION);
  154 |   let byStaff = await openDay(page, s, day, [monaId]);
  155 |   await page.getByRole("button", { name: s.newAppointment, exact: true }).click();
  156 |   let drawer = page.getByRole("dialog", { name: s.newAppointment });
  157 |   await fillBooking(drawer, s, booking);
  158 |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  159 |   const ask = page.getByRole("alertdialog", { name: s.askManager });
  160 |   await expect(ask).toContainText(s.outsideShift);
  161 |   await expect(ask).toContainText(s.onlyManagerConfirms);
  162 |   await expect(ask.getByRole("button", { name: s.bookAnyway })).toHaveCount(0);
  163 | 
  164 |   // Sending the override anyway: the function refuses it for a receptionist (5.1 ruling).
  165 |   const refused = await attemptCreate(request, RECEPTION, {
  166 |     branchId: SETUP_BRANCH.hawally,
  167 |     clientId: saraId,
  168 |     items: [{ service_id: serviceId, staff_id: monaId, starts_at: kuwait(day, "18:00") }],
  169 |     overrides: ["outside_shift"],
  170 |   });
  171 |   expect(refused.status).toBe(403);
  172 |   expect(refused.body).toMatchObject({ ok: false, error: { code: "FORBIDDEN", details: { reason: "override_forbidden" } } });
  173 |   await expect(columnOf(byStaff, monaId).locator(EVENT)).toHaveCount(0);
  174 | 
  175 |   await dropSession(page);
  176 |   await signInTo(page, s, MANAGER);
  177 |   byStaff = await openDay(page, s, day, [monaId]);
  178 |   await page.getByRole("button", { name: s.newAppointment, exact: true }).click();
  179 |   drawer = page.getByRole("dialog", { name: s.newAppointment });
  180 |   await fillBooking(drawer, s, booking);
  181 |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  182 |   const confirm = page.getByRole("alertdialog", { name: s.bookOutsideRules });
  183 |   await expect(confirm).toContainText(s.outsideShift);
  184 |   const reason = "Her only free hour this week";
  185 |   await confirm.getByRole("textbox", { name: s.reason }).fill(reason);
  186 |   await confirm.getByRole("button", { name: s.bookAnyway }).click();
  187 | 
  188 |   const booked = page.getByText(s.appointmentBooked);
  189 |   await expect(booked).toBeVisible();
  190 |   const ref = (await booked.textContent())?.match(/HWL-A\d+/)?.[0];
  191 |   expect(ref).toBeTruthy();
  192 |   await expect(timeOf(columnOf(byStaff, monaId).locator(EVENT))).toHaveText(hours("18:00", "19:00"));
  193 |   expect(await overridesOf(request, ref ?? "")).toEqual([{ rule: "outside_shift", action: "book", reason, created_by: MANAGER_USER_ID }]);
  194 | });
  195 | 
  196 | test("a walk-in gets its client afterwards; a blocked client is refused with the reason shown", async ({ page, request, s, appLocale }) => {
  197 |   const id = unique(appLocale);
  198 |   const day = addDays(kuwaitToday(), 1);
  199 |   const { serviceId, monaId } = await facialWithMona(request, id, day);
  200 |   await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  201 |   await createClient(request, { firstName: "Noura", lastName: id, firstNameAlt: "نورة", lastNameAlt: id, blockedReason: "Unpaid" });
  202 |   await book(request, RECEPTION, {
  203 |     branchId: SETUP_BRANCH.hawally,
  204 |     clientId: null,
  205 |     items: [{ service_id: serviceId, staff_id: monaId, starts_at: kuwait(day, "15:00") }],
  206 |   });
  207 | 
  208 |   await signInTo(page, s, RECEPTION);
  209 |   const column = columnOf(await openDay(page, s, day, [monaId]), monaId);
  210 |   await column.locator(EVENT).filter({ hasText: s.walkIn }).click();
  211 |   const drawer = page.getByRole("dialog", { name: s.walkIn });
  212 |   await expect(drawer).toContainText(s.walkInNoRecord);
  213 |   await drawer.getByRole("button", { name: s.attachAClient }).click();
  214 | 
  215 |   const dialog = page.getByRole("dialog", { name: s.attachAClient });
  216 |   // Result buttons carry both names, so the Latin one matches in either language.
  217 |   await dialog.getByLabel(s.findClient).fill(`Noura ${id}`);
  218 |   await dialog.getByRole("button", { name: new RegExp(`Noura ${id}`) }).click();
  219 |   await dialog.getByRole("button", { name: s.attachClient }).click();
  220 |   await expect(dialog.getByRole("alert").filter({ hasText: s.clientBlockedFromBooking })).toBeVisible();
  221 | 
  222 |   await dialog.getByRole("button", { name: s.changeClient }).click();
  223 |   await dialog.getByLabel(s.findClient).fill(`Sara ${id}`);
  224 |   await dialog.getByRole("button", { name: new RegExp(`Sara ${id}`) }).click();
  225 |   await dialog.getByRole("button", { name: s.attachClient }).click();
  226 |   await expect(page.getByText(s.clientAttached)).toBeVisible();
  227 |   await expect(dialog).toBeHidden();
  228 | 
  229 |   const sara = named(appLocale, "Sara", "سارة", id);
```