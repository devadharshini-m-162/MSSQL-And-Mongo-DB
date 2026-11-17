

USE HospitalRecordsDB;


-- 1. Insert departments
INSERT INTO Department (DepartmentName)
VALUES
('Cardiology'),
('Neurology'),
('Orthopedics'),
('Dermatology'),
('Pediatrics');


-- 2. Insert doctors
INSERT INTO Doctor (DoctorName, DepartmentID)
VALUES
('Dr. Arun Kumar', 1),
('Dr. Priya Sharma', 1),
('Dr. Rahul Nair', 2),
('Dr. Meena Krishnan', 2),
('Dr. Karthik Raj', 3),
('Dr. Divya Suresh', 3),
('Dr. Sanjay Rao', 4),
('Dr. Anitha Menon', 4),
('Dr. Vikram Das', 5),
('Dr. Lakshmi Iyer', 5);


-- 3. Insert patients
INSERT INTO Patient (PatientName, Address, Phone)
VALUES
('Aarav Kumar', 'Chennai', '9876500001'),
('Diya Sharma', 'Coimbatore', '9876500002'),
('Rohan Nair', 'Madurai', '9876500003'),
('Meera Krishnan', 'Salem', '9876500004'),
('Arjun Raj', 'Erode', '9876500005'),
('Ananya Suresh', 'Tiruppur', '9876500006'),
('Kavin Das', 'Chennai', '9876500007'),
('Ishita Rao', 'Trichy', '9876500008'),
('Nila Menon', 'Vellore', '9876500009'),
('Aditya Verma', 'Bengaluru', '9876500010');


-- 4. Insert patient visits
INSERT INTO Visit
    (PatientID, DoctorID, VisitDate, Diagnosis, Prescription, Status)
VALUES
(1, 1, '2026-11-01', 'Hypertension', 'Amlodipine 5mg', 'Completed'),
(2, 2, '2026-11-03', 'Chest Pain', 'ECG and medication', 'Open'),
(3, 3, '2026-11-05', 'Migraine', 'Pain relief medication', 'Completed'),
(4, 4, '2026-10-10', 'Headache', 'Rest and medication', 'Completed'),
(5, 5, '2026-10-12', 'Knee Pain', 'Physiotherapy', 'Open'),
(6, 6, '2026-09-15', 'Joint Pain', 'Calcium supplements', 'Completed'),
(7, 7, '2026-11-08', 'Skin Allergy', 'Antihistamine', 'Open'),
(8, 8, '2026-09-20', 'Eczema', 'Topical cream', 'Completed'),
(9, 9, '2026-11-10', 'Fever', 'Paracetamol', 'Open'),
(10, 10, '2026-10-25', 'Cold', 'Cough syrup', 'Completed');


-- 5. Insert billing records
INSERT INTO Billing (VisitID, BillAmount, PaymentStatus)
VALUES
(1, 1500.00, 'Paid'),
(2, 2500.00, 'Pending'),
(3, 1200.00, 'Paid'),
(4, 1000.00, 'Paid'),
(5, 1800.00, 'Pending'),
(6, 2000.00, 'Paid'),
(7, 900.00, 'Pending'),
(8, 1300.00, 'Paid'),
(9, 800.00, 'Pending'),
(10, 1100.00, 'Paid');


-- 6. Display inserted records
SELECT * FROM Patient;
SELECT * FROM Department;
SELECT * FROM Doctor;
SELECT * FROM Visit;
SELECT * FROM Billing;


-- 7. UPDATE demonstration
-- Correct a patient's address

SELECT * FROM Patient
WHERE PatientID = 1;

UPDATE Patient
SET Address = 'Anna Nagar, Chennai'
WHERE PatientID = 1;

SELECT * FROM Patient
WHERE PatientID = 1;


-- 8. DELETE demonstration
-- Insert a temporary patient and delete that record

INSERT INTO Patient (PatientName, Address, Phone)
VALUES ('Temporary Patient', 'Test Address', '9876500099');

SELECT * FROM Patient
WHERE Phone = '9876500099';

DELETE FROM Patient
WHERE Phone = '9876500099';

SELECT * FROM Patient
WHERE Phone = '9876500099';


-- 9. Retrieve patients who visited in November 2026

SELECT
    P.PatientID,
    P.PatientName,
    V.VisitDate,
    V.Diagnosis,
    V.Status
FROM Patient P
INNER JOIN Visit V
    ON P.PatientID = V.PatientID
WHERE V.VisitDate >= '2026-11-01'
  AND V.VisitDate < '2026-12-01'
ORDER BY V.VisitDate;


-- 10. Retrieve doctors belonging to the Cardiology department
-- Using WHERE and LIKE

SELECT
    D.DoctorID,
    D.DoctorName,
    DP.DepartmentName
FROM Doctor D
INNER JOIN Department DP
    ON D.DepartmentID = DP.DepartmentID
WHERE DP.DepartmentName LIKE '%Cardio%';


-- 11. ALTER TABLE: Add insurance_id column

ALTER TABLE Patient
ADD insurance_id VARCHAR(30) NULL;


-- Verify the new column
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Patient';


-- 12. ALTER TABLE: Rename Doctor table to Physician

EXEC sp_rename 'dbo.Doctor', 'Physician';


-- Verify renamed table
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';


-- 13. ALTER TABLE: Drop the unique department-name constraint

ALTER TABLE Department
DROP CONSTRAINT UQ_Department_DepartmentName;


-- Verify remaining constraints on Department
SELECT name
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('dbo.Department');


-- Final verification
SELECT * FROM Patient;
SELECT * FROM Department;
SELECT * FROM Physician;
SELECT * FROM Visit;
SELECT * FROM Billing;
