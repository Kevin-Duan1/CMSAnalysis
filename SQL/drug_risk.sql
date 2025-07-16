-- Identify patients with polypharmacy
WITH polypharm AS (SELECT person_id, COUNT(DISTINCT drug_concept_id) AS num_meds
FROM bigquery-public-data.cms_synthetic_patient_data_omop.drug_era 
GROUP BY person_id
HAVING num_meds > 1)

CREATE OR REPLACE TABLE cms_omop_pr.drug_risk AS
SELECT pc.pid, pc.died, pc.gender, pc.race, pc.condition, ph.num_meds, 
CASE WHEN num_meds > 5  AND num_meds <= 9 THEN 'High Risk'
WHEN num_meds > 10 THEN 'Very high Risk' END AS risk_level
FROM geocoding-practice-349318.cms_omop_pr.patient_conditions pc
LEFT JOIN polypharm ph
ON pc.pid = ph.person_id

-- medical adherance
-- drug classes (opiods, etc.)
;