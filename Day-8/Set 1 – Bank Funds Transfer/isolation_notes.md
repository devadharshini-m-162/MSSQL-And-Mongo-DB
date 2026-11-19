# Bank transfer isolation notes

## READ COMMITTED

SQL Server's default `READ COMMITTED` isolation prevents dirty reads. Shared locks used to read a row are normally released at the end of the statement, so a later statement in the same transaction can observe a newer committed value (non-repeatable read). With `READ_COMMITTED_SNAPSHOT` enabled at the database level, reads instead use row versions as of each statement's start; that is still different from transaction-level `SNAPSHOT`.

For a transfer, checking the source balance in one statement and debiting it later without a lock or conditional update is unsafe. The transfer script protects the critical check with `UPDLOCK, HOLDLOCK` and performs a conditional debit inside the same transaction. Both account updates and ledger rows commit together or roll back together.

Use this setup in a disposable test database before the two-session examples:

```sql
IF OBJECT_ID('dbo.Day8IsolationAccounts', 'U') IS NULL
    CREATE TABLE dbo.Day8IsolationAccounts
    (
        AccountId int NOT NULL PRIMARY KEY,
        Balance decimal(12,2) NOT NULL
    );
IF NOT EXISTS (SELECT 1 FROM dbo.Day8IsolationAccounts WHERE AccountId = 101)
    INSERT dbo.Day8IsolationAccounts VALUES (101, 1000.00);
```

### READ COMMITTED two-session example

Run Session A, then run Session B during its delay:

```sql
-- Session A
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
SELECT Balance FROM dbo.Day8IsolationAccounts WHERE AccountId = 101;
WAITFOR DELAY '00:00:10';
SELECT Balance FROM dbo.Day8IsolationAccounts WHERE AccountId = 101;
COMMIT;
```

```sql
-- Session B
UPDATE dbo.Day8IsolationAccounts
SET Balance = Balance - 10
WHERE AccountId = 101;
```

Under lock-based READ COMMITTED, Session A's second SELECT sees Session B's committed balance. When `READ_COMMITTED_SNAPSHOT` is enabled, each statement reads a consistent version as of that statement's start; the second statement still sees Session B's committed change.

## SNAPSHOT

Enable once in a test database (requires exclusive access while changing the setting):

```sql
ALTER DATABASE YourTestDatabase SET ALLOW_SNAPSHOT_ISOLATION ON;
```

Repeat the two-session schedule with Session A using `SET TRANSACTION ISOLATION LEVEL SNAPSHOT` instead of READ COMMITTED. Session A's second SELECT continues to return the transaction-start version, even though Session B commits the update during the delay. If both transactions update the same row, SQL Server can abort one with an update conflict; callers must retry the whole transaction.

## MongoDB multi-document transfer

`transactions.js` uses MongoDB shell commands to update the source and destination account documents in one session transaction. Both updates are conditional on account status and sufficient funds. Balances use integer cents to avoid floating-point currency arithmetic. If either account update fails or an error occurs, the catch block aborts the transaction so the transfer does not partially commit.

Seed the documents in the configured database before running:

```javascript
db.accounts.updateOne(
  { accountId: "A-101" },
  { $setOnInsert: { status: "ACTIVE", balanceCents: 100000 } },
  { upsert: true }
);
db.accounts.updateOne(
  { accountId: "A-202" },
  { $setOnInsert: { status: "ACTIVE", balanceCents: 50000 } },
  { upsert: true }
);
```

Transactions cost more than single-document writes: they require a replica set or sharded cluster, hold transaction state and locks/resources longer, add coordination/commit work, and can increase latency and contention. Use one only when atomicity across documents is required. Run the file with `mongosh`; it selects `BankTransferMongoDB`.
