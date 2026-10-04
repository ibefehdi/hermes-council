# Brief: Seed realistic test data (linker)

Read {{COUNCIL_DIR}}/output/technical/briefs/common.md first. All its safety rules apply.

The test account is nearly empty, so lists, dashboards, and reports show little and the council cannot observe how data propagates. Create a realistic, varied data set so every module has content. Reuse any COUNCIL-TEST records listed in {{COUNCIL_DIR}}/output/technical/test-records.md instead of duplicating them.

Create (every name starts with COUNCIL-TEST; fake contact details only: council-test+<n>@example.com, no phone numbers):

1. Clients: 12, varied (first/last names, some with birthday, gender, notes, tags/referral source where the form allows). Add a note to 3 of them.
2. Services: 5 across at least 2 categories (create a COUNCIL-TEST category if needed), different durations (30/45/60/90 min) and prices; assign the existing team member.
3. Products: 4 with brand/category, cost and retail price, stock quantity, linked to the COUNCIL-TEST supplier.
4. Appointments: about 15 spread over the past 7 days and the next 7 days, different clients, services, and times. Then:
   - check out 8 of the past ones with a Cash or Other manual payment (never card terminal, card on file, or payment link), adding a product to 2 of those checkouts and a discount to 1 if available;
   - cancel 2 using the "COUNCIL-TEST cancellation reason" if it exists;
   - mark 1 as no-show if available;
   - leave the future ones booked, and confirm or mark arrived on 1 if available.
5. Quick sales: 3 without appointments (products and/or services), cash/manual payment.
6. If available without payment setup or purchase: sell 1 gift card or voucher with a cash payment. Skip anything that requires activating an add-on or paid feature.

Skip team members if the UI warns about billing or subscription changes.

Log every record in test-records.md (type, name, ID if visible, date, status) as you go, grouped under "Seed data". Then write {{COUNCIL_DIR}}/output/technical/seed.md: what was created, counts per type, and a short check of where the data now shows up (Clients list count, Sales list, Payments, Daily sales summary, Dashboard widgets, a few reports such as Sales summary and Appointments summary), with evidence.
