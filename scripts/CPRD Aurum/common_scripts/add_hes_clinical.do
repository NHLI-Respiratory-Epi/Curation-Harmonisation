/*BREATHE Dataset curation project
Do file creation date 18/09/2023
Do file author Sara Hatam
Do file purpose to bring HES clinical files together*/

clear
drop _all
drop_frames hes_clinical

cd "${linked_data}\hesop_clinical_22_001769"

* now load in cohort table
open_frame cohort $cohort_file 0 0

open_frame hes_clinical "" 0 1

local hes_files : dir "${linked_data}\hesop_clinical_22_001769" files "hesop_clinical_*.dta", respectcase
local num_files : word count `hes_files'
display "There are `num_files' HES clinical files"


frame hes_clinical {
  append using `hes_files', force
  compress
  save_to_file "${linked_data}\hes_clinical_all" 1
}