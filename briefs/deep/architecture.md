# Brief: Technical architecture, API, data model, page connectivity (linker)

Output: {{COUNCIL_DIR}}/output/technical/architecture.md

Revisit every page in output/pages.json (plus any new pages you find) to build the technical picture of the whole application. Do not finish until every page in pages.json has its own entry in a "Per-page API map" section (route, API calls with method and path/operation, entities, outgoing links), based on network requests you captured on that page in this pass, not on the survey files.

1. Page connectivity: for EVERY page, list all outgoing navigation (links, buttons, menu items, row clicks, drawers) and incoming routes. Produce a full adjacency list table (from page | to page | trigger | type: navigate / drawer / modal / redirect) and a flowchart grouped by module.
2. API catalogue: capture the network calls on every page. One table row per endpoint: method, normalized path or GraphQL operation, API style (REST/GraphQL/RPC), purpose, pages that call it, entity, key request params, key response fields. Identify API hosts/base URLs and versioning.
3. Data model: from UI fields and response payloads, define each entity (Appointment, Client, Service, ServiceCategory, Product, Supplier, StockOrder, TeamMember, Shift, Sale, Payment, GiftCard, Membership, Package, Deal, Campaign, Location, Resource, ...) with fields, types, IDs, and relationships with cardinality. Produce a classDiagram and an erDiagram.
4. Frontend and platform: framework and routing (inspect window globals, script/asset names, meta tags via browser_evaluate, never secrets), SPA vs server navigation, auth mechanism (cookie vs bearer: names only, never values), realtime channels (WebSockets/SSE), feature-flag or experiment systems, third-party services loaded (analytics, payments, maps, support chat, error tracking), localisation, caching.
5. A component diagram as a flowchart: browser app modules <-> API services/hosts <-> third parties.

Sections of architecture.md: Platform and stack, API hosts and catalogue, Data model (diagrams + entity tables), Page connectivity (adjacency table + diagram), Component diagram, Third parties, Open questions.
