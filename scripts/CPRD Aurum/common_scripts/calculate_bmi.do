/*BREATHE Dataset curation project
Do file creation date 06/10/2022
Do file author Sara Hatam
Do file purpose - clean BMI
*/
args save_bmi_file save_intermediate_files
drop_frames all_bmi_codes bmi_values height_values weight_values derive_bmi
clear
drop _all

cd "${deriv_dta}" // change to the data folder

// find all files matching the term in current folder
local cleaned_obs_files : dir "${deriv_dta}" files "all_${disease}_observations_*.dta", respectcase 

// count number of files matching the term 
local num_cleaned_obs : word count `cleaned_obs_files'
display "There are `num_cleaned_obs' cleaned observation files for ${disease}"

load_frame_observations `num_cleaned_obs'

// loop through cleaned observation files
forvalues i = 1/`num_cleaned_obs'{
	display "Looping through all_${disease}_observations_`i'"
	
	frame observations {
	    
		* If more than one observations file then replace frame with new obs data each time
		if `num_cleaned_obs' > 1 {
		    display "Populating frame observations with ${deriv_dta}\all_${disease}_observations_`i'.dta"
		    use "${deriv_dta}\all_${disease}_observations_`i'.dta", replace
		
			* Needed for COPD/asthma to work
			display "Dropping obsid parentobsid variables to reduce size of dataset"
			drop obsid parentobsid
			display "Removing duplicates that now exist"
			gduplicates drop
		}
		
		display "Merging in term, category from  ${bmi_codelist}"

		* note this is quicker than merging frames
		merge m:1 medcodeid using "${bmi_codelist}", nogenerate keep(master match) keepusing(medcodeid term category)
	
		display "Moving BMI codes in frame observations into new frame called all_bmi_codes_`i'"
		frame put patid medcodeid obsdate value numunitid term category if !missing(term), into(all_bmi_codes_`i')
		
		drop term category
	}
	
	* This renames the first frame to all_weight_codes for future appending if multiple files (i.e. without the 1)
	if `i' == 1 {
		display "Renaming frame all_bmi_codes_`i' to frame all_bmi_codes"
	    frame rename all_bmi_codes_`i' all_bmi_codes
	}
	
	* If not the first frame then it will append to all_bmi_codes instead
	else {
		display "Appending BMI codes from frame all_bmi_codes_`i' into frame all_bmi_codes"
		frame all_bmi_codes: xframeappend all_bmi_codes_`i', drop
		
	}
	
}

open_frame cohort $cohort_file 1 1

frame all_bmi_codes {

	* First of all, drop missing values
	drop if missing(value)

	* Bring in date of birth from cohort for calculating age
	frlink m:1 patid, frame(cohort)
	frget dob, from(cohort)
	generate age = age(dob, obsdate)
	drop dob cohort
	
	keep patid obsdate value numunitid age category
	gduplicates drop
	
	* Move raw BMI values
	frame put patid obsdate value numunitid age if category == "bmi", into(bmi_values)
	
	* Move raw weight values
	frame put patid obsdate value numunitid age if category == "weight", into(weight_values)
	
	* Move raw height values
	frame put patid obsdate value numunitid age if category == "height", into(height_values)
}

drop_frames all_bmi_codes

frame bmi_values {
	count 
	replace value = round(value, 0.1)
	gduplicates drop

	* This is what SAIL uses for BMI
	drop if value > 100 | value < 10

	// now to deal with result from same day that are different - either in numunitid or value or both
	gsort patid obsdate
	duplicates tag patid obsdate, generate(dup_date)

	// we already know sometimes we get kg with numunitid of 156 on the same day as real bmi value
	drop if dup_date == 1 & numunitid == 156 

	// Remake dup_date to get others
	drop dup_date
	duplicates tag patid obsdate, generate(dup_date)
	
	* Some have 3 or more different values on the same day_diff
	// Hard to check if any/all values are close together so get the median
	bysort patid obsdate: egen med_val = median(value) if dup_date > 0
	replace med_val = round(med_val,0.1)
	* If value is more than 1 unit over median then flag
	generate _flag = 1 if dup_date > 0 & abs(value - med_val) > 1
	* But if we only drop these ones then we are assuming that the median is the correct one which might not be true
	
	* Therefore if there's multiple values different from median by more than 1, then drop all values that day for that patid as it implies that the median is not close to other vals
	// This is to weed out the one weird result amongst a bunch of results close together
	egen total_flags = total(_flag), by(patid obsdate)
	
	drop if dup_date > 0 & (_flag == 1 | total_flags > 1) // 21 values deleted
	drop _flag total_flags
	
	* Now get mean for everything else
	bysort patid obsdate: egen mean_val = mean(value) if dup_date > 0
	replace value = round(mean_val, 0.01) if !missing(mean_val)

	keep patid obsdate value age
	gduplicates drop
	
	duplicates tag patid obsdate, generate(dup_date_check)
	assert dup_date_check == 0
	drop dup_date_check


	if `save_intermediate_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_bmi_values_not_derived.dta" 1 
	}
	

}


