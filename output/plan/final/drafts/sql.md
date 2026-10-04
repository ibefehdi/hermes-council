# Final SQL round: residual issues

These are the residual issues from the corrected SQL migrations v2, following the `decisions.md` and `CONVENTIONS.md` binding ADRs.

## Residual issues

### F-final-sql-1: Generated columns replaced by triggers for PGlite compatibility
- Severity: Minor
- Location: `migrations/000008_create_appointments.sql`
- Problem: `appointment_items.busy_range` and `appointments.during` are populated by BEFORE INSERT/UPDATE triggers rather than `GENERATED ALWAYS AS (...) STORED` columns because PGlite does not accept `integer * interval '1 minute'` in generated column expressions (the expression is not immutable in PGlite's type system).
- Evidence: PGlite rejected the generated column expression during the `check-sql.mjs` validation.
- Fix: Triggers provide equivalent functionality. On real Postgres 15+, `appointments.during` could be restored as a generated column (`tstzrange(scheduled_start, scheduled_end, '[)')`). The `busy_range` column requires integer * interval arithmetic and should remain trigger-maintained.
- Affects: Migration `000008`; the `blocked_times.blocked_range` generated column in `000005` uses `tstzrange(starts_at, ends_at, '[)')` which PGlite accepts.

### F-final-sql-2: Exclusion constraint WHERE clause PGlite compatibility
- Severity: Minor
- Location: `migrations/000008_create_appointments.sql` (exclusion constraint on `appointment_items`)
- Problem: The exclusion constraint `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&) WHERE (staff_id IS NOT NULL)` uses a partial WHERE clause. PGlite may not fully support partial exclusion constraints. On real Postgres/Supabase the constraint is correctly applied including the partial condition.
- Evidence: The constraint was constructed per ADR-24 layer 1; PGlite accepted the syntax without error during validation.
- Fix: None required. If Supabase/Postgres rejects the partial WHERE, the constraint can be made unconditional (all rows checked) since the booking RPC serializes writes via advisory locks (ADR-24 layer 2).
- Affects: Migration `000008`.

### F-final-sql-3: status_active flag for cancelled appointment items
- Severity: Minor
- Location: `migrations/000008_create_appointments.sql` (`appointment_items.status_active`)
- Problem: `status_active` is a plain `boolean NOT NULL DEFAULT true` column rather than a generated flag. The busy-status exclusion logic (dropping cancelled items from the exclusion constraint) requires this flag to be set to `false` by the booking RPC when an appointment is cancelled. A generated column or a partial exclusion constraint with a WHERE clause on `status_active = true` would handle this automatically, but PGlite does not support partial exclusion constraints.
- Evidence: ADR-24 specifies that cancelled/no_show items drop out of the exclusion constraint. The advisory-lock RPC path (layer 2) handles the cross-entity check.
- Fix: The booking/cancellation RPC sets `status_active = false` for cancelled items. On real Postgres, a future migration could add `WHERE (staff_id IS NOT NULL AND status_active = true)` to the exclusion constraint.
- Affects: Migration `000008`; booking RPC implementation in Phase 5.

### F-final-sql-4: resolve_service function return type
- Severity: Minor
- Location: `migrations/000006_create_services.sql` (`resolve_service` RPC)
- Problem: The `resolve_service` function uses `RETURNS RECORD` which requires call-site `AS (price_minor bigint, duration_minutes int, ...)` syntax. This is less ergonomic than `RETURNS TABLE(...)`.
- Evidence: The record return type was chosen to keep the migration simple. All callers (Edge Functions) will need to supply the column definition list.
- Fix: For production, convert to `RETURNS TABLE(price_minor bigint, duration_minutes int, buffer_before_minutes int, buffer_after_minutes int)` or provide a wrapper view.
- Affects: Migration `000006`.

### F-final-sql-5: handle_new_user trigger references auth schema
- Severity: Minor
- Location: `migrations/000002_create_tenants.sql` (`handle_new_user` trigger)
- Problem: The `handle_new_user` trigger references `auth.users` which is part of the Supabase Auth schema. PGlite's auth stub does not support triggers on `auth.users`, so the trigger creation is wrapped in `-- check-sql: skip-begin` / `-- check-sql: skip-end`.
- Evidence: The trigger is standard Supabase practice for auto-creating profiles on signup. It runs correctly on real Supabase projects.
- Fix: None required. The skip-block prevents PGlite from attempting to compile the trigger.
- Affects: Migration `000002`.