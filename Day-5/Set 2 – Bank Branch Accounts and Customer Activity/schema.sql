CREATE DATABASE BankBranchDB;

USE BankBranchDB;

-- 1. Customer
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Address VARCHAR(250) NOT NULL
);

-- 2. Branch
CREATE TABLE Branch (
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName VARCHAR(100) NOT NULL UNIQUE
);

-- 3. Relationship Manager
CREATE TABLE RelationshipManager (
    ManagerID INT IDENTITY(1,1) PRIMARY KEY,
    ManagerName VARCHAR(100) NOT NULL,
    BranchID INT NOT NULL,

    CONSTRAINT FK_Manager_Branch
        FOREIGN KEY (BranchID)
        REFERENCES Branch(BranchID)
        ON DELETE NO ACTION
);


CREATE TABLE Account (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber VARCHAR(20) NOT NULL UNIQUE,
    AccountType VARCHAR(20) NOT NULL,
    Balance DECIMAL(12,2) NOT NULL,
    OpenedDate DATE NOT NULL,
    BranchID INT NOT NULL,
    ManagerID INT NOT NULL,

    CONSTRAINT CK_Account_Type
        CHECK (AccountType IN ('Savings', 'Current')),

    CONSTRAINT CK_Savings_Balance
        CHECK (AccountType <> 'Savings' OR Balance >= 0),

    CONSTRAINT FK_Account_Branch
        FOREIGN KEY (BranchID)
        REFERENCES Branch(BranchID)
        ON DELETE NO ACTION,

    CONSTRAINT FK_Account_Manager
        FOREIGN KEY (ManagerID)
        REFERENCES RelationshipManager(ManagerID)
        ON DELETE NO ACTION
);


-- 5. CustomerAccount
-- Supports one or more customers sharing an account.
CREATE TABLE CustomerAccount (
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,

    CONSTRAINT PK_CustomerAccount
        PRIMARY KEY (CustomerID, AccountID),

    CONSTRAINT FK_CustomerAccount_Customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE NO ACTION,

    CONSTRAINT FK_CustomerAccount_Account
        FOREIGN KEY (AccountID)
        REFERENCES Account(AccountID)
        ON DELETE NO ACTION
);


SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;