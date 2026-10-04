# plan/sql — quarantined drafts only

This directory contains **no active migrations**. The 13 round-1 draft files
live in `drafts-v1/`, each under a SUPERSEDED banner (round-2 finding F-1,
adjudicated in `../review2/adjudication.md`).

- Never apply `drafts-v1/*.sql` with `supabase db reset`, CI, or by hand.
- The active migration set is written fresh under `supabase/migrations/`
  (repo layout per `../CONVENTIONS.md` §2) during plan Phase 0/1, from the
  binding ADRs in `../decisions.md` — in particular ADR-15 (names),
  ADR-17/51 (money), ADR-20 (RLS, all-branches representation, composite
  FKs, role grants, search_path), ADR-21 (security_invoker + grants),
  ADR-24/26 (booking integrity, blocked time), ADR-34 (payments ledger),
  ADR-44/45/46 (ids, time, retention), ADR-52 (calendar prefs, client source).
- CI fails if the active migration path references anything under
  `drafts-v1/` (clean-migration gate, F-verifier-2).
