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
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON p.person_id = d.person_id
GROUP BY demographic_value

UNION ALL

-- Duration: 10 sec
-- Bytes Processed: 3.43 GB (3.33GB solo)
-- slot ms: 2705610
-- huge jump in processing here
(SELECT 'condition' as demographic_group,
CAST(ce.condition_concept_id AS STRING) as demographic_value,
COUNT(ce.person_id) AS total_patients,
COUNT(DISTINCT d.person_id) AS decesed_patients,
ROUND(COUNT(DISTINCT d.person_id) * 100 / COUNT(DISTINCT ce.person_id), 2) as mortality_rate_percent
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_era` ce
LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.death` d
ON d.person_id = ce.person_id
GROUP BY ce.condition_concept_id
HAVING count(ce.person_id) > 10000 -- otherwise some rare condition with small sample size exist
ORDER BY mortality_rate_percent DESC
LIMIT 10)


;

