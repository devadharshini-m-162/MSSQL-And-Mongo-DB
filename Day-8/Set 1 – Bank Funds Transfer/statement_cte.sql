WITH StatementRows AS
(
    SELECT
        t.AccountId,
        t.TransactionId,
        t.TransactionDate,
        t.Amount,
        a.OpeningBalance
    FROM (VALUES
        (101, 1001, CONVERT(datetime2(0), '2025-01-03T09:00:00'), CONVERT(decimal(12,2), -80.00)),
        (101, 1002, CONVERT(datetime2(0), '2025-01-05T13:15:00'), CONVERT(decimal(12,2), 250.00)),
        (101, 1003, CONVERT(datetime2(0), '2025-01-11T08:30:00'), CONVERT(decimal(12,2), -125.00)),
        (101, 1004, CONVERT(datetime2(0), '2025-01-18T16:45:00'), CONVERT(decimal(12,2), -25.00))
    ) AS t(AccountId, TransactionId, TransactionDate, Amount)
    JOIN (VALUES (101, CONVERT(decimal(12,2), 1000.00))) AS a(AccountId, OpeningBalance)
      ON a.AccountId = t.AccountId
),
Balances AS
(
    SELECT
        AccountId,
        TransactionId,
        TransactionDate,
        Amount,
        OpeningBalance + SUM(Amount) OVER
        (
            PARTITION BY AccountId
            ORDER BY TransactionDate, TransactionId
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS BalanceAfter
    FROM StatementRows
)
SELECT
    AccountId,
    TransactionId,
    TransactionDate,
    Amount,
    BalanceAfter,
    LAG(BalanceAfter, 1, CONVERT(decimal(12,2), 1000.00)) OVER
    (
        PARTITION BY AccountId
        ORDER BY TransactionDate, TransactionId
    ) AS PreviousBalance,
    ROW_NUMBER() OVER
    (
        PARTITION BY AccountId
        ORDER BY TransactionDate, TransactionId
    ) AS StatementRow
FROM Balances
ORDER BY AccountId, TransactionDate, TransactionId;
