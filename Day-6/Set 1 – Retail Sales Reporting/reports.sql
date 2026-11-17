USE RetailSalesDB;

-- 1. Top five products by revenue.
SELECT TOP (5)
    p.ProductID,
    p.ProductName,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS Revenue
FROM dbo.Products AS p
JOIN dbo.OrderItems AS oi ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY Revenue DESC, p.ProductName;

-- 2. Month-wise sales.
SELECT
    DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS Sales
FROM dbo.Orders AS o
JOIN dbo.OrderItems AS oi ON oi.OrderID = o.OrderID
GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
ORDER BY MonthStart;

-- 3. Customers with more than three orders.
SELECT
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM dbo.Customers AS c
JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(o.OrderID) > 3
ORDER BY OrderCount DESC, c.CustomerName;

-- 4. Average basket value by city.
WITH OrderTotals AS (
    SELECT
        o.OrderID,
        c.City,
        SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
    FROM dbo.Orders AS o
    JOIN dbo.Customers AS c ON c.CustomerID = o.CustomerID
    JOIN dbo.OrderItems AS oi ON oi.OrderID = o.OrderID
    GROUP BY o.OrderID, c.City
)
SELECT City, ROUND(AVG(OrderTotal), 2) AS AverageBasketValue
FROM OrderTotals
GROUP BY City
ORDER BY City;

-- 5. Orders without a payment.
SELECT o.OrderID, o.OrderDate, c.CustomerName
FROM dbo.Orders AS o
JOIN dbo.Customers AS c ON c.CustomerID = o.CustomerID
LEFT JOIN dbo.Payments AS p ON p.OrderID = o.OrderID
WHERE p.PaymentID IS NULL
ORDER BY o.OrderDate, o.OrderID;

-- 6. Customers with no orders.
SELECT c.CustomerID, c.CustomerName, c.City
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL
ORDER BY c.CustomerName;

-- 7. Revenue share by product category.
WITH CategoryRevenue AS (
    SELECT
        cat.CategoryID,
        cat.CategoryName,
        SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM dbo.Categories AS cat
    JOIN dbo.Products AS p ON p.CategoryID = cat.CategoryID
    JOIN dbo.OrderItems AS oi ON oi.ProductID = p.ProductID
    GROUP BY cat.CategoryID, cat.CategoryName
)
SELECT
    CategoryName,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(100.0 * Revenue / NULLIF(SUM(Revenue) OVER (), 0), 2) AS RevenueSharePercent
FROM CategoryRevenue
ORDER BY Revenue DESC;

-- 8. Day with the highest sales.
SELECT TOP (1) WITH TIES
    CAST(o.OrderDate AS date) AS SalesDate,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS DailySales
FROM dbo.Orders AS o
JOIN dbo.OrderItems AS oi ON oi.OrderID = o.OrderID
GROUP BY CAST(o.OrderDate AS date)
ORDER BY DailySales DESC;

-- Customer-friendly output using string, date and mathematical functions.
SELECT
    UPPER(CONCAT(c.CustomerName, ' - ', c.City)) AS CustomerDisplay,
    FORMAT(MIN(o.OrderDate), 'dd MMM yyyy') AS FirstOrderDate,
    DATEDIFF(DAY, MIN(o.OrderDate), CAST(GETDATE() AS date)) AS DaysAsCustomer,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS LifetimeSales
FROM dbo.Customers AS c
JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
JOIN dbo.OrderItems AS oi ON oi.OrderID = o.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.City
ORDER BY c.CustomerName;

-- NULL example: COUNT(*) counts every joined order; COUNT(PaymentID) counts
-- only matched payments; AVG(Amount) ignores NULL amounts.
SELECT
    COUNT(*) AS TotalOrders,
    COUNT(p.PaymentID) AS PaidOrders,
    AVG(p.Amount) AS AveragePayment
FROM dbo.Orders AS o
LEFT JOIN dbo.Payments AS p ON p.OrderID = o.OrderID;
