USE RetailInventoryDB;

--Insertions
INSERT INTO dbo.Supplier (SupplierName, SupplierPhone)
VALUES
('TechWorld',       '09876543210'),
('Veggies',       '09123456780'),
('FruitHub',       '09876123450'),
('GadgetsHere',       '09777111222'),
('OfficePlus',      '09666123456'),
('UrbanLiving',     '09555123456'),
('EliteElectronics','09444123456'),
('FurnituresAndCo',      '09333123456'),
('DailyEssentials', '09222123456'),
('NextGenMarket',   '09111987654');


INSERT INTO dbo.Category (CategoryName)
VALUES
( 'Electronics'),
('Accessories'),
('Furniture'),
('Appliances'),
('Stationery'),
('Storage'),
('Networking'),
('Lighting'),
('Kitchenware'),
('Personal Care');


INSERT INTO dbo.Warehouse ( WarehouseName)
VALUES
('Chennai Central'),
('Coimbatore Hub'),
('Madurai Depot'),
('Salem Warehouse'),
('Trichy Storage'),
('Erode Depot'),
('Vellore Hub'),
('Tirunelveli Store'),
('Bengaluru Warehouse'),
('Hyderabad Depot');


INSERT INTO dbo.Product (SKU, ProductName, CategoryID, SupplierID)
VALUES
('P101', 'Laptop',             1, 1),
('P102', 'Wireless Mouse',     2, 1),
('P103', 'Office Chair',       3, 2),
('P104', 'Desk Lamp',          8, 8),
('P105', 'Electric Kettle',    4, 3),
('P106', 'Notebook Pack',      5, 5),
('P107', 'Storage Cabinet',    6, 6),
('P108', 'WiFi Router',        7, 7),
('P109', 'Mixer Grinder',      9, 3),
('P110', 'Electric Trimmer',  10, 9);


INSERT INTO dbo.Inventory (SKU, WarehouseID, Quantity, ReorderLevel)
VALUES
('P101', 1, 20, 5),
('P101', 2, 12, 5),
('P102', 1, 50, 10),
('P103', 1, 30, 8),
('P104', 4, 25, 5),
('P105', 2, 18, 4),
('P106', 5, 100, 20),
('P107', 6, 14, 3),
('P108', 9, 22, 6),
('P109', 3, 16, 4);



--Verification
Select * from Supplier;

Select * from Category;

Select * from Product;

Select * from Warehouse;

Select * from Inventory;

--Failure Cases

-- 1. Duplicate Primary Key
INSERT INTO dbo.Product (SKU, ProductName, CategoryID, SupplierID)
VALUES ('P101', 'Duplicate Laptop', 1, 1);

/*
OP: Started executing query at  Line 89
Msg 2627, Level 14, State 1, Line 89
Violation of PRIMARY KEY constraint 'PK__Product__CA1ECF0CD72A9BEC'. Cannot insert duplicate key in object 'dbo.Product'. The duplicate key value is (P101).
*/

-- 2. Missing Parent
INSERT INTO dbo.Product (SKU, ProductName, CategoryID, SupplierID)
VALUES ('P999', 'Unknown Category Product', 999, 1);

/*
OP: Started executing query at  Line 98
Msg 547, Level 16, State 0, Line 98
The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Product_Category". The conflict occurred in database "RetailInventoryDB", table "dbo.Category", column 'CategoryID'.
*/

-- 3. CHECK Violation
INSERT INTO dbo.Inventory (SKU, WarehouseID, Quantity, ReorderLevel)
VALUES ('P102', 2, -5, 2);

/*
OP: Started executing query at  Line 108
Msg 547, Level 16, State 0, Line 108
The INSERT statement conflicted with the CHECK constraint "CK_Inventory_Quantity". The conflict occurred in database "RetailInventoryDB", table "dbo.Inventory", column 'Quantity'.
The statement has been terminated.
*/

-- 4. NOT NULL Violation 
INSERT INTO dbo.Supplier (SupplierName, SupplierPhone)
VALUES (NULL, '09999999999');

/*
OP: Started executing query at  Line 118
Msg 515, Level 16, State 2, Line 118
Cannot insert the value NULL into column 'SupplierName', table 'RetailInventoryDB.dbo.Supplier'; column does not allow nulls. INSERT fails.
The statement has been terminated.
*/

-- Task-4: (Update, Delete and Where)
-- 1. Update 

-- Before and After
SELECT *
FROM Supplier
WHERE SupplierName = 'TechWorld';

-- Update
UPDATE Supplier
SET SupplierPhone = '09988776655'
WHERE SupplierName = 'TechWorld';

-- 2.Delete

-- Before and After
SELECT *
FROM Product
WHERE SKU = 'P109';

-- Inventory Before and After
SELECT *
FROM Inventory
WHERE SKU = 'P109';

-- Delete
DELETE FROM Product
WHERE SKU = 'P109';