* Now to start bringing in weight
frame weight_values {
	
	count
	
	replace value = round(value, 0.1)
	gduplicates drop 
	
	merge m:1 numunitid using "${codelists}\other\cprd_height_weight_units.dta", keep(master match) nogenerate
	
	* 157 = BMI
	* 2358 corresponds to O/E weight and looks to be zero
	drop if numunitid == 157 | numunitid == 2358 
	
	/* Not doing conversion from stones and pounds as this was too messy and rare
	* Convert from stones to kg
	replace value = value * 6.4 if unit == "st"
	
	* Convert from pounds to kg
	replace value = value * 0.45 if unit == "lb"
	
	replace numunitid = . if unit == "st" | unit == "lb"
	replace unit = "" if unit == "st" | unit == "lb"
	*/
	
	* Drop any imperial units
	drop if unit == "lb" | unit == "st" 
	
	* Drop heights
	drop if unit == "m" | unit == "cm" | unit == "ft" | unit == "in"

	
	replace unit = "kg"
	
	* Regardless of age, no one should have weight outwith of 0-300
	drop if value > 300 | value < 0 
	
	* Ages 0-3 allowed range of 0 to 50
	drop if age <= 3 & value > 50 
	* Ages 4+ allowed 10 to 300
	drop if age >= 4 & value < 10 
	
	keep patid obsdate value unit age
	* Remove exact duplicates
	gduplicates drop 
	* Now check for duplicate weights that aren't the same
	gsort patid obsdate value
	duplicates tag patid obsdate, generate(dup_date)
	// similar procedure to BMI
	
	* Some have 3 or more different values on the same day_diff
	// Hard to check if any/all values are close together so get the median
	bysort patid obsdate: egen med_val = median(value) if dup_date > 0
	replace med_val = round(med_val, 0.1)
	* If value is more than 1 unit over median then flag
	generate _flag = 1 if dup_date > 0 & abs(value - med_val) > 1
	* But if we only drop these ones then we are assuming that the median is the correct one which might not be true
	
	* Therefore if there's multiple values different from median by more than 1, then drop all values that day for that patid as it implies that the median is not close to other vals
	// This is to weed out the one weird result amongst a bunch of results close together
	egen total_flags = total(_flag), by(patid obsdate)
	
	drop if dup_date > 0 & (_flag == 1 | total_flags > 1) 
	drop _flag total_flags
	
	* Now get mean for everything else
	bysort patid obsdate: egen mean_val = mean(value) if dup_date > 0
	replace value = round(mean_val, 0.01) if !missing(mean_val)

	keep patid obsdate value age unit
	gduplicates drop
	
	duplicates tag patid obsdate, generate(dup_date_check)
	assert dup_date_check == 0
	drop dup_date_check
	
	count 
	
	
	if `save_intermediate_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_weight_values.dta" 1
	}
}

frame height_values {
	
	count 

	
	// regardless of units/age, over 250 is too high
	drop if value <= 0 | value > 250 
	
	merge m:1 numunitid using "${codelists}\other\cprd_height_weight_units.dta", keep(master match) nogenerate

	* we will have to make rules for heights with no unit
	* most are cm but some are metres
	replace unit = "m" if (unit == "cm" | missing(unit)) & value <= 2.5
	replace unit = "cm" if (unit == "m" | missing(unit)) & value >= 10

	* Change suspected cm into m
	*drop if value < 50 & age > 3 & unit == "cm" 
	replace value = value/100 if unit == "cm"
	replace unit = "m" if unit == "cm"
	
	* Drop feet - too messy
	drop if unit == "ft" 

	replace value = round(value, 0.01)
	gduplicates drop 
	
	* Drop very unlikely values
	* This is for everyone
	drop if value < 0.1 | value > 2.5 
	
	* ages 0-3 allowed range of 0.1 to 1.35
	drop if age <= 3 & value > 1.35 
	
	* ages 4-11 allowed range of 0.5 to 2
	drop if age >= 4 & age <= 11 & (value < 0.5 | value > 2) 
	
	* ages 12-17 allowed range of 0.5 to 2.5
	drop if age >= 12 & age <= 17 & value < 0.5 
	* ages 18+ allowed range of 1.21 to 2.5
	drop if age >= 18 & value < 1.21 
	
	keep patid obsdate value unit age
	* Remove exact duplicates
	gduplicates drop 
	* Now check for duplicate heights that aren't the same
	gsort patid obsdate value
	duplicates tag patid obsdate, generate(dup_date)
	
	* Some have 3 or more different values on the same day_diff
	// Hard to check if any/all values are close together so get the median
	bysort patid obsdate: egen med_val = median(value) if dup_date > 0
	*replace med_val = round(med_val,0.01)
	* If value is more than 0.025 unit over median then flag
	generate _flag = 1 if abs(value - med_val) >= 0.03
	* But if we only drop these ones then we are assuming that the median is the correct one which might not be true
	
	* Therefore if there's multiple values different from median by more than 0.025, then drop all values that day for that patid as it implies that the median is not close to other vals
	// This is to weed out the one weird result amongst a bunch of results close together
	egen total_flags = total(_flag), by(patid obsdate)
	
	drop if dup_date > 0 & (_flag == 1 | total_flags > 1) 
	drop _flag total_flags
	
	* Now get mean for everything else
	bysort patid obsdate: egen mean_val = mean(value) if dup_date > 0
	replace value = round(mean_val, 0.01) if !missing(mean_val)
	
	keep patid obsdate value age unit
	gduplicates drop 
	
	duplicates tag patid obsdate, generate(dup_date_check)
	assert dup_date_check == 0
	drop dup_date_check
	count 
	
	
	if `save_intermediate_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_height_values.dta" 1
	}
}

