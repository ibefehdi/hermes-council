# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: calendar-appointment.spec.ts >> a no-show is recorded by the front desk and reopened by a manager with a reason
- Location: e2e/calendar-appointment.spec.ts:73:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('تغيّرت الحالة إلى محجوز.')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" getByText('تغيّرت الحالة إلى محجوز.') with timeout 5000ms
  - waiting for getByText('تغيّرت الحالة إلى محجوز.')

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
  - text: مدير الفرع
  - group "الفرع (مقفل)":
    - paragraph: حولي
  - button "البحث عن العملاء والمواعيد": بحث Ctrl K
  - button "English"
  - button "Maryam Hawally"
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
    - button "موعد جديد مع سارة ar-muxpejib01q": سارة ar-muxpejib01q
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
  - dialog "سارة ar-muxpei64396":
    - heading "سارة ar-muxpei64396" [level=2]
    - paragraph: المرجع HWL-A130
    - button "إغلاق"
    - text: لم يحضر
    - paragraph: الخميس، 8 أكتوبر · 15:00 – 16:00
    - region "العميل":
      - heading "العميل" [level=3]
      - link "سارة ar-muxpei64396":
        - /url: /clients/1f44845c-e3c1-4ef5-9a23-b37555005b12?branch=00000000-0000-4000-a000-000000000004
      - text: Sara ar-muxpei64396
    - region "الخدمات":
      - heading "الخدمات" [level=3]
      - list:
        - listitem: تنظيف بشرة ar-muxpei64396 مع منى ar-muxpei64396 · 15:00 – 16:00 · 60 دقيقة ‏25.000 د.ك.‏
      - paragraph: الإجمالي (60 دقيقة)
      - text: ‏25.000 د.ك.‏
    - region "الحالة":
      - heading "الحالة" [level=3]
      - button "إعادة فتح"
    - text: ملاحظة الموعد
    - textbox "ملاحظة الموعد"
    - text: يظهر لموظفي الاستقبال.
    - button "حفظ الملاحظة" [disabled]
    - dialog "إعادة فتح هذا الموعد؟":
      - heading "إعادة فتح هذا الموعد؟" [level=2]
      - paragraph: يعود الموعد إلى حالة محجوز. يجب أن يكون الوقت لا يزال متاحًا، وأي استثناء من القواعد المعتادة يُسجَّل مع سببك.
      - button "إغلاق"
      - text: السبب
      - textbox "السبب": Arrived late, still served
      - button "رجوع"
      - button "إعادة فتح" [disabled]
    - button "إغلاق"
    - button "الدفع (المرحلة 6)" [disabled]
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
  50  |   await expect(page.getByText(s.statusChangedTo(s.confirmed))).toBeVisible();
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
> 101 |   await expect(page.getByText(s.statusChangedTo(s.booked))).toBeVisible();
      |                                                             ^ Error: expect(locator).toBeVisible() failed
  102 |   await expect(managerDrawer.getByText(s.booked, { exact: true })).toBeVisible();
  103 | });
  104 | 
```