# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: calendar-appointment.spec.ts >> the front desk confirms an appointment, then cancels it with a reason and the time frees up
- Location: e2e/calendar-appointment.spec.ts:42:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('Status changed to Confirmed.')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" getByText('Status changed to Confirmed.') with timeout 5000ms
  - waiting for getByText('Status changed to Confirmed.')

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
  - button "All team members"
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
    - button "New appointment with Block appointment muxpao3qpqjw": Block appointment muxpao3qpqjw
    - button "New appointment with Block appointment muxpcfe6xb3e": Block appointment muxpcfe6xb3e
    - button "New appointment with Block burst muxpao3qpqjw": Block burst muxpao3qpqjw
    - button "New appointment with Block burst muxpcfe6xb3e": Block burst muxpcfe6xb3e
    - button "New appointment with Block en-muxpdmxk3zs": Block en-muxpdmxk3zs
    - button "New appointment with Block race muxpao3qpqjw": Block race muxpao3qpqjw
    - button "New appointment with Block race muxpcfe6xb3e": Block race muxpcfe6xb3e
    - button "New appointment with Block schedule muxpao3qpqjw": Block schedule muxpao3qpqjw
    - button "New appointment with Block schedule muxpcfe6xb3e": Block schedule muxpcfe6xb3e
    - button "New appointment with cancel muxpbv9jv9dz": cancel muxpbv9jv9dz
    - button "New appointment with clients muxpbv9jv9dz": clients muxpbv9jv9dz
    - button "New appointment with conflicts muxpbv9jv9dz": conflicts muxpbv9jv9dz
    - button "New appointment with create muxpbv9jv9dz": create muxpbv9jv9dz
    - button "New appointment with cross muxpbv9jv9dz": cross muxpbv9jv9dz
    - button "New appointment with cross-conflict muxpbv9jv9dz": cross-conflict muxpbv9jv9dz
    - button "New appointment with keys muxpbv9jv9dz": keys muxpbv9jv9dz
    - button "New appointment with Mona en-muxpdmxkhhd": Mona en-muxpdmxkhhd
    - button "New appointment with Mona en-muxpdmxki3o": Mona en-muxpdmxki3o
    - button "New appointment with Mona en-muxpdmxkmmf": Mona en-muxpdmxkmmf
    - button "New appointment with Mona en-muxpdmxkq2p": Mona en-muxpdmxkq2p
    - button "New appointment with Mona en-muxpdmxkr5d": Mona en-muxpdmxkr5d
    - button "New appointment with Mona en-muxpdmxksym": Mona en-muxpdmxksym
    - button "New appointment with Mona en-muxpdmxlvcp": Mona en-muxpdmxlvcp
    - button "New appointment with no-show muxpbv9jv9dz": no-show muxpbv9jv9dz
    - button "New appointment with Noor en-muxpdmxkr5d": Noor en-muxpdmxkr5d
    - button "New appointment with not-eligible muxpbv9jv9dz": not-eligible muxpbv9jv9dz
    - button "New appointment with notes muxpbv9jv9dz": notes muxpbv9jv9dz
    - button "New appointment with Noura en-muxpdmxiv9d": Noura en-muxpdmxiv9d
    - button "New appointment with override muxpbv9jv9dz": override muxpbv9jv9dz
    - button "New appointment with Race book-vs-block muxpan7hp4g5": Race book-vs-block muxpan7hp4g5
    - button "New appointment with Race book-vs-block muxpc46l2h01": Race book-vs-block muxpc46l2h01
    - button "New appointment with Race cancel-then-book muxpan7hp4g5": Race cancel-then-book muxpan7hp4g5
    - button "New appointment with Race cancel-then-book muxpc46l2h01": Race cancel-then-book muxpc46l2h01
    - button "New appointment with Race cancel-vs-resched muxpan7hp4g5": Race cancel-vs-resched muxpan7hp4g5
    - button "New appointment with Race cancel-vs-resched muxpc46l2h01": Race cancel-vs-resched muxpc46l2h01
    - button "New appointment with Race lock-x muxpan7hp4g5": Race lock-x muxpan7hp4g5
    - button "New appointment with Race lock-x muxpc46l2h01": Race lock-x muxpc46l2h01
    - button "New appointment with Race lock-y muxpan7hp4g5": Race lock-y muxpan7hp4g5
    - button "New appointment with Race lock-y muxpc46l2h01": Race lock-y muxpc46l2h01
    - button "New appointment with race muxpbv9jv9dz": race muxpbv9jv9dz
    - button "New appointment with Race ref-0 muxpan7hp4g5": Race ref-0 muxpan7hp4g5
    - button "New appointment with Race ref-0 muxpc46l2h01": Race ref-0 muxpc46l2h01
    - button "New appointment with Race ref-1 muxpan7hp4g5": Race ref-1 muxpan7hp4g5
    - button "New appointment with Race ref-1 muxpc46l2h01": Race ref-1 muxpc46l2h01
    - button "New appointment with Race ref-2 muxpan7hp4g5": Race ref-2 muxpan7hp4g5
    - button "New appointment with Race ref-2 muxpc46l2h01": Race ref-2 muxpc46l2h01
    - button "New appointment with Race ref-3 muxpan7hp4g5": Race ref-3 muxpan7hp4g5
    - button "New appointment with Race ref-3 muxpc46l2h01": Race ref-3 muxpc46l2h01
    - button "New appointment with Race ref-4 muxpan7hp4g5": Race ref-4 muxpan7hp4g5
    - button "New appointment with Race ref-4 muxpc46l2h01": Race ref-4 muxpc46l2h01
    - button "New appointment with Race resched-vs-book muxpan7hp4g5": Race resched-vs-book muxpan7hp4g5
    - button "New appointment with Race resched-vs-book muxpc46l2h01": Race resched-vs-book muxpc46l2h01
    - button "New appointment with Race resched-vs-resched muxpan7hp4g5": Race resched-vs-resched muxpan7hp4g5
    - button "New appointment with Race resched-vs-resched muxpc46l2h01": Race resched-vs-resched muxpc46l2h01
    - button "New appointment with Race same-slot-2 muxpan7hp4g5": Race same-slot-2 muxpan7hp4g5
    - button "New appointment with Race same-slot-2 muxpc46l2h01": Race same-slot-2 muxpc46l2h01
    - button "New appointment with Race same-slot-6 muxpan7hp4g5": Race same-slot-6 muxpan7hp4g5
    - button "New appointment with Race same-slot-6 muxpc46l2h01": Race same-slot-6 muxpc46l2h01
    - button "New appointment with Rana en-muxpdmxkhhd": Rana en-muxpdmxkhhd
    - button "New appointment with Rana en-muxpdmxki3o": Rana en-muxpdmxki3o
    - button "New appointment with reception-override muxpbv9jv9dz": reception-override muxpbv9jv9dz
    - button "New appointment with replay muxpbv9jv9dz": replay muxpbv9jv9dz
    - button "New appointment with reschedule-refusals muxpbv9jv9dz": reschedule-refusals muxpbv9jv9dz
    - button "New appointment with rt-colleague muxpbxfm617y": rt-colleague muxpbxfm617y
    - button "New appointment with rt-mover muxpbxfm617y": rt-mover muxpbxfm617y
    - button "New appointment with rt-own muxpbxfm617y": rt-own muxpbxfm617y
    - button "New appointment with scope muxpbv9jv9dz": scope muxpbv9jv9dz
    - button "New appointment with services muxpbv9jv9dz": services muxpbv9jv9dz
    - button "New appointment with Shift kuwait muxpcfmxbko7": Shift kuwait muxpcfmxbko7
    - button "New appointment with Shift replace muxpcfmxbko7": Shift replace muxpcfmxbko7
    - button "New appointment with Staff compensate muxpcg5hx7qy": Staff compensate muxpcg5hx7qy
    - button "New appointment with Staff existing muxpcg5hx7qy": Staff existing muxpcg5hx7qy
    - button "New appointment with Staff login muxpcg5hx7qy": Staff login muxpcg5hx7qy
    - button "New appointment with Staff mgr-login muxpcg5hx7qy": Staff mgr-login muxpcg5hx7qy
    - button "New appointment with Staff mgr-own muxpcg5hx7qy": Staff mgr-own muxpcg5hx7qy
    - button "New appointment with Staff no-email muxpcg5hx7qy": Staff no-email muxpcg5hx7qy
    - button "New appointment with Staff twin muxpcg5hx7qy": Staff twin muxpcg5hx7qy
    - button "New appointment with status muxpbv9jv9dz": status muxpbv9jv9dz
    - button "New appointment with Therapist a muxpc9mvqulc": Therapist a muxpc9mvqulc
    - button "New appointment with Therapist b muxpc9mvqulc": Therapist b muxpc9mvqulc
    - button "New appointment with Therapist c muxpc9mvqulc": Therapist c muxpc9mvqulc
    - button "New appointment with Therapist d muxpc9mvqulc": Therapist d muxpc9mvqulc
    - button "New appointment with Therapist e muxpc9mvqulc": Therapist e muxpc9mvqulc
    - button "New appointment with Therapist hawally-only muxpc9mvqulc": Therapist hawally-only muxpc9mvqulc
    - button "New appointment with walk-in muxpbv9jv9dz": walk-in muxpbv9jv9dz
    - button "Sara en-muxpdmxkhhd 15:00 – 16:00 Facial en-muxpdmxkhhd"
    - button "Sara en-muxpdmxki3o 15:00 – 16:00 Facial en-muxpdmxki3o"
    - button "Noura en-muxpdmxkmmf 10:00 – 11:00 Facial en-muxpdmxkmmf"
    - button "Sara en-muxpdmxkq2p 10:00 – 11:00 Facial en-muxpdmxkq2p"
    - button "Sara en-muxpdmxkq2p 12:00 – 13:00 Facial en-muxpdmxkq2p"
    - button "Sara en-muxpdmxkr5d 15:00 – 16:00 Facial en-muxpdmxkr5d"
    - button "Lina en-muxpdmxksym 15:00 – 16:00 Facial en-muxpdmxksym"
    - button "Sara en-muxpdmxksym 17:00 – 18:00 Facial en-muxpdmxksym"
    - button "Sara en-muxpdmxlvcp 15:00 – 16:00 Facial en-muxpdmxlvcp"
    - button "Lina en-muxpdmxkr5d 15:00 – 16:00 Facial en-muxpdmxkr5d"
    - button "Huda en-muxpdmxkhhd 15:00 – 16:00 Facial en-muxpdmxkhhd"
    - button "Sara en-muxpdmxki3o 16:00 – 17:30 Massage en-muxpdmxki3o"
  - status
  - dialog "Sara en-muxpdmxlvcp":
    - heading "Sara en-muxpdmxlvcp" [level=2]
    - paragraph: Reference HWL-A103
    - button "Close"
    - text: Booked
    - paragraph: Thursday, October 8 · 15:00 – 16:00
    - button "Move"
    - region "Client":
      - heading "Client" [level=3]
      - link "Sara en-muxpdmxlvcp":
        - /url: /clients/006b881c-713d-4b20-bb70-6e3dc459b0ab?branch=00000000-0000-4000-a000-000000000004
      - text: سارة en-muxpdmxlvcp
    - region "Services":
      - heading "Services" [level=3]
      - list:
        - listitem: Facial en-muxpdmxlvcp with Mona en-muxpdmxlvcp · 15:00 – 16:00 · 60 min KWD 25.000
      - paragraph: Total (60 min)
      - text: KWD 25.000
    - region "Status":
      - heading "Status" [level=3]
      - button "Confirm" [disabled]
      - button "Check in" [disabled]
      - button "No-show" [disabled]
      - button "Cancel appointment" [disabled]
    - text: Appointment note
    - textbox "Appointment note"
    - text: Visible to the front desk.
    - button "Save note" [disabled]
    - button "Close"
    - button "Checkout (Phase 6)" [disabled]
