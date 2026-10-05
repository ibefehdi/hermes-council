# Phase 2 Database & Security Audit

Auditor: auditor profile
Date: 2026-10-05
Repository: /Users/fahadasad/glowdesk @ edfad112962008246b818f9edf9c3c95591e05c2
Briefs: common.md + database.md

## Phase 2 overview

Phase 2: Staff & shifts. Subphases:
- 2.1 Staff records (db: staff_members, staff_branch_assignments)
- 2.2 Shifts (db: shifts)
- 2.3 Blocked time (db: blocked_times, appointments early)

### Migrations (new since Phase 1)
1. 20261006100000_create_search_normalization.sql
2. 20261006100100_create_staff_members.sql
3. 20261006100200_staff_rpcs.sql
4. 20261006110000_create_shifts.sql
5. 20261006110100_shift_rpcs.sql
6. 20261006120000_create_appointments.sql (pulled forward for Phase 2.3 cross-entity check)
7. 20261006120100_create_blocked_times.sql
8. 20261006120200_blocked_time_rpcs.sql

### pgTAP test files (new)
1. 008_staff_matrix.test.sql
2. 009_shifts_matrix.test.sql
3. 010_blocked_times_matrix.test.sql
4. 011_blocked_times_conflicts.test.sql

---

## Migration audit

Reading each migration file now.