// Usage: node check-ci.mjs <draft-dir> [repo] [--offline]
// <draft-dir> mirrors an app repository: .github/workflows/*.yml, .github/rulesets/main.json, and any test or
// config files to add. Checks that the workflows parse and pass actionlint (when available), that every action is
// pinned to a real commit SHA, and that the ruleset for main can actually be satisfied: each required check is a
// job that reports under that exact name on pull requests, nothing that runs on a PR escapes the required checks,
// and an aggregating job cannot be skipped into a pass. With [repo], also checks that every `pnpm <script>` the
// workflows call exists, and that the draft does not touch supabase/migrations/.
// --offline skips the GitHub lookups that verify action SHAs (reported as warnings instead).
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { parse } from 'yaml';

const args = process.argv.slice(2);
const offline = args.includes('--offline');
const [draft, repo] = args.filter((a) => a !== '--offline');
if (!draft) {
  console.error('Usage: node check-ci.mjs <draft-dir> [repo] [--offline]');
  process.exit(2);
}

const errors = [];
const warnings = [];
const fail = (m) => errors.push(m);
const warn = (m) => warnings.push(m);

function listFiles(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const p = join(dir, entry);
    return statSync(p).isDirectory() ? listFiles(p) : [p];
  });
}

const wfDir = join(draft, '.github/workflows');
const wfFiles = existsSync(wfDir) ? readdirSync(wfDir).filter((f) => /\.ya?ml$/.test(f)).map((f) => join(wfDir, f)) : [];
if (!wfFiles.length) fail(`${relative(draft, wfDir) || wfDir}: no workflow files`);

// --- Workflows --------------------------------------------------------------------------------------------------
const SECRET_PATTERNS = [/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}/, /sk-or-v1-[A-Za-z0-9]{16,}/, /sb_secret_[A-Za-z0-9_-]{10,}/];
const workflows = [];

function triggers(on) {
  if (typeof on === 'string') return { [on]: {} };
  if (Array.isArray(on)) return Object.fromEntries(on.map((t) => [t, {}]));
  return Object.fromEntries(Object.entries(on || {}).map(([k, v]) => [k, v || {}]));
}

