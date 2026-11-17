USE BankBranchDB;

-- 1. Insert Customers
INSERT INTO Customer (CustomerName, Address)
VALUES
('Arun Kumar', '12 Gandhi Road, Chennai'),
('Priya Sharma', '45 Lake View Street, Coimbatore'),
('Rahul Nair', '8 Park Avenue, Bengaluru'),
('Meena Krishnan', '21 Temple Road, Madurai'),
('Karthik Raj', '16 Market Street, Salem'),
('Divya Suresh', '9 River Road, Tiruppur');


-- 2. Insert Branches
INSERT INTO Branch (BranchName)
VALUES
('Chennai Main Branch'),
('Coimbatore Branch'),
('Bengaluru Branch');

-- 3. Insert Relationship Managers
INSERT INTO RelationshipManager (ManagerName, BranchID)
VALUES
('Sanjay Rao', 1),
('Lakshmi Iyer', 1),
('Vikram Das', 2),
('Anitha Menon', 2),
('Rohit Verma', 3);

-- 4. Insert Accounts
INSERT INTO Account
    (AccountNumber, AccountType, Balance, OpenedDate, BranchID, ManagerID)
VALUES
('ACC1001', 'Savings',  25000.00, '2026-07-05', 1, 1),
('ACC1002', 'Current',  85000.00, '2026-07-18', 1, 2),
('ACC1003', 'Savings',  12000.00, '2026-08-02', 2, 3),
('ACC1004', 'Current',  -5000.00, '2026-08-14', 2, 4),
('ACC1005', 'Savings',  55000.00, '2026-09-10', 3, 5),
('ACC1006', 'Current',  15000.00, '2026-09-25', 3, 5),
('ACC1007', 'Savings',  40000.00, '2026-05-12', 1, 1),
('ACC1008', 'Current',  95000.00, '2026-03-20', 2, 3),
('ACC1009', 'Savings',   8000.00, '2026-10-04', 1, 2),
('ACC1010', 'Current',  62000.00, '2026-06-30', 3, 5);


-- 5. Map Customers to Accounts
INSERT INTO CustomerAccount (CustomerID, AccountID)
VALUES
(1, 1),
(1, 2),
(2, 3),
(2, 4),
(3, 5),
(3, 6),
(4, 7),
(4, 8),
(5, 9),
(6, 10);

-- 6. Verify inserted records
SELECT * FROM Customer ORDER BY CustomerID;
SELECT * FROM Branch ORDER BY BranchID;
SELECT * FROM RelationshipManager ORDER BY ManagerID;
SELECT * FROM Account ORDER BY AccountID;
SELECT * FROM CustomerAccount ORDER BY CustomerID, AccountID;


-- Test table for DELETE
CREATE TABLE Test_Delete (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50)
);


-- Test table for TRUNCATE
CREATE TABLE Test_Truncate (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50)
);

-- Test table for DROP
CREATE TABLE Test_Drop (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50)
);

-- Insert three records into each table
INSERT INTO Test_Delete (Name)
VALUES ('Arun'), ('Priya'), ('Rahul');

INSERT INTO Test_Truncate (Name)
VALUES ('Arun'), ('Priya'), ('Rahul');

INSERT INTO Test_Drop (Name)
VALUES ('Arun'), ('Priya'), ('Rahul');

SELECT * FROM Test_Delete;
SELECT * FROM Test_Truncate;
SELECT * FROM Test_Drop;


-- Delete only one record
DELETE FROM Test_Delete
WHERE ID = 2;


-- Insert another record
INSERT INTO Test_Delete (Name)
VALUES ('Meena');

-- Transaction - 1
BEGIN TRANSACTION;

DELETE FROM Test_Delete
WHERE ID = 1;

ROLLBACK TRANSACTION;


-- Transaction - 2
BEGIN TRANSACTION;

TRUNCATE TABLE Test_Truncate;

SELECT * FROM Test_Truncate;

ROLLBACK TRANSACTION;


TRUNCATE TABLE Test_Truncate;

INSERT INTO Test_Truncate (Name)
VALUES ('Meena');

SELECT * FROM Test_Truncate;


BEGIN TRANSACTION;

DROP TABLE Test_Drop;

-- Check whether the table exists
SELECT OBJECT_ID('Test_Drop', 'U') AS TableExists;

ROLLBACK TRANSACTION;


-- Task 4

INSERT INTO Account
    (AccountNumber, AccountType, Balance, OpenedDate, BranchID, ManagerID)
VALUES
    ('ACC1011', 'Savings', 10000.00, '2026-08-20', 1, 1);


SELECT * FROM Account
WHERE AccountNumber = 'ACC1011';

-- Before and After update
SELECT * FROM Account
WHERE AccountNumber = 'ACC1003';

UPDATE Account
SET Balance = 28000.00
WHERE AccountNumber = 'ACC1003';


-- Before and After deletion
SELECT * FROM Account
WHERE AccountNumber = 'ACC1011';

DELETE FROM Account
WHERE AccountNumber = 'ACC1011';

-- where
SELECT
    AccountID,
    AccountNumber,
    AccountType,
    Balance,
    OpenedDate
FROM Account
WHERE
    OpenedDate BETWEEN '2026-07-01' AND '2026-09-30'
    AND Balance > 20000
    AND (
        AccountType IN ('Savings')
        OR Balance >= 75000
    )
ORDER BY OpenedDate;