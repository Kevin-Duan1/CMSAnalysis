-- Create chronic conditions mart
-- simplify condition names and group
SELECT p.pid, p.age, p.died, p.ethnicity, p.gender, p.race, p.risk_level, c.concept_name,
-- create flags for chronic conditions
CASE WHEN regexp_contains(c.concept_name, r'\b(chronic kidney|chronic obstructive pulmonary|diabetes|hypertension|dementia|alzheimer|cancer|hiv|aids|heart failure)') THEN 1 ELSE 0 END AS chronic_condition,
CASE WHEN regexp_contains(c.concept_name, r'\b(chronic kidney)\b') THEN 1 ELSE 0 END AS has_ckd,
CASE WHEN regexp_contains(c.concept_name, r'\b(chronic obstructive pulmonary)\b') THEN 1 ELSE 0 END AS has_copd,
CASE WHEN regexp_contains(c.concept_name, r'\b(diabetes)\b') THEN 1 ELSE 0 END AS has_diabetes,
CASE WHEN regexp_contains(c.concept_name, r'\b(hypertension)\b') THEN 1 ELSE 0 END AS has_hypertension,
CASE WHEN regexp_contains(c.concept_name, r'\b(dementia)\b') THEN 1 ELSE 0 END AS has_dementia,
CASE WHEN regexp_contains(c.concept_name, r'\b(alzheimer)\b') THEN 1 ELSE 0 END AS has_alzheimer,
CASE WHEN regexp_contains(c.concept_name, r'\b(cancer)\b') THEN 1 ELSE 0 END AS has_cancer,
CASE WHEN regexp_contains(c.concept_name, r'\b(hiv)\b') THEN 1 ELSE 0 END AS has_hiv,
CASE WHEN regexp_contains(c.concept_name, r'\b(aids)\b') THEN 1 ELSE 0 END AS has_aids,
CASE WHEN regexp_contains(c.concept_name, r'\b(heart failure)\b') THEN 1 ELSE 0 END AS heart_failure
FROM cms_omop_pr.patient_dems_1000 p
LEFT JOIN bigquery-public-data.cms_synthetic_patient_data_omop.condition_era ce
ON p.pid = ce.person_id
LEFT JOIN bigquery-public-data.cms_synthetic_patient_data_omop.concept c
ON ce.condition_concept_id = c.concept_id
WHERE regexp_contains(c.concept_name, r'\b(chronic kidney|chronic [a-z0-9 ]*pulmonary|diabetes|hypertension|dementia|alzheimer|cancer|hiv|aids|heart failure)')
;
