# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: calendar-reschedule.spec.ts >> a drag onto a taken time rolls back with a conflict, a suggested time moves it, and Undo puts it back
- Location: e2e/calendar-reschedule.spec.ts:82:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('Sara en-muxpdmxkr5d moved to')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" getByText('Sara en-muxpdmxkr5d moved to') with timeout 5000ms
  - waiting for getByText('Sara en-muxpdmxkr5d moved to')

```

```yaml
- link "Skip to main content":
  - /url: "#main"
- complementary:
  - navigation "Main":
    - list:
      - listitem:
        - link "Home":
          - /url: /?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "My day":
          - /url: /my-day?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "Calendar":
          - /url: /calendar?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "Clients":
          - /url: /clients?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "Team":
          - /url: /team?branch=00000000-0000-4000-a000-000000000004
      - listitem:
        - link "Catalogue":
          - /url: /catalogue?branch=00000000-0000-4000-a000-000000000004
      - listitem: Sales
      - listitem: Reports
- banner:
  - paragraph: Setup Studio
  - text: Receptionist
  - group "Branch (locked)":
    - paragraph: Hawally
  - button "Search clients and appointments": Search Ctrl K
  - button "العربية"
  - button "Reem Hawally"
- main:
  - heading "Calendar" [level=1]
  - button "New appointment"
  - radiogroup "Calendar view":
    - radio "Day" [checked]
    - radio "Week"
  - button "Previous day"
  - button "Today"
  - button "Next day"
  - heading "Thursday, October 8" [level=2]
  - button "2 team members"
  - text: Service category
  - combobox "Service category":
    - option "All categories" [selected]
    - option "Massage muxpc9mvqulc"
    - option "Concurrency muxpc46l2h01"
    - option "Bookings muxpbxfm617y"
    - option "Bookings muxpbv9jv9dz"
    - option "Block fixtures muxpao3qpqjw"
    - option "Concurrency muxpan7hp4g5"
    - option "Block fixtures muxpcfe6xb3e"
    - option "Booking fixtures"
  - text: Go to date
  - textbox "Go to date": 2026-10-08
  - button "Skip to appointments"
  - region "Appointments by staff":
    - button "New appointment with Mona en-muxpdmxkr5d": Mona en-muxpdmxkr5d
    - button "New appointment with Noor en-muxpdmxkr5d": Noor en-muxpdmxkr5d
    - button "Sara en-muxpdmxkr5d 14:00 – 15:00 Facial en-muxpdmxkr5d"
    - button "Lina en-muxpdmxkr5d 15:00 – 16:00 Facial en-muxpdmxkr5d"
  - status
