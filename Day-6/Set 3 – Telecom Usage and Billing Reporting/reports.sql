USE TelecomBillingDB;

DECLARE @AsOfDate date = '2026-11-18';

-- 1. Total call minutes per plan.
SELECT pl.PlanID, pl.PlanName, SUM(cr.CallMinutes) AS TotalCallMinutes
FROM dbo.Plans AS pl
JOIN dbo.Subscribers AS s ON s.PlanID = pl.PlanID
JOIN dbo.Call_Records AS cr ON cr.SubscriberID = s.SubscriberID
GROUP BY pl.PlanID, pl.PlanName
ORDER BY TotalCallMinutes DESC;

-- 2. Subscribers exceeding their data limit.
SELECT
    s.SubscriberID,
    s.SubscriberName,
    pl.PlanName,
    pl.DataLimitMB,
    SUM(du.UsageMB) AS UsedMB
FROM dbo.Subscribers AS s
JOIN dbo.Plans AS pl ON pl.PlanID = s.PlanID
JOIN dbo.Data_Usage AS du ON du.SubscriberID = s.SubscriberID
GROUP BY s.SubscriberID, s.SubscriberName, pl.PlanName, pl.DataLimitMB
HAVING SUM(du.UsageMB) > pl.DataLimitMB
ORDER BY UsedMB DESC;

-- 3. Month-wise revenue.
SELECT
    DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) AS InvoiceMonth,
    ROUND(SUM(Amount), 2) AS Revenue
FROM dbo.Invoices
GROUP BY DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1)
ORDER BY InvoiceMonth;

-- 4. Invoices overdue by more than 15 days.
SELECT
    CONCAT('INV-', FORMAT(i.InvoiceID, '000000')) AS FormattedInvoiceNumber,
    s.SubscriberName,
    i.DueDate,
    DATEDIFF(DAY, i.DueDate, @AsOfDate) AS DaysOverdue,
    CASE
        WHEN i.PaidDate IS NOT NULL THEN 'Paid'
        WHEN DATEDIFF(DAY, i.DueDate, @AsOfDate) > 15 THEN 'Overdue'
        ELSE 'Due'
    END AS DueDateStatus,
    i.Amount
FROM dbo.Invoices AS i
JOIN dbo.Subscribers AS s ON s.SubscriberID = i.SubscriberID
WHERE i.PaidDate IS NULL
  AND DATEDIFF(DAY, i.DueDate, @AsOfDate) > 15
ORDER BY i.DueDate;

-- 5. Subscribers with no usage rows.
SELECT s.SubscriberID, s.SubscriberName, s.Circle
FROM dbo.Subscribers AS s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Call_Records AS cr
    WHERE cr.SubscriberID = s.SubscriberID
)
AND NOT EXISTS (
    SELECT 1 FROM dbo.Data_Usage AS du
    WHERE du.SubscriberID = s.SubscriberID
)
ORDER BY s.SubscriberName;

-- 6. Average revenue per user (ARPU) by circle.
SELECT
    s.Circle,
    ROUND(SUM(i.Amount) / NULLIF(COUNT(DISTINCT s.SubscriberID), 0), 2) AS ARPU
FROM dbo.Subscribers AS s
JOIN dbo.Invoices AS i ON i.SubscriberID = s.SubscriberID
GROUP BY s.Circle
ORDER BY s.Circle;

-- 7. Plan popularity.
SELECT pl.PlanID, pl.PlanName, COUNT(s.SubscriberID) AS SubscriberCount
FROM dbo.Plans AS pl
LEFT JOIN dbo.Subscribers AS s ON s.PlanID = pl.PlanID
GROUP BY pl.PlanID, pl.PlanName
ORDER BY SubscriberCount DESC, pl.PlanName;

-- 8. Top ten data consumers.
SELECT TOP (10)
    s.SubscriberID,
    s.SubscriberName,
    SUM(du.UsageMB) AS TotalUsageMB
FROM dbo.Subscribers AS s
JOIN dbo.Data_Usage AS du ON du.SubscriberID = s.SubscriberID
GROUP BY s.SubscriberID, s.SubscriberName
ORDER BY TotalUsageMB DESC, s.SubscriberName;

-- NULL behaviour with subscribers that have missing usage rows.
-- SUM and AVG ignore NULL values; COUNT(*) counts the joined subscriber row,
-- while COUNT(UsageMB) counts only non-NULL usage values.
SELECT
    s.SubscriberID,
    COUNT(*) AS JoinedRows,
    COUNT(du.UsageMB) AS UsageValues,
    SUM(du.UsageMB) AS TotalUsageMB,
    AVG(du.UsageMB) AS AverageUsageMB
FROM dbo.Subscribers AS s
LEFT JOIN dbo.Data_Usage AS du ON du.SubscriberID = s.SubscriberID
GROUP BY s.SubscriberID
ORDER BY s.SubscriberID;
