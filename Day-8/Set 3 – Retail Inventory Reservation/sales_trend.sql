WITH MonthlySales AS
(
    SELECT ProductId, SalesMonth, SUM(Quantity * UnitPrice) AS SalesAmount
    FROM (VALUES
        (1, CONVERT(date, '2025-01-01'), 10, CONVERT(decimal(10,2), 79.99)),
        (1, CONVERT(date, '2025-02-01'), 14, CONVERT(decimal(10,2), 79.99)),
        (1, CONVERT(date, '2025-03-01'), 9, CONVERT(decimal(10,2), 79.99)),
        (2, CONVERT(date, '2025-01-01'), 20, CONVERT(decimal(10,2), 49.50)),
        (2, CONVERT(date, '2025-02-01'), 16, CONVERT(decimal(10,2), 49.50)),
        (2, CONVERT(date, '2025-03-01'), 22, CONVERT(decimal(10,2), 49.50))
    ) AS sample(ProductId, SalesMonth, Quantity, UnitPrice)
    GROUP BY ProductId, SalesMonth
),
SalesWithNeighbors AS
(
    SELECT
        ProductId,
        SalesMonth,
        SalesAmount,
        LAG(SalesAmount) OVER (PARTITION BY ProductId ORDER BY SalesMonth) AS PreviousMonthSales,
        LEAD(SalesAmount) OVER (PARTITION BY ProductId ORDER BY SalesMonth) AS NextMonthSales
    FROM MonthlySales
)
SELECT
    ProductId,
    SalesMonth,
    SalesAmount,
    PreviousMonthSales,
    SalesAmount - PreviousMonthSales AS ChangeFromPreviousMonth,
    NextMonthSales
FROM SalesWithNeighbors
ORDER BY ProductId, SalesMonth;
