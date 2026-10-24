CREATE DATABASE healthcare_db;

USE healthcare_db;

-- Create table and import Data :
CREATE TABLE healthcare (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    `Blood Type` VARCHAR(5),
    `Medical Condition` VARCHAR(100),
    `Date of Admission` VARCHAR(20),
    Doctor VARCHAR(150),
    Hospital VARCHAR(200),
    `Insurance Provider` VARCHAR(100),
    `Billing Amount` DECIMAL(12,2),
    `Room Number` INT,
    `Admission Type` VARCHAR(30),
    `Discharge Date` VARCHAR(20),
    Medication VARCHAR(100),
    `Test Results` VARCHAR(50)
);

SELECT COUNT(*) AS total_records FROM healthcare;

SELECT * FROM healthcare LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    SUM(
        CASE
            WHEN `Date of Admission` IS NOT NULL
             AND STR_TO_DATE(`Date of Admission`, '%d-%m-%Y') IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_admission_dates,
    SUM(
        CASE
            WHEN `Discharge Date` IS NOT NULL
             AND STR_TO_DATE(`Discharge Date`, '%d-%m-%Y') IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_discharge_dates
FROM healthcare;

DESCRIBE healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Check Missing Values :
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN `Blood Type` IS NULL THEN 1 ELSE 0 END) AS missing_blood_type,
    SUM(CASE WHEN `Medical Condition` IS NULL THEN 1 ELSE 0 END) AS missing_medical_condition,
    SUM(CASE WHEN `admission_date_new` IS NULL THEN 1 ELSE 0 END) AS missing_admission_date,
    SUM(CASE WHEN Doctor IS NULL THEN 1 ELSE 0 END) AS missing_doctor,
    SUM(CASE WHEN Hospital IS NULL THEN 1 ELSE 0 END) AS missing_hospital,
    SUM(CASE WHEN `Insurance Provider` IS NULL THEN 1 ELSE 0 END) AS missing_insurance,
    SUM(CASE WHEN `Billing Amount` IS NULL THEN 1 ELSE 0 END) AS missing_billing_amount,
    SUM(CASE WHEN `Room Number` IS NULL THEN 1 ELSE 0 END) AS missing_room_number,
    SUM(CASE WHEN `Admission Type` IS NULL THEN 1 ELSE 0 END) AS missing_admission_type,
    SUM(CASE WHEN `discharge_date_new` IS NULL THEN 1 ELSE 0 END) AS missing_discharge_date,
    SUM(CASE WHEN Medication IS NULL THEN 1 ELSE 0 END) AS missing_medication,
    SUM(CASE WHEN `Test Results` IS NULL THEN 1 ELSE 0 END) AS missing_test_results
FROM healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Check Duplicate Records :
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT
        Name, Age, Gender, `Blood Type`,
        `Medical Condition`, `admission_date_new`,
        Doctor, Hospital, `Insurance Provider`,
        `Billing Amount`, `Room Number`,
        `Admission Type`, `discharge_date_new`,
        Medication, `Test Results`
    ) AS unique_records
FROM healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Identify Duplicate Records :
-- Identify Duplicate Records
SELECT
    Name,
    Age,
    Gender,
    `Blood Type`,
    `Medical Condition`,
    `admission_date_new`,
    Doctor,
    Hospital,
    `Insurance Provider`,
    `Billing Amount`,
    `Room Number`,
    `Admission Type`,
    `discharge_date_new`,
    Medication,
    `Test Results`,
    COUNT(*) AS duplicate_count
FROM healthcare
GROUP BY
    Name,
    Age,
    Gender,
    `Blood Type`,
    `Medical Condition`,
    `admission_date_new`,
    Doctor,
    Hospital,
    `Insurance Provider`,
    `Billing Amount`,
    `Room Number`,
    `Admission Type`,
    `discharge_date_new`,
    Medication,
    `Test Results`
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Identify Extra Duplicate Records :
SELECT
    SUM(duplicate_count) AS records_in_duplicate_groups,
    SUM(duplicate_count - 1) AS extra_duplicate_records
FROM (
    SELECT COUNT(*) AS duplicate_count
    FROM healthcare
    GROUP BY
        Name, Age, Gender, `Blood Type`,
        `Medical Condition`, `admission_date_new`,
        Doctor, Hospital, `Insurance Provider`,
        `Billing Amount`, `Room Number`,
        `Admission Type`, `discharge_date_new`,
        Medication, `Test Results`
    HAVING COUNT(*) > 1
) AS duplicates;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Create Backup :
CREATE TABLE healthcare_backup AS SELECT * FROM healthcare;

