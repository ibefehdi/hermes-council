// Usage: node check-sql.mjs <migrations-dir> [tests-dir]
// Applies every *.sql in <migrations-dir> (sorted by name) to a fresh in-memory Postgres (PGlite) with
// stand-ins for Supabase's auth schema and roles, then runs every *.sql in [tests-dir].
// Tests run as written; use `set role authenticated` and `select set_config('request.jwt.claims', ...)`
// to act as a user, and raise an exception (or a failing assert) when an expectation is not met.
// Statements Supabase provides but PGlite cannot run (pg_cron, pgmq, pg_net, vault) go between
// `-- check-sql: skip-begin` and `-- check-sql: skip-end` lines.
import { PGlite } from '@electric-sql/pglite';
import { btree_gist } from '@electric-sql/pglite/contrib/btree_gist';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';
import { citext } from '@electric-sql/pglite/contrib/citext';
import { uuid_ossp } from '@electric-sql/pglite/contrib/uuid_ossp';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const [migDir, testDir] = process.argv.slice(2);
if (!migDir) {
  console.error('Usage: node check-sql.mjs <migrations-dir> [tests-dir]');
  process.exit(2);
}

const SUPABASE_STUBS = `
create schema if not exists extensions;
create schema if not exists auth;
do $$ begin
  create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
exception when duplicate_object then null; end $$;
grant usage on schema public, extensions, auth to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to service_role;
create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  phone text,
  raw_app_meta_data jsonb default '{}'::jsonb,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
create or replace function auth.jwt() returns jsonb language sql stable as
  $f$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $f$;
create or replace function auth.uid() returns uuid language sql stable as
  $f$ select nullif(auth.jwt() ->> 'sub', '')::uuid $f$;
create or replace function auth.role() returns text language sql stable as
  $f$ select coalesce(auth.jwt() ->> 'role', current_user) $f$;
grant execute on all functions in schema auth to anon, authenticated, service_role;
`;

const stripSkipped = (sql) => sql.replace(/^--\s*check-sql:\s*skip-begin[\s\S]*?^--\s*check-sql:\s*skip-end.*$/gim, '');
const lineOf = (sql, pos) => (pos ? sql.slice(0, Number(pos)).split('\n').length : '?');
const sqlFiles = (dir) => readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();

const db = new PGlite({ extensions: { btree_gist, pgcrypto, citext, uuid_ossp } });
await db.exec(SUPABASE_STUBS);

let failed = 0;
async function run(dir, label) {
  for (const f of sqlFiles(dir)) {
    const sql = stripSkipped(readFileSync(join(dir, f), 'utf8'));
    try {
      await db.exec(sql);
      await db.exec('reset role; reset all;');
      console.log(`ok   ${label} ${f}`);
    } catch (e) {
      failed++;
      console.log(`FAIL ${label} ${f}:${lineOf(sql, e.position)}: ${e.message}${e.detail ? ` (${e.detail})` : ''}`);
      await db.exec('rollback; reset role; reset all;').catch(() => {});
      if (label === 'migration') return false;
    }
  }
  return true;
}

if (await run(migDir, 'migration')) {
  const { rows } = await db.query(`
    select c.relname as table, c.relrowsecurity as rls,
           (select count(*) from pg_policies p where p.schemaname = 'public' and p.tablename = c.relname) as policies
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' order by 1`);
  const noRls = rows.filter((r) => !r.rls);
  const noPolicies = rows.filter((r) => r.rls && Number(r.policies) === 0);
  console.log(`\n${rows.length} public tables, ${rows.length - noRls.length} with RLS enabled`);
  for (const r of noRls) { failed++; console.log(`FAIL public.${r.table}: RLS not enabled`); }
  for (const r of noPolicies) console.log(`warn public.${r.table}: RLS enabled but no policies (deny-all)`);
  const { rows: definers } = await db.query(`
    select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
      and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%')`);
  for (const d of definers) { failed++; console.log(`FAIL public.${d.proname}: SECURITY DEFINER without a fixed search_path`); }
  if (testDir && existsSync(testDir)) await run(testDir, 'test');
}

console.log(failed ? `\n${failed} problem(s)` : '\nOK: migrations apply cleanly and all tests pass');
process.exit(failed ? 1 : 0);
