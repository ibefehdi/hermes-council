# Brief: Create and edit flows (linker)

Output: /Users/fahad/council/output/technical/flows.md

Exercise the main create/edit flows end to end with COUNCIL-TEST data, capture the exact API sequence, and prove where each record propagates.

Flows (in this order, since later ones reuse earlier records):

1. Client: create (fake contact details), edit, add a note; inspect every profile tab.
2. Service: create a COUNCIL-TEST service (category, duration, price, team assignment), edit price.
3. Product and stock: create a COUNCIL-TEST supplier and product, adjust stock, create a stock order (do not send it to a real supplier email).
4. Team member: create a COUNCIL-TEST team member with services and a shift. If the UI says this changes billing or subscription cost, stop and document instead.
5. Appointment: book the COUNCIL-TEST client for the COUNCIL-TEST service with a team member; edit time/service; reschedule by drag or edit; add a note; then check out with a cash/other manual payment type (never a card terminal or payment link). Also create a second appointment and cancel it with a reason; mark a third as no-show if available.
6. Sale without appointment: quick sale of the COUNCIL-TEST product, manual payment.
7. Promotion: create a COUNCIL-TEST deal/discount; create a blast campaign DRAFT only (never send/schedule); inspect automations without enabling sending.

For each flow:

- Steps and every form field (label, type, required, validation). Submit once with required fields empty to capture validation messages.
- The API calls in order (method, path/operation, request field names, response field names, status).
- Resulting state and where the record now appears (calendar, client history, sales list, payments, daily sales, stock levels, reports, dashboard widgets). Check each place and record yes/no with evidence.
- A sequenceDiagram (actor -> UI -> API endpoints) per flow.

Also produce stateDiagram-v2 lifecycles for: appointment (booked, confirmed, arrived, started, completed, cancelled, no-show, ...), sale/invoice and payment, stock order. Only include states you observed or the UI exposes.

Log every record in test-records.md as you create it.

Sections of flows.md: one section per flow, Propagation matrix (record x page), Lifecycles, Validation rules summary.
