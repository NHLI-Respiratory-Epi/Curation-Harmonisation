/*BREATHE Dataset curation project
Do file creation date 16/12/2022
Do file author Sara Hatam
Do file purpose - get FEV1 % predicted
*/

args save_final_spirom_file

drop_frames all_spirometry_events fev1_values fev1_pred_values fev1_perc_pred_values more_fev1_perc_pred_values match_fev1_to_pred even_more_fev1_perc_pred_values get_closest_height more_predicted_values clean_values finalised_perc_pred

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
		
		display "Merging in term, fev1, fev1_predicted, fev1_percent_pred, bronchdil from  ${spirometry_codelist}"

		* note this is quicker than merging frames
		merge m:1 medcodeid using "${spirometry_codelist}", nogenerate keep(master match) keepusing(medcodeid term fev1 fev1_predicted fev1_percent_pred bronchdil)
		
		keep if (fev1 == 1 | fev1_predicted == 1 | fev1_percent_pred == 1) & !missing(value)
	
		display "Moving spirometry events in frame observations into new frame called all_spirometry_events_`i'"
		frame put patid medcodeid obsdate value numunitid term fev1 fev1_predicted fev1_percent_pred bronchdil if !missing(term), into(all_spirometry_events_`i')
		
		drop term fev1 fev1_predicted fev1_percent_pred bronchdil
	}
	
	* This renames the first frame to all_fev1_codes for future appending if multiple files (i.e. without the 1)
	if `i' == 1 {
		display "Renaming frame all_spirometry_events_`i' to frame all_spirometry_events"
	    frame rename all_spirometry_events_`i' all_spirometry_events
	}
	
	* If not the first frame then it will append to all_spirometry_events instead
	else {
		display "Appending spirometry events from frame all_spirometry_events_`i' into frame all_spirometry_events"
		frame all_spirometry_events: xframeappend all_spirometry_events_`i', drop
		
	}
	
}

open_frame units "${codelists}\other\cprd_fev1_units.dta" 1 1

frame all_spirometry_events {
	drop if value <= 0
	frlink m:1 numunitid, frame(units)
	frget unit, from(units)
	
	generate bronchodilation = .
	replace bronchodilation = 0 if bronchdil == 0 | bronchdil == 1 
	replace bronchodilation = 1 if bronchdil == 2
	label define broncho_labels 0 "Before/no mention" 1 "After"
	label values bronchodilation broncho_labels
	label variable bronchodilation "Whether spirometry was performed before or after bronchodilation"
	
    frame put patid obsdate term value numunitid bronchodilation unit if fev1==1, into(fev1_values)
	frame put patid obsdate term value bronchodilation unit if fev1_predicted==1, into(fev1_pred_values)
	frame put patid obsdate term value bronchodilation unit if fev1_percent_pred==1, into(fev1_perc_pred_values)
}


frame fev1_values {
	count 
	replace unit = "ml/s" if value >= 100 & (missing(unit) | unit == "L/s")
	replace unit = "L/s" if value <= 7 
	replace unit = "ml/s" if value > 200 
	generate predicted = 1 if numunitid == 2305
	
	* These ones are ambiguous
	drop if missing(unit) & missing(predicted)
	
	frame put * if predicted == 1, into(more_predicted_values)
	drop if predicted == 1
	drop predicted
	
	frame put * if unit == "% predicted", into(more_fev1_perc_pred_values)
	drop if unit == "% predicted"
	
	count 
	count if unit == "ml/s" 
	count if unit == "ml/s" & (value/1000 > 7 | value/1000 < 0.1) 
	count if unit == "L/s" & (value > 7 | value < 0.1) 
	
	* <1% of values come from ml/s ones
	* Restricting to L/s range 

	
	drop if unit == "ml/s"
	drop if value < 0.1
	drop if value > 7
	drop term numunitid
	gduplicates drop
	
	// keep best result if multiple on the same day
	duplicates tag patid obsdate bronchodilation, generate(dup)
	bysort patid obsdate bronchodilation: egen best_fev1 = max(value) if dup > 0
	replace value = best_fev1 if !missing(best_fev1) & dup > 0
	drop dup best_fev1
	gduplicates drop
	
	// assert no duplicates remaining
	duplicates tag patid obsdate bronchodilation, generate(dup)
	assert dup == 0
	drop dup
	
	save_to_file "${deriv_dta}\\${disease}_fev1_values_cleaned.dta" 1
	
	
}

frame fev1_pred_values {
    // There might not be any hence capture was used
	capture xframeappend more_predicted_values, drop
	capture drop predicted 
	
	replace unit = "ml/s" if value >= 100 & (missing(unit) | unit == "L/s")
	replace unit = "L/s" if value <= 7 
	replace unit = "ml/s" if value > 200 
	
	* These ones are ambiguous
	drop if missing(unit)
	
	frame put * if unit == "% predicted", into(even_more_fev1_perc_pred_values)
	
	capture drop bronchodilation
	drop if unit == "% predicted"
	
	
	drop if unit == "ml/s"
	drop if value < 0.1
	drop if value > 7
	drop term
	gduplicates drop
	
	// assert no duplicates remaining
	duplicates tag patid obsdate, generate(dup)
	
	
	drop if dup > 0
	assert dup == 0
	drop dup
	
	save_to_file "${deriv_dta}\\${disease}_fev1_predicted_raw.dta" 1
	
	frame put *, into(match_fev1_to_pred)
}

open_frame cohort $cohort_file 1 1
frame match_fev1_to_pred {
    rename value raw_fev1_pred
    joinby patid obsdate using "${deriv_dta}\\${disease}_fev1_values_cleaned.dta", unmatched(using)
	drop _merge
	
	frlink m:1 patid, frame(cohort)
	frget gender dob, from(cohort)
	drop cohort
	
	// Calculate age at measurement
	gen age_at_fev1 = age(dob, obsdate)
	
	frame put patid obsdate age_at_fev1, into(get_closest_height)
}

// Same methodology as closest height for BMI
frame get_closest_height {
    rename obsdate fev1_date
	joinby patid using "${deriv_dta}\\${disease}_height_values.dta"
	rename obsdate height_date
	rename value height
	rename age age_at_height

	generate child_at_height = 1 if age_at_height < 18
	generate child_at_fev1 = 1 if age_at_fev1 < 18
	generate day_diff = abs(height_date - fev1_date)

	* Sort in order of ranking
	gsort patid fev1_date day_diff height_date
	* If either height or fev1 is under 18 with day difference of more than a month
	* Then don't include in ranking
	drop if (child_at_height == 1 | child_at_fev1 == 1) & day_diff > 30

	* Create ranking
	bysort patid fev1_date: generate rank = _n

	* Get next rank's date diff in case the day difference is the same forward and backwards
	bysort patid fev1_date: generate shifted_day_diff = day_diff[_n+1]
	* If day difference not the same, then use closest height
	bysort patid fev1_date: generate closest_height = 1 if rank == 1 & shifted_day_diff > day_diff

	* Bring in next rank's height if same day difference
	bysort patid fev1_date: generate shifted_height = height[_n+1] if rank == 1 & shifted_day_diff == day_diff
	* If the next rank's height is the same as the first rank's height then use first rank
	replace closest_height = 1 if !missing(shifted_height) & shifted_height == height & rank == 1

	* If two heights are both equidistant and are different by <0.05, then flag for getting mean
	generate get_mean = 1 if !missing(shifted_height) & abs(shifted_height - height) <= 0.05 & rank == 1 & missing(closest_height)

	* Otherwise just take closest one before as the height chosen
	replace closest_height = 1 if rank == 1 & missing(closest_height) & missing(get_mean)

	* Sense-checking: make sure that if a row was flagged for getting mean that it is not also flagged as closest height
	bysort patid fev1_date: generate num_row_picked = sum(closest_height) + sum(get_mean)
	assert num_row_picked == 1

	* Keep only these rows
	keep if closest_height == 1 | get_mean == 1
	* Replace height with mean of two closest heights if get_mean is flagged
	replace height = round((height + shifted_height)/2, 0.01) if get_mean == 1
	drop shifted_day_diff closest_height get_mean num_row_picked rank age_at_height child_at_height child_at_fev1 shifted_height
	rename fev1_date obsdate
	gduplicates drop
}



frame fev1_perc_pred_values {
    capture xframeappend more_fev1_perc_pred_values even_more_fev1_perc_pred_values, drop
	capture drop term numunitid
	replace value = round(value, 1)
	drop if value < 5 | value > 200
	replace unit = "% predicted"
	gduplicates drop
	
	// keep best result if multiple on the same day
	duplicates tag patid obsdate bronchodilation, generate(dup)
	bysort patid obsdate bronchodilation: egen best_pred = max(value) if dup > 0
	replace value = best_pred if !missing(best_pred) & dup > 0
	drop dup best_pred
	gduplicates drop
	
	// assert no duplicates remaining
	duplicates tag patid obsdate bronchodilation, generate(dup)
	assert dup == 0
	drop dup
	
	rename value raw_fev1_perc
	save_to_file "${deriv_dta}\\${disease}_fev1_percent_predicted_raw.dta" 1
}

frame match_fev1_to_pred {
    keep patid obsdate raw_fev1_pred bronchodilation value gender age_at_fev1
	rename value raw_fev1
	
	* Most have a height which is good
	frlink m:1 patid obsdate, frame(get_closest_height)
	frget height height_date, from(get_closest_height)
	drop get_closest_height
	
	// derive predicted FEV1
	generate deriv_fev1_pred = .
	replace deriv_fev1_pred = (4.3*height) - (0.0290*age_at_fev1) - 2.490 if gender == 1
	replace deriv_fev1_pred = (3.95*height) - (0.025*age_at_fev1) - 2.6 if gender == 2
	replace deriv_fev1_pred = round(deriv_fev1_pred, 0.01)
	
	generate deriv_fev1_perc_using_deriv_pred = round(raw_fev1/deriv_fev1_pred * 100, 1)
	generate deriv_fev1_perc_using_raw_pred = round(raw_fev1/raw_fev1_pred * 100, 1)
	joinby patid obsdate bronchodilation using "${deriv_dta}\\${disease}_fev1_percent_predicted_raw.dta", unmatched(both)
	drop unit _merge
	gduplicates drop
	
	frame put patid obsdate raw_fev1_pred bronchodilation deriv_fev1_pred deriv_fev1_perc_using_deriv_pred deriv_fev1_perc_using_raw_pred raw_fev1_perc, into(clean_values)
}

frame clean_values {

	frame put *, into(finalised_perc_pred)
	
	keep patid obsdate raw_fev1_pred deriv_fev1_pred
	
	generate value = .
	generate source = .
	
	// prioritise raw 
	replace value = raw_fev1_pred
	replace source = 1 if !missing(raw_fev1_pred)
	
	// then derived
	replace value = deriv_fev1_pred if missing(value)
	replace source = 2 if !missing(value) & missing(source)
	

	drop if missing(source)
	drop if value < 5 | value > 200
	
	label define pred_labels 1 "GP-entered" 2 "Derived using ERS '93 formulae only"
	label values source pred_labels
	
	keep patid obsdate value source
	gduplicates drop
	generate unit = "L/s"
	
	save_to_file "${deriv_dta}\\${disease}_fev1_predicted_cleaned.dta" 1
}
	

frame finalised_perc_pred {
    
    generate fev1_perc = .
	generate source = .
	
	replace fev1_perc = raw_fev1_perc
	replace source = 1 if !missing(raw_fev1_perc)
	
	replace fev1_perc = deriv_fev1_perc_using_raw_pred if missing(fev1_perc) & !missing(deriv_fev1_perc_using_raw_pred)
	replace source = 2 if !missing(fev1_perc) & missing(source) 

	replace fev1_perc = deriv_fev1_perc_using_deriv_pred if missing(fev1_perc) & !missing(deriv_fev1_perc_using_deriv_pred)
	replace source = 3 if !missing(fev1_perc) & missing(source) 
	
	drop if missing(source)
	
    label define percent_labels 1 "GP-entered" 2 "Derived from raw predicted FEV1" 3 "Derived from predicted FEV1 using ERS '93 formulae"
	label values source percent_labels
	
	keep patid obsdate bronchodilation fev1_perc source
	rename fev1_perc value
	generate unit = "% predicted FEV1"
	
	generate gold_stage = .
	replace gold_stage = 1 if value >= 80
	replace gold_stage = 2 if value >= 50 & value < 80 
	replace gold_stage = 3 if value >= 30 & value < 50
	replace gold_stage = 4 if value < 30
	
		
	label define gold_label 1 "1 (Mild)" 2 "2 (Moderate)" 3 "3 (Severe)" 4 "4 (Very severe)"
	label values gold_stage gold_label
	
	label variable unit "Unit of value"
	label variable gold_stage "COPD stage using GOLD (1-4)"
	label variable source "Source of value"
	label variable value "Value of FEV1 percent predicted"
	label variable obsdate "Observation date"
	
	order patid obsdate value unit gold_stage bronchodilation source 
	
	if `save_final_spirom_file' == 1 {
	    save_to_file "${deriv_dta}\\${disease}_fev1_percent_predicted_cleaned.dta" 1
	}
}

