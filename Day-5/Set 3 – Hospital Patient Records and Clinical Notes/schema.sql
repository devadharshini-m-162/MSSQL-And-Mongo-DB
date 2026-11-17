
CREATE DATABASE HospitalRecordsDB;


USE HospitalRecordsDB;


-- 1. Patient table
CREATE TABLE Patient (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    PatientName VARCHAR(100) NOT NULL,
    Address VARCHAR(250) NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE
);

-- 2. Department table
CREATE TABLE Department (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Department_DepartmentName UNIQUE (DepartmentName)
);


-- 3. Doctor table
CREATE TABLE Doctor (
    DoctorID INT IDENTITY(1,1) PRIMARY KEY,
    DoctorName VARCHAR(100) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID)
        REFERENCES Department(DepartmentID)
);


-- 4. Visit table
CREATE TABLE Visit (
    VisitID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    VisitDate DATE NOT NULL,
    Diagnosis VARCHAR(250) NOT NULL,
    Prescription VARCHAR(500),
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Visit_Status DEFAULT 'Open',

    CONSTRAINT CK_Visit_VisitDate
        CHECK (
            VisitDate >= '2000-01-01'
            AND VisitDate <= CAST(GETDATE() AS DATE)
        ),

    CONSTRAINT CK_Visit_Status
        CHECK (Status IN ('Open', 'Completed', 'Cancelled')),

    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID)
);


-- 5. Billing table
CREATE TABLE Billing (
    BillingID INT IDENTITY(1,1) PRIMARY KEY,
    VisitID INT NOT NULL UNIQUE,
    BillAmount DECIMAL(10,2) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL
        CONSTRAINT DF_Billing_PaymentStatus DEFAULT 'Pending',

    CONSTRAINT CK_Billing_BillAmount
        CHECK (BillAmount >= 0),

    CONSTRAINT CK_Billing_PaymentStatus
        CHECK (PaymentStatus IN ('Pending', 'Paid', 'Unpaid')),

    FOREIGN KEY (VisitID) REFERENCES Visit(VisitID)
);


-- Verify table creation
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';