/*BREATHE Dataset curation project
Do file creation date 29/04/2022, last updated 12/05/2022
Do file author Sarah Cook/Sara Hatam
Do file purpose - creating a dataset with patids eligibility for linkage for asthma, COPD and ILD dataset curation project
To append all patids of patients eligible for linkage with either ILD or COPD or asthma in order to request HES and ONS data*/

drop _all
* Take ILD patient file
use "${project_folder}\ild_data\deriv_dta\Patient.dta"
* Then append in the patient files for COPD and asthma
append using "${project_folder}\copd_data\deriv_dta\Patient.dta" "${project_folder}\asthma_data\deriv_dta\Patient.dta"
count 
* Drop duplicates as some patients may have multiple diseases
gduplicates drop
count 

* Light cleaning
display "Dropping patients with patient registration start date after patient registration end date, or where year of birth after registration"
drop if regstartdate > regenddate | year(regstartdate) < yob | year(regenddate) < yob 


* Keep only the patid column
keep patid
gduplicates drop
count 
* Save file
save "${eligibility_folder}\all_unique_patids.dta", replace 

* Import the eligibility file from CPRD - very big so will take a few minutes to import
import delimited "${linkages}\Aurum_enhanced_eligibility_January_2022.txt", clear
format patid %32.0g
* Make sure to only keep patids eligible for all our requested datasets
keep if hes_ae == 1 & hes_op == 1 & hes_apc == 1 & ons_death_e == 1
* Merge in the unique patids from all three diseases from above
merge 1:1 patid using "${eligibility_folder}\all_unique_patids.dta", keep(match) //keep patids found in both datasets
gduplicates drop
count 
* Keep only the patid column
keep patid
* Save as stata file
save "${eligibility_folder}\eligible_patids.dta", replace 
* Then export as tab delimited text file to submit for the linkage request
export delimited "${eligibility_folder}\\${protocol_number}_${organisation}_patientlist.txt", delimiter(tab) replace


