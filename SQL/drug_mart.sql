-- Identify drugs and their names used
WITH drug_terms AS (
SELECT de.person_id, de.drug_concept_id, c.concept_name as name_of_drug
FROM bigquery-public-data.cms_synthetic_patient_data_omop.drug_era 
WHERE de.drug_concept_id = c.concept_id),


CREATE OR REPLACE TABLE cms_omop_pr.drug_mart AS
SELECT pc.pid, pc.died, pc.gender, pc.race, pc.condition, dd.name_of_drug
FROM patient_conditions pc
LEFT JOIN drug_dems dt
ON pc.pid = dd.person_id

-- medical adherance
-- drug classes (opiods, etc.)
;