- status
- alert
```

# Test source

```ts
  11  | // the Move dialog for another branch. Every run books its own visits.
  12  | 
  13  | const EVENT = "[data-event-id]:not([id^='time-grid-event-copy-'])";
  14  | // BookingCalendar draws 24px per slot; Hawally keeps the default 15-minute step.
  15  | const PX_PER_MINUTE = 24 / 15;
  16  | 
  17  | type Request = Parameters<typeof createService>[0];
  18  | 
  19  | async function twoBooked(request: Request, id: string, day: string) {
  20  |   const serviceId = await createService(request, { en: `Facial ${id}`, ar: `تنظيف بشرة ${id}` }, { duration: 60 });
  21  |   const shifts = [{ day, starts: "09:00", ends: "22:00" }];
  22  |   const monaId = await createStaff(request, {
  23  |     name: { en: `Mona ${id}`, ar: `منى ${id}` },
  24  |     branchId: SETUP_BRANCH.hawally,
  25  |     serviceIds: [serviceId],
  26  |     shifts,
  27  |   });
  28  |   const noorId = await createStaff(request, {
  29  |     name: { en: `Noor ${id}`, ar: `نور ${id}` },
  30  |     branchId: SETUP_BRANCH.hawally,
  31  |     serviceIds: [serviceId],
  32  |     shifts,
  33  |   });
  34  |   const saraId = await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  35  |   const linaId = await createClient(request, { firstName: "Lina", lastName: id, firstNameAlt: "لينا", lastNameAlt: id });
  36  |   for (const [clientId, staffId] of [
  37  |     [saraId, monaId],
  38  |     [linaId, noorId],
  39  |   ] as const) {
  40  |     await book(request, "setup-reception@spacorner.test", {
  41  |       branchId: SETUP_BRANCH.hawally,
  42  |       clientId,
  43  |       items: [{ service_id: serviceId, staff_id: staffId, starts_at: kuwait(day, "15:00") }],
  44  |     });
  45  |   }
  46  |   return { monaId, noorId };
  47  | }
  48  | 
  49  | async function openDay(page: Page, s: Strings, day: string, staff: string[]) {
  50  |   await page.goto("/login");
  51  |   await signIn(page, s, "setup-reception@spacorner.test");
  52  |   await expect(page).toHaveURL(/\?branch=/);
  53  |   await page.goto(`/calendar?branch=${SETUP_BRANCH.hawally}&date=${day}&staff=${encodeURIComponent(JSON.stringify(staff))}`);
  54  |   return page.getByRole("region", { name: s.appointmentsByStaff });
  55  | }
  56  | 
  57  | // The card's own times, not its pixel offset: other runs' shifts at Hawally can widen the
  58  | // grid's hours at any refetch (realtime included), which moves every card down.
  59  | const timeOf = (event: Locator) => event.locator(".gd-event-time");
  60  | const hours = (start: string, end: string) => new RegExp(`${start}\\s*–\\s*${end}`);
  61  | 
  62  | async function box(locator: Locator) {
  63  |   const found = await locator.boundingBox();
  64  |   if (!found) throw new Error("not on screen");
  65  |   return found;
  66  | }
  67  | 
  68  | /** Drags `event` into `column`, `minutes` later than it started, from on-screen boxes (mirrored in RTL). */
  69  | async function drag(page: Page, event: Locator, column: Locator, minutes: number) {
  70  |   await event.scrollIntoViewIfNeeded();
  71  |   const from = await box(event);
  72  |   const to = await box(column);
  73  |   const startX = from.x + from.width / 2;
  74  |   const startY = from.y + Math.min(12, from.height / 2);
  75  |   await page.mouse.move(startX, startY);
  76  |   await page.mouse.down();
  77  |   await page.waitForTimeout(250);
  78  |   await page.mouse.move(to.x + to.width / 2, startY + minutes * PX_PER_MINUTE, { steps: 20 });
  79  |   await page.mouse.up();
  80  | }
  81  | 
  82  | test("a drag onto a taken time rolls back with a conflict, a suggested time moves it, and Undo puts it back", async ({
  83  |   page,
  84  |   request,
  85  |   s,
  86  |   appLocale,
  87  | }) => {
  88  |   const id = unique(appLocale);
  89  |   const day = addDays(kuwaitToday(), 1);
  90  |   const sara = appLocale === "ar" ? `سارة ${id}` : `Sara ${id}`;
  91  |   const { monaId, noorId } = await twoBooked(request, id, day);
  92  | 
  93  |   const byStaff = await openDay(page, s, day, [monaId, noorId]);
  94  |   const column = (staffId: string) => byStaff.locator(`.gd-resource-column[data-resource-id="${staffId}"]`);
  95  |   const saraWith = (staffId: string) => column(staffId).locator(EVENT).filter({ hasText: sara });
  96  |   await expect(saraWith(monaId)).toBeVisible();
  97  | 
  98  |   // Noor's column follows Mona's in reading order: to the left in Arabic.
  99  |   const [monaBox, noorBox] = [await box(column(monaId)), await box(column(noorId))];
  100 |   expect(appLocale === "ar" ? noorBox.x < monaBox.x : noorBox.x > monaBox.x).toBe(true);
  101 | 
  102 |   // Noor is busy at 15:00: the move is refused and Sara goes back to Mona.
  103 |   await drag(page, saraWith(monaId), column(noorId), 0);
  104 |   const toast = page.getByRole("alert").filter({ hasText: s.couldNotMove(sara) });
  105 |   await expect(toast).toBeVisible();
  106 |   await expect(saraWith(monaId)).toBeVisible();
  107 |   await expect(saraWith(noorId)).toHaveCount(0);
  108 | 
  109 |   // One of the free times nearby moves her there.
  110 |   await toast.getByRole("listitem").first().getByRole("button").click();
> 111 |   await expect(page.getByText(s.movedTo(sara))).toBeVisible();
      |                                                 ^ Error: expect(locator).toBeVisible() failed
  112 |   await expect(saraWith(noorId)).toBeVisible();
  113 | 
  114 |   await page.getByRole("button", { name: s.undo, exact: true }).click();
  115 |   await expect(page.getByText(s.moveUndone)).toBeVisible();
  116 |   await expect(saraWith(monaId)).toBeVisible();
  117 |   await expect(saraWith(noorId)).toHaveCount(0);
  118 | 
  119 |   // An hour later with Mona is free.
  120 |   await drag(page, saraWith(monaId), column(monaId), 60);
  121 |   await expect(page.getByText(s.movedTo(sara))).toBeVisible();
  122 |   await expect(timeOf(saraWith(monaId))).toHaveText(hours("16:00", "17:00"));
  123 | });
  124 | 
  125 | test("the keyboard reaches appointments through the skip link, moves between columns and moves a visit with Alt+arrows", async ({
  126 |   page,
  127 |   request,
  128 |   s,
  129 |   appLocale,
  130 | }) => {
  131 |   const id = unique(appLocale);
  132 |   const day = addDays(kuwaitToday(), 1);
  133 |   const sara = appLocale === "ar" ? `سارة ${id}` : `Sara ${id}`;
  134 |   const lina = appLocale === "ar" ? `لينا ${id}` : `Lina ${id}`;
  135 |   const { monaId, noorId } = await twoBooked(request, id, day);
  136 | 
  137 |   const byStaff = await openDay(page, s, day, [monaId, noorId]);
  138 |   const saraEvent = byStaff.locator(`.gd-resource-column[data-resource-id="${monaId}"] ${EVENT}`).filter({ hasText: sara });
  139 |   const linaEvent = byStaff.locator(`.gd-resource-column[data-resource-id="${noorId}"] ${EVENT}`).filter({ hasText: lina });
  140 |   await expect(linaEvent).toBeVisible();
  141 | 
  142 |   const skip = page.getByRole("button", { name: s.skipToAppointments });
  143 |   await skip.focus();
  144 |   await expect(skip).toBeVisible();
  145 |   await page.keyboard.press("Enter");
  146 |   await expect(saraEvent).toBeFocused();
  147 |   // One tab stop for the whole grid.
  148 |   await expect(byStaff.locator(`${EVENT}[tabindex="0"]`)).toHaveCount(1);
  149 | 
  150 |   // The next column is to the right in English and to the left in Arabic.
  151 |   await page.keyboard.press(appLocale === "ar" ? "ArrowLeft" : "ArrowRight");
  152 |   await expect(linaEvent).toBeFocused();
  153 | 
  154 |   await expect(timeOf(linaEvent)).toHaveText(hours("15:00", "16:00"));
  155 |   for (let step = 0; step < 4; step += 1) await page.keyboard.press("Alt+ArrowDown");
  156 |   await expect(timeOf(linaEvent)).toHaveText(hours("16:00", "17:00"));
  157 |   // Four quick moves are announced once.
  158 |   await expect(page.getByRole("status").filter({ hasText: s.movedTo(lina) })).toHaveCount(1);
  159 | 
  160 |   // Undo returns the visit to where the burst started.
  161 |   await page.getByRole("button", { name: s.undo, exact: true }).click();
  162 |   await expect(page.getByText(s.moveUndone)).toBeVisible();
  163 |   await expect(timeOf(linaEvent)).toHaveText(hours("15:00", "16:00"));
  164 | });
  165 | 
  166 | test("an owner moves an appointment to another branch: a new reference and that branch's price", async ({ page, request, s, appLocale }) => {
  167 |   const id = unique(appLocale);
  168 |   const day = addDays(kuwaitToday(), 1);
  169 |   const serviceId = await createService(request, { en: `Facial ${id}`, ar: `تنظيف بشرة ${id}` }, { duration: 60, price: 25_000 });
  170 |   const staffId = await createStaff(request, {
  171 |     name: { en: `Mona ${id}`, ar: `منى ${id}` },
  172 |     branchId: SETUP_BRANCH.hawally,
  173 |     serviceIds: [serviceId],
  174 |     shifts: [{ day, starts: "09:00", ends: "14:00" }],
  175 |   });
  176 |   // Mornings at Hawally, afternoons at Jahra: one person's shifts never overlap.
  177 |   await assignToBranch(request, staffId, { branchId: SETUP_BRANCH.jahra, serviceIds: [serviceId], shifts: [{ day, starts: "14:00", ends: "22:00" }] });
  178 |   await setBranchPrice(request, serviceId, SETUP_BRANCH.jahra, 30_000);
  179 |   const clientId = await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  180 |   const ref = await book(request, "setup-reception@spacorner.test", {
  181 |     branchId: SETUP_BRANCH.hawally,
  182 |     clientId,
  183 |     items: [{ service_id: serviceId, staff_id: staffId, starts_at: kuwait(day, "10:00") }],
  184 |   });
  185 |   expect(ref).toMatch(/^HWL-/);
  186 | 
  187 |   await page.goto("/login");
  188 |   await signIn(page, s, "setup-owner@spacorner.test");
  189 |   await expect(page).toHaveURL(/\?branch=/);
  190 |   await page.goto(`/calendar?branch=${SETUP_BRANCH.hawally}&date=${day}`);
  191 |   await page.getByRole("region", { name: s.appointmentsByStaff }).locator(EVENT).filter({ hasText: id }).click();
  192 |   const drawer = page.getByRole("dialog", { name: new RegExp(id) });
  193 |   await drawer.getByRole("button", { name: s.move, exact: true }).click();
  194 | 
  195 |   const dialog = page.getByRole("dialog", { name: s.moveAppointment });
  196 |   await dialog.getByRole("combobox", { name: s.branch }).selectOption(SETUP_BRANCH.jahra);
  197 |   await expect(dialog.getByRole("combobox", { name: s.teamMember })).toHaveValue(staffId);
  198 |   await dialog.getByRole("radio", { name: "16:00", exact: true }).check();
  199 |   await dialog.getByRole("button", { name: s.moveAppointment }).click();
  200 | 
  201 |   const moved = page.getByRole("dialog", { name: s.appointmentMoved });
  202 |   await expect(moved).toBeVisible();
  203 |   await expect(moved).toContainText(/JHR-A\d+/);
  204 |   await expect(moved).toContainText("30.000");
  205 | });
  206 | 
```