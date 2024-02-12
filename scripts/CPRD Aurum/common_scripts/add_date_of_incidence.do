/*BREATHE Dataset curation project
Do file creation date 28/06/2022
Do file author Sara Hatam
Do file purpose to add date of incidence and earliest mention to the dataset*/

args allow_disease_in_birth_year update_cohort_incidence reduce_obs
clear
drop _all
drop_frames incidence_prevalence new_cohort_info
get_num_clean_obs


* This loads in observations into frame observations if one file
* And makes empty observations frame if multiple files
load_frame_observations $num_cleaned_obs

forvalues i = 1/$num_cleaned_obs{
	display "Looping through all_${disease}_observations_`i'"
	
	frame observations {
	    
		if $num_cleaned_obs > 1 {
		    display "Populating frame observations with ${deriv_dta}\all_${disease}_observations_`i'.dta"
		    use "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
			
			* Needed for asthma/COPD to work
			display "Dropping obsid, parentobsid as not needed here"
			drop obsid parentobsid
			display "Dropping duplicates"
			gduplicates drop
		}
		
		
		display "Merging in incident, prevalent from ${cohort_def}"
		* note this is quicker than merging frames
		merge m:1 medcodeid using "${cohort_def}", keepusing(medcodeid incident prevalent) nogenerate keep(master match)

		display "Moving incidence/prevalence codes in frame observations into new frame called incidence_prevalence_`i'"
		frame put patid medcodeid obsdate within_first_year same_year_as_birth incident prevalent if incident == 1 | prevalent == 1, into(incidence_prevalence_`i')
	
		drop incident prevalent
	}
	
	if `i' == 1 {
	    display "Renaming frame incidence_prevalence_`i' to frame incidence_prevalence"
	    frame rename incidence_prevalence_`i' incidence_prevalence
	}
	
	else {
	    display "Appending incident/prevalent codes from frame incidence_prevalence_`i' into frame incidence_prevalence"
		frame incidence_prevalence: xframeappend incidence_prevalence_`i', drop
	}
	
}

* now load in cohort table
open_frame cohort $cohort_file 0 0

frame incidence_prevalence {
	gduplicates drop // drop any duplicates

	* Remove results in same year as birth
	if `allow_disease_in_birth_year' != 1 {
		display "Drop observations in the same year as birth"
		drop if same_year_as_birth == 1
	}
	
	if $min_age > 0 {
		display "Getting date of birth from cohort file"
		* Bring in date of birth from cohort for calculating age
		frlink m:1 patid, frame(cohort)
		frget dob, from(cohort)
		generate age = age(dob, obsdate)
		drop dob cohort
		
		display "Drop observations where patient is younger than minimum age of ${min_age}"
		drop if age < $min_age
	}
	
	gsort patid obsdate // sort by ascending order of obsdate to ensure earliest is first
	bysort patid: generate disease_count = _n // get count by patid
	
	// get number of patids with valid "DISEASE" code
	count if disease_count == 1 
	
	// now make earliest mention which includes first year registration period (unless same year as birth is not allowed)
	generate earliest_mention = obsdate if disease_count == 1
	
	// then make date of incidence which is only calculated if it's the earliest mention of incident code and NOT within the first year (unless same year as birth allowed)
	generate date_of_incidence = obsdate if disease_count == 1 & (within_first_year == 0 | same_year_as_birth == 1) & incident == 1
	
	* Label differently based on how we've worked it out
	if `allow_disease_in_birth_year' == 1 {
		label variable date_of_incidence "Date of earliest mention of incident ${disease} GP code (NULL if in 1st year reg unless same yob)"

		label variable earliest_mention "Date of earliest mention of any ${disease} GP code inc 1st year of registration" 

	}
	else {

		label variable date_of_incidence "Date of earliest mention of incident ${disease} GP code (NULL if within 1st year of reg)"

		label variable earliest_mention "Date of earliest mention of any ${disease} GP code excl same year as birth" 
	}
	
	format date_of_incidence %td // turn from numeric into date
	format earliest_mention %td // turn from numeric into date

	label variable obsdate "Date of observation"
	label variable incident "Whether medcodeid is classified as incident for ${disease} (0/1)"
	label variable prevalent "Whether medcodeid is classified as prevalent for ${disease} (0/1)"
	
	frame put patid date_of_incidence earliest_mention if disease_count == 1, into(new_cohort_info)
	
	drop earliest_mention date_of_incidence disease_count
	
	if "${disease}" == "ild" {
		display "Merging in ILD classifications (broad_ipf, narrow_ipf, autoimmune_ild, exposure_ild, treatment_ild, other) from ${cohort_def}"

		merge m:1 medcodeid using "${cohort_def}", keepusing(medcodeid broad_ipf narrow_ipf autoimmune_ild exposure_ild treatment_ild other) nogenerate keep(match)
	}
}


capture collect drop add_incidence_prevalence
collect create add_incidence_prevalence
frame cohort {
	capture drop earliest_mention date_of_incidence
    // link to the frame with dates of incidence and earliest mention
	frlink 1:1 patid, frame(new_cohort_info)
	// bring in the new variables
	frget earliest_mention date_of_incidence, from(new_cohort_info)
	// drop the linking variable column
	drop new_cohort_info
	drop if missing(earliest_mention)
	collect_cohort_count $stage_num "Dropped patids with no valid ${disease} code after data cleaning and limiting age at disease event to ${min_age}+"
	
	drop if earliest_mention > $study_end
	collect_cohort_count $stage_num "Dropped patids with earliest mention of ${disease} after study end"

	collect layout (result) (counts)
	
	collect export cohort_counts_2.xlsx, name(add_incidence_prevalence) replace

	if `update_cohort_incidence' == 1 {
	   save "${cohort_file}", replace 
	}
}

frame incidence_prevalence {
    frlink m:1 patid, frame(cohort)
	drop if missing(cohort)
	compress
	save "${deriv_dta}\\${disease}_incidence_prevalence_table.dta", replace
}

frame drop new_cohort_info

// now drop observations from those in cohort with invalid disease codes
if `reduce_obs' == 1 {
	forvalues i = 1/$num_cleaned_obs{
		display "Looping through all_${disease}_observations_`i'"
		
		frame observations {
			if $num_cleaned_obs > 1 {
				display "Populating frame observations with ${deriv_dta}\all_${disease}_observations_`i'.dta"
				use "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
			}
		
		display "Finding observations from patids that are no longer in the cohort after all ILD codes were invalid"
		frlink m:1 patid, frame(cohort)
		drop if missing(cohort) // this means patid not found in cohort
		drop cohort
		save "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
		}
	}
}


