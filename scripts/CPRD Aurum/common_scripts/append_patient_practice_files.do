/*BREATHE Dataset curation project
Do file creation date 12/04/2022
Do file author Sarah Cook/Sara Hatam
Do file purpose merging in patient practice files - COPD/ILD/asthma dataset*/

drop _all

foreach disease in "ild" "copd" "asthma"{

	/* Set up local macros */
	local data = "${project_folder}\\`disease'_data"
	local deriv_dta = "`data'\deriv_dta"
	local log_files = "`data'\log_files"

	/* each disease has a different folder for raw data */
	if "`disease'" == "ild" {
		local data_folder = "Z:\ILD_2022"
	} 
	if "`disease'" == "copd" {
		local data_folder = "Z:\copd2022new"
	}
	if "`disease'" == "asthma" {
		local data_folder = "Z:\asthma_2022"
	}

	/* this is where we store the data we create */
	local prepped_data = "`data_folder'\orig_dta"

	/*Finds all the patient files and appends them together*/
	cd "`prepped_data'"
	local patient_files : dir "`prepped_data'" files "Patient_*.dta", respectcase
	append using `patient_files'

	/*Do some checks on data*/
	assert acceptable==1
	assert patienttype==3
	assert (gender==1 | gender==2)
	gduplicates drop
	count 
	
	/*drop variables we don't need - uts as blank, emis_ddate as will use cprd death date, patienttypeid as all are 3, acceptable as all 1 */
	drop emis_ddate patienttypeid acceptable

	save "`deriv_dta'\Patient.dta", replace 
	drop _all

	/*Finds all the practice files and appends them together*/
	local practice_files : dir "`prepped_data'" files "Practice_*.dta", respectcase
	append using `practice_files'
	
	gduplicates drop
	save "`deriv_dta'\Practice.dta", replace 
	drop _all

}

