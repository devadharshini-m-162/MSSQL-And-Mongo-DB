USE BankLoanDB;

-- 1. Loans overdue by more than three instalments.
SELECT l.LoanID, l.CustomerID, r.MissedInstallments
FROM dbo.Loans l
JOIN (
    SELECT LoanID,
           COUNT(*) AS MissedInstallments
    FROM dbo.Installments
    WHERE Status = 'Missed'
    GROUP BY LoanID
) r ON r.LoanID = l.LoanID
WHERE r.MissedInstallments > 3;

-- 2. Customers with loans in more than one branch.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
JOIN dbo.Loans l ON l.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT l.BranchID) > 1;

-- 3. Guarantors who are also borrowers.
SELECT DISTINCT g.GuarantorID AS CustomerID,
       c.CustomerName
FROM dbo.Guarantors g
JOIN dbo.Customers c ON c.CustomerID = g.GuarantorID
JOIN dbo.Loans l ON l.CustomerID = g.GuarantorID;

-- 4. Branches with no loans.
SELECT b.BranchID, b.BranchName
FROM dbo.Branches b
LEFT JOIN dbo.Loans l ON l.BranchID = b.BranchID
WHERE l.LoanID IS NULL;

-- 5. Customers whose exposure exceeds the branch average.
SELECT c.CustomerID, c.CustomerName, l.BranchID,
       SUM(l.LoanAmount) AS CustomerExposure
FROM dbo.Customers c
JOIN dbo.Loans l ON l.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName, l.BranchID
HAVING SUM(l.LoanAmount) > (
    SELECT AVG(CustomerExposure)
    FROM (
        SELECT SUM(l2.LoanAmount) AS CustomerExposure
        FROM dbo.Loans l2
        GROUP BY l2.CustomerID
    ) CustomerExposures
);

-- 6. Customers whose exposure exceeds their branch average.
SELECT c.CustomerID, c.CustomerName,
       SUM(l.LoanAmount) AS Exposure
FROM dbo.Customers c
JOIN dbo.Loans l ON l.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName, l.BranchID
HAVING SUM(l.LoanAmount) > (
    SELECT AVG(l2.LoanAmount)
    FROM dbo.Loans l2
    WHERE l2.BranchID = l.BranchID
);

-- 7. Customers with a loan but no repayment in the last 60 days.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
WHERE EXISTS (
    SELECT 1 FROM dbo.Loans l
    WHERE l.CustomerID = c.CustomerID
)
AND NOT EXISTS (
    SELECT 1
    FROM dbo.Loans l
    JOIN dbo.Repayments r ON r.LoanID = l.LoanID
    WHERE l.CustomerID = c.CustomerID
      AND r.PaymentDate >= DATEADD(DAY, -60, CAST(GETDATE() AS date))
);

-- 8. Highest loan for each branch.
SELECT b.BranchID, b.BranchName, MAX(l.LoanAmount) AS HighestLoan
FROM dbo.Branches b
JOIN dbo.Loans l ON l.BranchID = b.BranchID
GROUP BY b.BranchID, b.BranchName;

-- 9. Branches whose highest loan exceeds the average of branch maximums.
SELECT BranchID, BranchName, HighestLoan
FROM (
    SELECT b.BranchID, b.BranchName,
           MAX(l.LoanAmount) AS HighestLoan
    FROM dbo.Branches b
    JOIN dbo.Loans l ON l.BranchID = b.BranchID
    GROUP BY b.BranchID, b.BranchName
) BranchMax
WHERE HighestLoan > (
    SELECT AVG(MaxAmount)
    FROM (
        SELECT MAX(l2.LoanAmount) AS MaxAmount
        FROM dbo.Loans l2
        GROUP BY l2.BranchID
    ) BankBranchMax
);

-- 10. Loans without guarantors.
SELECT l.LoanID, l.CustomerID, l.LoanAmount
FROM dbo.Loans l
LEFT JOIN dbo.Guarantors g ON g.LoanID = l.LoanID
WHERE g.GuarantorID IS NULL;