for (const file of wfFiles) {
  const name = relative(draft, file);
  const raw = readFileSync(file, 'utf8');
  for (const re of SECRET_PATTERNS) if (re.test(raw)) fail(`${name}: contains what looks like a secret or key (${re.source.slice(0, 12)}...)`);
  let doc;
  try {
    doc = parse(raw);
  } catch (e) {
    fail(`${name}: YAML does not parse: ${e.message.split('\n')[0]}`);
    continue;
  }
  if (!doc || typeof doc !== 'object' || !doc.jobs) {
    fail(`${name}: no jobs`);
    continue;
  }
  const on = triggers(doc.on);
  if (on.pull_request_target) fail(`${name}: uses pull_request_target, which runs PR code with write access and secrets`);
  if (doc.permissions === undefined) fail(`${name}: no top-level permissions block (set least privilege, e.g. contents: read)`);
  if (doc.permissions === 'write-all') fail(`${name}: permissions: write-all`);
  const writes = (p) => (p && typeof p === 'object' ? Object.entries(p).filter(([, v]) => v === 'write').map(([k]) => k) : []);
  for (const k of writes(doc.permissions)) warn(`${name}: top-level permission ${k}: write`);

  for (const [id, job] of Object.entries(doc.jobs)) {
    if (!job.uses && job['timeout-minutes'] === undefined) fail(`${name} job ${id}: no timeout-minutes (a hung step would hold the PR for 6 hours)`);
    if (job.permissions === 'write-all') fail(`${name} job ${id}: permissions: write-all`);
    for (const k of writes(job.permissions)) warn(`${name} job ${id}: permission ${k}: write`);
  }
  for (const m of raw.matchAll(/\$\{\{\s*secrets\.([A-Za-z0-9_]+)/g)) {
    if (m[1] !== 'GITHUB_TOKEN') warn(`${name}: uses secrets.${m[1]}; pull requests from forks will not see it, and the local Supabase stack needs no secrets`);
  }
  workflows.push({ name, raw, doc, on });
}

// --- Action pins ------------------------------------------------------------------------------------------------
const remoteRefs = new Map();
function refsOf(ownerRepo) {
  if (!remoteRefs.has(ownerRepo)) {
    const r = spawnSync('git', ['ls-remote', `https://github.com/${ownerRepo}.git`], {
      encoding: 'utf8', timeout: 30_000, env: { ...process.env, GIT_TERMINAL_PROMPT: '0' },
    });
    remoteRefs.set(ownerRepo, r.status === 0
      ? r.stdout.trim().split('\n').map((l) => l.split('\t')).map(([sha, ref]) => ({ sha, ref }))
      : null);
  }
  return remoteRefs.get(ownerRepo);
}

for (const { name, raw } of workflows) {
  for (const m of raw.matchAll(/^\s*(?:-\s*)?uses:\s*['"]?([^'"\s#]+)['"]?[ \t]*(?:#[ \t]*(\S+))?/gm)) {
    const [, uses, comment] = m;
    if (uses.startsWith('./')) continue;
    if (uses.startsWith('docker://')) {
      if (!uses.includes('@sha256:')) warn(`${name}: ${uses} is not pinned to an image digest`);
      continue;
    }
    const at = uses.lastIndexOf('@');
    if (at < 0) { fail(`${name}: ${uses} has no ref`); continue; }
    const ref = uses.slice(at + 1);
    const ownerRepo = uses.slice(0, at).split('/').slice(0, 2).join('/');
    if (!/^[0-9a-f]{40}$/.test(ref)) {
      fail(`${name}: ${uses} is pinned to "${ref}"; pin to a full commit SHA with the version as a comment (uses: ${ownerRepo}@<sha> # vX.Y.Z)`);
      continue;
    }
    if (offline) { warn(`${name}: ${uses} not verified (--offline)`); continue; }
    const refs = refsOf(ownerRepo);
    if (!refs) { fail(`${name}: could not list refs of github.com/${ownerRepo} (network, or the repository does not exist)`); continue; }
    if (!refs.some((r) => r.sha === ref)) {
      fail(`${name}: ${uses} is not the commit of any tag or branch of ${ownerRepo} (an invented SHA?)`);
      continue;
    }
    if (comment) {
      const tagged = refs.filter((r) => r.ref === `refs/tags/${comment}` || r.ref === `refs/tags/${comment}^{}`).map((r) => r.sha);
      if (!tagged.length) warn(`${name}: ${ownerRepo} has no tag ${comment} (comment on ${uses})`);
      else if (!tagged.includes(ref)) fail(`${name}: ${ownerRepo}@${ref} is commented ${comment}, but tag ${comment} points to ${tagged.at(-1)}`);
    } else {
      warn(`${name}: ${uses} has no version comment`);
    }
  }
}

// --- Ruleset for main -------------------------------------------------------------------------------------------
const rulesetFile = join(draft, '.github/rulesets/main.json');
let required = [];
let mergeQueue = false;
if (!existsSync(rulesetFile)) {
  fail('.github/rulesets/main.json: missing (the ruleset that makes the checks required for main)');
} else {
  let rs;
  try {
    rs = JSON.parse(readFileSync(rulesetFile, 'utf8'));
  } catch (e) {
    fail(`.github/rulesets/main.json: invalid JSON: ${e.message}`);
  }
  if (rs) {
    if (rs.target !== 'branch') fail(`.github/rulesets/main.json: target must be "branch", got ${JSON.stringify(rs.target)}`);
    if (rs.enforcement !== 'active') fail(`.github/rulesets/main.json: enforcement must be "active", got ${JSON.stringify(rs.enforcement)}`);
    const include = rs.conditions?.ref_name?.include || [];
    if (!include.some((r) => r === 'refs/heads/main' || r === '~DEFAULT_BRANCH')) {
      fail('.github/rulesets/main.json: conditions.ref_name.include must contain "refs/heads/main" or "~DEFAULT_BRANCH"');
    }
    const rules = rs.rules || [];
    const types = rules.map((r) => r.type);
    if (!types.includes('pull_request')) fail('.github/rulesets/main.json: no pull_request rule, so changes can reach main without a PR');
    for (const t of ['deletion', 'non_fast_forward']) if (!types.includes(t)) warn(`.github/rulesets/main.json: no ${t} rule`);
    mergeQueue = types.includes('merge_queue');
    const rsc = rules.find((r) => r.type === 'required_status_checks');
    required = (rsc?.parameters?.required_status_checks || []).map((c) => c.context).filter(Boolean);
    if (!required.length) fail('.github/rulesets/main.json: no required_status_checks contexts');
    if (rsc && rsc.parameters?.strict_required_status_checks_policy !== true && !mergeQueue) {
      warn('.github/rulesets/main.json: strict_required_status_checks_policy is not true; a PR can merge on checks that ran against an outdated main');
    }
  }
}

// A job reports a check run named after `name` (or its id). Matrix jobs report "<name> (<values>)", so they cannot
// be required by their plain name.
function prRuns(wf) {
  const pr = wf.on.pull_request;
  if (!pr) return false;
  const branches = pr.branches;
  if (branches && !branches.some((b) => b === 'main' || b === '**' || b === '*')) return false;
  if (pr['branches-ignore']?.includes('main')) return false;
  return true;
}
const prWorkflows = workflows.filter(prRuns);
if (workflows.length && !prWorkflows.length) fail('no workflow runs on pull requests into main');

const checkName = (id, job) => (typeof job.name === 'string' ? job.name : id);
const jobsByCheck = new Map();
for (const wf of prWorkflows) {
  for (const [id, job] of Object.entries(wf.doc.jobs)) jobsByCheck.set(checkName(id, job), { wf, id, job });
}

const requiredWorkflows = new Set();
for (const ctx of required) {
  const hit = jobsByCheck.get(ctx);
  if (!hit) {
    fail(`required check "${ctx}" matches no job name in a workflow that runs on pull requests into main (merges would wait for it forever)`);
    continue;
  }
  const { wf, id, job } = hit;
  requiredWorkflows.add(wf);
  if (job.strategy?.matrix) fail(`required check "${ctx}" (${wf.name} job ${id}) is a matrix job; its check runs are named "${ctx} (...)". Require an aggregating job instead`);
  if (String(job.name || '').includes('${{')) fail(`required check "${ctx}" (${wf.name} job ${id}) has an expression in its name`);
  if (job.needs) {
    const cond = String(job.if ?? '');
    if (!/always\(\)|!\s*cancelled\(\)/.test(cond)) {
      fail(`required check "${ctx}" (${wf.name} job ${id}) has needs but no "if: always()" or "if: \${{ !cancelled() }}"; when a needed job fails it is skipped, and GitHub counts a skipped required check as passing`);
    }
    if (!JSON.stringify(job.steps || []).includes('needs.')) {
      fail(`required check "${ctx}" (${wf.name} job ${id}) never inspects needs.*.result, so it passes even when a needed job failed or was cancelled`);
    }
  }
  if (job.if && !job.needs && !/always\(\)|!\s*cancelled\(\)/.test(String(job.if))) {
    warn(`required check "${ctx}" (${wf.name} job ${id}) has a condition; if it evaluates false the job is skipped and the check counts as passing`);
  }
}

for (const wf of requiredWorkflows) {
  const pr = wf.on.pull_request;
  if (pr.paths || pr['paths-ignore']) {
    fail(`${wf.name}: pull_request has a paths filter; when it does not match, the required checks never report and the PR cannot merge. Filter inside jobs instead`);
  }
  if (mergeQueue && !wf.on.merge_group) fail(`${wf.name}: the ruleset uses a merge queue but the workflow has no merge_group trigger`);
}

// Everything that runs on a PR should be behind a required check, or a failure would not block the merge.
const covered = new Set();
const visit = (wf, id) => {
  const key = `${wf.name}#${id}`;
  if (covered.has(key)) return;
  covered.add(key);
  const needs = wf.doc.jobs[id]?.needs;
  for (const n of needs ? [].concat(needs) : []) visit(wf, n);
};
for (const ctx of required) {
  const hit = jobsByCheck.get(ctx);
  if (hit) visit(hit.wf, hit.id);
}
for (const wf of prWorkflows) {
  for (const [id, job] of Object.entries(wf.doc.jobs)) {
    if (covered.has(`${wf.name}#${id}`)) continue;
    const msg = `${wf.name} job ${id} runs on pull requests but no required check depends on it, so its failure would not block a merge`;
    if (job['continue-on-error'] === true) warn(`${msg} (continue-on-error: true, treated as informational)`);
    else fail(msg);
  }
}

// --- Draft files against the repo -------------------------------------------------------------------------------
if (repo) {
  const files = listFiles(draft).map((f) => relative(draft, f)).filter((f) => !f.split('/').includes('node_modules'));
  const added = [];
  const modified = [];
  for (const f of files) {
    if (f.startsWith('supabase/migrations/')) fail(`${f}: the draft must not add or change migrations (merge gates test the schema, they do not change it)`);
    (existsSync(join(repo, f)) ? modified : added).push(f);
  }

  const pkgAt = (rel) => {
    const p = existsSync(join(draft, rel)) ? join(draft, rel) : join(repo, rel);
    return existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : null;
  };
  const rootScripts = pkgAt('package.json')?.scripts || {};
  const workspaceScripts = new Map();
  for (const group of ['apps', 'packages']) {
    const dir = join(repo, group);
    if (!existsSync(dir)) continue;
    for (const d of readdirSync(dir)) {
      const pkg = pkgAt(`${group}/${d}/package.json`);
      if (pkg?.name) workspaceScripts.set(pkg.name, pkg.scripts || {});
    }
  }
  const BUILTINS = new Set(['install', 'i', 'ci', 'add', 'remove', 'rm', 'update', 'up', 'exec', 'dlx', 'store', 'list', 'ls',
    'why', 'outdated', 'audit', 'rebuild', 'config', 'env', 'setup', 'prune', 'fetch', 'import', 'link', 'unlink', 'pack',
    'publish', 'recursive', 'root', 'bin', 'init', 'licenses', 'patch', 'patch-commit', 'deploy', 'self-update', 'create', 'approve-builds']);
  for (const { name, doc } of workflows) {
    for (const [id, job] of Object.entries(doc.jobs)) {
      for (const step of job.steps || []) {
        if (typeof step.run !== 'string') continue;
        for (const segment of step.run.split(/\n|&&|\|\||;|\|/)) {
          const t = segment.trim().split(/\s+/);
          const at = t.indexOf('pnpm');
          if (at < 0 || (at > 0 && !/^(time|env|[A-Z_]+=\S*)$/.test(t[at - 1]))) continue;
          let rest = t.slice(at + 1);
          let scripts = rootScripts;
          let where = 'package.json';
          if ((rest[0] === '--filter' || rest[0] === '-F') && rest[1]) {
            scripts = workspaceScripts.get(rest[1].replace(/^['"]|['"]$/g, ''));
            where = `${rest[1]}/package.json`;
            if (!scripts) { warn(`${name} job ${id}: pnpm --filter ${rest[1]}: no workspace package with that name`); continue; }
            rest = rest.slice(2);
          }
          if (rest[0] === 'run') rest = rest.slice(1);
          const script = rest[0];
          if (!script || script.startsWith('-') || script.startsWith('$') || BUILTINS.has(script)) continue;
          if (!(script in scripts)) fail(`${name} job ${id}: runs "pnpm ${script}", but ${where} has no "${script}" script`);
        }
      }
    }
  }
  console.log(`Draft adds ${added.length} file(s) and changes ${modified.length} existing file(s) in ${repo}`);
  for (const f of modified) console.log(`  changes ${f}`);
}

// --- actionlint -------------------------------------------------------------------------------------------------
if (wfFiles.length) {
  const rels = wfFiles.map((f) => relative(draft, f));
  let r = spawnSync('actionlint', ['-no-color', '-oneline', ...rels], { cwd: draft, encoding: 'utf8' });
  let ran = !r.error;
  if (!ran && !offline) {
    r = spawnSync('docker', ['run', '--rm', '-v', `${resolve(draft)}:/repo`, '-w', '/repo', 'rhysd/actionlint:latest', '-no-color', '-oneline', ...rels],
      { encoding: 'utf8', timeout: 180_000 });
    ran = !r.error && r.status !== 125 && !/Cannot connect to the Docker daemon|connect to the docker API/i.test(r.stderr || '');
  }
  if (!ran) warn('actionlint not run (install it with `brew install actionlint`, or start Docker)');
  else if (r.status !== 0) for (const line of `${r.stdout}${r.stderr}`.trim().split('\n').filter(Boolean)) fail(`actionlint: ${line}`);
}

for (const w of warnings) console.log(`warn ${w}`);
for (const e of errors) console.log(`FAIL ${e}`);
if (errors.length) {
  console.log(`\n${errors.length} problem(s)`);
  process.exit(1);
}
console.log(`\nOK: ${wfFiles.length} workflow(s), ${required.length} required check(s) for main: ${required.join(', ')}`);
