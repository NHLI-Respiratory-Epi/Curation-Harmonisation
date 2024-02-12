/*BREATHE Dataset curation project
Do file creation date 30/09/2022
Do file author Sara Hatam
Do file purpose to add ILD classification columns to the cohort table */

args update_cohort_classification
drop_frames ild_classification

open_frame ild_classification "${deriv_dta}\\${disease}_incidence_prevalence_table.dta" 0 1

frame ild_classification {
    
	drop if obsdate >= $study_end
	
	keep patid broad_ipf narrow_ipf treatment_ild exposure_ild autoimmune_ild other
	
	foreach v of varlist * {
		if "`v'" != "patid" {
			display "Getting one row per patid with total of `v' in all rows"
			egen `v'_total = total(`v'), by(patid)
			drop `v'
			rename `v'_total `v'
			replace `v' = 1 if `v' > 0
		}

	}

	gduplicates drop

}

* now load in cohort table
open_frame cohort $cohort_file 0 0
frame cohort {
    capture drop broad_ipf narrow_ipf autoimmune_ild exposure_ild treatment_ild other
	
    frlink 1:1 patid, frame(ild_classification)
	frget broad_ipf narrow_ipf autoimmune_ild exposure_ild treatment_ild other, from(ild_classification)
	drop ild_classification
	
	label variable broad_ipf "Presence of ILD code classified as broad IPF (0/1)"
	label variable narrow_ipf "Presence of ILD code classified as narrow IPF (0/1)"
	label variable autoimmune_ild "Presence of ILD code classified as autoimmune-related (0/1)"
	label variable exposure_ild "Presence of ILD code classified as exposure-related (0/1)"
	label variable treatment_ild "Presence of ILD code classified as treatment-related (0/1)"
	label variable other "Presence of ILD code not elsewhere classified (0/1)"
	
	if `update_cohort_classification' == 1 {
		save "${cohort_file}", replace 
	}
}

