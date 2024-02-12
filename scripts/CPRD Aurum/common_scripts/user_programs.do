/*BREATHE Dataset curation project
Do file creation date 08/07/2022
Do file author Sara Hatam
Do file purpose - create programs to make this project easier
*/

capture program drop open_frame
program open_frame
	args framename filename force_use force_empty

	capture confirm frame `framename' // this checks if frame already exists
	
	local empty 0 // create macro that indicates if frame is empty or not
	
	* if it does exist then error code stored in _rc macro will be 0
	if _rc != 0 {
	    display "Frame `framename' does not exist; creating new frame"
		frame create `framename'
		local empty 1 // frame should be empty since it has just been created
	}
	
	if _rc == 0 {
	    
		display "Frame `framename' already exists"
		
	    frame `framename' {
			if `force_empty' == 1 {
			    display "All data from frame `framename' will be deleted"
			    drop _all
				local empty 1
			}
			
			display _N " rows found in existing frame `framename'"
			
		    if _N == 0 & `force_empty' == 0 {
			    local empty 1 // frame is considered empty if no rows 
			}
			
		}
	}
	
	// if filename has been given then
	if "`filename'" != "" {
	    // use the file to population frame based on args
	    if (`force_use' == 0 & `empty' == 1) | `force_use' == 1 {
		    display "Frame `framename' will be populated with data from `filename'"
		    frame `framename' {
				use `filename', clear
			}
		}
		
		if (`force_use' == 0 & `empty' == 0){
		    display "Frame `framename' is not empty - please set force_use argument to 1 if you would like to proceed with using `filename'"
		}
	}
	
end

capture program drop save_to_file
program save_to_file
	args filename overwrite

		compress
		
		if `overwrite' == 1 {
		    display "argument overwrite set to 1; `filename' will be overwritten with current data if it already exists"
			save `filename', replace 
		}

		if `overwrite' == 0 {
		    display "argument overwrite set to 0; data will not be saved if `filename' already exists"
		    capture save `filename'
			if _rc == 0 {
			    display "`filename' does not exist - saving current data to `filename'"
			}
			
			else {
			    display "`filename' already exists - NOT saving current data to `filename'"
			}
		}
end


capture program drop change_disease
program change_disease
	args disease
	display "Changing disease from ${disease} to `disease'"

	/* disease specific scripts will be here */
	global disease `disease'
	global disease_scripts "${curation_folder}\github_files\cprd_scripts\data_prep\\`1'_scripts"
	/* disease data folder below */
	global data "${output_folder}\\`disease'_data"
	capture mkdir $data // makes the folder if doesn't already exist
	
	global deriv_dta "${data}\deriv_dta"
	capture mkdir $deriv_dta
	
	global results "${data}\results"
	capture mkdir $results
	
	global log_files "${data}\log_files"
	capture mkdir $log_files
	
	global cohort_file "${deriv_dta}\\`disease'_cohort_table.dta"

	/* each disease has a different folder for raw data */
	if "`disease'" == "ild" {
		global data_folder "Z:\Group_work\ILD_2022\orig_dta" // this will change for different data extracts

		global cohort_def "${codelists}\ild_vars\ild_cohort_definition\definite_ild_incidence_prevalence_classification-aurum_snomed_read.dta"

		global allow_disease_in_birth_year 0
		global min_age 40
		
	} 
	if "`disease'" == "copd" {
		global data_folder "Z:\copd2022new\orig_dta" // this will change for different data extracts
		global cohort_def "${codelists}\copd_vars\copd_cohort_definition\definite_copd_incidence_prevalence-aurum_gold_snomed_read.dta"
		global allow_disease_in_birth_year 0
		global min_age 35
	}
	if "`disease'" == "asthma" {
		global data_folder "Z:\asthma_2022\orig_dta" // this will change for different data extracts
		global cohort_def "${codelists}\asthma_vars\asthma_cohort_definition\definite_asthma_incidence_prevalence-aurum_snomed_read.dta"
		global allow_disease_in_birth_year 1
		global min_age 0
	}
end

* Note that stringcols(1) is a common import_arg
capture program drop import_file
program import_file
	args input_filename import_args output_filename
	
	display "Importing `input_filename' with the following arguments: `import_args'"
	import delimited `input_filename', clear `import_args'
	
	if "`output_filename'" != "" {
		display "Saving as `output_filename'"
		save `output_filename', replace
	}

end

capture program drop drop_frames
program drop_frames
	
	display "Dropping the following frames if they exist: `0'"
	
	foreach framename in `0' {
	    capture confirm frame `framename'
		
		if _rc == 0 {
	    
			display "Frame `framename' already exists - dropping"
			frame drop `framename'
		}
		
		else {
		    
			display "Frame `framename' does not exist - no need to drop"
		}
	}
end

capture program drop load_frame_observations 
program load_frame_observations
	args num_cleaned_obs
	* If there are multiple observation files, make an empty frame
	if `num_cleaned_obs' > 1 {
		* Create empty observations frame
		display "Making empty frame called observations"
		open_frame observations "" 0 1
	}
	* Otherwise if there is just one, then load it in if it's not loaded already
	// this avoids re-loading it in if it's already there
	else {

		display "Making sure frame observations is available"
		open_frame observations "" 0 0
		
		frame observations {
			if _N == 0 {
			   display "Frame observations is empty - populating with ${deriv_dta}\all_${disease}_observations_1.dta"
			   use "${deriv_dta}\all_${disease}_observations_1.dta", replace 
			}
			
			else {
			   display "Frame observations is already populated"
			}
		}
	}
end

capture program drop collect_cohort_count
program collect_cohort_count
	args stage_num comment
	
	collect get stage_`stage_num' = _N, tags(counts[num_patids])
	collect get stage_`stage_num' = "`comment'", tags(counts[steps_taken])
	global stage_num = `stage_num' + 1
	
end

capture program drop get_num_clean_obs
program get_num_clean_obs
	cd "${deriv_dta}"
	local cleaned_obs_files : dir "${deriv_dta}" files "all_${disease}_observations_*.dta", respectcase
	global num_cleaned_obs : word count `cleaned_obs_files'
	display "There are `num_cleaned_obs' cleaned observation files"
end
