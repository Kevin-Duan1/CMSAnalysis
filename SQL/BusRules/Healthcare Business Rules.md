# Healthcare Business Rules

## Patient Demographics
**Age Bands:**
- 0–17: Under 18
- 18–34: Adult
- 35–54: Late Adult
- 55–74: Early senior
- 75+: Late Senior

**Gender Specific Risk**
- Prostate cancer risk → Male only
- Breast cancer screening → Female, age 40–74
- Pregnancy-related exclusions → Female, age below 12 and 50+

**Race/Ethnicity Adjustments**
- Black patients → Higher hypertension prevalence
- Hispanic patients → Higher diabetes risk
- Asian patients → Higher stroke risk at lower BMI

## Condition-based rules
**Chronic Conditions with high mortality**
- Congestive Heart Failure (CHF)
- Chronic Kidney Disease (CKD) Stage 3+
- Chronic Obstructive Pulmonary Disease (COPD)
- Diabetes with complications (e.g., neuropathy, nephropathy)
- Cancer (especially metastatic or hematologic)
- Dementia or Alzheimer’s
- HIV/AIDS

**Comorbidity risk**
- ≥3 chronic conditions → High-risk cohort
- Charlson Comorbidity Index ≥ 5 → Elevated mortality (will need to implement in database)

## Drug-based rules
**Polypharmacy**
- ≥5 concurrent medications → Moderate risk
- ≥10 concurrent medications → High risk (flag for review)

**Drug classes**
- Opioids (especially long-acting or high-dose)
- Antipsychotics in elderly (linked to increased mortality)
- Benzodiazepines (fall risk, respiratory depression)
- Chemotherapy agents (flag for cancer cohort)
- Immunosuppressants (e.g., post-transplant)

**Medication rules**
- Proportion of Days Covered (PDC) < 80% → Non-adherent
- Gaps > 30 days in chronic meds → Risk of hospitalization