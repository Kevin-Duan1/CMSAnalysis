-- Create chronic conditions mart
WITH condition_concepts AS (
    SELECT concept_id, LOWER(concept_name) as concept_name
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept c
    WHERE domain_id = 'Condition'
),
condition_names AS (
    SELECT ce.condition_concept_id, ce.person_id, cc.concept_name
    FROM bigquery-public-data.cms_synthetic_patient_data_omop.condition_era ce
    LEFT JOIN condition_concepts cc
    ON ce.condition_concept_id = cc.concept_id
),
patient_cond AS(
    SELECT  p.pid, p.age, p.died, p.ethnicity, p.gender, p.race, p.risk_level, cn.concept_name
    FROM cms_omop_pr.patient_dems_1000 p
    LEFT JOIN condition_names cn
    ON p.pid = cn.person_id
)
CREATE OR REPLACE TABLE conditions_flags AS
SELECT pid, age, died,ethnicity, gender, race, concept_name,
-- create flags for chronic conditions
CASE WHEN regexp_contains(concept_name, r'\b(chronic kidney|chronic obstructive pulmonary|diabetes|hypertension|dementia|alzheimer|cancer|hiv|aids|heart failure)') THEN 1 ELSE 0 END AS chronic_condition,
CASE WHEN regexp_contains(concept_name, r'\b(chronic kidney)\b') THEN 1 ELSE 0 END AS has_ckd,
CASE WHEN regexp_contains(concept_name, r'\b(chronic obstructive pulmonary)\b') THEN 1 ELSE 0 END AS has_copd,
CASE WHEN regexp_contains(concept_name, r'\b(diabetes)\b') THEN 1 ELSE 0 END AS has_diabetes,
CASE WHEN regexp_contains(concept_name, r'\b(hypertension)\b') THEN 1 ELSE 0 END AS has_hypertension,
CASE WHEN regexp_contains(concept_name, r'\b(dementia)\b') THEN 1 ELSE 0 END AS has_dementia,
CASE WHEN regexp_contains(concept_name, r'\b(alzheimer)\b') THEN 1 ELSE 0 END AS has_alzheimer,
CASE WHEN regexp_contains(concept_name, r'\b(cancer)\b') THEN 1 ELSE 0 END AS has_cancer,
CASE WHEN regexp_contains(concept_name, r'\b(hiv)\b') THEN 1 ELSE 0 END AS has_hiv,
CASE WHEN regexp_contains(concept_name, r'\b(depression|major depressive)\b') THEN 1 ELSE 0 END AS has_depression,
CASE WHEN regexp_contains(concept_name, r'\b(aids)\b') THEN 1 ELSE 0 END AS has_aids,
CASE WHEN regexp_contains(concept_name, r'\b(heart failure)\b') THEN 1 ELSE 0 END AS heart_failure
FROM patient_cond


-- need to investigate and prevent duplicates for conditions
-- v1: 3.58 gb
-- v2: 3.61 gb
;

------------------------------------------------------------------------------------------------------------------------------------
-- Dealing with duplicates for conditions and very similar conditions
CREATE OR REPLACE TABLE condition_mart AS

WITH reclassification AS (
SELECT pid, age, died,ethnicity, gender, race, 
      -- Cardiovascular conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(heart (failure|disease)|cardiac|myocardial|coronary|CHF|congestive heart)\b') THEN 'heart disease'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(hypertension|high blood pressure|HTN)\b') THEN 'hypertension'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(stroke|cerebrovascular|CVA)\b') THEN 'stroke'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(atrial fibrillation|AFib|arrhythmia)\b') THEN 'heart rhythm disorders'
      
      -- Respiratory conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(COPD|chronic obstructive|emphysema|chronic bronchitis)\b') THEN 'COPD'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(asthma)\b') THEN 'asthma'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(pulmonary fibrosis|interstitial lung)\b') THEN 'lung disease'
      
      -- Endocrine/Metabolic conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(diabetes|diabetic|DM|T1DM|T2DM)\b') THEN 'diabetes'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(thyroid|hyperthyroid|hypothyroid)\b') THEN 'thyroid disorders'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(obesity|obese|BMI)\b') THEN 'obesity'
      
      -- Kidney/Renal conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(chronic kidney|renal (failure|disease)|CKD|ESRD|dialysis)\b') THEN 'kidney disease'
      
      -- Neurological conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\bdementia\b') AND NOT REGEXP_CONTAINS(concept_name, r'(?i)\b(with|due to|secondary to)\b') THEN 'dementia'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(alzheimer|alzheimers)\b') THEN 'alzheimers'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(parkinson|parkinsons)\b') THEN 'parkinsons'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(epilepsy|seizure)\b') THEN 'epilepsy'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(multiple sclerosis|MS)\b') THEN 'multiple sclerosis'
      
      -- Cancer/Oncology
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(cancer|carcinoma|tumor|malignant|neoplasm|oncology)\b') THEN 'cancer'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(leukemia|lymphoma)\b') THEN 'blood cancer'
      
      -- Mental Health
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(depression|depressive)\b') AND NOT REGEXP_CONTAINS(concept_name, r'(?i)\b(with|due to|secondary to)\b') THEN 'depression'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(anxiety|panic)\b') THEN 'anxiety'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(bipolar|manic)\b') THEN 'bipolar disorder'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(schizophrenia|psychosis)\b') THEN 'schizophrenia'
      
      -- Musculoskeletal conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(arthritis|osteoarthritis|rheumatoid)\b') THEN 'arthritis'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(osteoporosis|bone density)\b') THEN 'osteoporosis'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(fibromyalgia)\b') THEN 'fibromyalgia'
      
      -- Gastrointestinal conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(crohn|inflammatory bowel|IBD|ulcerative colitis)\b') THEN 'inflammatory bowel disease'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(liver (disease|cirrhosis)|hepatitis)\b') THEN 'liver disease'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(gastroesophageal reflux|GERD)\b') THEN 'GERD'
      
      -- Autoimmune conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(lupus|SLE)\b') THEN 'lupus'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(rheumatoid arthritis|RA)\b') THEN 'rheumatoid arthritis'
      
      -- Blood/Hematologic conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(anemia|iron deficiency)\b') THEN 'anemia'
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(hemophilia|bleeding disorder)\b') THEN 'bleeding disorders'
      
      -- Eye conditions
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(glaucoma|macular degeneration|diabetic retinopathy)\b') THEN 'eye disease'
      
      -- Substance abuse
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(alcohol|drug|substance) (abuse|dependence|addiction)\b') THEN 'substance abuse'
      
      -- HIV/AIDS
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(HIV|AIDS)\b') THEN 'HIV/AIDS'
      
      -- Sleep disorders
      WHEN REGEXP_CONTAINS(concept_name, r'(?i)\b(sleep apnea|insomnia)\b') THEN 'sleep disorders' ELSE 'Other condition' END AS condition_type
FROM conditions_flags
WHERE chronic_condition = 1
)

SELECT pid, age, died,ethnicity, gender, race, condition_type, num as occurrence
FROM reclassification
GROUP BY condition_type, pid