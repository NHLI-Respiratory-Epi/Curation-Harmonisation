/*BREATHE Dataset curation project
Do file creation date 16/06/2023
Do file author Sara Hatam
Do file purpose to combine and clean drug issue files*/

args num_issues_each_file overwrite_issues
do "${common_scripts}\drop_drug_issues"

clear
drop _all
cd "${data_folder}"

local issue_files : dir "${data_folder}" files "DrugIssue_*.dta", respectcase
local num_issues : word count `issue_files'
display "There are `num_issues' drug issue files"

open_frame cohort "" 0 0
frame cohort {
    if _N == 0 {
	    display "Frame cohort is empty when it should be populated"
		open_frame cohort $cohort_file 1 0
	}
}

if `num_issues' <= 15 {
    
	open_frame issues "" 0 1
	
	frame issues {
	  append using `issue_files'
	  drop_drug_issues
	  compress
	  save_to_file "${deriv_dta}\all_${disease}_drug_issues_1" `overwrite_issues'
	}

}

if `num_issues' > 15 {
    
	local num_files_needed = ceil(`num_issues'/`num_issues_each_file') // this finds the number of total observation files that will be made
	
	local start_obs = 1
	local end_obs = `num_issues_each_file'
	
	* this ensures that the end_obs value is never higher than the number of observation files
	if `end_obs' > `num_issues'{
	    local end_obs = `num_issues'
	}
	
	forvalues i=1/`num_files_needed'{
	    
		display "Creating all_${disease}_drug_issues_`i' with drug issues `start_obs' to `end_obs'"
		open_frame file_`i' "" 0 1
	    
		// now need to loop through 
		forvalues j=`start_obs'/`end_obs'{
			
		    display "Cleaning DrugIssue_`j' from ${data_folder}\DrugIssue_`j'.dta"
			
			if `j'==`start_obs'{
			    frame file_`i'{
					use "${data_folder}\DrugIssue_`j'.dta", clear
					drop_drug_issues
				}
			}
			
			else {
			    frame default {
					use "${data_folder}\DrugIssue_`j'.dta", clear
					drop_drug_issues
					tempfile issue_`j'
					save `issue_`j'', replace
					display "Clearing data in frame default"
					drop _all
				}

			
				frame file_`i' {
				    display "Appending DrugIssue_`j' to file_`i'"
					append using `issue_`j''
					display "Erasing tempfile `issue_`j''"
					erase `issue_`j''
					*count
				}
			}

		}

		// once finished
		local start_obs = `start_obs' + `num_issues_each_file'
		local end_obs = `end_obs' + `num_issues_each_file'
		
		if `end_obs' > `num_issues'{
		    local end_obs = `num_issues'
		}
		
		frame file_`i' {
			* Now save file
			save_to_file "${deriv_dta}\all_${disease}_drug_issues_`i'" `overwrite_issues'
		}
		
		frame default {
			frame drop file_`i'
		}
		
	}
}