USE RetailReturnsDB;

-- 1. Products with a return rate above 10 percent.
SELECT p.ProductID, p.ProductName,
       ROUND(100.0 * SUM(CASE WHEN r.ReturnID IS NOT NULL THEN 1 ELSE 0 END)
             / NULLIF(COUNT(s.SaleID), 0), 2) AS ReturnRatePercent
FROM dbo.Products p
LEFT JOIN dbo.Sales s ON s.ProductID = p.ProductID
LEFT JOIN dbo.Returns r ON r.SaleID = s.SaleID
GROUP BY p.ProductID, p.ProductName
HAVING 100.0 * SUM(CASE WHEN r.ReturnID IS NOT NULL THEN 1 ELSE 0 END)
       / NULLIF(COUNT(s.SaleID), 0) > 10;

-- 2. Customers with returns but no refund.
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM dbo.Customers c
JOIN dbo.Sales s ON s.CustomerID = c.CustomerID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
LEFT JOIN dbo.Refunds f ON f.ReturnID = r.ReturnID
WHERE f.RefundID IS NULL;

-- 3. Stores with the highest refund value.
SELECT TOP (1) WITH TIES st.StoreID, st.StoreName,
       SUM(f.RefundAmount) AS TotalRefundValue
FROM dbo.Stores st
JOIN dbo.Sales s ON s.StoreID = st.StoreID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
JOIN dbo.Refunds f ON f.ReturnID = r.ReturnID
GROUP BY st.StoreID, st.StoreName
ORDER BY TotalRefundValue DESC;

-- 4. Employees and their managers.
SELECT e.EmployeeID, e.EmployeeName, e.ManagerID,
       m.EmployeeName AS ManagerName
FROM dbo.Employees e
LEFT JOIN dbo.Employees m ON m.EmployeeID = e.ManagerID;

-- 5. Customers found by IN.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
WHERE c.CustomerID IN (
    SELECT s.CustomerID
    FROM dbo.Sales s
);

-- 6. NOT IN NULL pitfall demonstration.
SELECT CustomerID, CustomerName
FROM dbo.Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM dbo.Sales
);

-- 7. Safe correction using NOT EXISTS.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Sales s
    WHERE s.CustomerID = c.CustomerID
);

-- 8. Stores whose refund is above at least one refund in another store in the region.
SELECT st.StoreID, st.StoreName,
       SUM(f.RefundAmount) AS StoreRefund
FROM dbo.Stores st
JOIN dbo.Sales s ON s.StoreID = st.StoreID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
JOIN dbo.Refunds f ON f.ReturnID = r.ReturnID
GROUP BY st.StoreID, st.StoreName, st.Region
HAVING SUM(f.RefundAmount) > ANY (
    SELECT SUM(f2.RefundAmount)
    FROM dbo.Stores st2
    JOIN dbo.Sales s2 ON s2.StoreID = st2.StoreID
    JOIN dbo.Returns r2 ON r2.SaleID = s2.SaleID
    JOIN dbo.Refunds f2 ON f2.ReturnID = r2.ReturnID
    WHERE st2.Region = st.Region
      AND st2.StoreID <> st.StoreID
    GROUP BY st2.StoreID
);

-- 9. Stores whose refund exceeds every other store in the region.
SELECT st.StoreID, st.StoreName,
       SUM(f.RefundAmount) AS StoreRefund
FROM dbo.Stores st
JOIN dbo.Sales s ON s.StoreID = st.StoreID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
JOIN dbo.Refunds f ON f.ReturnID = r.ReturnID
GROUP BY st.StoreID, st.StoreName, st.Region
HAVING SUM(f.RefundAmount) > ALL (
    SELECT SUM(f2.RefundAmount)
    FROM dbo.Stores st2
    JOIN dbo.Sales s2 ON s2.StoreID = st2.StoreID
    JOIN dbo.Returns r2 ON r2.SaleID = s2.SaleID
    JOIN dbo.Refunds f2 ON f2.ReturnID = r2.ReturnID
    WHERE st2.Region = st.Region
      AND st2.StoreID <> st.StoreID
    GROUP BY st2.StoreID
);

-- 10. Stores with no sales.
SELECT st.StoreID, st.StoreName
FROM dbo.Stores st
LEFT JOIN dbo.Sales s ON s.StoreID = st.StoreID
WHERE s.SaleID IS NULL;

-- Nested subquery 1: products returned above the average product return count.
SELECT p.ProductID, p.ProductName, COUNT(r.ReturnID) AS ReturnCount
FROM dbo.Products p
JOIN dbo.Sales s ON s.ProductID = p.ProductID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(r.ReturnID) > (
    SELECT AVG(ProductReturnCount)
    FROM (
        SELECT COUNT(r2.ReturnID) AS ProductReturnCount
        FROM dbo.Products p2
        JOIN dbo.Sales s2 ON s2.ProductID = p2.ProductID
        JOIN dbo.Returns r2 ON r2.SaleID = s2.SaleID
        GROUP BY p2.ProductID
    ) ProductCounts
);

-- Nested subquery 2: refunds above the store's average refund.
SELECT st.StoreID, st.StoreName, f.RefundID, f.RefundAmount
FROM dbo.Stores st
JOIN dbo.Sales s ON s.StoreID = st.StoreID
JOIN dbo.Returns r ON r.SaleID = s.SaleID
JOIN dbo.Refunds f ON f.ReturnID = r.ReturnID
WHERE f.RefundAmount > (
    SELECT AVG(f2.RefundAmount)
    FROM dbo.Refunds f2
    JOIN dbo.Returns r2 ON r2.ReturnID = f2.ReturnID
    JOIN dbo.Sales s2 ON s2.SaleID = r2.SaleID
    WHERE s2.StoreID = st.StoreID
);
