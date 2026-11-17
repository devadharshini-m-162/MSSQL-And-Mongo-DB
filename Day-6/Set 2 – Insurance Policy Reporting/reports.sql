USE InsuranceReportingDB;

DECLARE @AsOfDate date = '2026-11-18';

-- 1. Policies expiring in the next 30 days.
SELECT p.PolicyID, p.PolicyNumber, c.CustomerName, pr.ProductName, p.EndDate
FROM dbo.Policies AS p
JOIN dbo.Customers AS c ON c.CustomerID = p.CustomerID
JOIN dbo.Products AS pr ON pr.ProductID = p.ProductID
WHERE p.Status = 'Active'
  AND p.EndDate >= @AsOfDate
  AND p.EndDate < DATEADD(DAY, 31, @AsOfDate)
ORDER BY p.EndDate, p.PolicyNumber;

-- 2. Premium collected per product.
SELECT pr.ProductID, pr.ProductName, ROUND(SUM(pm.Amount), 2) AS PremiumCollected
FROM dbo.Products AS pr
JOIN dbo.Policies AS p ON p.ProductID = pr.ProductID
JOIN dbo.Premiums AS pm ON pm.PolicyID = p.PolicyID
GROUP BY pr.ProductID, pr.ProductName
ORDER BY PremiumCollected DESC;

-- 3. Customers with more than one active policy.
-- WHERE filters individual policies before grouping; HAVING filters grouped
-- customers after COUNT has been calculated.
SELECT c.CustomerID, c.CustomerName, COUNT(*) AS ActivePolicyCount
FROM dbo.Customers AS c
JOIN dbo.Policies AS p ON p.CustomerID = c.CustomerID
WHERE p.Status = 'Active'
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(*) > 1
ORDER BY ActivePolicyCount DESC, c.CustomerName;

-- 4. Claim ratio per product (claims divided by collected premium).
WITH ProductPremium AS (
    SELECT p.ProductID, SUM(pm.Amount) AS PremiumAmount
    FROM dbo.Policies AS p
    JOIN dbo.Premiums AS pm ON pm.PolicyID = p.PolicyID
    GROUP BY p.ProductID
),
ProductClaims AS (
    SELECT p.ProductID, SUM(cl.ClaimAmount) AS ClaimAmount
    FROM dbo.Policies AS p
    JOIN dbo.Claims AS cl ON cl.PolicyID = p.PolicyID
    GROUP BY p.ProductID
)
SELECT
    pr.ProductName,
    COALESCE(pc.ClaimAmount, 0) AS ClaimAmount,
    COALESCE(pp.PremiumAmount, 0) AS PremiumAmount,
    ROUND(100.0 * COALESCE(pc.ClaimAmount, 0) /
          NULLIF(pp.PremiumAmount, 0), 2) AS ClaimRatioPercent
FROM dbo.Products AS pr
LEFT JOIN ProductPremium AS pp ON pp.ProductID = pr.ProductID
LEFT JOIN ProductClaims AS pc ON pc.ProductID = pr.ProductID
ORDER BY pr.ProductName;

-- 5. Policies without claims.
SELECT p.PolicyID, p.PolicyNumber, c.CustomerName, pr.ProductName
FROM dbo.Policies AS p
JOIN dbo.Customers AS c ON c.CustomerID = p.CustomerID
JOIN dbo.Products AS pr ON pr.ProductID = p.ProductID
LEFT JOIN dbo.Claims AS cl ON cl.PolicyID = p.PolicyID
WHERE cl.ClaimID IS NULL
ORDER BY p.PolicyNumber;

-- 6. Average premium by customer age band.
WITH CustomerPremium AS (
    SELECT
        c.CustomerID,
        CASE
            WHEN DATEDIFF(YEAR, c.DateOfBirth, @AsOfDate)
                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.DateOfBirth, @AsOfDate),
                                     c.DateOfBirth) > @AsOfDate THEN 1 ELSE 0 END < 30
                THEN 'Under 30'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, @AsOfDate)
                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.DateOfBirth, @AsOfDate),
                                     c.DateOfBirth) > @AsOfDate THEN 1 ELSE 0 END < 60
                THEN '30-59'
            ELSE '60+'
        END AS AgeBand,
        pm.Amount
    FROM dbo.Customers AS c
    JOIN dbo.Policies AS p ON p.CustomerID = c.CustomerID
    JOIN dbo.Premiums AS pm ON pm.PolicyID = p.PolicyID
)
SELECT AgeBand, ROUND(AVG(Amount), 2) AS AveragePremium
FROM CustomerPremium
GROUP BY AgeBand
ORDER BY AgeBand;

-- 7. Monthly new policies.
SELECT
    DATEFROMPARTS(YEAR(StartDate), MONTH(StartDate), 1) AS PolicyMonth,
    COUNT(*) AS NewPolicyCount
FROM dbo.Policies
GROUP BY DATEFROMPARTS(YEAR(StartDate), MONTH(StartDate), 1)
ORDER BY PolicyMonth;

-- 8. Top five agents by collected premium.
SELECT TOP (5)
    a.AgentID,
    a.AgentName,
    ROUND(SUM(pm.Amount), 2) AS PremiumCollected
FROM dbo.Agents AS a
JOIN dbo.Policies AS p ON p.AgentID = a.AgentID
JOIN dbo.Premiums AS pm ON pm.PolicyID = p.PolicyID
GROUP BY a.AgentID, a.AgentName
ORDER BY PremiumCollected DESC, a.AgentName;

-- Customer-friendly policy output: masked number and policy age band.
SELECT
    CONCAT('****', RIGHT(p.PolicyNumber, 4)) AS MaskedPolicyNumber,
    CASE
        WHEN DATEDIFF(YEAR, p.StartDate, @AsOfDate) < 1 THEN 'Under 1 year'
        WHEN DATEDIFF(YEAR, p.StartDate, @AsOfDate) < 5 THEN '1-4 years'
        ELSE '5+ years'
    END AS PolicyAgeBand,
    DATEDIFF(DAY, p.StartDate, @AsOfDate) AS PolicyAgeDays
FROM dbo.Policies AS p
ORDER BY p.PolicyNumber;
