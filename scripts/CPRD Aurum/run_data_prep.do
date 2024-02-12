*** do file for running all the data prep scripts - work in progress

/*1) Run macros */
do "Z:\Group_work\curation_project\BREATHE\cprd_scripts\run_macros"

<<<<<<< Updated upstream
/*2) Run conversion and eligibility scripts as not disease-specific*/
=======
* Make sure you have gtools and ftools installed!
/*
* For gduplicates
ssc install gtools
gtools, upgrade

* For fmerge (supposedly quicker version of merge)
cap ado uninstall ftools
ssc install ftools

* Appends frames together
ssc install xframeappend
*/

*TODO: keep figuring out order and ways to set up run_data_prep

/*1) Tidy up workspace*/
clear all
drop _all
set more off
macro drop _all
frames reset
set rmsg on

/*2) Set up first set of global macros*/
global protocol_number "22_001769"
global organisation "ICL"
global curation_folder "Z:\Group_work\curation_project"

/* change this */
global output_folder "Z:\Group_work\curation_project"
/////////////////
capture mkdir $output_folder // makes the folder if doesn't already exist

global study_start date("01-01-2004", "DMY")
global study_end date("01-01-2020", "DMY")
global cprd_end date("07-02-2022", "DMY") // comes from: https://cprd.com/cprd-aurum-february-2022-dataset

/* generic scripts will be stored here */
global github_folder "${curation_folder}\BREATHE" // this shouldn't change between projects
global common_scripts "${github_folder}\cprd_scripts\data_prep\common_scripts"
/*codelists*/
global codelists "${github_folder}\reformatted_codelists"
global cprd_pracids_to_remove "${codelists}\other\cprd_pracids_to_remove.dta"
global ethnicity_codelist "${codelists}\common_vars\ethnicity\ethnicity-aurum_snomed_read_hes.dta" //TODO: update
global bmi_codelist "${codelists}\common_vars\bmi\height_weight_bmi_values-aurum_snomed_read.dta"
global spirometry_codelist "${codelists}\copd_vars\spirometry\spirometry-aurum_snomed_read-nhli.dta"
global smoking_codelist "${codelists}\common_vars\smoking_status\smoking_status-aurum_gold_snomed_read-breathe.dta"

global eligibility_folder "${output_folder}\patid_for_linkage"
/* Database lookups - these may change depending on extract */ 
global linkages "Z:\Database guidelines and info\CPRD\CPRD_Latest_Lookups_Linkages_Denominators\Aurum_Linkages_Set_22"
global lookups "Z:\Database guidelines and info\CPRD\CPRD_Latest_Lookups_Linkages_Denominators\Aurum_Lookups_Feb_2022"


global linked_data "${curation_folder}\linked_data"
global imd "${linked_data}\stata_files\patient_imd2019.dta"
global ons_deaths "${linked_data}\stata_files\patient_deaths.dta"
global log 1 // 0 for no log, 1 for logging

* run user programs which loads in any programs needed later
do "${common_scripts}\user_programs"

/*3) Run conversion and eligibility scripts as not disease-specific*/
>>>>>>> Stashed changes
* Don't need to keep running these after the first time so set to 0 once finished
global run_append_patient_practice 0
global run_eligibility 0 

if $run_append_patient_practice == 1 {
    do "${common_scripts}\append_patient_practice_files" // takes roughly 14s
}

if $run_eligibility == 1 {
	do "${common_scripts}\get_linkage_eligible_patids" // takes 3.32m
}


/*3) Now set up disease-specific macros*/
/* NOTE: this will change based on the disease */
global disease "copd" // has to be one of "asthma", "ild", "copd"
change_disease ${disease} // this is a program that updates the macros
* Note that for CPRD data extracts other than COPD/ILD/asthma Feb 2022 you will need to change this

if $log == 1 {
    log close _all
	log using "${log_files}\log $S_DATE.log", append // this uses current date and appends
}

<<<<<<< Updated upstream
*4) Next merge practice and patient info and limit to eligible patids
global run_create_cohort 0
=======
*5) Next merge practice and patient info and limit to eligible patids
global run_create_cohort 1
>>>>>>> Stashed changes

