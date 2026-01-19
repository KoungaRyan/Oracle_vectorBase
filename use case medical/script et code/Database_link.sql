DROP DATABASE LINK mysql_link;

CREATE DATABASE LINK mysql_link
CONNECT TO "ryan" IDENTIFIED BY "ryan23"
USING 'mysql_dsn';

SELECT *
FROM healthcare@mysql_link
FETCH FIRST 5 ROWS ONLY;


SELECT "patient_id", "Name"
FROM "healthcare"@mysql_link
FETCH FIRST 1 ROWS ONLY;


--- creation des table externe-----
CREATE OR REPLACE VIEW healthcare_view AS
SELECT 
    "patient_id",
    "Name" AS name,
    "Age" AS age,
    "gender" As gender,
    "doctor" AS doctor,
    "hospital" AS hospital,
    "medication" AS medication,
    "Blood Type" AS blood_type,
    "Medical Condition" AS medical_condition,
    "Date of Admission" AS date_of_admission,
    "Insurance Provider" AS insurance_provider,
    "Billing Amount" AS billing_amount,
    "Room Number" AS room_number,
    "Admission Type" AS admission_type,
    "Discharge Date" AS discharge_date,
    "Test Results" AS test_results
FROM "healthcare"@mysql_link;


SELECT name, hospital, billing_amount
FROM healthcare_view
WHERE gender = 'Female'
FETCH FIRST 5 ROWS ONLY;

DESC healthcare_view;



