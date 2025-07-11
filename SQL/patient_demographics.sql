-- subset data to test queries and minimize costs

-- Duration: 5 sec
-- Bytes Processed: 125 MB
-- slot ms: 7580
CREATE OR REPLACE TABLE cms_omop_pr.patient_dems_1000 AS 

WITH base_dems AS (
  SELECT 
    p.person_id AS pid,
    CASE WHEN p.gender_concept_id = 8532 THEN 'Female' 
         WHEN p.gender_concept_id = 8507 THEN 'Male'
         ELSE 'Other/Unknown' END AS gender,
    CASE WHEN p.race_concept_id = 8516 THEN 'BLACK OR AFRICAN AMERICAN'
         WHEN p.race_concept_id = 8527 THEN 'WHITE'
         ELSE 'UNKNOWN' END AS race,
    CASE WHEN p.ethnicity_concept_id = 38003564 THEN 'Not Hispanic or Latino'
         WHEN p.ethnicity_concept_id = 38003563 THEN 'Hispanic or Latino'
         ELSE 'UNKNOWN' END AS ethnicity,
    DATE_DIFF('2010-06-01', DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) AS age,
    CASE WHEN d.person_id IS NOT NULL THEN 1 ELSE 0 END AS died
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
  LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
    ON p.person_id = d.person_id
),

with_rownum AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY died ORDER BY RAND()) AS rand_per_group
  FROM base_dems
)

SELECT 
  pid, gender, race, ethnicity, age, died,
  CASE 
    WHEN age <= 64 THEN 'Low Risk'
    WHEN age BETWEEN 65 AND 74 THEN 'Medium Risk'
    WHEN age BETWEEN 75 AND 84 THEN 'High Risk'
    WHEN age >= 85 THEN 'Very High Risk'
  END AS risk_level
FROM with_rownum
WHERE rand_per_group <= 1000;


-- FULL QUERY
------------------------------------------------------------------------------------------------------------------------------
-- Duration: 2 sec
-- Bytes Processed: 126 MB
-- slot ms: 7572

SELECT p.person_id as pid, 
CASE WHEN p.gender_concept_id = 8532 THEN 'Female' 
WHEN p.gender_concept_id = 8507 THEN 'Male'
ELSE 'Other/Unknown' END AS gender, 
CASE WHEN p.race_concept_id= 8516 THEN 'BLACK OR AFRICAN AMERICAN'
WHEN p.race_concept_id= 8527 THEN 'WHITE'
ELSE 'UNKNOWN' END AS race,
CASE WHEN p.ethnicity_concept_id = 38003564 THEN 'Not Hispanic or Latino'
WHEN p.ethnicity_concept_id = 38003563 THEN 'Hispanic or Latino' END AS ethnicity,
DATE_DIFF('2010-06-01', DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) AS age,
CASE WHEN d.person_id IS NOT NULL THEN 1 else 0 END as died
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON p.person_id = d.person_id
;