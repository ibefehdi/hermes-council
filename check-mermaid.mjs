// Usage: node check-mermaid.mjs <file.md> [more.md ...]
// Parses every ```mermaid block with the real Mermaid parser and reports blocks that would not render.
import { chromium } from 'playwright';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));
const MERMAID_JS = join(DIR, 'node_modules/mermaid/dist/mermaid.min.js');
const files = process.argv.slice(2);
if (!files.length) {
  console.error('Usage: node check-mermaid.mjs <file.md> [more.md ...]');
  process.exit(2);
}

const blocks = [];
for (const file of files) {
  if (!existsSync(file)) {
    console.error(`Missing file: ${file}`);
    process.exit(2);
  }
  const lines = readFileSync(file, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() !== '```mermaid') continue;
    const start = i + 1;
    let end = start;
    while (end < lines.length && lines[end].trim() !== '```') end++;
    blocks.push({ file, line: start + 1, code: lines.slice(start, end).join('\n') });
    i = end;
  }
}

if (!blocks.length) {
  console.log('OK: no mermaid blocks found');
  process.exit(0);
}

const browser = await chromium.launch({ channel: 'chrome' }).catch(() => chromium.launch());
const page = await browser.newPage();
await page.setContent('<html><body></body></html>');
await page.addScriptTag({ path: MERMAID_JS });
await page.evaluate(() => window.mermaid.initialize({ startOnLoad: false }));

let failures = 0;
for (const b of blocks) {
  const error = await page.evaluate(async (code) => {
    try {
      await window.mermaid.parse(code);
      return null;
    } catch (e) {
      return String(e?.message || e).split('\n').slice(0, 4).join(' | ');
    }
  }, b.code);
  if (error) {
    failures++;
    console.log(`FAIL ${b.file}:${b.line}  ${error}`);
  }
}
await browser.close();

if (failures) {
  console.log(`${failures} of ${blocks.length} mermaid diagram(s) failed to parse`);
  process.exit(1);
}
console.log(`OK: ${blocks.length} mermaid diagram(s) parsed`);
