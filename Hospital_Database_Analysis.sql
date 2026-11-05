CREATE DATABASE IF NOT EXISTS healthcare_db;
USE healthcare_db;

CREATE TABLE IF NOT EXISTS healthcare (
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
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Import your CSV into healthcare table now.

SELECT COUNT(*) AS total_records FROM healthcare;

SELECT * FROM healthcare LIMIT 10;

DESCRIBE healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CHECK DATE FORMAT AND INVALID DATES 
SELECT
    SUM(
        CASE
            WHEN NULLIF(TRIM(`Date of Admission`), '') IS NOT NULL
             AND STR_TO_DATE(
                 TRIM(`Date of Admission`), '%d-%m-%Y'
             ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_admission_dates,

    SUM(
        CASE
            WHEN NULLIF(TRIM(`Discharge Date`), '') IS NOT NULL
             AND STR_TO_DATE(
                 TRIM(`Discharge Date`), '%d-%m-%Y'
             ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_discharge_dates
FROM healthcare;

-- View invalid date records before conversion
SELECT *
FROM healthcare
WHERE
    (
        NULLIF(TRIM(`Date of Admission`), '') IS NOT NULL
        AND STR_TO_DATE(
            TRIM(`Date of Admission`), '%d-%m-%Y'
        ) IS NULL
    )
    OR
    (
        NULLIF(TRIM(`Discharge Date`), '') IS NOT NULL
        AND STR_TO_DATE(
            TRIM(`Discharge Date`), '%d-%m-%Y'
        ) IS NULL
    );
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CONVERT VARCHAR DATES INTO ACTUAL DATE COLUMNS
ALTER TABLE healthcare
    ADD COLUMN admission_date_new DATE,
    ADD COLUMN discharge_date_new DATE;

UPDATE healthcare SET admission_date_new = STR_TO_DATE( NULLIF(TRIM(`Date of Admission`), ''),'%d-%m-%Y'),
                      discharge_date_new = STR_TO_DATE( NULLIF(TRIM(`Discharge Date`), ''),'%d-%m-%Y');

-- Verify converted dates
SELECT `Date of Admission`, admission_date_new,
       `Discharge Date`, discharge_date_new
FROM healthcare LIMIT 10;

-- Check for missing or invalid converted dates
SELECT
    COUNT(*) AS total_records,
    SUM(admission_date_new IS NULL) AS missing_admission_dates,
    SUM(discharge_date_new IS NULL) AS missing_discharge_dates
FROM healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE OLD VARCHAR DATE COLUMNS
ALTER TABLE healthcare
    DROP COLUMN `Date of Admission`,
    DROP COLUMN `Discharge Date`;

ALTER TABLE healthcare
    RENAME COLUMN admission_date_new TO admission_date,
    RENAME COLUMN discharge_date_new TO discharge_date;

-- Confirm actual data types
DESCRIBE healthcare;

SELECT admission_date, discharge_date FROM healthcare LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CHECK MISSING VALUES
SELECT
    COUNT(*) AS total_records,
    SUM(Name IS NULL) AS missing_name,
    SUM(Age IS NULL) AS missing_age,
    SUM(Gender IS NULL) AS missing_gender,
    SUM(`Blood Type` IS NULL) AS missing_blood_type,
    SUM(`Medical Condition` IS NULL) AS missing_medical_condition,
    SUM(admission_date IS NULL) AS missing_admission_date,
    SUM(Doctor IS NULL) AS missing_doctor,
    SUM(Hospital IS NULL) AS missing_hospital,
    SUM(`Insurance Provider` IS NULL) AS missing_insurance,
    SUM(`Billing Amount` IS NULL) AS missing_billing_amount,
    SUM(`Room Number` IS NULL) AS missing_room_number,
    SUM(`Admission Type` IS NULL) AS missing_admission_type,
    SUM(discharge_date IS NULL) AS missing_discharge_date,
    SUM(Medication IS NULL) AS missing_medication,
    SUM(`Test Results` IS NULL) AS missing_test_results
FROM healthcare;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CHECK DUPLICATE RECORDS
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT
        Name, Age, Gender, `Blood Type`,
        `Medical Condition`, admission_date,
        Doctor, Hospital, `Insurance Provider`,
        `Billing Amount`, `Room Number`,
        `Admission Type`, discharge_date,
        Medication, `Test Results`
    ) AS unique_records
FROM healthcare;

-- Identify duplicate groups
SELECT
    Name, Age, Gender, `Blood Type`,
    `Medical Condition`, admission_date,
    Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`,
    `Admission Type`, discharge_date,
    Medication, `Test Results`,
    COUNT(*) AS duplicate_count
FROM healthcare
GROUP BY
    Name, Age, Gender, `Blood Type`,
    `Medical Condition`, admission_date,
    Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`,
    `Admission Type`, discharge_date,
    Medication, `Test Results`
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Calculate extra duplicate records
SELECT
    SUM(duplicate_count) AS records_in_duplicate_groups,
    SUM(duplicate_count - 1) AS extra_duplicate_records
FROM (
    SELECT COUNT(*) AS duplicate_count
    FROM healthcare
    GROUP BY
        Name, Age, Gender, `Blood Type`,
        `Medical Condition`, admission_date,
        Doctor, Hospital, `Insurance Provider`,
        `Billing Amount`, `Room Number`,
        `Admission Type`, discharge_date,
        Medication, `Test Results`
    HAVING COUNT(*) > 1
) AS duplicates;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE BACKUP

CREATE TABLE healthcare_backup AS SELECT * FROM healthcare;

SELECT COUNT(*) AS backup_records FROM healthcare_backup;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- ADD UNIQUE RECORD ID
ALTER TABLE healthcare ADD COLUMN record_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT record_id, Name, Age FROM healthcare LIMIT 10;

-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE CLEAN TABLE AND REMOVE DUPLICATES
DROP TABLE IF EXISTS healthcare_clean;

CREATE TABLE healthcare_clean LIKE healthcare;

INSERT INTO healthcare_clean (
    Name, Age, Gender, `Blood Type`,
    `Medical Condition`, admission_date,
    Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`,
    `Admission Type`, discharge_date,
    Medication, `Test Results`
)
SELECT DISTINCT
    Name, Age, Gender, `Blood Type`,
    `Medical Condition`, admission_date,
    Doctor, Hospital, `Insurance Provider`,
    `Billing Amount`, `Room Number`,
    `Admission Type`, discharge_date,
    Medication, `Test Results`
FROM healthcare;

-- Verify clean records
SELECT COUNT(*) AS cleaned_records FROM healthcare_clean;

SELECT * FROM healthcare_clean LIMIT 10;

DESCRIBE healthcare_clean;

-- ------------------------------------------------------------------------------------------------------------------------------------------
-- CALCULATE LENGTH OF STAY
ALTER TABLE healthcare_clean ADD COLUMN Length_of_Stay INT;

UPDATE healthcare_clean SET Length_of_Stay = DATEDIFF(discharge_date, admission_date);

SELECT Name, admission_date, discharge_date, Length_of_Stay FROM healthcare_clean LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- DATA ANALYSIS
-- 1. Total Patients
SELECT COUNT(*) AS Total_Patients FROM healthcare_clean;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Average Patient Age
SELECT ROUND(AVG(Age), 2) AS Average_Patient_Age FROM healthcare_clean;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Male vs Female Distribution
SELECT
    Gender,
    COUNT(*) AS Total_Patients,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM healthcare_clean), 2
    ) AS Percentage
FROM healthcare_clean
GROUP BY Gender
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Medical Conditions
SELECT
    `Medical Condition`,
    COUNT(*) AS Total_Patients
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Average and Total Billing by Medical Condition
SELECT
    `Medical Condition`,
    ROUND(AVG(`Billing Amount`), 2) AS Average_Billing,
    ROUND(SUM(`Billing Amount`), 2) AS Total_Billing
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Average_Billing DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Patients by Admission Type
SELECT
    `Admission Type`,
    COUNT(*) AS Total_Patients,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM healthcare_clean), 2
    ) AS Percentage
FROM healthcare_clean
GROUP BY `Admission Type`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Length of Stay by Medical Condition
SELECT
    `Medical Condition`,
    ROUND(AVG(Length_of_Stay), 2) AS Average_Stay_Days,
    MAX(Length_of_Stay) AS Maximum_Stay_Days,
    MIN(Length_of_Stay) AS Minimum_Stay_Days
FROM healthcare_clean
GROUP BY `Medical Condition`
ORDER BY Average_Stay_Days DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 8. Monthly Patient Admissions
SELECT
    MONTHNAME(admission_date) AS Admission_Month,
    COUNT(*) AS Total_Admissions
FROM healthcare_clean
GROUP BY
    MONTH(admission_date),
    MONTHNAME(admission_date)
ORDER BY MONTH(admission_date);
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 9. Top 10 Hospitals by Patient Count
SELECT
    Hospital,
    COUNT(*) AS Total_Patients
FROM healthcare_clean
GROUP BY Hospital
ORDER BY Total_Patients DESC
LIMIT 10;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 10. Insurance Provider Analysis
SELECT
    `Insurance Provider`,
    COUNT(*) AS Total_Patients,
    ROUND(AVG(`Billing Amount`), 2) AS Average_Billing,
    ROUND(SUM(`Billing Amount`), 2) AS Total_Billing
FROM healthcare_clean
GROUP BY `Insurance Provider`
ORDER BY Total_Patients DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 11. Age Group Analysis
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
-- 12. Test Results Distribution
SELECT
    `Test Results`,
    COUNT(*) AS Total_Patients,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM healthcare_clean), 2
    ) AS Percentage
FROM healthcare_clean
GROUP BY `Test Results`
ORDER BY Total_Patients DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------------
-- FINAL TABLE STRUCTURE

DESCRIBE healthcare;
DESCRIBE healthcare_clean;

SELECT COUNT(*) AS raw_records FROM healthcare;
SELECT COUNT(*) AS clean_records FROM healthcare_clean;
