# Brief: Flows pass 2 (linker)

Read /Users/fahad/council/output/technical/briefs/common.md first, then flows.md (the brief) and the existing /Users/fahad/council/output/technical/flows.md and test-records.md.

The first flows pass created COUNCIL-TEST Client1 (ID 301303785), COUNCIL-TEST Service1, COUNCIL-TEST Product1, COUNCIL-TEST Supplier1, and an appointment on Mon 5 Oct 10:00 for Client1 + Service1. These records exist (the Clients list shows 4 clients including COUNCIL-TEST Client1). It skipped the checkout and the quick sale, and the product and supplier creation evidence is only inferred.

Do this, appending to flows.md (keep existing content; mark what changed) and logging records in test-records.md:

1. Checkout the Mon 5 Oct COUNCIL-TEST appointment using a manual payment type such as Cash or Other. A cash/manual payment is explicitly allowed; never use a card terminal, card on file, or payment link. Do not send a receipt to a real address (the client email is council-test+1@example.com). Capture every API call in order and the resulting sale/invoice ID.
2. Quick sale: sell COUNCIL-TEST Product1 (or COUNCIL-TEST Service1 if the product is not sellable) with a cash/manual payment. Capture the API sequence.
3. Product and supplier: open COUNCIL-TEST Product1 and COUNCIL-TEST Supplier1, make a small edit to each (e.g. description), and capture the real mutation/endpoint so the inferred entries become evidenced.
4. Cancellation: create a second COUNCIL-TEST appointment and cancel it using the "COUNCIL-TEST cancellation reason" that the settings pass added.
5. Propagation: for the checkout and the quick sale, check and record yes/no with evidence in Sales list, Payments/transactions, Daily sales summary, the client's profile history, the Dashboard widgets, and the relevant reports (Sales summary, Payments summary, etc.). Update the propagation matrix.
6. Add sequenceDiagrams for checkout and quick sale, and update the sale/payment stateDiagram-v2 with the states you observed. Validate with `node /Users/fahad/council/check-mermaid.mjs /Users/fahad/council/output/technical/flows.md`.
