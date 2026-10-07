# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: calendar-booking.spec.ts >> the front desk books a walk-in with anyone available
- Location: e2e/calendar-booking.spec.ts:64:1

# Error details

```
Error: expect(locator).toBeChecked() failed

Locator: getByRole('dialog', { name: 'موعد جديد' }).getByRole('region', { name: 'الخدمة', exact: true }).getByRole('radio', { name: '17:00', exact: true })
Expected: checked
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeChecked" getByRole('dialog', { name: 'موعد جديد' }).getByRole('region', { name: 'الخدمة', exact: true }).getByRole('radio', { name: '17:00', exact: true }) with timeout 5000ms
  - waiting for getByRole('dialog', { name: 'موعد جديد' }).getByRole('region', { name: 'الخدمة', exact: true }).getByRole('radio', { name: '17:00', exact: true })

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
  - button "كل أعضاء الفريق"
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
    - button "موعد جديد مع Block appointment muxpao3qpqjw": Block appointment muxpao3qpqjw
    - button "موعد جديد مع Block appointment muxpcfe6xb3e": Block appointment muxpcfe6xb3e
    - button "موعد جديد مع حجب ar-muxpeffg0u3": حجب ar-muxpeffg0u3
    - button "موعد جديد مع Block burst muxpao3qpqjw": Block burst muxpao3qpqjw
    - button "موعد جديد مع Block burst muxpcfe6xb3e": Block burst muxpcfe6xb3e
    - button "موعد جديد مع حجب en-muxpdmxk3zs": حجب en-muxpdmxk3zs
    - button "موعد جديد مع Block race muxpao3qpqjw": Block race muxpao3qpqjw
    - button "موعد جديد مع Block race muxpcfe6xb3e": Block race muxpcfe6xb3e
    - button "موعد جديد مع Block schedule muxpao3qpqjw": Block schedule muxpao3qpqjw
    - button "موعد جديد مع Block schedule muxpcfe6xb3e": Block schedule muxpcfe6xb3e
    - button "موعد جديد مع كلاهما en-muxpeh8otr3": كلاهما en-muxpeh8otr3
    - button "موعد جديد مع cancel muxpbv9jv9dz": cancel muxpbv9jv9dz
    - button "موعد جديد مع clients muxpbv9jv9dz": clients muxpbv9jv9dz
    - button "موعد جديد مع conflicts muxpbv9jv9dz": conflicts muxpbv9jv9dz
    - button "موعد جديد مع create muxpbv9jv9dz": create muxpbv9jv9dz
    - button "موعد جديد مع cross muxpbv9jv9dz": cross muxpbv9jv9dz
    - button "موعد جديد مع cross-conflict muxpbv9jv9dz": cross-conflict muxpbv9jv9dz
    - button "موعد جديد مع keys muxpbv9jv9dz": keys muxpbv9jv9dz
    - button "موعد جديد مع لينا en-muxpeeglvyt": لينا en-muxpeeglvyt
    - button "موعد جديد مع منى ar-muxpefi2si9": منى ar-muxpefi2si9
    - button "موعد جديد مع منى ar-muxpefsyucs": منى ar-muxpefsyucs
    - button "موعد جديد مع منى ar-muxpegf0jt3": منى ar-muxpegf0jt3
    - button "موعد جديد مع منى ar-muxpegj371k": منى ar-muxpegj371k
    - button "موعد جديد مع منى ar-muxpeglagup": منى ar-muxpeglagup
    - button "موعد جديد مع منى ar-muxpei64396": منى ar-muxpei64396
    - button "موعد جديد مع منى ar-muxpeiq7bed": منى ar-muxpeiq7bed
    - button "موعد جديد مع منى ar-muxpej3dg1d": منى ar-muxpej3dg1d
    - button "موعد جديد مع منى ar-muxpej4vxts": منى ar-muxpej4vxts
    - button "موعد جديد مع منى en-muxpdmxkhhd": منى en-muxpdmxkhhd
    - button "موعد جديد مع منى en-muxpdmxki3o": منى en-muxpdmxki3o
    - button "موعد جديد مع منى en-muxpdmxkmmf": منى en-muxpdmxkmmf
    - button "موعد جديد مع منى en-muxpdmxkq2p": منى en-muxpdmxkq2p
    - button "موعد جديد مع منى en-muxpdmxkr5d": منى en-muxpdmxkr5d
    - button "موعد جديد مع منى en-muxpdmxksym": منى en-muxpdmxksym
    - button "موعد جديد مع منى en-muxpdmxlvcp": منى en-muxpdmxlvcp
    - button "موعد جديد مع منى en-muxpdplphmy": منى en-muxpdplphmy
    - button "موعد جديد مع منى en-muxpdr1njvy": منى en-muxpdr1njvy
    - button "موعد جديد مع منى en-muxpdr6qre2": منى en-muxpdr6qre2
    - button "موعد جديد مع منى en-muxpdzzvvwo": منى en-muxpdzzvvwo
    - button "موعد جديد مع منى en-muxpe0ic3ph": منى en-muxpe0ic3ph
    - button "موعد جديد مع منى en-muxpe0nc0ew": منى en-muxpe0nc0ew
    - button "موعد جديد مع منى en-muxpe8grtrp": منى en-muxpe8grtrp
    - button "موعد جديد مع منى en-muxpebawbkz": منى en-muxpebawbkz
    - button "موعد جديد مع منى en-muxpecst777": منى en-muxpecst777
    - button "موعد جديد مع no-show muxpbv9jv9dz": no-show muxpbv9jv9dz
    - button "موعد جديد مع نور ar-muxpegj371k": نور ar-muxpegj371k
    - button "موعد جديد مع نور en-muxpdmxkr5d": نور en-muxpdmxkr5d
    - button "موعد جديد مع نور en-muxpe0ic3ph": نور en-muxpe0ic3ph
    - button "موعد جديد مع نور en-muxpecst777": نور en-muxpecst777
    - button "موعد جديد مع not-eligible muxpbv9jv9dz": not-eligible muxpbv9jv9dz
    - button "موعد جديد مع notes muxpbv9jv9dz": notes muxpbv9jv9dz
    - button "موعد جديد مع نورة en-muxpdmxiv9d": نورة en-muxpdmxiv9d
    - button "موعد جديد مع override muxpbv9jv9dz": override muxpbv9jv9dz
    - button "موعد جديد مع Race book-vs-block muxpan7hp4g5": Race book-vs-block muxpan7hp4g5
    - button "موعد جديد مع Race book-vs-block muxpc46l2h01": Race book-vs-block muxpc46l2h01
    - button "موعد جديد مع Race cancel-then-book muxpan7hp4g5": Race cancel-then-book muxpan7hp4g5
    - button "موعد جديد مع Race cancel-then-book muxpc46l2h01": Race cancel-then-book muxpc46l2h01
    - button "موعد جديد مع Race cancel-vs-resched muxpan7hp4g5": Race cancel-vs-resched muxpan7hp4g5
    - button "موعد جديد مع Race cancel-vs-resched muxpc46l2h01": Race cancel-vs-resched muxpc46l2h01
    - button "موعد جديد مع Race lock-x muxpan7hp4g5": Race lock-x muxpan7hp4g5
    - button "موعد جديد مع Race lock-x muxpc46l2h01": Race lock-x muxpc46l2h01
    - button "موعد جديد مع Race lock-y muxpan7hp4g5": Race lock-y muxpan7hp4g5
    - button "موعد جديد مع Race lock-y muxpc46l2h01": Race lock-y muxpc46l2h01
    - button "موعد جديد مع race muxpbv9jv9dz": race muxpbv9jv9dz
    - button "موعد جديد مع Race ref-0 muxpan7hp4g5": Race ref-0 muxpan7hp4g5
    - button "موعد جديد مع Race ref-0 muxpc46l2h01": Race ref-0 muxpc46l2h01
    - button "موعد جديد مع Race ref-1 muxpan7hp4g5": Race ref-1 muxpan7hp4g5
    - button "موعد جديد مع Race ref-1 muxpc46l2h01": Race ref-1 muxpc46l2h01
    - button "موعد جديد مع Race ref-2 muxpan7hp4g5": Race ref-2 muxpan7hp4g5
    - button "موعد جديد مع Race ref-2 muxpc46l2h01": Race ref-2 muxpc46l2h01
    - button "موعد جديد مع Race ref-3 muxpan7hp4g5": Race ref-3 muxpan7hp4g5
    - button "موعد جديد مع Race ref-3 muxpc46l2h01": Race ref-3 muxpc46l2h01
    - button "موعد جديد مع Race ref-4 muxpan7hp4g5": Race ref-4 muxpan7hp4g5
    - button "موعد جديد مع Race ref-4 muxpc46l2h01": Race ref-4 muxpc46l2h01
    - button "موعد جديد مع Race resched-vs-book muxpan7hp4g5": Race resched-vs-book muxpan7hp4g5
    - button "موعد جديد مع Race resched-vs-book muxpc46l2h01": Race resched-vs-book muxpc46l2h01
    - button "موعد جديد مع Race resched-vs-resched muxpan7hp4g5": Race resched-vs-resched muxpan7hp4g5
    - button "موعد جديد مع Race resched-vs-resched muxpc46l2h01": Race resched-vs-resched muxpc46l2h01
    - button "موعد جديد مع Race same-slot-2 muxpan7hp4g5": Race same-slot-2 muxpan7hp4g5
    - button "موعد جديد مع Race same-slot-2 muxpc46l2h01": Race same-slot-2 muxpc46l2h01
    - button "موعد جديد مع Race same-slot-6 muxpan7hp4g5": Race same-slot-6 muxpan7hp4g5
    - button "موعد جديد مع Race same-slot-6 muxpc46l2h01": Race same-slot-6 muxpc46l2h01
    - button "موعد جديد مع رنا ar-muxpegf0jt3": رنا ar-muxpegf0jt3
    - button "موعد جديد مع رنا ar-muxpeglagup": رنا ar-muxpeglagup
    - button "موعد جديد مع رنا ar-muxpeiq7bed": رنا ar-muxpeiq7bed
    - button "موعد جديد مع رنا ar-muxpej4vxts": رنا ar-muxpej4vxts
    - button "موعد جديد مع رنا en-muxpdmxkhhd": رنا en-muxpdmxkhhd
    - button "موعد جديد مع رنا en-muxpdmxki3o": رنا en-muxpdmxki3o
    - button "موعد جديد مع رنا en-muxpdplphmy": رنا en-muxpdplphmy
    - button "موعد جديد مع رنا en-muxpdr6qre2": رنا en-muxpdr6qre2
    - button "موعد جديد مع رنا en-muxpdzzvvwo": رنا en-muxpdzzvvwo
    - button "موعد جديد مع reception-override muxpbv9jv9dz": reception-override muxpbv9jv9dz
    - button "موعد جديد مع replay muxpbv9jv9dz": replay muxpbv9jv9dz
    - button "موعد جديد مع reschedule-refusals muxpbv9jv9dz": reschedule-refusals muxpbv9jv9dz
    - button "موعد جديد مع rt-colleague muxpbxfm617y": rt-colleague muxpbxfm617y
    - button "موعد جديد مع rt-mover muxpbxfm617y": rt-mover muxpbxfm617y
    - button "موعد جديد مع rt-own muxpbxfm617y": rt-own muxpbxfm617y
    - button "موعد جديد مع سارة en-muxpdz03ygv": سارة en-muxpdz03ygv
    - button "موعد جديد مع scope muxpbv9jv9dz": scope muxpbv9jv9dz
    - button "موعد جديد مع services muxpbv9jv9dz": services muxpbv9jv9dz
    - button "موعد جديد مع وردية en-muxpeay9g80": وردية en-muxpeay9g80
    - button "موعد جديد مع Shift kuwait muxpcfmxbko7": Shift kuwait muxpcfmxbko7
    - button "موعد جديد مع Shift replace muxpcfmxbko7": Shift replace muxpcfmxbko7
    - button "موعد جديد مع Staff compensate muxpcg5hx7qy": Staff compensate muxpcg5hx7qy
    - button "موعد جديد مع Staff existing muxpcg5hx7qy": Staff existing muxpcg5hx7qy
    - button "موعد جديد مع Staff login muxpcg5hx7qy": Staff login muxpcg5hx7qy
    - button "موعد جديد مع Staff mgr-login muxpcg5hx7qy": Staff mgr-login muxpcg5hx7qy
    - button "موعد جديد مع Staff mgr-own muxpcg5hx7qy": Staff mgr-own muxpcg5hx7qy
    - button "موعد جديد مع Staff no-email muxpcg5hx7qy": Staff no-email muxpcg5hx7qy
    - button "موعد جديد مع Staff twin muxpcg5hx7qy": Staff twin muxpcg5hx7qy
    - button "موعد جديد مع status muxpbv9jv9dz": status muxpbv9jv9dz
    - button "موعد جديد مع Therapist a muxpc9mvqulc": Therapist a muxpc9mvqulc
    - button "موعد جديد مع Therapist b muxpc9mvqulc": Therapist b muxpc9mvqulc
    - button "موعد جديد مع Therapist c muxpc9mvqulc": Therapist c muxpc9mvqulc
    - button "موعد جديد مع Therapist d muxpc9mvqulc": Therapist d muxpc9mvqulc
    - button "موعد جديد مع Therapist e muxpc9mvqulc": Therapist e muxpc9mvqulc
    - button "موعد جديد مع Therapist hawally-only muxpc9mvqulc": Therapist hawally-only muxpc9mvqulc
    - button "موعد جديد مع walk-in muxpbv9jv9dz": walk-in muxpbv9jv9dz
    - button "نورة العلي ar-muxpefi2si9 10:00 – 11:00 تنظيف بشرة ar-muxpefi2si9"
    - button "سارة ar-muxpegf0jt3 15:00 – 16:00 تنظيف بشرة ar-muxpegf0jt3"
    - button "سارة ar-muxpegj371k 16:00 – 17:00 تنظيف بشرة ar-muxpegj371k"
    - button "سارة ar-muxpeglagup 15:00 – 16:00 تنظيف بشرة ar-muxpeglagup"
    - button "سارة ar-muxpei64396 15:00 – 16:00 تنظيف بشرة ar-muxpei64396"
    - button "سارة ar-muxpeiq7bed 15:00 – 16:00 تنظيف بشرة ar-muxpeiq7bed"
    - button "لينا ar-muxpej3dg1d 15:00 – 16:00 تنظيف بشرة ar-muxpej3dg1d"
    - button "سارة en-muxpdmxkhhd 15:00 – 16:00 تنظيف بشرة en-muxpdmxkhhd"
    - button "سارة en-muxpdmxki3o 15:00 – 16:00 تنظيف بشرة en-muxpdmxki3o"
    - button "نورة العلي en-muxpdmxkmmf 10:00 – 11:00 تنظيف بشرة en-muxpdmxkmmf"
    - button "سارة en-muxpdmxkq2p 10:00 – 11:00 تنظيف بشرة en-muxpdmxkq2p"
    - button "سارة en-muxpdmxkq2p 12:00 – 13:00 تنظيف بشرة en-muxpdmxkq2p"
    - button "لينا en-muxpdmxksym 15:00 – 16:00 تنظيف بشرة en-muxpdmxksym"
    - button "سارة en-muxpdmxksym 17:00 – 18:00 تنظيف بشرة en-muxpdmxksym"
    - button "سارة en-muxpdmxlvcp 15:00 – 16:00 تنظيف بشرة en-muxpdmxlvcp"
    - button "سارة en-muxpdplphmy 15:00 – 16:00 تنظيف بشرة en-muxpdplphmy"
    - button "سارة en-muxpdr1njvy 18:00 – 19:00 تنظيف بشرة en-muxpdr1njvy"
    - button "سارة en-muxpe0ic3ph 15:00 – 16:00 تنظيف بشرة en-muxpe0ic3ph"
    - button "سارة en-muxpe0nc0ew 15:00 – 16:00 تنظيف بشرة en-muxpe0nc0ew"
    - button "سارة en-muxpe8grtrp 15:00 – 16:00 تنظيف بشرة en-muxpe8grtrp"
    - button "سارة en-muxpecst777 16:00 – 17:00 تنظيف بشرة en-muxpecst777"
    - button "لينا ar-muxpegj371k 15:00 – 16:00 تنظيف بشرة ar-muxpegj371k"
    - button "سارة en-muxpdmxkr5d 14:00 – 15:00 تنظيف بشرة en-muxpdmxkr5d"
    - button "لينا en-muxpdmxkr5d 15:00 – 16:00 تنظيف بشرة en-muxpdmxkr5d"
    - button "لينا en-muxpe0ic3ph 15:00 – 16:00 تنظيف بشرة en-muxpe0ic3ph"
    - button "سارة ar-muxpegf0jt3 16:00 – 17:30 تدليك ar-muxpegf0jt3"
    - button "هدى ar-muxpeglagup 15:00 – 16:00 تنظيف بشرة ar-muxpeglagup"
    - button "هدى ar-muxpeiq7bed 15:00 – 16:00 تنظيف بشرة ar-muxpeiq7bed"
    - button "هدى en-muxpdmxkhhd 15:00 – 16:00 تنظيف بشرة en-muxpdmxkhhd"
    - button "سارة en-muxpdmxki3o 16:00 – 17:30 تدليك en-muxpdmxki3o"
    - button "هدى en-muxpdplphmy 15:00 – 16:00 تنظيف بشرة en-muxpdplphmy"
    - button "بدون حجز 17:00 – 18:30 تدليك en-muxpdr6qre2"
  - status
  - dialog "موعد جديد":
    - heading "موعد جديد" [level=2]
    - paragraph: الأوقات بالمنطقة الزمنية للفرع (Asia/Kuwait).
    - button "إغلاق"
    - group "العميل":
      - text: العميل
      - checkbox "بدون حجز" [checked]
      - text: بدون حجز بدون سجل عميل. يمكنك ربط عميل بالموعد لاحقًا.
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
        - option "رنا ar-muxpej4vxts" [selected]
      - group "الأوقات المتاحة":
        - text: الأوقات المتاحة
        - status "جارٍ تحميل الأوقات المتاحة"
      - text: وقت البدء
      - textbox "وقت البدء": 17:00
      - text: اختر وقتًا متاحًا أعلاه، أو اكتب وقتًا.
      - paragraph: 90 دقيقة · ‏40.500 د.ك.‏
    - button "إضافة خدمة أخرى"
    - text: الإجمالي (90 دقيقة) ‏40.500 د.ك.‏ ملاحظة الموعد
    - textbox "ملاحظة الموعد"
    - text: اختياري. يظهر لموظفي الاستقبال.
    - button "إلغاء"
    - button "احجز الموعد"
- status
- alert
```

