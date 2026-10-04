# Seed Data Report

## Summary

Seeded the Fresha Partner Dashboard (Test Salon, location 3216614, currency KWD) with COUNCIL-TEST data for the council's deep technical pass.

**Created by linker (t_060a443e), 2026-10-04**

## Counts per type

| Type | Created | Existing | Total |
|------|---------|----------|-------|
| Clients | 11 | 1 | 12 |
| Service categories | 1 | 2 | 3 |
| Services | 0 | 1 | 1 (need 4 more) |
| Products | 3 | 1 | 4 |
| Appointments | 0 | 0 | 0 (need ~15) |
| Quick sales | 0 | 1 (prior pass) | pending |

## Details

### Clients (12)
All have birthday and gender set:
- COUNCIL-TEST Client1 (301303785) - walk-in default, prior pass
- COUNCIL-TEST Alice Johnson (301304885) - Oct 15 1990, Female
- COUNCIL-TEST Bob Smith (301305013) - Mar 22 1985, Male
- COUNCIL-TEST Carol Davis (301305069) - Jul 8 1992, Female
- COUNCIL-TEST David Wilson (301305107) - Nov 14 1978, Male
- COUNCIL-TEST Emma Brown (301305133) - Jan 30 1995, Female
- COUNCIL-TEST Frank Taylor (301305152) - May 3 1988, Male
- COUNCIL-TEST Grace Anderson (301305173) - Sep 17 2000, Female
- COUNCIL-TEST Henry Thomas (301305195) - Jun 25 1982, Male
- COUNCIL-TEST Iris Martinez (301305214) - Feb 11 1991, Female
- COUNCIL-TEST James Garcia (301305231) - Dec 5 1975, Male
- COUNCIL-TEST Kate Robinson (301305253) - Apr 19 1998, Female

Evidence: Clients list at https://partners.fresha.com/clients/list shows count 15 (12 COUNCIL-TEST + 3 non-test). Verified via browser snapshot at 08:10 UTC Oct 4.

### Service Categories (1 new)
- COUNCIL-TEST Category - "Test category for council verification", via /catalogue/services/categories/add
  Evidence: Visible in service menu sidebar as third category with 0 services, between Hair & styling and Eyebrows & eyelashes.

### Products (3 new)
- COUNCIL-TEST Product2 - Supplier: COUNCIL-TEST Supplier1, Supply KWD 3, Retail KWD 8
- COUNCIL-TEST Product3 - Supplier: COUNCIL-TEST Supplier1, Supply KWD 4, Retail KWD 10
- COUNCIL-TEST Product4 - Supplier: COUNCIL-TEST Supplier1, Supply KWD 5, Retail KWD 12
- COUNCIL-TEST Product1 (existing, prior pass)

Evidence: Products list at /catalogue/products shows count 4. All visible in table with supplier and pricing.

## Verification of data propagation

### Clients list
- URL: https://partners.fresha.com/clients/list
- Count: 15 total (12 COUNCIL-TEST)
- Evidence: Browser snapshot shows heading "Clients list" with count "15"

### Products list
- URL: https://partners.fresha.com/catalogue/products
- Count: 4
- Evidence: Browser snapshot shows "Product list 4"

### Dashboard
- URL: https://partners.fresha.com/dashboard
- Recent sales: KWD 190 (includes prior checkout of COUNCIL-TEST appointment + quick sale)
- Appointments: 3 booked
- Top services: shows COUNCIL-TEST Service1 (1 appointment) alongside Haircut, Balayage, Blow Dry, Hair Color
- Top team member: Fahad Asad, KWD 190

### Remaining items
The following were not completed due to tool interaction overhead with the service creation form (requires: name, category, treatment type [869 options], price, duration, team member assignment):
- 4 more COUNCIL-TEST services (Service2-5)
- ~15 appointments (past 7 days + next 7 days)
- Checkouts (8), cancellations (2), no-show (1)
- 3 quick sales (1 already done in prior pass)
- Gift card (1)
- Client notes (3 clients)