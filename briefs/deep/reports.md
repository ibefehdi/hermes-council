# Brief: Reports (cartographer)

Output: {{COUNCIL_DIR}}/output/technical/reports.md

The first survey mapped Reports as a single page. Map every report.

1. Open the reports area and enumerate every category/report group and every report in each (including favourites, standard, premium/gated).
2. For each report: name, category, purpose, route, filters (date range, location, team member, etc.), grouping options, columns/metrics with what each means, charts, drill-downs (where clicking a row leads), export formats, scheduling/email options, the API call(s) that load the data (method, path/operation, key params, response field names).
3. For each report, name the source entities and the features that feed it (e.g. "Sales summary" <- checkout/sales; "Appointments summary" <- calendar bookings). Note gated reports and what the gate says.
4. Diagrams: a flowchart "entities/features -> reports", and a classDiagram of the reporting model if the API reveals one.

Sections of reports.md: Report catalogue table (name, category, gated, export), one section per report, Data lineage, Diagrams.
