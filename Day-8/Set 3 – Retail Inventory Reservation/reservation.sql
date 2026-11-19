IF OBJECT_ID('dbo.Day8Products', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Day8Products
    (
        ProductId int NOT NULL PRIMARY KEY,
        CategoryId int NOT NULL,
        ProductName varchar(80) NOT NULL,
        Stock int NOT NULL,
        UnitPrice decimal(10,2) NOT NULL,
        CONSTRAINT CK_Day8Products_Stock CHECK (Stock >= 0)
    );
END;

IF OBJECT_ID('dbo.Day8Orders', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Day8Orders
    (
        OrderId bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderDate datetime2(0) NOT NULL,
        OrderStatus varchar(20) NOT NULL
    );
END;

IF OBJECT_ID('dbo.Day8OrderLines', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Day8OrderLines
    (
        OrderLineId bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId bigint NOT NULL REFERENCES dbo.Day8Orders(OrderId),
        ProductId int NOT NULL REFERENCES dbo.Day8Products(ProductId),
        Quantity int NOT NULL,
        UnitPrice decimal(10,2) NOT NULL,
        CONSTRAINT CK_Day8OrderLines_Quantity CHECK (Quantity > 0)
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Day8Products WHERE ProductId = 1)
    INSERT dbo.Day8Products (ProductId, CategoryId, ProductName, Stock, UnitPrice)
    VALUES (1, 10, 'Wireless Headphones', 12, 79.99);
IF NOT EXISTS (SELECT 1 FROM dbo.Day8Products WHERE ProductId = 2)
    INSERT dbo.Day8Products (ProductId, CategoryId, ProductName, Stock, UnitPrice)
    VALUES (2, 10, 'Portable Speaker', 30, 49.50);
IF NOT EXISTS (SELECT 1 FROM dbo.Day8Products WHERE ProductId = 3)
    INSERT dbo.Day8Products (ProductId, CategoryId, ProductName, Stock, UnitPrice)
    VALUES (3, 20, 'Desk Lamp', 4, 35.00);

DECLARE @InsufficientRequest TABLE (ProductId int NOT NULL, Quantity int NOT NULL);
INSERT INTO @InsufficientRequest VALUES (1, 1000);
DECLARE @StockBefore int = (SELECT Stock FROM dbo.Day8Products WHERE ProductId = 1);

PRINT 'Insufficient-stock reservation: transaction must roll back.';
BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS
    (
        SELECT 1
        FROM @InsufficientRequest AS request
        LEFT JOIN dbo.Day8Products AS product WITH (UPDLOCK, HOLDLOCK)
            ON product.ProductId = request.ProductId
        WHERE request.Quantity <= 0
           OR product.ProductId IS NULL
           OR product.Stock < request.Quantity
    )
    BEGIN
        THROW 53001, 'Insufficient stock or invalid order line.', 1;
    END;

    UPDATE product
    SET Stock = product.Stock - request.Quantity
    FROM dbo.Day8Products AS product
    JOIN @InsufficientRequest AS request ON request.ProductId = product.ProductId;
    INSERT dbo.Day8Orders (OrderDate, OrderStatus) VALUES (SYSUTCDATETIME(), 'PLACED');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    PRINT CONCAT('Expected reservation failure: ', ERROR_MESSAGE());
END CATCH;

SELECT @StockBefore AS StockBeforeFailure,
       Stock AS StockAfterRollback,
       CASE WHEN Stock = @StockBefore THEN 'PASS: stock unchanged' ELSE 'FAIL' END AS RollbackEvidence
FROM dbo.Day8Products WHERE ProductId = 1;

DECLARE @OrderItems TABLE (ProductId int NOT NULL, Quantity int NOT NULL);
INSERT INTO @OrderItems VALUES (1, 2), (2, 1);
DECLARE @CreatedOrder TABLE (OrderId bigint);

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS
    (
        SELECT 1
        FROM @OrderItems AS request
        LEFT JOIN dbo.Day8Products AS product WITH (UPDLOCK, HOLDLOCK)
            ON product.ProductId = request.ProductId
        WHERE request.Quantity <= 0
           OR product.ProductId IS NULL
           OR product.Stock < request.Quantity
    )
    BEGIN
        THROW 53002, 'Insufficient stock or invalid order line.', 1;
    END;

    UPDATE product
    SET Stock = product.Stock - request.Quantity
    FROM dbo.Day8Products AS product
    JOIN @OrderItems AS request ON request.ProductId = product.ProductId;

    INSERT dbo.Day8Orders (OrderDate, OrderStatus)
    OUTPUT inserted.OrderId INTO @CreatedOrder(OrderId)
    VALUES (SYSUTCDATETIME(), 'PLACED');

    INSERT dbo.Day8OrderLines (OrderId, ProductId, Quantity, UnitPrice)
    SELECT created.OrderId, request.ProductId, request.Quantity, product.UnitPrice
    FROM @CreatedOrder AS created
    CROSS JOIN @OrderItems AS request
    JOIN dbo.Day8Products AS product ON product.ProductId = request.ProductId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT created.OrderId, product.ProductId, product.ProductName, product.Stock
FROM @CreatedOrder AS created
JOIN dbo.Day8OrderLines AS line ON line.OrderId = created.OrderId
JOIN dbo.Day8Products AS product ON product.ProductId = line.ProductId
ORDER BY product.ProductId;

-- Simulate payment authorization failure: compensate by releasing reserved stock.
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE product
    SET Stock = product.Stock + line.Quantity
    FROM dbo.Day8Products AS product
    JOIN dbo.Day8OrderLines AS line ON line.ProductId = product.ProductId
    JOIN @CreatedOrder AS created ON created.OrderId = line.OrderId;

    UPDATE orderHeader
    SET OrderStatus = 'PAYMENT_FAILED'
    FROM dbo.Day8Orders AS orderHeader
    JOIN @CreatedOrder AS created ON created.OrderId = orderHeader.OrderId
    WHERE orderHeader.OrderStatus = 'PLACED';
    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 53003, 'Could not mark the order as payment failed.', 1;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT orderHeader.OrderId, orderHeader.OrderStatus, product.ProductId, product.Stock
FROM @CreatedOrder AS created
JOIN dbo.Day8Orders AS orderHeader ON orderHeader.OrderId = created.OrderId
JOIN dbo.Day8OrderLines AS line ON line.OrderId = orderHeader.OrderId
JOIN dbo.Day8Products AS product ON product.ProductId = line.ProductId
ORDER BY product.ProductId;

-- Correlated subquery: compare each product's stock with its own category average.
SELECT product.ProductId, product.ProductName, product.CategoryId, product.Stock
FROM dbo.Day8Products AS product
WHERE product.Stock <
      (SELECT AVG(CONVERT(decimal(10,2), categoryProduct.Stock))
       FROM dbo.Day8Products AS categoryProduct
       WHERE categoryProduct.CategoryId = product.CategoryId)
ORDER BY product.CategoryId, product.ProductId;
