/*BREATHE data curation project*/
/*Author Sara Hatam*/
/*Creation date 16/06/23*/
/*Purpose: to clean the drug issue files*/


// note that majority of missing obsdates are invalid dates before 1990 and
// enterdate is before regstartdate
capture program drop drop_drug_issues
program drop_drug_issues
	display "Dropping dirty drug issues"

	keep patid issueid drugrecid issuedate enterdate prodcodeid dosageid quantity quantunitid duration estnhscost
	display "Starting number of drug issues is " _N

	display "Dropping observations that are missing a prodcodeid"
	drop if prodcodeid == "" | missing(prodcodeid)
	display "Number of drug issues is now " _N

	// issuedate may not always filled in, replace with enterdate if so
	display "Replacing issuedate with enterdate if missing issuedate"
	replace issuedate = enterdate if missing(issuedate)
	
	// weird issue dates to be replaced with enterdate
	display "Replacing issuedate with enterdate if year of issue is before 1980 and year of entry is after 1980"
	replace issuedate = enterdate if year(issuedate) < 1980 & year(enterdate) > 1980
	
	display "Replacing issuedate with enterdate if date of issue is after CPRD version release date"
	replace issuedate = enterdate if issuedate > $cprd_end
	
	drop enterdate
	
	// lots of results with invalid dates of 1900 or earlier
	display "Removing drug issues from before 1980"
	drop if year(issuedate) < 1980
	display "Number of drug issues is now " _N
	
	// drop results without any issuedate even after adding in enterdate - if this is even possible
	display "Dropping drug issues that are missing a date"
	drop if missing(issuedate)
	display "Number of drug issues is now " _N


	display "Dropping observations that are after CPRD version release date"
	drop if issuedate > $cprd_end
	display "Number of drug issues is now " _N

	// merge in patient year of birth, death, reg start and end dates to remove observations outwith the expected range
	display "Linking observations to frame cohort"
	frlink m:1 patid, frame(cohort)
	display "Dropping observations from patids that are not in the cohort anymore"
	drop if missing(cohort)
	display "Number of drug issues is now " _N
	
	display "Getting dob, regstartdate, regenddate, lcd, date_of_death from frame cohort"
	frget dob regstartdate regenddate lcd date_of_death, from(cohort)
	drop cohort

	display "Dropping drug issues that occur before patient registration start date or after patient registration end date"
	drop if issuedate < regstartdate | issuedate > regenddate
	display "Number of drug issues is now " _N

	display "Dropping observations that occur before patient birth year"
	drop if year(issuedate) < year(dob)
	display "Number of drug issues is now " _N

	display "Dropping observations that occur after practice last collection date"
	drop if issuedate > lcd
	display "Number of drug issues is now " _N

	display "Dropping observations that occur after patient death date"
	drop if issuedate > date_of_death
	display "Number of drug issues is now " _N

	drop dob regstartdate regenddate lcd date_of_death
	
	* Filter out codes that don't mean anything to us
	//e.g. 294711000000118 = "transfer-degraded medication entry"
	// 8881641000033118 = "<*** transfer degraded medication entry ***>"
	drop if prodcodeid == "294711000000118" | prodcodeid == "8881641000033118"

	display "Compressing drug issues"
	compress
	display "Final number of drug issues is " _N
end
