-- ADRs implemented: ADR-20 (RLS), ADR-24 (btree_gist for exclusion constraints),
--   ADR-33 (pg_cron/pgmq for async work), ADR-44 (gen_random_uuid), ADR-46 (soft delete)
--
-- Enable extensions required for the MVP schema.
-- pg_cron follows the Supabase hosted install form (ADR-33, F-DB-10).

-- Extensions that work fine in PGlite / standard Postgres
create extension if not exists btree_gist with schema extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;

-- check-sql: skip-begin
-- pg_cron: Supabase hosted install form
create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;
-- pgmq: Supabase Queues
create extension if not exists pgmq with schema extensions;
-- pg_net: required for pg_cron -> Edge Function invocation (ADR-33, revised in
-- final round per verifier finding F-final-db-1)
create extension if not exists pg_net with schema extensions;
-- check-sql: skip-end

-- Base grants for the public schema (roles are created by Supabase; stubbed in check-sql)
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to service_role;
alter default privileges in schema public grant all on sequences to service_role;
alter default privileges in schema public grant all on functions to service_role;
alter default privileges in schema public grant all on routines to service_role;

-- Schemas
create schema if not exists extensions;
create schema if not exists auth;
grant usage on schema extensions, auth to anon, authenticated, service_role;