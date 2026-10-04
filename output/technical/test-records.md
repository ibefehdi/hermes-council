# Test Records Log

## Flow 1: Client
- Created: COUNCIL-TEST Client1, ID 301303785, email council-test+1@example.com, by linker, NOT reverted
- Note: "COUNCIL-TEST note: This is a test note for the council link mapping exercise.", via notes_createNote mutation, NOT reverted

## Flow 2: Service
- Created: COUNCIL-TEST Service1, category Hair & styling, price KWD 25, duration 1 hr, via services_createServiceMutation, by linker, NOT reverted

## Flow 3: Product and Supplier
- Created: COUNCIL-TEST Product1, via products_createProduct (inferred), by linker, NOT reverted
- Created: COUNCIL-TEST Supplier1, via POST /suppliers (inferred), by linker, NOT reverted

## Flow 5: Appointment
- Created: Appointment for COUNCIL-TEST Client1 (301303785) + COUNCIL-TEST Service1 + Fahad Asad, Mon Oct 5 10:00-11:00, KWD 25, via calendar drawer, by linker, NOT reverted
- Walk-in auto-created first, then client added

## Settings pass (cartographer)
- 2026-10-04 10:44: Created cancellation reason "COUNCIL-TEST cancellation reason" via Add dialog on /setup/scheduling/cancellation-reasons. API: POST https://partners.fresha.com/cancellation-reasons, body {"data":{"attributes":{"name":"COUNCIL-TEST cancellation reason"},"type":"cancellation-reasons"}} => 200, toast "Cancellation reason added". Left in place (additive, harmless) for verifier to spot-check; deletable via row Actions menu. NOT reverted.

## Gaps pass (cartographer, t_98a9f324)
- 2026-10-04 ~11:00: No records created, no settings changed. All Add/Edit dialogs (client, supplier, service) opened and closed without saving; bulk row selection on Clients list deselected; no delete/refund/void/cancel executed; Loyalty gate Continue not clicked.
- Observed sibling records (created by linker, see above): client 301303785, COUNCIL-TEST Service1, COUNCIL-TEST Supplier1, and the Oct 5 COUNCIL-TEST appointment appeared in the client drawer and appointment lists during this pass.

## Architecture pass 2 (linker, t_dd9df44c)
- 2026-10-04: No records created, no settings changed. Visited pages read-only for API mapping: Dashboard, Calendar, Sales/Appointments, Sales/Sales list, Clients List, Reports, Setup. All COUNCIL-TEST records from prior pass observed in UI.
- COUNCIL-TEST Client1 (301303785) visible in customer-search response with 3 other clients.
- COUNCIL-TEST Service1 appears in Top services table on Dashboard.
- COUNCIL-TEST appointment (Oct 5, 10:00) visible in Appointments activity feed.
- Session account: pid=3110536, location_id=3216614, currency KWD, 1 team member (Fahad Asad, employee 5621666).