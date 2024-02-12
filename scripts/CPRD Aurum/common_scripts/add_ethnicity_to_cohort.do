/*BREATHE Dataset curation project
Do file creation date 03/05/2022
Do file author Sarah Cook/Sara Hatam
Do file purpose to add ethnicity variable to the dataset - algorithm is developed from work by Rohini Mathur: 10.1093/pubmed/fdt116

Note that this file will work anytime after cohort file is created */

args save_ethnicity_file update_cohort_ethnicity
clear
drop _all
frame change default

* Drop frames that get created during script to avoid errors
drop_frames hes_ethnicity_codelist all_ethnicity_codes check_hes_ethnicity final_ethnicity_codes find_latest_eth21 find_mode_ethnicity

* Load ethnicity codelist into frame
open_frame ethnicity_codelist $ethnicity_codelist 1 0
* Make duplicate just for HES into new frame
frame ethnicity_codelist: frame put hes_ethnicity ethnicity6 ethnicityuk2011, into(hes_ethnicity_codelist)

cd "${deriv_dta}" // change to the data folder
// find all files matching the term in current folder
local cleaned_obs_files : dir "${deriv_dta}" files "all_${disease}_observations_*.dta", respectcase 

// count number of files matching the term 
local num_cleaned_obs : word count `cleaned_obs_files'
display "There are `num_cleaned_obs' cleaned observation files for ${disease}"

