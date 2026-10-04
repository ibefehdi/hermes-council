# Brief: Architecture pass 2 (linker)

Read /Users/fahad/council/output/technical/briefs/common.md and architecture.md first.

The first architecture pass wrote /Users/fahad/council/output/technical/architecture.md but only visited 7 pages and left 31 items UNVERIFIED. The brief requires every page.

1. Keep every existing section of architecture.md. Extend and correct it; do not rewrite it from scratch. If you correct something, say what changed.
2. Visit EVERY page in /Users/fahad/council/output/pages.json (41 pages), plus the settings and report pages documented in settings.md and reports.md in the same folder. On each page call browser_network_requests (and browser_network_request for the important calls) and record what the page loads.
3. Append a section "Per-page API map": one subsection per page with route, the API calls it makes (method, normalized path or GraphQL operation, purpose), the entities involved, and its outgoing links/actions.
4. Complete the "Page connectivity" adjacency table so every page has its outgoing and incoming edges, and update the navigation flowchart.
5. Add every endpoint you find to the API catalogue table, and every newly observed entity field to the data model and diagrams.
6. Resolve each UNVERIFIED item in architecture.md: CONFIRMED / WRONG / STILL UNVERIFIED, with evidence.
7. Validate with `node /Users/fahad/council/check-mermaid.mjs /Users/fahad/council/output/technical/architecture.md` until OK.

Write incrementally (append per page) so progress survives a crash.