* Now to derive BMI
* For each weight value, take closest height
* Unless height was taken when patient was a child and there are more than 1 year between height and weight
frame weight_values {
	frame put *, into(derive_bmi)
}

frame derive_bmi {
	
	* Renaming so that different column names in weight for joinby
	rename value weight
	rename age age_at_weight
	rename obsdate weight_date
	drop unit
	
	* To do outer join, recommended to use joinby
	joinby patid using "${deriv_dta}\\${disease}_height_values.dta"
	rename value height 
	rename age age_at_height
	rename obsdate height_date
	drop unit

	* Get the day difference between the dates of height and weight
	generate day_diff = abs(weight_date - height_date)

	generate child_at_height = 1 if age_at_height < 18
	generate child_at_weight = 1 if age_at_weight < 18

	* Sort in order of ranking
	gsort patid weight_date day_diff height_date
	* If either height or weight is under 18 with day difference of more than a month
	* Then don't include in ranking
	drop if (child_at_height == 1 | child_at_weight == 1) & day_diff > 30

	* Create ranking
	bysort patid weight_date: generate rank = _n

	* Get next rank's date diff in case the day difference is the same forward and backwards
	bysort patid weight_date: generate shifted_day_diff = day_diff[_n+1]
	* If day difference not the same, then use closest height
	bysort patid weight_date: generate closest_height = 1 if rank == 1 & shifted_day_diff > day_diff

	* Bring in next rank's height if same day difference
	bysort patid weight_date: generate shifted_height = height[_n+1] if rank == 1 & shifted_day_diff == day_diff
	* If the next rank's height is the same as the first rank's height then use first rank
	replace closest_height = 1 if !missing(shifted_height) & shifted_height == height & rank == 1

	* If two heights are both equidistant and are different by <0.05, then flag for getting mean
	generate get_mean = 1 if !missing(shifted_height) & abs(shifted_height - height) <= 0.05 & rank == 1 & missing(closest_height)

	* Otherwise just take closest one before as the height chosen
	replace closest_height = 1 if rank == 1 & missing(closest_height) & missing(get_mean)

	* Sense-checking: make sure that if a row was flagged for getting mean that it is not also flagged as closest height
	bysort patid weight_date: generate num_row_picked = sum(closest_height) + sum(get_mean)
	assert num_row_picked == 1

	* Keep only these rows
	keep if closest_height == 1 | get_mean == 1
	* Replace height with mean of two closest heights if get_mean is flagged
	replace height = round((height + shifted_height)/2, 0.01) if get_mean == 1
	drop shifted_day_diff closest_height get_mean num_row_picked rank

	* Derive BMI with formula
	generate value = round(weight/(height * height),0.1)
	* Assign the same restrictions as raw BMI values earlier
	drop if value < 10 | value > 100
	rename weight_date obsdate
	rename age_at_weight age

	keep patid obsdate value age
	count 


	if `save_intermediate_files' == 1 {
		save_to_file "${deriv_dta}\\${disease}_bmi_values_derived.dta" 1
	}

	* Now bring raw and derived BMI values together
	rename value derived_bmi
	joinby patid obsdate age using "${deriv_dta}\\${disease}_bmi_values_not_derived.dta", unmatched(both)
	rename value raw_bmi
	gsort patid obsdate

	
	generate bmi = .
	generate unit = "kg/m2"
	
	generate source = .

	replace bmi = raw_bmi if missing(derived_bmi)
	replace source = 0 if missing(derived_bmi)

	replace bmi = derived_bmi if missing(raw_bmi)
	replace source = 1 if missing(raw_bmi)

	generate abs_diff = abs(derived_bmi - raw_bmi)
	replace abs_diff = round(abs_diff, 0.1)
	
	replace bmi = raw_bmi if abs_diff == 0
	replace source = 0 if abs_diff == 0

	* Changing this to prioritise raw
	*replace bmi = round((raw_bmi+derived_bmi)/2,0.1) if abs_diff > 0 & abs_diff <= 5
	replace bmi = raw if abs_diff > 0 & abs_diff <= 5
	replace source = 0 if abs_diff > 0 & abs_diff <= 5

	* Drop dirty BMIs - those that don't match between derive and raw well
	drop if missing(bmi)
	rename bmi value

	keep patid obsdate value unit age source
	
	count 
		
	* Categorise the BMI values
	generate adult_bmi_cat = .

	replace adult_bmi_cat = 1 if value <= 18.4 // underweight
	replace adult_bmi_cat = 2 if value > 18.4 & value < 25 // normal
	replace adult_bmi_cat = 3 if value >= 25 & value < 30 // overweight
	replace adult_bmi_cat = 4 if value >= 30 // obese
	replace adult_bmi_cat = 0 if age <= 18 // too young to be categorised

	label define bmi_labels 0 "Not over 18" 1 "Underweight" 2 "Normal" 3 "Overweight" 4 "Obese"
	label values adult_bmi_cat bmi_labels
	label define source_labels 0 "GP-entered" 1 "Derived only using height and weight"
	label values source source_labels

	label variable value "BMI values between 10 and 100"
	label variable unit "Unit of value"
	label variable age "Approx age at observation"
	label variable source "Whether BMI is GP-entered, or only derived from height and weight"
	
	if `save_bmi_file' == 1 {
		save_to_file "${deriv_dta}\\${disease}_bmi_values_cleaned.dta" 1
	}
}

