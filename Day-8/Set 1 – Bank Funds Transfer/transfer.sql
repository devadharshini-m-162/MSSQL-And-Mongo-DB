CREATE TABLE #Accounts
(
    AccountId int NOT NULL PRIMARY KEY,
    Status varchar(12) NOT NULL,
    Balance decimal(12, 2) NOT NULL
);
CREATE TABLE #Ledger
(
    EntryId int IDENTITY PRIMARY KEY,
    TransferId uniqueidentifier NOT NULL,
    AccountId int NOT NULL,
    EntryType varchar(12) NOT NULL,
    Amount decimal(12, 2) NOT NULL,
    CreatedAt datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);

INSERT INTO #Accounts (AccountId, Status, Balance)
VALUES (101, 'ACTIVE', 1000.00), (202, 'ACTIVE', 500.00);

DECLARE @FromAccount int = 101,
        @ToAccount int = 202,
        @Amount decimal(12, 2) = 125.00,
        @Fee decimal(12, 2) = 5.00,
        @TransferId uniqueidentifier = NEWID(),
        @BeforeFrom decimal(12, 2),
        @BeforeTo decimal(12, 2);

SELECT @BeforeFrom = Balance FROM #Accounts WHERE AccountId = @FromAccount;
SELECT @BeforeTo = Balance FROM #Accounts WHERE AccountId = @ToAccount;

PRINT 'Deliberate failure after debit; both account balances must be restored.';
BEGIN TRY
    BEGIN TRANSACTION;

    IF @Amount <= 0
    BEGIN
        THROW 51001, 'Transfer amount must be positive.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM #Accounts WHERE AccountId = @FromAccount AND Status = 'ACTIVE')
    BEGIN
        THROW 51002, 'Source account is missing or inactive.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM #Accounts WHERE AccountId = @ToAccount AND Status = 'ACTIVE')
    BEGIN
        THROW 51003, 'Destination account is missing or inactive.', 1;
    END;
    IF (SELECT Balance FROM #Accounts WITH (UPDLOCK, HOLDLOCK) WHERE AccountId = @FromAccount) < @Amount
    BEGIN
        THROW 51004, 'Insufficient funds.', 1;
    END;

    UPDATE #Accounts
    SET Balance = Balance - @Amount
    WHERE AccountId = @FromAccount AND Status = 'ACTIVE' AND Balance >= @Amount;
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 51005, 'Debit failed; account status or balance changed.', 1;
    END;

    ;THROW 51006, 'Injected failure after debit for rollback demonstration.', 1;

    UPDATE #Accounts SET Balance = Balance + @Amount WHERE AccountId = @ToAccount;
    INSERT INTO #Ledger (TransferId, AccountId, EntryType, Amount)
    VALUES (@TransferId, @FromAccount, 'DEBIT', -@Amount),
           (@TransferId, @ToAccount, 'CREDIT', @Amount);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    PRINT CONCAT('Caught expected error: ', ERROR_MESSAGE());
END CATCH;

SELECT @BeforeFrom AS SourceBefore,
       source.Balance AS SourceAfterRollback,
       @BeforeTo AS DestinationBefore,
       destination.Balance AS DestinationAfterRollback,
       CASE WHEN source.Balance = @BeforeFrom AND destination.Balance = @BeforeTo
            THEN 'PASS: rollback restored both balances'
            ELSE 'FAIL: balances differ' END AS RollbackEvidence
FROM #Accounts AS source
CROSS JOIN #Accounts AS destination
WHERE source.AccountId = @FromAccount AND destination.AccountId = @ToAccount;
SELECT COUNT(*) AS LedgerRowsAfterFailedTransfer FROM #Ledger;

PRINT 'Successful transfer; savepoint removes the optional fee only.';
SET @TransferId = NEWID();
BEGIN TRY
    BEGIN TRANSACTION;

    IF @Amount <= 0
    BEGIN
        THROW 51011, 'Transfer amount must be positive.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM #Accounts WHERE AccountId = @FromAccount AND Status = 'ACTIVE')
    BEGIN
        THROW 51012, 'Source account is missing or inactive.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM #Accounts WHERE AccountId = @ToAccount AND Status = 'ACTIVE')
    BEGIN
        THROW 51013, 'Destination account is missing or inactive.', 1;
    END;
    IF (SELECT Balance FROM #Accounts WITH (UPDLOCK, HOLDLOCK) WHERE AccountId = @FromAccount) < @Amount
    BEGIN
        THROW 51014, 'Insufficient funds.', 1;
    END;

    UPDATE #Accounts
    SET Balance = Balance - @Amount
    WHERE AccountId = @FromAccount AND Status = 'ACTIVE' AND Balance >= @Amount;
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 51015, 'Debit failed; account status or balance changed.', 1;
    END;

    UPDATE #Accounts
    SET Balance = Balance + @Amount
    WHERE AccountId = @ToAccount AND Status = 'ACTIVE';
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 51016, 'Credit failed; destination account is not active.', 1;
    END;

    INSERT INTO #Ledger (TransferId, AccountId, EntryType, Amount)
    VALUES (@TransferId, @FromAccount, 'DEBIT', -@Amount),
           (@TransferId, @ToAccount, 'CREDIT', @Amount);

    SAVE TRANSACTION FeePosting;
    UPDATE #Accounts SET Balance = Balance - @Fee WHERE AccountId = @FromAccount;
    -- Simulate fee-posting rejection; undo only work after the savepoint.
    ROLLBACK TRANSACTION FeePosting;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() = 1
        ROLLBACK TRANSACTION;
    ELSE IF XACT_STATE() = -1
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT AccountId, Status, Balance FROM #Accounts ORDER BY AccountId;
SELECT TransferId, AccountId, EntryType, Amount FROM #Ledger ORDER BY EntryId;
-- Expected final balances: account 101 = 875.00; account 202 = 625.00.
-- Expected ledger rows: one debit -125.00 and one credit +125.00; no fee row.
