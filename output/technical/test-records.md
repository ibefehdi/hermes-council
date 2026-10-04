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

## Flows pass 2 (linker, t_8482715c)
- 2026-10-04: Checkout of COUNCIL-TEST appointment (1319614874). Order ID: 1091450803. Invoice/Sale ID: 567896865. Sale #2, Completed. Payment: Cash KWD 25. Client: COUNCIL-TEST Client1 (301303785). NOT reverted.
- 2026-10-04: Quick sale of COUNCIL-TEST Service1. Order ID: 1091452695. Invoice/Sale ID: 567897371. Sale #3, Walk-In, Completed. Payment: Cash KWD 25. NOT reverted.
- 2026-10-04: Edited COUNCIL-TEST Product1 (product ID 13279305): added description "COUNCIL-TEST: verified edit for link mapping". Via product edit dialog. NOT reverted.
- 2026-10-04: Edited COUNCIL-TEST Supplier1 (supplier ID 1353761): added description "COUNCIL-TEST: verified edit for link mapping". Via supplier edit dialog. NOT reverted.
- Appointment cancellation: NOT executed (preserved for propagation checks). Menu path and dialog observed: Actions → Cancel appointment → select "COUNCIL-TEST cancellation reason".
- Key API discovery: All sales follow initializeOrder → (setTipAmount) → addOrderIntendedTransaction → capturePayments pipeline at partners-api-gateway.fresha.com.
## Seed data (linker, t_060a443e)

### Clients (12 total: 11 new + 1 existing)
- Created: COUNCIL-TEST Alice Johnson, ID 301304885, email council-test+2@example.com, birthday Oct 15 1990, Female, by linker, NOT reverted
- Created: COUNCIL-TEST Bob Smith, ID 301305013, email council-test+3@example.com, birthday Mar 22 1985, Male, by linker, NOT reverted
- Created: COUNCIL-TEST Carol Davis, ID 301305069, email council-test+4@example.com, birthday Jul 8 1992, Female, by linker, NOT reverted
- Created: COUNCIL-TEST David Wilson, ID 301305107, email council-test+5@example.com, birthday Nov 14 1978, Male, by linker, NOT reverted
- Created: COUNCIL-TEST Emma Brown, ID 301305133, email council-test+6@example.com, birthday Jan 30 1995, Female, by linker, NOT reverted
- Created: COUNCIL-TEST Frank Taylor, ID 301305152, email council-test+7@example.com, birthday May 3 1988, Male, by linker, NOT reverted
- Created: COUNCIL-TEST Grace Anderson, ID 301305173, email council-test+8@example.com, birthday Sep 17 2000, Female, by linker, NOT reverted
- Created: COUNCIL-TEST Henry Thomas, ID 301305195, email council-test+9@example.com, birthday Jun 25 1982, Male, by linker, NOT reverted
- Created: COUNCIL-TEST Iris Martinez, ID 301305214, email council-test+10@example.com, birthday Feb 11 1991, Female, by linker, NOT reverted
- Created: COUNCIL-TEST James Garcia, ID 301305231, email council-test+11@example.com, birthday Dec 5 1975, Male, by linker, NOT reverted
- Created: COUNCIL-TEST Kate Robinson, ID 301305253, email council-test+12@example.com, birthday Apr 19 1998, Female, by linker, NOT reverted
- Existing: COUNCIL-TEST Client1, ID 301303785, email council-test+1@example.com (created in prior pass)

### Service Category
- Created: COUNCIL-TEST Category, description "Test category for council verification", via /catalogue/services/categories/add, by linker, NOT reverted

### Products (4 total: 3 new + 1 existing)
- Existing: COUNCIL-TEST Product1 (created in prior pass)
- Created: COUNCIL-TEST Product2, supplier COUNCIL-TEST Supplier1, supply KWD 3, retail KWD 8, by linker, NOT reverted
- Created: COUNCIL-TEST Product3, supplier COUNCIL-TEST Supplier1, supply KWD 4, retail KWD 10, by linker, NOT reverted
- Created: COUNCIL-TEST Product4, supplier COUNCIL-TEST Supplier1, supply KWD 5, retail KWD 12, by linker, NOT reverted

### Services (pending: need 4 more)
- Existing: COUNCIL-TEST Service1, category Hair & styling, price KWD 25, duration 1 hr (created in prior pass)
- NOT YET CREATED: COUNCIL-TEST Service2, Service3, Service4, Service5

### Appointments (pending)
- NOT YET CREATED