# Codelist sources #
This page gives details on the codelists used in the Curation Harmonisation project and their sources.

## Asthma
### Primary care
* **File:** [definite_asthma_incidence_prevalence-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_asthma_incidence_prevalence-aurum_snomed_read.txt)

* **Source:** [Nissen et al., 2017](https://doi.org/10.1136%2Fbmjopen-2017-017474)

* **Additional comments:** Codes were classified as incident and/or prevalent manually using input from Professor Jenni Quint and her team.

### Secondary care
* **File:** [HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv)

* **Source:** [HDRUK Phenotype Library: Asthma Secondary care - BREATHE recommended - 2](https://phenotypes.healthdatagateway.org/phenotypes/PH783/version/2207/detail/)

## Chronic Obstructive Pulmonary Disease (COPD)
### Primary care
* **File:** [definite_copd_incidence_prevalence-aurum_gold_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_copd_incidence_prevalence-aurum_gold_snomed_read.txt)

* **Source:** [HDRUK Phenotype Library: Chronic obstructive pulmonary disease (COPD) Primary care - 3  | SNOMED CT codes](https://phenotypes.healthdatagateway.org/phenotypes/PH797/detail/)

* **Additional comments:**
  - The codes were selected where column 'BREATHE recommended' is 'Y'.
  - The incident/prevalent tags were re-classified for this project and approved by Professor Jenni Quint. Any code descriptions containing regex _"follow|manage|plan|review|multiple.*emergency|emergency.*since|monitor|rescue pack|invite|exacerbations in past"_ had incident set to 0 and prevalent set to 1.

### Secondary care
* **File:** [HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv)

* **Source:** []()

## Interstitial Lung Disease (ILD)
### Primary care
* **File:** [definite_ild_incidence_prevalence_classification-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_ild_incidence_prevalence_classification-aurum_snomed_read.txt)

* **Source:** []()
  
### Secondary care
* **File:** [ild-icd10.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/ild-icd10.txt)

* **Source:** []()

## Ethnicity
* **File:** [ethnicity-aurum_snomed_read_hes.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/ethnicity-aurum_snomed_read_hes.txt)

* **Source:** []()

## Height/weight/BMI
* **File:** [height_weight_bmi_values-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/height_weight_bmi_values-aurum_snomed_read.txt)

* **Source:** []()

## Smoking status
* **File:** [smoking_status-aurum_gold_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/smoking_status-aurum_gold_snomed_read.txt)

* **Source:** []()

## COPD medications
* **File:** [copd_medications-aurum_dmd_bnf_read_atc.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/copd_medications-aurum_dmd_bnf_read_atc.txt)

* **Source:** []()

## Spirometry
* **File:** [spirometry-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/spirometry-aurum_snomed_read.txt)

* **Source:** NHLI Respiratory Epidemiology team
