# Skill format (Cursor and Claude Code)

Both tools use the same skill format, so one SKILL.md works in both:

```
.cursor/skills/<skill-name>/SKILL.md
.claude/skills/<skill-name>/SKILL.md
```

A skill folder may also contain one level of supporting files (reference.md, examples.md, templates) linked from SKILL.md.

## SKILL.md

```markdown
---
name: skill-name
description: Third-person description of WHAT the skill covers and WHEN to apply it, with trigger terms.
---

# Title

## Quick start / rules
...
## Examples
...
## Additional resources
- [reference.md](reference.md)
```

Rules:

- `name`: lowercase letters, digits, and hyphens only, max 64 characters, equal to the folder name.
- `description`: non-empty, max 1024 characters, third person, includes both what and when, with concrete trigger terms (file types, folders, tasks). These are convention skills that should load automatically, so do not add `disable-model-invocation`.
- Body under 500 lines. Put long reference material in a linked file one level deep.
- Be concise and prescriptive: one default per concern with a short escape hatch, not a menu of options. Assume the reader is a capable engineer; include only project-specific rules.
- Use concrete examples from this project (real table names, function names, folder paths), and consistent terminology.
- No time-sensitive statements.

Validate with `node {{COUNCIL_DIR}}/check-skills.mjs {{COUNCIL_DIR}}/output/plan/skills`.
