/*BREATHE Dataset curation project
Do file creation date 12/04/2023
Do file author Sara Hatam
Do file purpose - get longitudinal smoking and apply algorithm
*/

args save_smoking_files

drop_frames all_smoking_events long_smoking

get_num_clean_obs

load_frame_observations $num_cleaned_obs


// loop through cleaned observation files
forvalues i = 1/$num_cleaned_obs{
	display "Looping through all_${disease}_observations_`i'"
	
	frame observations {
	    
		* If more than one observations file then replace frame with new obs data each time
		if $num_cleaned_obs > 1 {
		    display "Populating frame observations with ${deriv_dta}\all_${disease}_observations_`i'.dta"
		    use "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
		
			* Needed for COPD/asthma to work
			display "Dropping obsid parentobsid variables to reduce size of dataset"
			drop obsid parentobsid
			display "Removing duplicates that now exist"
			gduplicates drop
		}
		
		display "Merging in term, smoking_status from ${smoking_codelist}"

		* note this is quicker than merging frames
		/*merge using smoking codelist which categorises into never, ex and current*/
		merge m:1 medcodeid using "${smoking_codelist}", nogenerate keep(master match) keepusing(medcodeid term smoking_status ever_smoker)
		
	
		display "Moving smoking events in frame observations into new frame called all_smoking_events_`i'"
		frame put patid medcodeid obsdate term smoking_status ever_smoker if !missing(term), into(all_smoking_events_`i')
		
		drop term smoking_status ever_smoker
	}
	
	* This renames the first frame to all_fev1_codes for future appending if multiple files (i.e. without the 1)
	if `i' == 1 {
		display "Renaming frame all_smoking_events_`i' to frame all_smoking_events"
	    frame rename all_smoking_events_`i' all_smoking_events
	}
	
	* If not the first frame then it will append to all_smoking_events instead
	else {
		display "Appending smoking events from frame all_smoking_events_`i' into frame all_smoking_events"
		frame all_smoking_events: xframeappend all_smoking_events_`i', drop
		
	}
	
}

frame all_smoking_events {
    label define lab_smok 0"Never" 1"Ex-smoker" 2"Current"
	label values smoking_status lab_smok
    frame put patid obsdate smoking_status ever_smoker, into(long_smoking)
}

frame long_smoking {
    gduplicates drop
	
	if `save_smoking_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_smoking_pre_algorithm.dta" 1
	}
	
	* First get highest smoking status per person per day
	bysort patid obsdate: egen new_smoking_status = max(smoking_status)
	drop smoking_status ever_smoker
	gduplicates drop
	generate ever_smoker = .
	replace ever_smoker = 1 if new_smoking_status > 0
	replace ever_smoker = 0 if new_smoking_status == 0
	
	* Order by patid, obsdate and descending smoking status 
	gsort patid obsdate -new_smoking_status
	by patid: generate sum_smoking = sum(ever_smoker)
	replace new_smoking_status = 1 if sum_smoking > 0 & new_smoking_status == 0
	gduplicates drop
	
	rename new_smoking_status smoking_status
	label values smoking_status lab_smok
	
	duplicates tag patid obsdate, generate(dup_)
	assert dup_ == 0
	drop dup_ sum_smoking
	
	if `save_smoking_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_smoking_post_algorithm.dta" 1
	}
}
