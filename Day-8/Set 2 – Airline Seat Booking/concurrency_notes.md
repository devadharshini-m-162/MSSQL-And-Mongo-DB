# Airline booking concurrency notes

The seat row is the serialization point. The SQL booking transaction uses `UPDLOCK, HOLDLOCK`, changes the status only from `AVAILABLE`, and inserts the booking in the same transaction. The composite primary key on `(FlightId, SeatNo)` and unique booking constraint protect data integrity even if a caller has a bug.

## Expected two-session outcome

| Isolation mode | Typical observation | Correctness guard |
|---|---|---|
| READ COMMITTED | Both sessions can read `AVAILABLE` before either update. The first conditional update obtains the write lock; the other waits and then affects zero rows after the winner commits. | Conditional `UPDATE ... WHERE SeatStatus='AVAILABLE'`, row-count check, unique constraints |
| SERIALIZABLE | The first session retains locks protecting the seat predicate. The second session blocks at the read or write, then observes `BOOKED` after the first commits. | Predicate/row locks plus the same conditional update and unique constraints |

Use the two-session schedule in `booking_transaction.sql`. Run one booking at a time against the same sample seat and reset it to `AVAILABLE` between isolation tests. Exactly one booking should commit. Production code should handle duplicate-key and deadlock errors as failed/retryable requests rather than reporting a successful booking.

In a local SQL Server 2025 run, READ COMMITTED allowed both sessions to initially read `AVAILABLE`; one conditional update succeeded, the other returned `Seat already booked`, and the final booking count was one. Under SERIALIZABLE with `UPDLOCK, HOLDLOCK`, one session acquired the seat lock first and the other proceeded only after the seat was booked; the final count was also one. Which passenger wins depends on scheduling and is not guaranteed by the isolation level.

For the MongoDB shell example, seed one available seat document before running:

```javascript
db.seats.updateOne(
  { flightId: "HX101", seatNo: "12A" },
  { $setOnInsert: { status: "AVAILABLE" } },
  { upsert: true }
);
```

The script creates the unique booking index outside the transaction. Run it with `mongosh` against a replica set or sharded cluster. Re-running it for an already-booked seat should report a failed booking, not a second reservation.

The ranked report uses fares in descending order. For `HX101`, tied fares produce `RANK` values `1, 2, 2, 4` and `DENSE_RANK` values `1, 2, 2, 3`. The running revenue window has a passenger-ID tiebreaker to make the row-by-row accumulation deterministic.
