IF OBJECT_ID('tempdb..#Products') IS NOT NULL DROP TABLE #Products;
IF OBJECT_ID('tempdb..#Sales') IS NOT NULL DROP TABLE #Sales;
CREATE TABLE #Products
(
    ProductId int PRIMARY KEY,
    CategoryId int NOT NULL,
    ProductName varchar(60) NOT NULL
);
CREATE TABLE #Sales
(
    ProductId int NOT NULL,
    Quantity int NOT NULL
);

INSERT #Products VALUES
    (1, 10, 'Wireless Headphones'),
    (2, 10, 'Portable Speaker'),
    (3, 10, 'Bluetooth Earbuds'),
    (4, 10, 'USB Microphone'),
    (5, 20, 'Desk Lamp'),
    (6, 20, 'Floor Lamp');
INSERT #Sales VALUES
    (1, 44), (1, 12), (2, 38), (3, 38), (4, 20), (5, 31), (6, 17);

WITH ProductSales AS
(
    SELECT
        product.ProductId,
        product.CategoryId,
        product.ProductName,
        SUM(sale.Quantity) AS UnitsSold
    FROM #Products AS product
    JOIN #Sales AS sale ON sale.ProductId = product.ProductId
    GROUP BY product.ProductId, product.CategoryId, product.ProductName
),
RankedProducts AS
(
    SELECT
        ProductId,
        CategoryId,
        ProductName,
        UnitsSold,
        ROW_NUMBER() OVER
        (
            PARTITION BY CategoryId
            ORDER BY UnitsSold DESC, ProductId
        ) AS CategoryRow
    FROM ProductSales
)
SELECT CategoryId, ProductId, ProductName, UnitsSold, CategoryRow
FROM RankedProducts
WHERE CategoryRow <= 3
ORDER BY CategoryId, CategoryRow;
