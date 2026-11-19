# Retail inventory reservation notes

## SQL transaction

`reservation.sql` locks the requested product rows while validating stock, decrements all requested products, inserts the order header and lines, and commits them as one unit. If stock is missing or insufficient, `THROW` transfers control to `CATCH`, which rolls back. The script prints before/after stock to make the failed reservation evidence explicit. It then simulates payment failure and compensates by restoring the reserved quantities and marking the order `PAYMENT_FAILED`. In production, coordinate payment authorization and reservation expiry or use an outbox/saga because an external payment provider cannot join the database transaction.

## MongoDB atomicity choice

The supplied `stock_update.js` changes one product document using a conditional filter (`stock >= quantity`) and `$inc`. Single-document writes are atomic, so concurrent reservations cannot both decrement below zero when every writer uses this condition. No multi-document transaction is needed for this isolated stock decrement.

Seed a product in the configured database before running the script:

```javascript
db.products.updateOne(
  { productId: "SKU-1001" },
  { $setOnInsert: { stock: 12 } },
  { upsert: true }
);
```

The sample uses product `SKU-1001` and reserves two units. Change `productId` or `quantityToReserve` in the shell file to try other values.

Use a MongoDB multi-document transaction when the order document, multiple product documents, inventory reservation record, and any same-database payment state must be committed or aborted together. Transactions require a replica set or sharded cluster and add coordination, latency, and resource overhead. For an order containing several product documents, use a transaction or a reservation/outbox workflow; a single-document atomic update cannot guarantee all products change together.

`rank_report.sql` uses `ROW_NUMBER() PARTITION BY CategoryId` to return at most three products per category. `sales_trend.sql` uses `LAG` and `LEAD` over each product's chronological monthly aggregates; a missing calendar month is not synthesized in this sample.
