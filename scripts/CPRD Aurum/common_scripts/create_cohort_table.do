/*BREATHE Dataset curation project
Do file creation date 13/05/2022
Do file author Sara Hatam
Do file purpose merging in patient practice files and adding in date of death and IMD - COPD/ILD/asthma dataset*/

args save_file filename overwrite

open_frame cohort "" 0 1 // this program creates empty frame called cohort, deletes whatever is already in the frame

/*Merge patid and patient practice files*/
frame cohort {
	use "${deriv_dta}\Patient.dta", clear
	count
	collect_cohort_count $stage_num "Start"
	
	display "Dropping patients with registration end date before study start"
	drop if regenddate < $study_start
	count
	collect_cohort_count $stage_num "Dropped patids with registration end date before study start"
	
	display "Dropping patients with year of birth after study end"
	drop if dob > $study_end
	count
	collect_cohort_count $stage_num "Dropped patids with year of birth after study end"
	
	merge 1:1 patid using "${eligibility_folder}\eligible_patids.dta", keep(match) nogenerate
	collect_cohort_count $stage_num "Dropped patids without linkage eligibility"

	* as ineligible people have been dropped, there may be practices that cannot be matched to a patid anymore
	* however there shouldn't be any pracids found only in the patient file hence the assertion
	merge m:1 pracid using "${deriv_dta}\Practice.dta", assert(using match) keep(match) keepusing(pracid region lcd) nogenerate
	/* NOTE: uts variable is not filled for Aurum at the moment so not keeping it but if it ever gets populated, add to keepusing() above */
	
	drop if missing(region) | region == 0
	collect_cohort_count $stage_num "Dropped patids from practices without a region"

	* Remove practices that are unreliable
	merge m:1 pracid using "${cprd_pracids_to_remove}", keep(master) nogenerate
	collect_cohort_count $stage_num "Dropped patids from practices that are likely to have merged with other practices"
	
	* merge in date of death from ONS
	merge 1:1 patid pracid using "${ons_deaths}", keepusing(patid pracid dod dor dod_partial match_rank) nogenerate keep(master match)
	generate date_of_death = date(dod, "DMY")
	generate date_of_registration = date(dor, "DMY")
	display "Where dod_partial is filled then date of death is missing - using date of registration in place"
	replace date_of_death = date_of_registration if !missing(dod_partial) & missing(dod)
	replace date_of_death = cprd_ddate if missing(date_of_death) & !missing(cprd_ddate) // ONS date of deaths only available until 29th March 2021, or patient may have died outside of England and Wales (https://doi.org/10.1002/pds.4747)
	format date_of_death %td

	* no point keeping patients that died before data start
	display "Dropping patients with date of death after study start"
	drop if date_of_death < $study_start
	count
	collect_cohort_count $stage_num "Dropped patids with date of death before study start"
	
	* make variable for end of follow up
	display "Making variable for end of follow up from earliest of study end, date of death, practice last collection date and registration end date"
	generate followup_end = min($study_end, date_of_death, lcd, regenddate)
	format followup_end %td
	
	* drop variables that are no longer needed
	drop dod yob mob dod_partial dor date_of_registration usualgpstaffid cprd_ddate match_rank

	* merge in IMD
	merge 1:1 patid pracid using "${imd}", keep(master match) nogenerate
	
	label variable followup_end "Date of end of follow-up (earliest of study end, death, lcd and regenddate)"
	label variable regstartdate "GP registration start date"
	label variable regenddate "GP registration end date"
	
	label variable date_of_death "Date of death from ONS; if the date is missing then date of registration is used here"
	label variable region "Region of GP in England"


	* set missing regions to unknown 
	replace region = 0 if missing(region)
	label define region_labels 0 "None" 1 "North East" 2 "North West" 3 "Yorkshire and The Humber" 4 "East Midlands" 5 "West Midlands" 6 "East of England" 7 "London" 8 "South East" 9 "South West" 10 "Wales" 11 "Scotland" 12 "Northern Ireland"
	label values region region_labels


	label define gender_labels 1 "Male" 2 "Female"
	label values gender gender_labels

	rename e2019_imd_5 imd
	label variable imd "English index of deprivation 2019 (quintiles) at patient-level where 1 is least deprived"
	label define imd_labels 1 "1 (least deprived)" 5 "5 (most deprived)"
	label values imd imd_labels

	count 
	compress

	if `save_file' == 1 {
		save_to_file `filename' `overwrite'
	}

}

collect layout (result) (counts)
collect save "${deriv_dta}\create_cohort_table", replace
collect export "${deriv_dta}\cohort_counts.xlsx", name(create_cohort_table) replace