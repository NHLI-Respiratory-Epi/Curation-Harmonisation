/*Do file for extracting COPD/Asthma medications for data curation project -  COPD cohort*/
/*this do file creates a long medication table*/
/*do file author Sarah Cook & Sara Hatam*/
/*do file creation date 6/9/2022*/
/*last updated 16/06/2023*/
/*database CPRD Aurum*/

args overwrite_medications
clear
drop _all
frame change default

* Drop frames that get created during script to avoid errors
drop_frames drug_issues medications

cd "${deriv_dta}" // change to the data folder
// find all files matching the term in current folder
local cleaned_drug_files : dir "${deriv_dta}" files "all_${disease}_drug_issues_*.dta", respectcase 

// count number of files matching the term 
local num_cleaned_drugs : word count `cleaned_drug_files'
display "There are `num_cleaned_drugs' cleaned drug issue files for ${disease}"

if `num_cleaned_drugs' > 9 {
    local num_to_loop 9
} 
else {
    local num_to_loop `num_cleaned_drugs'
}



drop_frames medications

if `num_to_loop' < `num_cleaned_drugs' {
    
	local start_loop = `num_to_loop' + 1
	
	display "Looping from `start_loop' to `num_cleaned_drugs'"
    
	forvalues i = `start_loop'/`num_cleaned_drugs'{
		display "Looping through all_${disease}_drug_issues_`i'"
		
		open_frame medications_`i' "" 1 1
		frame medications_`i' {
			
			display "Populating frame drugs with ${deriv_dta}\all_${disease}_drug_issues_`i'.dta"
			use "${deriv_dta}\all_${disease}_drug_issues_`i'.dta", replace
			drop drugrecid estnhscost
			
			display "Keeping drug issues in ${medications_codelist}"
			* note this is quicker than merging frames
			merge m:1 prodcodeid using "${medications_codelist}", nogenerate keep(match) keepusing(prodcodeid drugsubstancename substancestrength category)
				
		}
		
		* This renames the first frame to medications for future appending if multiple files (i.e. without the 1)
		if `i' == `start_loop' {
			display "Renaming frame medications_`i' to frame medications"
			frame rename medications_`i' medications
		}
		
		* If not the first frame then it will append to medications instead
		else {
			display "Appending medication codes from frame medications_`i' into frame medications"
			frame medications: xframeappend medications_`i', drop
		}
		
	}

	frame medications {
	   label variable category "Category of COPD medication" 
	   sort patid issuedate
	   save_to_file "${deriv_dta}\\${disease}_medications_2.dta"  1`overwrite_medications'
	}

drop_frames medications
	
}

/*From here you have a long table which can be used as general template*/