if $run_create_cohort == 1 {
	global stage_num 1
	capture collect drop create_cohort_table
	collect create create_cohort_table
	global save_orig_cohort 1 // decide whether you want the cohort file to be saved
	global overwrite_cohort_file 1
    do "${common_scripts}\create_cohort_table" $save_orig_cohort $cohort_file $overwrite_cohort_file
}

<<<<<<< Updated upstream
*5) Clean the observations
global run_clean_observations 0
=======
*6) Clean the observations
global run_clean_observations 1
>>>>>>> Stashed changes
if $run_clean_observations == 1 {
    global overwrite_obs 1
	global num_obs_each_file = 45
    do "${common_scripts}\clean_observations" $num_obs_each_file $overwrite_obs // around 14.5m for ILD and 135m for COPD
}


<<<<<<< Updated upstream
*6) Add in date of incidence and earliest mention
=======
*7) Add in date of incidence and earliest mention
>>>>>>> Stashed changes
* Note that this script also cuts the cohort table down to those with a valid ILD code *
global run_date_of_incidence 1
if $run_date_of_incidence == 1 {
	global stage_num 8
	collect use add_incidence_prevalence "${deriv_dta}\create_cohort_table", replace
    global update_cohort_incidence 1
	global reduce_obs 1 // limit observations to those found to have valid code
	do "${common_scripts}\add_date_of_incidence" $allow_disease_in_birth_year $update_cohort_incidence $reduce_obs
}

* Also get HES earliest mention
global run_hes_earliest_mention 1
if $run_hes_earliest_mention == 1 {
    global update_cohort_hes_em 1
	do "${common_scripts}\add_earliest_mention_secondary_care" $update_cohort_hes_em
}

*7) Add in ethnicity
global run_ethnicity 0
global save_ethnicity_file 1
global update_cohort_ethnicity 1
if $run_ethnicity == 1 {
    do "${common_scripts}\add_ethnicity_to_cohort" $save_ethnicity_file $update_cohort_ethnicity 
}

<<<<<<< Updated upstream
*8) Add in BMI
global run_bmi 0
=======
*9) Add in BMI
global run_bmi 1
>>>>>>> Stashed changes
global save_bmi_file 1
global save_intermediate_files 1
if $run_bmi == 1 {
    do "${common_scripts}\calculate_bmi" $save_bmi_file $save_intermediate_files
}

<<<<<<< Updated upstream
*9) Bring in ILD classifications - only for ILD
=======
*10) Bring in ILD classifications - only for ILD TODO: check if this is done
>>>>>>> Stashed changes
global run_classification 0
global update_cohort_classification 1
if $run_classification == 1 & "${disease}" == "ild" {
    do "${common_scripts}\add_ild_classification_to_cohort" $update_cohort_classification
}

<<<<<<< Updated upstream
*10) Add in longitudinal smoking
global run_smoking 0
=======
*11) Add in longitudinal smoking
global run_smoking 1
>>>>>>> Stashed changes
global save_smoking_files 1

if $run_smoking == 1 {
    do "${common_scripts}\get_smoking_status_inc_algorithm" $save_smoking_files
}

*11) Add in spirometry from GP records - only for COPD
global run_spirometry 0
global save_final_spirom_file 1

if $run_spirometry == 1 & "${disease}" == "copd" {
    do "${common_scripts}\get_spirometry_fev1_perc_predicted" $save_final_spirom_file
}

*12) Clean and combine the drug issues files
global run_clean_drug_issues 0
if $run_clean_drug_issues == 1 {
	global overwrite_issues 1
	global num_issues_each_file = 11
	do "${common_scripts}\clean_drug_issues" $num_issues_each_file $overwrite_issues
}

*13) Extract disease-relevant medications from the drug issue files
global run_medications 0
if $run_medications == 1 & ( "${disease}" == "copd" | "${disease}" == "asthma") {
    global overwrite_medications 1
	do "${common_scripts}\extract_medications" $overwrite_medications
}


*capture log close
