# Brief: Setup and Settings (cartographer)

Output: {{COUNCIL_DIR}}/output/technical/settings.md

The first survey mapped Setup as a single page. Map every settings sub-page.

1. Open /setup and enumerate every section and link (business details, locations, resources, sales/payment settings, taxes, receipts, service charges, gift card and membership settings, client settings such as cancellation reasons and referral sources, team settings and permissions, online booking settings, notifications, forms, integrations, billing, etc.). Follow nested pages, tabs, and modals.
2. For each settings page: route, purpose, every field (label, type, options, current value class not personal values, required, validation), save behaviour, API calls on load and on save.
3. For each settings page, document what it affects elsewhere in the product (e.g. a tax setting changes checkout totals; a cancellation reason appears in the appointment cancel dialog). Verify at least the important ones by looking at the affected page.
4. Make one safe, additive COUNCIL-TEST edit wherever the page supports it (e.g. add a COUNCIL-TEST cancellation reason, referral source, payment type, resource) to capture the create/update API payload, then confirm where it appears. Revert toggles you change. Log everything in test-records.md.
5. Diagrams: a flowchart of the settings tree, and a flowchart "settings -> affected features".

Sections of settings.md: Settings tree, one section per settings page (fields table, API calls, affects), Safe edits performed, Diagrams, Gated/unavailable settings.
