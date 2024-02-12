/*BREATHE Dataset curation project
Do file creation date 03/05/2022
Do file author Sara Hatam
Do file purpose to combine and clean observation files*/

args num_obs_each_file overwrite_obs
do "${common_scripts}\drop_observations"

clear
drop _all
cd "${data_folder}"

local obs_files : dir "${data_folder}" files "Observation_*.dta", respectcase
local num_obs : word count `obs_files'
display "There are `num_obs' observation files"

open_frame cohort "" 0 0
frame cohort {
    if _N == 0 {
	    display "Frame cohort is empty when it should be populated"
		open_frame cohort $cohort_file 1 0
	}
}

open_frame filter_out "${codelists}\other\observation_codes_to_remove.dta" 1 0

if `num_obs' <= 15 {
    
	open_frame observations "" 0 1
	
	frame observations {
	  append using `obs_files'
	  drop_observations
	  compress
	  save_to_file "${deriv_dta}\all_${disease}_observations_1" `overwrite_obs'
	}

}

if `num_obs' > 15 {
    
	local num_files_needed = ceil(`num_obs'/`num_obs_each_file') // this finds the number of total observation files that will be made
	
	local start_obs = 1
	local end_obs = `num_obs_each_file'
	
	* this ensures that the end_obs value is never higher than the number of observation files
	if `end_obs' > `num_obs'{
	    local end_obs = `num_obs'
	}
	
	forvalues i=1/`num_files_needed'{
	    
		display "Creating all_${disease}_observations_`i' with observations `start_obs' to `end_obs'"
		open_frame file_`i' "" 0 1
	    
		// now need to loop through 
		forvalues j=`start_obs'/`end_obs'{
			
		    display "Cleaning Observation_`j' from ${data_folder}\Observation_`j'.dta"
			
			if `j'==`start_obs'{
			    frame file_`i'{
					use "${data_folder}\Observation_`j'.dta", clear
					*do "${common_scripts}\drop_observations"
					drop_observations
				}
			}
			
			else {
			    frame default {
					use "${data_folder}\Observation_`j'.dta", clear
					*do "${common_scripts}\drop_observations"
					drop_observations
					tempfile obs_`j'
					save `obs_`j'', replace
					display "Clearing data in frame default"
					drop _all
				}

			
				frame file_`i' {
				    display "Appending Observation_`j' to file_`i'"
					append using `obs_`j''
					display "Erasing tempfile `obs_`j''"
					erase `obs_`j''
					*count
				}
			}

		}

		// once finished
		local start_obs = `start_obs' + `num_obs_each_file'
		local end_obs = `end_obs' + `num_obs_each_file'
		
		if `end_obs' > `num_obs'{
		    local end_obs = `num_obs'
		}
		
		frame file_`i' {
			* Now save file
			save_to_file "${deriv_dta}\all_${disease}_observations_`i'" `overwrite_obs'
		}
		
		frame default {
			frame drop file_`i'
		}
		
	}
}


