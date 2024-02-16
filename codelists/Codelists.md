# Codelists #
This page gives details on the codelists used in the Curation Harmonisation project and their sources. 

To access original codelists that are not linked here, please contact sara.hatam@ed.ac.uk 

## Asthma
### Primary care
* **File:** [definite_asthma_incidence_prevalence-aurum_snomed_read.tsv](definite_asthma_incidence_prevalence-aurum_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; Clinical Practice Research Datalink (CPRD) Aurum medcodeid

* **Source:** [Nissen et al., 2017](https://doi.org/10.1136%2Fbmjopen-2017-017474)

* **Additional comments:** Codes were classified as incident and/or prevalent manually using input from Respiratory Electronic Health Record group led by Professor Jenni Quint.

### Secondary care
* **File:** [HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv)

* **Coding system(s)**: ICD10

* **Source:** [HDRUK Phenotype Library: Asthma Secondary care - BREATHE recommended - 2](https://phenotypes.healthdatagateway.org/phenotypes/PH783/version/2207/detail/)

## Chronic Obstructive Pulmonary Disease (COPD)
### Primary care
* **File:** [definite_copd_incidence_prevalence-aurum_gold_snomed_read.tsv](definite_copd_incidence_prevalence-aurum_gold_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid; CPRD GOLD medcode

* **Source:** [HDRUK Phenotype Library: Chronic obstructive pulmonary disease (COPD) Primary care - 3  | SNOMED CT codes](https://phenotypes.healthdatagateway.org/phenotypes/PH797/detail/)

* **Additional comments:**
  - The codes were selected where column 'BREATHE recommended' is 'Y'.
  - The incident/prevalent tags were re-classified for this project and approved by Professor Jenni Quint. Any code descriptions containing regex _"follow|manage|plan|review|multiple.*emergency|emergency.*since|monitor|rescue pack|invite|exacerbations in past"_ had incident set to 0 and prevalent set to 1.

### Secondary care 
* **File:** [HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv](https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/blob/main/codelists/HDRUKPhenotypeLibrary-PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv)

* **Coding system(s)**: ICD10
  
* **Source:** [HDRUK Phenotype Library: Chronic obstructive pulmonary disease (COPD) Secondary care - BREATHE recommended - 2](https://phenotypes.healthdatagateway.org/phenotypes/PH798/detail/)

## Interstitial Lung Disease (ILD)
### Primary care
* **File:** [definite_ild_incidence_prevalence_classification-aurum_snomed_read.tsv](definite_ild_incidence_prevalence_classification-aurum_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid

* **Source:** Adapted from codelist provided by Ann Morgan, Respiratory Electronic Health Record group (including [validated Idiopathic Pulmonary Fibrosis (IPF) codes](https://github.com/NHLI-Respiratory-Epi/Validation-of-the-recording-of-Idiopathic-Pulmonary-Fibrosis-in-routinely-collected-electronic-healt/blob/main/broad_and_narrow_ipf-aurum_snomed_read.tsv) from [Morgan et al., 2023](https://doi.org/10.1186/s12890-023-02550-0)

* **Additional comments:**
  - ILD is hard to code up due to the heterogenous nature so we used a draft master codelist from Respiratory Electronic Health Record group which tagged codes into definite or possible ILD as well as possible or definite various ILD subclassifications with multiple clinicians' input, and adapted it for this project
  - We used only codes tagged as definite ILD and dropped the following codes from the master codelist with descriptions: _"alveolar capillary block", "alveolar microlithiasis", "alveolar proteinosis", "alveolitis due to cryptostroma corticale"_
  - ILD subclassifications were re-done with Professor Jenni Quint's approval:
      - Due to the challenging nature of distinguishing ILD subclassifications, we simplified categories to the following: broad IPF, narrow IPF, treatment-related, exposure-related, autoimmune-related and other
      - Broad and narrow IPF codes were changed to match those validated in [Morgan et al., 2023](https://doi.org/10.1186/s12890-023-02550-0)
      - Any code descriptions with regex _'drug|radiation'_ were reclassified to treatment-related ILD
      - Any code descriptions with definite subclassification of pneumoconiosis or hypersensitivity pneumonitis (HP) in master codelist or with regex _'progressive massive fibrosis|pneumoconios(i|e)s|pneumomelanosis|pneumopathy.*dust|bauxite|shaver|amianthosis|corundum smelt|graphit|melan(o)?edema|silic(otic|atosis|osis)|aluminosis|anthracosis|black lung|asbestos|miner|flax|steel|coal|cannabinosis|colliers|talc|sidero(sis|tic)|welder|stannosis|allergic pneumonitis|(bronchitis and pneumonitis|chronic pulmonary fibrosis|acute).*chemical fumes'_ were reclassified to exposure-related ILD
      - Any code descriptions with definite subclassification of rheumatoid arthritis (RA)-ILD or Scleroderma-Associated (SSc)-ILD in master codelist (and not in any of the previous subclassification) or with regex _'sarcoidosis|rheumatoid arthritis|scler|lupus|sjogren|polymyositis|connective|granulomatosis|dermatomyositis|collagen'_ were reclassified to autoimmune-related ILD
      - All other codes were reclassified as other ILD
  
### Secondary care
* **File:** [ild-icd10.tsv](ild-icd10.tsv)

* **Coding system(s)**: ICD10

* **Source:** Provided by Professor Jenni Quint but adapted to include ILD subclassifications

* **Additional comments:**
  - To match ILD primary care codelist, the same ILD subclassifications were applied here (apart from narrow IPF which there were no codes matching): broad IPF, treatment-related, exposure-related, autoimmune-related and other
  - Some primary care code descriptions match the ICD10 descriptions so the same classifications were given for these codes.
  - For the rest of the unclassified codes, the following regexes were applied with resulting classifications approved by Professor Jenni Quint:
    - Any code descriptions with regex _'drug|radiation'_ were classified as treatment-related ILD
    - Any code descriptions with regex _'progressive massive fibrosis|pneumoconios(i|e)s|pneumomelanosis|pneumopathy.*dust|bauxite|shaver|amianthosis|corundum smelt|graphit|melan(o)?edema|silic(otic|atosis|osis)|aluminosis|anthracosis|black lung|asbestos|miner|flax|steel|coal|cannabinosis|colliers|talc|sidero(sis|tic)|welder|stannosis|bird|hypersensitivity|dust|aspergillosis|chemical|farmer|maltworker|maple-bark|mushroom'_ were classified as exposure-related ILD (except code M32.0 which is treatment-related)
    - Any code descriptions with regex _'sarcoidosis|rheum|scler|lupus|sjogren|connective|granulomatosis|dermatomyositis|collagen|sjogren|hiv|myositis|polyarteritis|overlap'_ were classified as autoimmune-related ILD
    - Any codes with regex _'^J84($|\\.[189])'_ were classified as broad IPF
    - Any code descriptions with regex _'food|solids|essences|langerhans|alveolar and parietoalveolar conditions|external'_ or codes with regex _'^J9(8\\.[24]|9$)'_ were classified as other ILD

## Ethnicity
* **File:** [ethnicity-aurum_snomed_read_hes.tsv](ethnicity-aurum_snomed_read_hes.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid; Hospital Episode Statistics (HES) ethnicity code

* **Source:** Adapted from [COVID-Collateral](https://github.com/johntaz/COVID-Collateral/blob/master/codelists/CSV/aurum_codelist_ethnicity.csv)

* **Additional comments:**
  - **Main changes:**
    - As the project is a UK-wide project, we chose to create variables specific to each UK nation's 2011 census categories: _EthnicityEngWales2011_, _EthnicityScot2011_ and _EthnicityNI2011_, as well as a UK-wide census 2011 variable based on [UK Government ethnicity harmonised standard](https://analysisfunction.civilservice.gov.uk/policy-store/ethnicity-harmonised-standard/#presentation-united-kingdom), named _EthnicityUK2011_
    - We also kept a broad ethnic group variable, named _Ethnicity6_, but instead of consisting of "White", "Black", "South Asian", "Mixed", "Other" and "Not Stated", we changed "South Asian" to "Asian" to match all the UK censuses 2011 and included East Asian ethnic groups in this new group
    - The table below shows the mapping between the different ethnicity variables:

      |	EthnicityEngWales2011	| EthnicityScot2011	|	EthnicityNI2011 |	EthnicityUK2011	|	Ethnicity6|	
      |----|---------|------|----|----|
      |Bangladeshi|	Bangladeshi|	Bangladeshi|	Bangladeshi|	Asian|
      |Chinese|	Chinese|	Chinese|	Chinese|	Asian|
      |Indian|	Indian|	Indian|	Indian|	Asian|
      |Other Asian|	Other Asian|	Other Asian|	Other Asian|	Asian|
      |Pakistani|	Pakistani|	Pakistani|	Pakistani|	Asian|
      |African|	African|	African|	Black African|	Black|
      |Caribbean|	Caribbean|	Caribbean|	Black Caribbean	|Black|
      |Other Black|	Other Black|	Other Black|	Other Black|	Black|
      |Other Mixed|	Other Mixed|	Mixed|	Mixed|	Mixed|
      |White and Asian|	White and Asian|	Mixed|	Mixed|	Mixed|
      |White and Black African|	White and Black African|	Mixed|	Mixed|	Mixed|
      |White and Black Caribbean|	White and Black Caribbean|	Mixed|	Mixed|	Mixed|
      |Not Stated|	Not Stated|	Not Stated|	Not Stated|	Not Stated|
      |Arab	|Arab	|Arab	|Other ethnic group|	Other|
      |Other ethnic group	|Other ethnic group	|Other ethnic group	|Other ethnic group	|Other|
      |Gypsy or Irish Traveller	|Gypsy/Traveller	|Irish Traveller	|White	|White|
      |Gypsy or Irish Traveller	|Gypsy/Traveller	|White	|White	|White|
      |Irish	|Irish	|White	|White	|White|
      |British	|Other British	|White	|White	|White|
      |Other White|	Other White	|White	|White	|White|
      |Other White	|Polish	|White	|White	|White|
      |British	|Scottish	|White	|White	|White|

  - **Codes that were dropped**:
    - Generic codes for ethnicity which may have details written in free text (originally coded as 'Not Stated'):
      - _"ethnic group finding","ethnic groups (census)","ethnic category","ethnic groups (1991 census) (uk)","ethnic groups (1991 census) (united kingdom)","ethnicity and other related nationality data","ethnic groups","ethnic category - 2001 census", "ethnic category - 2011 census", "ethnic category - 2011 census england and wales", "ethnic category - 2011 census northern ireland", "ethnic category - 2011 census scotland","ethnicity / related nationality data","ethnicity","ethnic group","ethnicity / related nationality data - finding","race","country of origin","born in - country","ethnic group (1991 census) (uk)","ethnic category - 2011 census northern ireland simple reference set","ethnic category - 2011 census england and wales simple reference set","finding of ethnicity / related nationality data","ethnic background","on examination - ethnic group","ethnic groups (1991 census)","ethnic group (1991 census) (united kingdom)","ethnic category - 2011 census scotland simple reference set"_
    - Codes with Emis code category ID of _19_ (= nationality) as infrequently used and nationality is not necessarily the same as ethnicity
    - Codes with Read code starting with '_13y'_ as they are religions/beliefs, not necessarily ethnicities
     
  - **Codes that were added**:
    - Codes with same descriptions or first three characters of Read code as those already in codelist (these were given same groupings as the original codes)
    - Codes with Emis code category ID of 22 (= ethnicity)
    - Codes with descriptions matching regex _"ethnic|^roma$"_ but not _"mother|father|carer|neutropenia|nose|lifestyle"_
    - **Codes matching those previously dropped were not re-included**
    
  - **Codes that were regrouped**:
    - 'Chinese' was regrouped in _Ethnicity6_ as 'Asian' (previously 'Other')
    - Scottish census 2011 distinguishes between 'Scottish' and 'Other British' thus the codes with the following descriptions were recoded to 'Scottish' in _EthnicityScot2011_: _"scottish - ethnic category 2001 census", "white: scottish - scotland ethnic category 2011 census", "white scottish"_
    - Scottish census 2011 also distinguishes 'Polish' from the 'Other White' category thus the codes with the following descriptions were recoded to 'Polish' in _EthnicityScot2011_: _"white: polish - scotland ethnic category 2011 census", "polish - ethnic category 2001 census"_
    - To avoid listing out each nation's census 2011 mappings (see above), we have specified the change from the original codelist variable _eth16_ to our codelist variable _EthnicityEngWales2011_ below:

   | Code description(s) |     eth16    |	EthnicityEngWales2011	  |	Reason for change    |
   |:----|:---------|:------|:------|
   | "other ethnic group: arab - eng+wales ethnic cat 2011 census", "north african - ethnic category 2001 census", "moroccan - ethnic category 2001 census", "other ethnic grp: arab/arab scot/arab british- scotland 2011", "north african arab (nmo)", "arab - ethnic category 2001 census", "other ethnic group: arab - ni ethnic category 2011 census"| Other ethnic group|Arab|Regrouping based on UK census 2011|
   |"malaysian - ethnic category 2001 census", "vietnamese - ethnic category 2001 census", "filipino - ethnic category 2001 census", "japanese - ethnic category 2001 census", "vietnamese", "asian and chinese - ethnic category 2001 census"|Other ethnic group|Other Asian|Regrouping based on UK census 2011|
  |"irish traveller - northern ireland ethnic cat 2011 census", "white: gypsy/irish traveller - eng+wales eth cat 2011 census", "white: gypsy/irish traveller - scotland ethnic cat 2011 cens", "irish traveller - ethnic category 2001 census", "irish traveller"|Irish|Gypsy or Irish Traveller|Correction/Regrouping based on UK census 2011|
  |"gypsy/romany - ethnic category 2001 census", "traveller - ethnic category 2001 census"|Other White|Gypsy or Irish Traveller|Regrouping based on UK census 2011|
   | "white" | Irish | British | Correction |
   | "other ethnic, asian/white origin","chinese and white - ethnic category 2001 census" | Other Mixed | White and Asian | Correction |
   | "new zealand ethnic groups" | Not Stated | Other ethnic group | Correction |
   | "nigerian - ethnic category 2001 census" | Other Black | African | Correction |
   |"black east african asian","black indo-caribbean","black indian sub-continent","black e afric asia/indo-caribb","black - other asian","black n african/arab/iranian","black arab","black north african","black iranian"|Other Black|Other Mixed|Correction|
   |"black guyana", "caribbean island (nmo)", "black caribbean", "caribbean i./w.i./guyana (nmo)", "black caribbean/w.i./guyana", "guyana (nmo)", "west indian (nmo)", "black west indian", "race: afro-caribbean"|Other Black|Caribbean|Correction|
   |"race: west indian", "west indian origin"|Other Asian|Caribbean|Correction|
   |"other ethnic, mixed white orig", "other ethnic, mixed white origin"|Other Mixed|Other White|Correction|
   |"o/e - ethnic group", "o/e - ethnic group nos", "o/e - ethnic origin", "ethnic groups (census) nos"|Not Stated| Other ethnic group | Correction|
   |Regexes: _"not stated", "unknown" "declined"_ |N/A| Not Stated | New code|
   |"black or african or caribbean or black british: other black or african or caribbean background - england and wales ethnic category 2011 census", "black or african or caribbean or black british: other black or african or caribbean background - northern ireland ethnic category 2011 census", "black"|N/A| Other Black | New code|
   |"caribbean or black: black, black scottish or black british - scotland ethnic category 2011 census"|N/A| Caribbean | New code|
   |"mixed multiple ethnic groups: any other mixed or multiple ethnic background - england and wales ethnic category 2011 census"|N/A| Other Mixed | New code|
   |"gypsies", "gypsy"|N/A| Gypsy or Irish Traveller | New code|
   |"portuguese", "new zealand european", "other european in new zealand", "race: white", "romanian","bulgarian", "czech", "slovak", "pakeha", "european origin", "slovak roma", "czech roma", "hungarian roma", "polish roma", "romanian roma", "bulgarian roma", "roma"|N/A| Other White | New code|
   |"arabs", "yemeni", "middle eastern origin"|N/A| Arab | New code|
   |"oriental", "japanese", "koreans", "nepalese", "nepali", "far eastern origin"|N/A| Other Asian | New code|
   |"race: chinese"|N/A| Chinese | New code|
   |"new zealand maori", "cook island maori", "brazilian", "niuean", "tokelauan", "fijian", "tongan", "samoan", "ethnic groups (census) nos", "country of origin nos", "north american origin", "south american origin", "australian origin", "tokelau"|N/A| Other ethnic group | New code|
   |"mixed racial group"|N/A| Other Mixed | New code|

## Height/weight/BMI
* **File:** [height_weight_bmi_values-aurum_snomed_read.tsv](height_weight_bmi_values-aurum_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid

* **Source:** Created for the Curation Harmonisation project

* **Additional comments:**
  - While there were many codelists available online for height/weight/body mass index, we decided to perform our own comprehensive search in the CPRD Aurum medical dictionary using the following regexes:
    - **Height:** matching _"height"_ AND not matching _"knee height|average|unsuitable|ratio|centile|uterus|uterine|predict|heightened|refuse|weight|furniture|injury|unfit|footwear|sitting|fear|fundal|step|parent|jump|waterlow|over|under|weight for height|bp|fall|growth|declined"_
    - **Weight:** matching _"weight|obese"_ AND not matching _"body mass index|bmi|obese class|waterlow|knee|%|fetal|target|not available|referral|prostate|liver|diet|diffusion|injury|baseline weight|maternal|manage|vomit|centile|ideal|los|eating disorder|difficult|infant|premature|weightless|fixation|bearing|monitor|birth|symptom|weight decreas|obese build|symptomlesion|unfit|steady|sweat|velocity|lift|foot|placenta|eyelid|problem|static|education|therapy|trial|percentage|overweight child|pregnancy|bear|transfer|refus|concern|not done|unsuitable|maint|change|7pcl|trend|heparin|decline|kininogen|mth exam|stable|dry|height|childhood failure|weights|calculus|heavy|counterweight|preoccupation|procedure|ratio|chart|g/kg|property|regimen|amount|abdomen|estimate|tolerance|weighted|intervention|oedema|reason|weight - baby|clinic|(reference|sample) weight|risk to health|pattern|unintentional"_
    - **BMI:** matching _"bmi|body mass index"_ AND not matching _"frax|submit|malnutrition universal screening tool|target|framingham|percentage|maximum"_
  -  Then we looked at the CPRD Aurum data for our cohorts to find out which codes actually had useful data values (or had similar descriptions to those with useful data values) and confirmed this new codelist with Professor Jenni Quint

## Smoking status
* **File:** [smoking_status-aurum_gold_snomed_read.tsv](smoking_status-aurum_gold_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid; CPRD GOLD medcode

* **Source:** []()

## COPD medications
* **File:** [copd_medications-aurum_dmd_bnf_read_atc.tsv](copd_medications-aurum_dmd_bnf_read_atc.tsv)

* **Coding system(s)**: Read; Dictionary of medicines and devices (dm+d); British National Formulary (BNF); Anatomical Therapeutic Chemical (ATC); CPRD Aurum prodcodeid

* **Source:** Adapted from codelist provided by Hannah Whittaker, Respiratory Electronic Health Record group led by Professor Jenni Quint

* **Additional comments:**
  - Hannah Whittaker's codelist was updated in collaboration with Professor Jenni Quint
  - The _groups_ variable in the original codelist was replaced with a new variable _category_ which gives explicit categories to each drug:
    - 'abx' = antibiotics
    - 'ocs' = oral corticosteroids
    - 'ics' = inhaled corticosteroids
    - 'laba' = long-acting bronchodilator (LABA) inhalers
    - 'lama' = long-acting muscarinic antagonist (LAMA) inhalers
    - 'saba' = short-acting bronchodilator (SABA) inhalers
    - 'sama' = short-acting muscarinic antagonist (SAMA) inhalers
    - 'laba-ics' = combination of LABA and ICS
    - 'laba-lama' = combination of LABA and LAMA
    - 'saba-sama' = combination of SABA and SAMA
    - 'triple' = triple inhaled therapy (i.e ICS + LABA + LAMA) 
  - Codes were added:
    - Theophylline drugs (_category_ = 'theophylline') were added by finding drugs with _"theophylline sodium glycinate", "theophylline"_ in _DrugSubstanceName_ in CPRD Aurum product dictionary
    - Phosphodiesterase-4 inhibitor (PDE4i) drugs (_category_ = 'pde4i') were added with regex _'roflumilast|apremilast'_ in _DrugSubstanceName_ in CPRD Aurum product dictionary
    - We searched the CPRD Aurum product dictionary for additional drugs with the same _DrugSubstanceName_ from each category and searched to see if there are any more with the same _DrugSubstanceName_ with an appropriate route of admission (e.g. for the inhalers, _RouteOfAdministration_ was limited to ‘inhalation’)
    - To future-proof the codelist, newer drugs were added by searching for the following _DrugSubstanceName_ in CPRD Aurum product dictionary:
      - "budesonide/ formoterol fumarate dihydrate/ glycopyrronium bromide" for category 'triple' 
      - "formoterol fumarate dihydrate/ glycopyrronium bromide" for category 'laba-lama'
  - Codes were dropped:
    - The codes with the following _DrugSubstanceName_ were dropped: _"ampicillin", "cefadroxil monohydrate"_
    - For non-inhaler categories, drugs were dropped where _RouteOfAdministration_ is NOT 'oral'

## Spirometry
* **File:** [spirometry-aurum_snomed_read.tsv](spirometry-aurum_snomed_read.tsv)

* **Coding system(s)**: Read; SNOMED-CT; CPRD Aurum medcodeid

* **Source:** Respiratory Electronic Health Record group led by Professor Jenni Quint