- status
- alert
```

# Test source

```ts
  1   | import type { Page } from "@playwright/test";
  2   | import { addDays } from "./blockedTimeFlows";
  3   | import { book, createClient, createService, createStaff, kuwait } from "./bookingFixtures";
  4   | import { expect, signIn, test } from "./fixtures";
  5   | import { unique } from "./memberFlows";
  6   | import { kuwaitToday } from "./shiftFlows";
  7   | import { SETUP_BRANCH } from "./staffFlows";
  8   | import type { Strings } from "./strings";
  9   | 
  10  | // The appointment drawer at Setup Studio Hawally: each run books a fresh
  11  | // appointment through the bookings function, then works it from the calendar.
  12  | 
  13  | async function bookOne(request: Parameters<typeof createService>[0], id: string, day: string) {
  14  |   const serviceId = await createService(request, { en: `Facial ${id}`, ar: `تنظيف بشرة ${id}` }, { duration: 60, price: 25_000 });
  15  |   const staffId = await createStaff(request, {
  16  |     name: { en: `Mona ${id}`, ar: `منى ${id}` },
  17  |     branchId: SETUP_BRANCH.hawally,
  18  |     serviceIds: [serviceId],
  19  |     shifts: [{ day, starts: "09:00", ends: "22:00" }],
  20  |   });
  21  |   const clientId = await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id });
  22  |   await book(request, "setup-reception@spacorner.test", {
  23  |     branchId: SETUP_BRANCH.hawally,
  24  |     clientId,
  25  |     items: [{ service_id: serviceId, staff_id: staffId, starts_at: kuwait(day, "15:00") }],
  26  |   });
  27  | }
  28  | 
  29  | async function openAppointment(page: Page, s: Strings, email: string, id: string, day: string) {
  30  |   await page.goto("/login");
  31  |   await signIn(page, s, email);
  32  |   await expect(page).toHaveURL(/\?branch=/);
  33  |   await page.goto(`/calendar?branch=${SETUP_BRANCH.hawally}&date=${day}`);
  34  |   const byStaff = page.getByRole("region", { name: s.appointmentsByStaff });
  35  |   await byStaff.locator("[data-event-id]:not([id^='time-grid-event-copy-'])").filter({ hasText: id }).click();
  36  |   return page.getByRole("dialog", { name: new RegExp(id) });
  37  | }
  38  | 
  39  | const events = (page: Page, s: Strings, id: string) =>
  40  |   page.getByRole("region", { name: s.appointmentsByStaff }).locator("[data-event-id]").filter({ hasText: id });
  41  | 
  42  | test("the front desk confirms an appointment, then cancels it with a reason and the time frees up", async ({ page, request, s, appLocale }) => {
  43  |   const id = unique(appLocale);
  44  |   const day = addDays(kuwaitToday(), 1);
  45  |   await bookOne(request, id, day);
  46  | 
  47  |   const drawer = await openAppointment(page, s, "setup-reception@spacorner.test", id, day);
  48  |   await expect(drawer).toContainText("25.000");
  49  |   await drawer.getByRole("button", { name: s.confirm, exact: true }).click();
> 50  |   await expect(page.getByText(s.statusChangedTo(s.confirmed))).toBeVisible();
      |                                                                ^ Error: expect(locator).toBeVisible() failed
  51  |   await expect(drawer.getByText(s.confirmed, { exact: true })).toBeVisible();
  52  | 
  53  |   await drawer.getByRole("button", { name: s.cancelAppointment }).click();
  54  |   const dialog = page.getByRole("dialog", { name: s.cancelThisAppointment });
  55  |   // Escape closes only the dialog on top; the drawer stays.
  56  |   await expect(dialog).toBeVisible();
  57  |   await page.keyboard.press("Escape");
  58  |   await expect(dialog).toBeHidden();
  59  |   await expect(drawer).toBeVisible();
  60  |   await drawer.getByRole("button", { name: s.cancelAppointment }).click();
  61  |   // The reason is required: submitting without one says so.
  62  |   await dialog.getByRole("button", { name: s.cancelAppointment }).click();
  63  |   await expect(dialog.getByRole("alert")).toBeVisible();
  64  |   await dialog.getByRole("combobox", { name: s.reason }).selectOption({ label: s.clientUnwell });
  65  |   await dialog.getByRole("button", { name: s.cancelAppointment }).click();
  66  | 
  67  |   await expect(page.getByText(s.appointmentCancelled)).toBeVisible();
  68  |   await expect(dialog).toBeHidden();
  69  |   await expect(drawer).toContainText(s.cancelledBecause(s.clientUnwell));
  70  |   await expect(events(page, s, id)).toHaveCount(0);
  71  | });
  72  | 
  73  | test("a no-show is recorded by the front desk and reopened by a manager with a reason", async ({ page, request, s, appLocale }) => {
  74  |   const id = unique(appLocale);
  75  |   const day = addDays(kuwaitToday(), 1);
  76  |   await bookOne(request, id, day);
  77  | 
  78  |   const drawer = await openAppointment(page, s, "setup-reception@spacorner.test", id, day);
  79  |   await drawer.getByRole("button", { name: s.noShow, exact: true }).click();
  80  |   await page.getByRole("alertdialog").getByRole("button", { name: s.markNoShow }).click();
  81  |   await expect(page.getByText(s.statusChangedTo(s.noShow))).toBeVisible();
  82  |   // The receptionist can't reopen it (5.1 ruling: backward moves are for managers).
  83  |   await expect(drawer.getByRole("button", { name: s.reopen })).toHaveCount(0);
  84  |   await expect(events(page, s, id)).toHaveCount(1);
  85  |   await page.keyboard.press("Escape");
  86  |   await expect(drawer).toBeHidden();
  87  |   // Drop this tab's session only: signing out revokes the receptionist's sessions in parallel workers too.
  88  |   await page.evaluate(() => {
  89  |     for (const key of Object.keys(window.localStorage)) if (key.startsWith("sb-")) window.localStorage.removeItem(key);
  90  |   });
  91  | 
  92  |   const managerDrawer = await openAppointment(page, s, "setup-manager@spacorner.test", id, day);
  93  |   await managerDrawer.getByRole("button", { name: s.reopen }).click();
  94  |   const dialog = page.getByRole("dialog", { name: new RegExp(s.reopen) });
  95  |   // A reason is required for a backward move.
  96  |   await dialog.getByRole("button", { name: s.reopen, exact: true }).click();
  97  |   const reason = dialog.getByRole("textbox", { name: s.reason });
  98  |   await expect(reason).toHaveAttribute("aria-invalid", "true");
  99  |   await reason.fill("Arrived late, still served");
  100 |   await dialog.getByRole("button", { name: s.reopen, exact: true }).click();
  101 |   await expect(page.getByText(s.statusChangedTo(s.booked))).toBeVisible();
  102 |   await expect(managerDrawer.getByText(s.booked, { exact: true })).toBeVisible();
  103 | });
  104 | 
```