* This loads in observations into frame observations if one file
* And makes empty observations frame if multiple files
load_frame_observations `num_cleaned_obs'

forvalues i = 1/`num_cleaned_obs'{
	display "Looping through all_${disease}_observations_`i'"
	
	frame observations {
	    
		* If more than one observations file then replace frame with new obs data each time
		if `num_cleaned_obs' > 1 {
		    display "Populating frame observations with ${deriv_dta}\all_${disease}_observations_`i'.dta"
		    use "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
			
			* Needed for asthma/COPD to work
			display "Dropping obsid, parentobsid as not needed here"
			drop obsid parentobsid
			display "Dropping duplicates"
			gduplicates drop
		}
		
		display "Merging in ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 from ${ethnicity_codelist}"
		* note this is quicker than merging frames
		merge m:1 medcodeid using "${ethnicity_codelist}", nogenerate keepusing(medcodeid ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011) keep(master match)
			
		display "Moving ethnicity codes in frame observations into new frame called all_ethnicity_codes_`i'"
		frame put patid medcodeid obsdate ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 if !missing(ethnicity6), into(all_ethnicity_codes_`i')
	
		drop ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011
	}
	
	* This renames the first frame to all_ethnicity_codes for future appending if multiple files (i.e. without the 1)
	if `i' == 1 {
	    display "Renaming frame all_ethnicity_codes_`i' to frame all_ethnicity_codes"
	    frame rename all_ethnicity_codes_`i' all_ethnicity_codes
	}
	
	* If not the first frame then it will append to all_ethnicity_codes instead
	else {
	    display "Appending ethnicity codes from frame all_ethnicity_codes_`i' into frame all_ethnicity_codes"
		frame all_ethnicity_codes: xframeappend all_ethnicity_codes_`i', drop
	}
	
}


frame all_ethnicity_codes {
    gduplicates drop
	gsort patid -obsdate // sort by patid, descending date
	
	* Make new variables which will be used later
	bysort patid: generate patid_total = _N // find out how many ethnicity codes per patid
	bysort patid ethnicityengwales2021: generate patid_eth21_total = _N // find out how many of each eth21 per patid
	bysort patid ethnicity6: generate patid_eth6_total = _N // find out how many of each broad ethnicity category per patid
	
	// set flag for not stated ethnicity codes
	gen invalid_code = .
	replace invalid_code = 1 if ethnicity6 == "Not Stated"
	replace invalid_code = 0 if missing(invalid_code)
	
	// if the only codes are not stated then flag patid to check hes
	gen check_hes = .
	replace check_hes = 1 if invalid_code == 1 & patid_total == patid_eth6_total // this identifies patids where all codes are invalid
	replace check_hes = 0 if missing(check_hes)
	
	drop if check_hes == 0 & invalid_code == 1 // remove from this frame
	
	gsort patid -patid_eth21_total // sort by number of each medcodeid in descending order
	
	// only get mode for those without only invalid codes
	frame put patid medcodeid ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 patid_eth21_total if check_hes == 0 & invalid_code == 0, into(find_mode_ethnicity)
}

frame find_mode_ethnicity{
    gduplicates drop
	gsort patid -patid_eth21_total
	bysort patid: generate next_most_common = patid_eth21_total[_n+1] // this generates a new variable with patid_eth21_total shifted up by 1 row grouped by patid
	bysort patid: generate freq_code_order = _n
	generate chosen_ethnicity = .
	* pick eth21 as ethnicity if it's the most common one and there aren't any other eth21s with the same frequency
	replace chosen_ethnicity = 1 if freq_code_order == 1 & (next_most_common < patid_eth21_total | missing(next_most_common))
	replace chosen_ethnicity = 0 if missing(chosen_ethnicity)
	
	* identify patids where there is no mode ethnicity so that we can just use the latest eth21 that is valid instead
	generate get_latest_eth21 = .
	replace get_latest_eth21 = 1 if chosen_ethnicity == 0 & freq_code_order == 1 // if the most frequent was not chosen then get latest instead
	replace get_latest_eth21 = 0 if missing(get_latest_eth21)
	frame put patid get_latest_eth21 if get_latest_eth21 == 1, into(find_latest_eth21)
	
	keep if chosen_ethnicity == 1
	keep patid medcodeid ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011
	generate ethnicity_source = 1 // meaning cprd_mode
}

* This finds the latest eth21 code
frame all_ethnicity_codes{
    gsort patid -obsdate // sort by descending date
	bysort patid: generate date_code_order = _n // order from latest date
	frlink m:1 patid, frame(find_latest_eth21) // link to frame find_latest_eth21
	generate chosen_ethnicity = .
	replace chosen_ethnicity = 1 if !missing(find_latest_eth21) & date_code_order == 1
	
	frame put patid medcodeid ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 if chosen_ethnicity == 1, into(final_ethnicity_codes)
}

open_frame cohort ${cohort_file} 0 0
frame cohort: frame put patid, into(check_hes_ethnicity)

frame final_ethnicity_codes {
    generate ethnicity_source = 2
	xframeappend find_mode_ethnicity, drop // append in the mode cprd codes
	count // 47,544 in ILD with valid ethnicity in CPRD
}

frame hes_ethnicity_codelist {
    gduplicates drop
}

frame check_hes_ethnicity {
    count
    frlink 1:1 patid, frame(final_ethnicity_codes)
	keep if missing(final_ethnicity_codes) // only keep those without valid code in CPRD
	drop final_ethnicity_codes
	
	merge 1:1 patid using "Z:\Group_work\curation_project\linked_data\stata_files\hes_patient_22_001769_DM.dta", keep(master match) keepusing(patid gen_ethnicity) nogenerate // merge in the HES ethnicity
	
	generate hes_ethnicity = gen_ethnicity
	
	// We don't want to hide that some are missing
	// replace hes_ethnicity = "Unknown" if gen_ethnicity == "" | missing(gen_ethnicity)
	
	frlink m:1 hes_ethnicity, frame(hes_ethnicity_codelist)
	// assert !missing(hes_ethnicity_codelist)
	frget ethnicity6 ethnicityuk2011, from(hes_ethnicity_codelist)
	keep patid ethnicity6 ethnicityuk2011
	
	generate ethnicityengwales2011 = ""
	generate ethnicityengwales2021 = ""
	generate ethnicity_source = 3 if !missing(ethnicity6)
	replace ethnicity_source = 0 if missing(ethnicity6)
}

frame final_ethnicity_codes {
	xframeappend check_hes_ethnicity, drop // append in the hes ethnicities
	count // this is the final set of ethnicities
	gsort patid
	
	/*
	rename ethnicity6 ethnicity6
	generate ethnicity6 = .
	replace ethnicity6 = 0 if ethnicity6 == "Not Stated"
	replace ethnicity6 = 1 if ethnicity6 == "White"
	replace ethnicity6 = 2 if eth5_old == "Black"
	replace ethnicity6 = 3 if eth5_old == "Asian"
	replace ethnicity6 = 4 if eth5_old == "Mixed"
	replace ethnicity6 = 5 if eth5_old == "Other"
	
	rename eth11 eth11_old
	generate eth11 = .
	replace eth11 = 0 if eth11_old == "Not Stated"
	replace eth11 = 1 if eth11_old == "White"
	replace eth11 = 2 if eth11_old == "Black African"
	replace eth11 = 3 if eth11_old == "Black Caribbean"
	replace eth11 = 4 if eth11_old == "Other Black"
	replace eth11 = 5 if eth11_old == "Indian"
	replace eth11 = 6 if eth11_old == "Pakistani"
	replace eth11 = 7 if eth11_old == "Bangladeshi"
	replace eth11 = 8 if eth11_old == "Chinese"
	replace eth11 = 9 if eth11_old == "Other Asian"
	replace eth11 = 10 if eth11_old == "Mixed"
	replace eth11 = 11 if eth11_old == "Other ethnic group"
	
	rename eth21 eth21_old
	generate eth21 = .
	replace eth21 = 0 if eth21_old == "Not Stated"
	replace eth21 = 1 if eth21_old == "British"
	replace eth21 = 2 if eth21_old == "Scottish"
	replace eth21 = 3 if eth21_old == "Irish"
	replace eth21 = 4 if eth21_old == "Polish"
	replace eth21 = 5 if eth21_old == "Gypsy or Irish Traveller"
	replace eth21 = 6 if eth21_old == "Roma"
	replace eth21 = 7 if eth21_old == "Other White"
	replace eth21 = 8 if eth21_old == "African"
	replace eth21 = 9 if eth21_old == "Caribbean"
	replace eth21 = 10 if eth21_old == "Other Black"
	replace eth21 = 11 if eth21_old == "Indian"
	replace eth21 = 12 if eth21_old == "Pakistani"
	replace eth21 = 13 if eth21_old == "Bangladeshi"
	replace eth21 = 14 if eth21_old == "Chinese"
	replace eth21 = 15 if eth21_old == "Other Asian"
	replace eth21 = 16 if eth21_old == "White and Black Caribbean"
	replace eth21 = 17 if eth21_old == "White and Black African"
	replace eth21 = 18 if eth21_old == "White and Asian"
	replace eth21 = 19 if eth21_old == "Other Mixed"
	replace eth21 = 20 if eth21_old == "Arab"
	replace eth21 = 21 if eth21_old == "Other ethnic group"
	*/
	
	label define ethnicity_source_labels 0 "none" 1 "cprd_mode" 2 "cprd_latest" 3 "hes_algorithm"
	label values ethnicity_source ethnicity_source_labels
	
	/*
	label define eth5_labels 0 "Not Stated" 1 "White" 2 "Black" 3 "Asian" 4 "Mixed" 5 "Other"
	label values eth5 eth5_labels
	
	label define eth11_labels 0 "Not Stated" 1 "White" 2 "Black African" 3 "Black Caribbean" 4 "Other Black" 5 "Indian" 6 "Pakistani" 7 "Bangladeshi" 8 "Chinese" 9 "Other Asian" 10 "Mixed" 11 "Other ethnic group"
	label values eth11 eth11_labels
	
	label define eth21_labels 0 "Not Stated" 1 "British" 2 "Scottish" 3 "Irish" 4 "Polish" 5 "Gypsy or Irish Traveller" 6 "Roma" 7 "Other White" 8 "African" 9 "Caribbean" 10 "Other Black" 11 "Indian" 12 "Pakistani" 13 "Bangladeshi" 14 "Chinese" 15 "Other Asian" 16 "White and Black Caribbean" 17 "White and Black African" 18 "White and Asian" 19 "Other Mixed" 20 "Arab" 21 "Other ethnic group"

	drop eth5_old eth11_old eth21_old
	*/
	
	label variable ethnicity6 "Ethnicity categorised into 5 groups"
	label variable ethnicityengwales2011 "Ethnicity categorised into England/Wales 2011 census groups"
	label variable ethnicityengwales2021 "Ethnicity categorised into England/Wales 2021 census groups"
	label variable ethnicityuk2011 "Ethnicity categorised into UK-harmonised 2011 census groups"
	label variable ethnicity_source "Source of ethnicity"
	
	if `save_ethnicity_file' == 1 {
	    save_to_file "${deriv_dta}\\${disease}_final_ethnicity.dta" 1
	}
	
}

frame cohort {

    * if these variables exist they will be dropped
    capture drop ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 ethnicity_source
	
	frlink 1:1 patid, frame(final_ethnicity_codes)
	frget ethnicity6 ethnicityengwales2011 ethnicityengwales2021 ethnicityuk2011 ethnicity_source, from(final_ethnicity_codes)

	drop final_ethnicity_codes 

	if `update_cohort_ethnicity' == 1 {
	    save_to_file $cohort_file 1
	}
}



