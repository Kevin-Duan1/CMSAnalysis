-- DATASET REVIEW
-----------------------------------------------------------------------------
-- Concepts
-- determine the necessary indexes so we may identify and derive meaning from codes
WITH gender_index AS (
    SELECT concept_id, concept_name, 
    vocabulary_id --what coding system used (SNOMED, HCPCS, etc.)
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept
    WHERE concept_id in (SELECT DISTINCT(gender_concept_id) FROM bigquery-public-data.cms_synthetic_patient_data_omop.person)
),

ethnicity_index AS (
    SELECT concept_id, concept_name, 
    vocabulary_id --what coding system used (SNOMED, HCPCS, etc.)
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept
    WHERE concept_id in (SELECT DISTINCT(ethnicity_concept_id) FROM bigquery-public-data.cms_synthetic_patient_data_omop.person)
),

race_index AS (
    SELECT concept_id, concept_name, 
    vocabulary_id --what coding system used (SNOMED, HCPCS, etc.)
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept
    WHERE concept_id in (SELECT DISTINCT(race_concept_id) FROM bigquery-public-data.cms_synthetic_patient_data_omop.person)
)

SELECT * 
FROM gender_index
UNION ALL 
SELECt * 
FROM ethnicity_index
UNION ALL
SELECT *
FROM race_index
;
-----------------------------------------------------------------------------
-- Demographics
-- summary statistics for patient death, by demographic (age, gender, etc.)
SELECT 'Overall' as demographic_group, 
'All Patients' as demographic_value, 
COUNT(DISTINCT p.person_id) as total_patients, 
COUNT(DISTINCT d.person_id) as deceased_patients, 
ROUND(COUNT(DISTINCT d.person_id) * 100.0 / COUNT(DISTINCT p.person_id), 2) as mortality_rate_percent, 
FROM`bigquery-public-data.cms_synthetic_patient_data_omop.person` p 
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON p.person_id = d.person_id

-- patient death rates for sex
UNION ALL
SELECT 'GENDER' AS demographic_group,
CASE WHEN p.gender_concept_id = 8532 THEN 'Female' 
WHEN p.gender_concept_id = 8507 THEN 'Male'
ELSE 'Other/Unknown' END AS demographic_value, 
COUNT(DISTINCT p.person_id) AS total_patients,
COUNT(DISTINCT d.person_id) AS decesed_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 / COUNT(DISTINCT p.person_id), 2) as mortality_rate_percent
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON p.person_id = d.person_id
GROUP BY p.gender_concept_id
UNION ALL
--- patient death rates for age
SELECT 'AGE' AS demographic_group,
CASE WHEN DATE_DIFF('2010-06-01', DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) < 25 THEN 'Under 25'
WHEN DATE_DIFF('2010-06-01', DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) BETWEEN 25 AND 49 THEN '25 - 49'
WHEN DATE_DIFF('2010-06-01', DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) BETWEEN 50 AND 75 THEN '50 - 75' ELSE 'Over 75' END AS demographic_value, 
COUNT(DISTINCT p.person_id) AS total_patients,
COUNT(DISTINCT d.person_id) AS decesed_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 / COUNT(DISTINCT p.person_id), 2) as mortality_rate_percent
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON p.person_id = d.person_id
GROUP BY demographic_value

UNION ALL
-- patient death rates for race
SELECT 'RACE' as demographic_group,
CASE WHEN p.race_concept_id = 8515 THEN 'ASIAN'
WHEN p.race_concept_id= 8516 THEN 'BLACK OR AFRICAN AMERICAN'
WHEN p.race_concept_id= 8527 THEN 'WHITE'
WHEN p.race_concept_id = 8557 THEN 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER'
WHEN p.race_concept_id = 8657 THEN 'AMERICAN INDIAN OR ALASKA NATIVE'
WHEN p.race_concept_id = 8522 THEN 'OTHER'
ELSE 'Unknown' END AS demographic_value,
COUNT(DISTINCT p.person_id) AS total_patients,
COUNT(DISTINCT d.person_id) AS decesed_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 / COUNT(DISTINCT p.person_id), 2) as mortality_rate_percent
FROM bigquery-public-data.cms_synthetic_patient_data_omop.person p
LEFT JOIN bigquery-public-data.cms_synthetic_patient_data_omop.death d
ON p.person_id = d.person_id
GROUP BY demographic_value

-----------------------------------------------------------------------------
-- Condition
-- Need to understand condition ids with their respective names/terms
WITH con_dict as (
SELECT concept_id, concept_name
FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept
WHERE domain_id = 'Condition'
),

con_names as (
    SELECT ce.person_id, COALESCE(cd.concept_name, 'Unknown') AS condition
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.condition_era ce
    LEFT JOIN con_dict cd
    ON ce.condition_concept_id = cn.concept_id
)


-- mortality summary for conditions
SELECT cn.condition, COUNT(DISTINCT cn.person_id) AS total_patients, COUNT(DISTINCT d.person_id) as deceased_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 / COUNT(DISTINCT cn.person_id),2) AS mortality_rate
FROM con_names cn
LEFT JOIN (SELECT person_id FROM bigquery-public-data.cms_synthetic_patient_data_omop.death) d
ON cn.person_id = d.person_id
GROUP BY cn.condition
ORDER BY mortality_rate DESC
;

-----------------------------------------------------------------------------
-- Drugs

-- determine the death rates of drugs
SELECT drug_concept_id
COUNT(DISTINCT de.person_id) AS total_patients,
COUNT(DISTINCT d.person_id) AS disease_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 /COUNT(DISTINCT de.person_id)) AS mortality_rate
FROM bigquery-public-data.cms_synthetic_patient_data_omop.drug_era de
LEFT JOIN bigquery-public-data.cms_synthetic_patient_data_omop.death d
ON de.person_id = d.person_id
GROUP BY de.drug_concept_id
ORDER BY mortality_rate DESC
;