# Test source

```ts
  1   | import type { Page } from "@playwright/test";
  2   | import { createClient, createService, createStaff } from "./bookingFixtures";
  3   | import { expect, signIn, test } from "./fixtures";
  4   | import { unique } from "./memberFlows";
  5   | import { kuwaitToday } from "./shiftFlows";
  6   | import { SETUP_BRANCH } from "./staffFlows";
  7   | import type { Strings } from "./strings";
  8   | 
  9   | // The new-booking drawer at Setup Studio Hawally (Asia/Kuwait, 24-hour, open
  10  | // from 14:00 at the latest): fresh services, staff and clients each run; the
  11  | // drawer books through the bookings function as the receptionist.
  12  | 
  13  | const addDays = (date: string, days: number) => new Date(Date.parse(`${date}T00:00:00Z`) + days * 86_400_000).toISOString().slice(0, 10);
  14  | 
  15  | async function setUp(request: Parameters<typeof createService>[0], id: string, day: string) {
  16  |   const facial = await createService(request, { en: `Facial ${id}`, ar: `تنظيف بشرة ${id}` }, { duration: 60, price: 25_000 });
  17  |   const massage = await createService(request, { en: `Massage ${id}`, ar: `تدليك ${id}` }, { duration: 90, price: 40_500 });
  18  |   const shifts = [{ day, starts: "09:00", ends: "22:00" }];
  19  |   await createStaff(request, { name: { en: `Mona ${id}`, ar: `منى ${id}` }, branchId: SETUP_BRANCH.hawally, serviceIds: [facial], shifts });
  20  |   await createStaff(request, { name: { en: `Rana ${id}`, ar: `رنا ${id}` }, branchId: SETUP_BRANCH.hawally, serviceIds: [massage], shifts });
  21  |   await createClient(request, { firstName: "Sara", lastName: id, firstNameAlt: "سارة", lastNameAlt: id, allergies: "Latex" });
  22  |   await createClient(request, { firstName: "Noura", lastName: id, firstNameAlt: "نورة", lastNameAlt: id, blockedReason: "Unpaid" });
  23  | }
  24  | 
  25  | async function openDrawer(page: Page, s: Strings, day: string) {
  26  |   await page.goto("/login");
  27  |   await signIn(page, s, "setup-reception@spacorner.test");
  28  |   await expect(page).toHaveURL(/\?branch=/);
  29  |   await page.goto(`/calendar?branch=${SETUP_BRANCH.hawally}&date=${day}`);
  30  |   await page.getByRole("button", { name: s.newAppointment, exact: true }).click();
  31  |   return page.getByRole("dialog", { name: s.newAppointment });
  32  | }
  33  | 
  34  | test("the front desk books a two-service visit with two people and sees the total", async ({ page, request, s, appLocale }) => {
  35  |   const id = unique(appLocale);
  36  |   const day = addDays(kuwaitToday(), 1);
  37  |   await setUp(request, id, day);
  38  |   const ar = appLocale === "ar";
  39  | 
  40  |   const drawer = await openDrawer(page, s, day);
  41  |   await drawer.getByLabel(s.findClient).fill(`Sara ${id}`);
  42  |   await drawer.getByRole("button", { name: new RegExp(id) }).click();
  43  |   await expect(drawer.getByText("Latex")).toBeVisible();
  44  | 
  45  |   const first = drawer.getByRole("region", { name: s.service, exact: true });
  46  |   await first.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: ar ? `تنظيف بشرة ${id}` : `Facial ${id}` });
  47  |   await first.getByRole("combobox", { name: s.teamMember }).selectOption({ label: ar ? `منى ${id}` : `Mona ${id}` });
  48  |   await first.getByRole("radio", { name: "15:00", exact: true }).check();
  49  | 
  50  |   await drawer.getByRole("button", { name: s.addAnotherService }).click();
  51  |   const second = drawer.getByRole("region", { name: s.serviceN(2) });
  52  |   await second.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: ar ? `تدليك ${id}` : `Massage ${id}` });
  53  |   await second.getByRole("combobox", { name: s.teamMember }).selectOption({ label: ar ? `رنا ${id}` : `Rana ${id}` });
  54  |   await second.getByRole("radio", { name: "16:00", exact: true }).check();
  55  |   await expect(drawer).toContainText("65.500");
  56  | 
  57  |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  58  |   await expect(page.getByText(s.appointmentBooked)).toBeVisible();
  59  |   await expect(drawer).toBeHidden();
  60  |   const byStaff = page.getByRole("region", { name: s.appointmentsByStaff });
  61  |   await expect(byStaff.locator("[data-event-id]").filter({ hasText: id })).toHaveCount(2);
  62  | });
  63  | 
  64  | test("the front desk books a walk-in with anyone available", async ({ page, request, s, appLocale }) => {
  65  |   const id = unique(appLocale);
  66  |   const day = addDays(kuwaitToday(), 1);
  67  |   await setUp(request, id, day);
  68  | 
  69  |   const drawer = await openDrawer(page, s, day);
  70  |   await drawer.getByRole("checkbox", { name: s.walkIn }).check();
  71  |   const item = drawer.getByRole("region", { name: s.service, exact: true });
  72  |   await item.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: appLocale === "ar" ? `تدليك ${id}` : `Massage ${id}` });
  73  |   await expect(item.getByRole("combobox", { name: s.teamMember })).toHaveValue("");
  74  |   // Anyone: each time names who takes it; picking one assigns them.
  75  |   await item.getByRole("radio", { name: new RegExp(`^17:00 .*${id}`) }).click();
  76  |   await expect(item.getByRole("combobox", { name: s.teamMember })).toHaveValue(/[0-9a-f-]{36}/);
> 77  |   await expect(item.getByRole("radio", { name: "17:00", exact: true })).toBeChecked();
      |                                                                         ^ Error: expect(locator).toBeChecked() failed
  78  | 
  79  |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  80  |   await expect(page.getByText(s.appointmentBooked)).toBeVisible();
  81  |   const byStaff = page.getByRole("region", { name: s.appointmentsByStaff });
  82  |   await expect(byStaff.locator("[data-event-id]").filter({ hasText: s.walkIn }).filter({ hasText: id })).toHaveCount(1);
  83  | });
  84  | 
  85  | test("a blocked client can't be booked and the drawer says why", async ({ page, request, s, appLocale }) => {
  86  |   const id = unique(appLocale);
  87  |   const day = addDays(kuwaitToday(), 1);
  88  |   await setUp(request, id, day);
  89  | 
  90  |   const drawer = await openDrawer(page, s, day);
  91  |   await drawer.getByLabel(s.findClient).fill(`Noura ${id}`);
  92  |   await drawer.getByRole("button", { name: new RegExp(id) }).click();
  93  |   const item = drawer.getByRole("region", { name: s.service, exact: true });
  94  |   await item.getByRole("combobox", { name: s.service, exact: true }).selectOption({ label: appLocale === "ar" ? `تنظيف بشرة ${id}` : `Facial ${id}` });
  95  |   await item.getByRole("radio", { name: new RegExp(`^15:00`) }).check();
  96  |   await drawer.getByRole("button", { name: s.bookAppointment }).click();
  97  |   await expect(drawer.getByRole("alert").filter({ hasText: s.clientBlockedFromBooking })).toBeVisible();
  98  |   await expect(drawer).toBeVisible();
  99  | });
  100 | 
```