/*BREATHE Dataset curation project
Do file creation date 18/09/2023
Do file author Sara Hatam
Do file purpose to use HES primary diagnoses to create new HES earliest mention*/

args update_cohort_hes_em
clear
drop _all

* now load in cohort table
open_frame cohort $cohort_file 0 0

open_frame hes_prim_diag "${linked_data}\22_001769\Aurum_linked\Final\hes_primary_diagnoses" 0 1

frame hes_prim_diag {
    keep patid admidate discharged icd_primary icdx
	frlink m:1 patid, frame(cohort)
	drop if missing(cohort)
	
	// sometimes discharge date only available so use this in place of adm date
	generate event_date = date(admidate, "DMY")
	replace event_date = date(discharged, "DMY") if missing(event_date)
	
	drop if missing(event_date)
	format event_date %td
	
	drop admidate discharged
	gduplicates drop
	
	// keep only ICD codes in cohort definition codelist
	frlink m:1 icd_primary, frame(icd_codelist code)
	drop if missing(icd_codelist)
	
	keep patid event_date
	gduplicates drop
	* Create ranking
	gsort patid event_date
	bysort patid: generate rank = _n
	keep if rank == 1
	
	rename event_date hes_earliest_mention
	compress
	
}

frame cohort {
	frlink 1:1 patid, frame(hes_prim_diag)
	frget hes_earliest_mention, from(hes_prim_diag)
	drop hes_prim_diag
	label variable hes_earliest_mention "Date of earliest mention of any ${disease} ICD10 code in HES primary diagnoses" 
	
	if `update_cohort_hes_em' == 1 {
	   save "${cohort_file}", replace 
	}
}