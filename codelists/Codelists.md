# Codelists #
This page gives details on the codelists used in the Curation Harmonisation project and their sources.

## Asthma
### Primary care
* **File:** [definite_asthma_incidence_prevalence-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_asthma_incidence_prevalence-aurum_snomed_read.txt)

* **Source:** [Nissen et al., 2017](https://doi.org/10.1136%2Fbmjopen-2017-017474)

* **Additional comments:** Codes were classified as incident and/or prevalent manually using input from Professor Jenni Quint and her team (NHLI Respiratory Epidemiology team) from previous projects.

### Secondary care (ICD10)
* **File:** [HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv)

* **Source:** [HDRUK Phenotype Library: Asthma Secondary care - BREATHE recommended - 2](https://phenotypes.healthdatagateway.org/phenotypes/PH783/version/2207/detail/)

## Chronic Obstructive Pulmonary Disease (COPD)
### Primary care
* **File:** [definite_copd_incidence_prevalence-aurum_gold_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_copd_incidence_prevalence-aurum_gold_snomed_read.txt)

* **Source:** [HDRUK Phenotype Library: Chronic obstructive pulmonary disease (COPD) Primary care - 3  | SNOMED CT codes](https://phenotypes.healthdatagateway.org/phenotypes/PH797/detail/)

* **Additional comments:**
  - The codes were selected where column 'BREATHE recommended' is 'Y'.
  - The incident/prevalent tags were re-classified for this project and approved by Professor Jenni Quint. Any code descriptions containing regex _"follow|manage|plan|review|multiple.*emergency|emergency.*since|monitor|rescue pack|invite|exacerbations in past"_ had incident set to 0 and prevalent set to 1.

### Secondary care (ICD10)
* **File:** [HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv)

* **Source:** [HDRUK Phenotype Library: Chronic obstructive pulmonary disease (COPD) Secondary care - BREATHE recommended - 2](https://phenotypes.healthdatagateway.org/phenotypes/PH798/detail/)

## Interstitial Lung Disease (ILD)
### Primary care
* **File:** [definite_ild_incidence_prevalence_classification-aurum_snomed_read.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/definite_ild_incidence_prevalence_classification-aurum_snomed_read.txt)

* **Source:** NHLI Respiratory Epidemiology team (including [validated Idiopathic Pulmonary Fibrosis (IPF) codes](https://github.com/NHLI-Respiratory-Epi/Validation-of-the-recording-of-Idiopathic-Pulmonary-Fibrosis-in-routinely-collected-electronic-healt/blob/main/broad_and_narrow_ipf-aurum_snomed_read.tsv) from [Morgan et al., 2023](https://doi.org/10.1186/s12890-023-02550-0)

* **Additional comments:**
  - ILD is hard to code up due to the heterogenous nature so we used a draft master codelist from NHLI Respiratory Epidemiology team available **here** which tagged codes into definite or possible ILD as well as possible or definite various ILD subclassifications with multiple clinicians' input, and adapted it for this project.
  - We used only codes tagged as definite ILD and dropped the following codes from the master codelist with descriptions: _"alveolar capillary block", "alveolar microlithiasis", "alveolar proteinosis", "alveolitis due to cryptostroma corticale"_
  - ILD subclassifications were re-done with Professor Jenni Quint's approval:
      - Due to the challenging nature of distinguishing ILD subclassifications, we simplified categories to the following: broad IPF, narrow IPF, treatment-related, exposure-related, autoimmune-related and other
      - Broad and narrow IPF codes were changed to match those validated in [Morgan et al., 2023](https://doi.org/10.1186/s12890-023-02550-0)
      - Any code descriptions with regex _'drug|radiation'_ were reclassified to treatment-related ILD
      - Any code descriptions with definite subclassification of pneumoconiosis or hypersensitivity pneumonitis (HP) in master codelist or with regex _'progressive massive fibrosis|pneumoconios(i|e)s|pneumomelanosis|pneumopathy.*dust|bauxite|shaver|amianthosis|corundum smelt|graphit|melan(o)?edema|silic(otic|atosis|osis)|aluminosis|anthracosis|black lung|asbestos|miner|flax|steel|coal|cannabinosis|colliers|talc|sidero(sis|tic)|welder|stannosis|allergic pneumonitis|(bronchitis and pneumonitis|chronic pulmonary fibrosis|acute).*chemical fumes'_ were reclassified to exposure-related ILD
      - Any code descriptions with definite subclassification of rheumatoid arthritis (RA)-ILD or Scleroderma-Associated (SSc)-ILD in master codelist (and not in any of the previous subclassification) or with regex _'sarcoidosis|rheumatoid arthritis|scler|lupus|sjogren|polymyositis|connective|granulomatosis|dermatomyositis|collagen'_ were reclassified to autoimmune-related ILD
      - All other codes were reclassified as other ILD
  
### Secondary care (ICD10)
* **File:** [ild-icd10.txt](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/ild-icd10.txt)

* **Source:** NHLI Respiratory Epidemiology team

* **Additional comments:**
  - To match ILD primary care codelist, the same ILD subclassifications were applied here: broad IPF, narrow IPF, treatment-related, exposure-related, autoimmune-related and other
  - Some primary care code descriptions match the ICD10 descriptions so the same classifications were given for these codes.
  - For the rest of the unclassified codes, the following regexes were applied with resulting classifications approved by Professor Jenni Quint:
    - Any code descriptions with regex _'drug|radiation'_ were classified as treatment-related ILD
    - Any code descriptions with regex _'progressive massive fibrosis|pneumoconios(i|e)s|pneumomelanosis|pneumopathy.*dust|bauxite|shaver|amianthosis|corundum smelt|graphit|melan(o)?edema|silic(otic|atosis|osis)|aluminosis|anthracosis|black lung|asbestos|miner|flax|steel|coal|cannabinosis|colliers|talc|sidero(sis|tic)|welder|stannosis|bird|hypersensitivity|dust|aspergillosis|chemical|farmer|maltworker|maple-bark|mushroom'_ were classified as exposure-related ILD (except code M32.0 which is treatment-related)
    - Any code descriptions with regex _'sarcoidosis|rheum|scler|lupus|sjogren|connective|granulomatosis|dermatomyositis|collagen|sjogren|hiv|myositis|polyarteritis|overlap'_ were classified as autoimmune-related ILD
    - Any codes with regex _'^J84($|\\.[189])'_ were classified as broad IPF
    - Any code descriptions with regex _'food|solids|essences|langerhans|alveolar and parietoalveolar conditions|external'_ or codes with regex _'^J9(8\\.[24]|9$)'_ were classified as other ILD
    - No codes were given a classification of narrow IPF

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