SELECT COUNT(*) AS backup_records FROM healthcare_backup;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Add Unique ID :
ALTER TABLE healthcare
ADD COLUMN record_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT record_id, Name, Age FROM healthcare LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Data Cleaning :
CREATE TABLE healthcare_clean LIKE healthcare;

INSERT INTO healthcare_clean
(
    Name, Age, Gender, `Blood Type`, `Medical Condition`,
    `admission_date_new`, Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`, `Admission Type`,
    `discharge_date_new`, Medication, `Test Results`
)
SELECT DISTINCT
    Name, Age, Gender, `Blood Type`, `Medical Condition`,
    `admission_date_new`, Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`, `Admission Type`,
    `discharge_date_new`, Medication, `Test Results`
FROM healthcare;

SELECT COUNT(*) AS total_records FROM healthcare_clean;

SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT
           Name, Age, Gender, `Blood Type`, `Medical Condition`,
           `admission_date_new`, Doctor, Hospital, `Insurance Provider`,
           `Billing Amount`, `Room Number`, `Admission Type`,
           `discharge_date_new`, Medication, `Test Results`
       ) AS unique_records
FROM healthcare_clean;

SELECT * FROM healthcare_clean LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Calculate Patient Length of Stay (LOS) :
SELECT
    Name,
    `admission_date_new`,
    `discharge_date_new`,
    DATEDIFF(
        `discharge_date_new`,
        `admission_date_new`
    ) AS Length_of_Stay
FROM healthcare_clean
LIMIT 10;

ALTER TABLE healthcare_clean ADD COLUMN Length_of_Stay INT;

UPDATE healthcare_clean SET Length_of_Stay = DATEDIFF(`discharge_date_new`, `admission_date_new`);

SELECT `admission_date_new`, `discharge_date_new`, Length_of_Stay FROM healthcare_clean LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Calculate Total Patient :
SELECT COUNT(*) AS Total_Patients FROM healthcare_clean;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Calculate Average Patient :
SELECT ROUND(AVG(Age), 2) AS Average_Patient_Age FROM healthcare_clean;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Male vs Female Patient Distribution :
SELECT Gender, COUNT(*) AS Total_Patients, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_clean),2) AS Percentage
FROM healthcare_clean
GROUP BY Gender
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Medical Conditions :
SELECT `Medical Condition`, COUNT(*) AS Total_Patients
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Average Hospital Billing by Medical Condition :
SELECT `Medical Condition`,
    ROUND(AVG(`Billing Amount`), 2) AS Average_Billing,
    ROUND(SUM(`Billing Amount`), 2) AS Total_Billing
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Average_Billing DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Patients by Admission Type :
SELECT `Admission Type`, COUNT(*) AS Total_Patients, ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM healthcare_clean),2) AS Percentage
FROM healthcare_clean
GROUP BY `Admission Type`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Patient Length of Stay by Medical Condition :
SELECT `Medical Condition`,
    ROUND(AVG(Length_of_Stay), 2) AS Average_Stay_Days,
    MAX(Length_of_Stay) AS Maximum_Stay_Days,
    MIN(Length_of_Stay) AS Minimum_Stay_Days
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Average_Stay_Days DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Monthly Patient Admissions :
SELECT MONTHNAME(`admission_date_new`) AS Admission_Month, COUNT(*) AS Total_Admissions
FROM healthcare_clean
GROUP BY MONTH(`admission_date_new`), MONTHNAME(`admission_date_new`)
ORDER BY Total_Admissions DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Analyze Hospital-wise Patient Count :
SELECT Hospital, COUNT(*) AS Total_Patients
FROM healthcare_clean
GROUP BY Hospital ORDER BY Total_Patients DESC LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Insurance Provider Analysis :
SELECT
    `Insurance Provider`,
    COUNT(*) AS Total_Patients,
    ROUND(AVG(`Billing Amount`), 2) AS Average_Billing,
    ROUND(SUM(`Billing Amount`), 2) AS Total_Billing
FROM healthcare_clean
GROUP BY `Insurance Provider`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Age Group Analysis :
SELECT
    CASE
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 29 THEN '18-29'
        WHEN Age BETWEEN 30 AND 44 THEN '30-44'
        WHEN Age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS Age_Group,
    COUNT(*) AS Total_Patients,
    ROUND(AVG(`Billing Amount`), 2) AS Average_Billing
FROM healthcare_clean
GROUP BY Age_Group
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Test Results Distribution :
SELECT
    `Test Results`,
    COUNT(*) AS Total_Patients,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_clean),
        2
    ) AS Percentage
FROM healthcare_clean
GROUP BY `Test Results`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
DESCRIBE healthcare;
DESCRIBE healthcare_clean;

