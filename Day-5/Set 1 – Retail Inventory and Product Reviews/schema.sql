CREATE DATABASE RetailInventoryDB;

USE RetailInventoryDB;

--Suppiler Table
CREATE TABLE Supplier (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL UNIQUE,
    SupplierPhone VARCHAR(20) NOT NULL
);

--Category Table
CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE
);

--Product Table
CREATE TABLE Product (
    SKU VARCHAR(20) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,

    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,

    CONSTRAINT FK_Product_Category
        FOREIGN KEY (CategoryID)
        REFERENCES Category(CategoryID),

    CONSTRAINT FK_Product_Supplier
        FOREIGN KEY (SupplierID)
        REFERENCES Supplier(SupplierID)
);

--Warehouse Table
CREATE TABLE Warehouse (
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName VARCHAR(100) NOT NULL UNIQUE
);

--Inventory Table
CREATE TABLE Inventory (
    SKU VARCHAR(20) NOT NULL,
    WarehouseID INT NOT NULL,

    Quantity INT NOT NULL
        CONSTRAINT DF_Inventory_Quantity DEFAULT 0,

    ReorderLevel INT NOT NULL
        CONSTRAINT DF_Inventory_ReorderLevel DEFAULT 0,

    CONSTRAINT PK_Inventory
        PRIMARY KEY (SKU, WarehouseID),

    CONSTRAINT CK_Inventory_Quantity
        CHECK (Quantity >= 0),

    CONSTRAINT CK_Inventory_ReorderLevel
        CHECK (ReorderLevel >= 0),

    CONSTRAINT FK_Inventory_Product
        FOREIGN KEY (SKU)
        REFERENCES Product(SKU)
        ON DELETE CASCADE,

    CONSTRAINT FK_Inventory_Warehouse
        FOREIGN KEY (WarehouseID)
        REFERENCES Warehouse(WarehouseID)
        ON DELETE CASCADE
);


SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;