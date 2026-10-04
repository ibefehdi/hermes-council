// Usage: node check-skills.mjs <skills-root>
// <skills-root> contains .cursor/skills/<name>/ and .claude/skills/<name>/ trees that must be identical.
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = process.argv[2];
if (!root) {
  console.error('Usage: node check-skills.mjs <skills-root>');
  process.exit(2);
}

const trees = ['.cursor/skills', '.claude/skills'].map((t) => join(root, t));
const errors = [];

function listFiles(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const p = join(dir, entry);
    return statSync(p).isDirectory() ? listFiles(p) : [p];
  });
}

function checkSkill(dir, name) {
  const file = join(dir, 'SKILL.md');
  if (!existsSync(file)) return errors.push(`${dir}: missing SKILL.md`);
  const text = readFileSync(file, 'utf8');
  const m = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!m) return errors.push(`${file}: missing YAML frontmatter`);
  const [, fm, body] = m;
  const field = (key) => {
    const block = fm.match(new RegExp(`^${key}:\\s*(>-?|\\|-?)?\\s*\\n((?:[ \\t]+.*\\n?)+)`, 'm'));
    if (block) return block[2].replace(/\s+/g, ' ').trim();
    const line = fm.match(new RegExp(`^${key}:\\s*(.*)$`, 'm'));
    return line ? line[1].trim().replace(/^['"]|['"]$/g, '') : '';
  };
  const skillName = field('name');
  const description = field('description');
  if (!/^[a-z0-9-]{1,64}$/.test(skillName)) errors.push(`${file}: name "${skillName}" must be lowercase letters/digits/hyphens, max 64`);
  if (skillName !== name) errors.push(`${file}: name "${skillName}" must equal folder name "${name}"`);
  if (!description) errors.push(`${file}: description is empty`);
  if (description.length > 1024) errors.push(`${file}: description is ${description.length} chars (max 1024)`);
  const lines = body.split('\n').length;
  if (lines >= 500) errors.push(`${file}: body is ${lines} lines (keep under 500)`);
}

for (const tree of trees) {
  if (!existsSync(tree)) {
    errors.push(`missing ${tree}`);
    continue;
  }
  for (const name of readdirSync(tree)) {
    const dir = join(tree, name);
    if (statSync(dir).isDirectory()) checkSkill(dir, name);
  }
}

if (trees.every(existsSync)) {
  const [a, b] = trees.map((t) => new Map(listFiles(t).map((f) => [relative(t, f), readFileSync(f, 'utf8')])));
  for (const [rel, content] of a) {
    if (!b.has(rel)) errors.push(`.claude/skills/${rel} missing (exists in .cursor)`);
    else if (b.get(rel) !== content) errors.push(`${rel} differs between .cursor and .claude`);
  }
  for (const rel of b.keys()) if (!a.has(rel)) errors.push(`.cursor/skills/${rel} missing (exists in .claude)`);
}

if (errors.length) {
  for (const e of errors) console.log(`FAIL ${e}`);
  process.exit(1);
}
const count = existsSync(trees[0]) ? readdirSync(trees[0]).length : 0;
console.log(`OK: ${count} skill(s), .cursor and .claude copies identical`);
