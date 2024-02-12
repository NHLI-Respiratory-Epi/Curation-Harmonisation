/*BREATHE data curation project*/
/*Author Sara Hatam*/
/*Creation date 25/08/22*/
/*Purpose: to clean the observation files*/

// note that majority of missing obsdates are invalid dates before 1990 and
// enterdate is before regstartdate
capture program drop drop_observations
program drop_observations
	display "Dropping dirty observations"

	keep patid obsid obsdate enterdate parentobsid medcodeid value numunitid obstypeid
	display "Starting number of observations is " _N

	display "Dropping observations that are missing a medcodeid"
	drop if medcodeid == "" | missing(medcodeid)
	display "Number of observations is now " _N

	// obsdate not always filled in, replace with enterdate if so
	display "Replacing obsdate with enterdate if missing obsdate"
	replace obsdate = enterdate if missing(obsdate)
	drop enterdate
	
	// lots of results with invalid dates of 1900 or earlier
	display "Removing observations from 1st January 1900 or earlier"
	drop if obsdate <= date("01-01-1900", "DMY")
	display "Number of observations is now " _N
	
	// drop results without any obsdate even after adding in enterdate - if this is even possible
	display "Dropping observations that are missing a date"
	drop if missing(obsdate)
	display "Number of observations is now " _N


	display "Dropping observations that are after CPRD release date"
	drop if obsdate > $cprd_end
	display "Number of observations is now " _N

	// merge in patient year of birth, death, reg start and end dates to remove observations outwith the expected range
	display "Linking observations to frame cohort"
	frlink m:1 patid, frame(cohort)
	display "Dropping observations from patids that are not in the cohort anymore"
	drop if missing(cohort)
	display "Number of observations is now " _N
	
	display "Getting dob, regstartdate, regenddate, lcd, date_of_death from frame cohort"
	frget dob regstartdate regenddate lcd date_of_death, from(cohort)
	drop cohort
	
	display "Number of observations is " _N

	display "Dropping observations that occur before patient registration start date or after patient registration end date"
	drop if obsdate < regstartdate | obsdate > regenddate
	display "Number of observations is " _N

	display "Dropping observations that occur before patient birth year"
	drop if year(obsdate) < year(dob)
	display "Number of observations is " _N

	display "Dropping observations that occur after practice last collection date"
	drop if obsdate > lcd
	display "Number of observations is " _N

	display "Dropping observations that occur after patient death date"
	drop if obsdate > date_of_death
	display "Number of observations is " _N

	display "Creating within_first_year variable for observations"
	generate within_first_year = .
	replace within_first_year = 1 if (obsdate - regstartdate) < 365
	replace within_first_year = 0 if missing(within_first_year)
	label variable within_first_year "Whether observation occurred during first year of GP registration (0/1)"

	display "Creating same_year_as_birth variable for observations"
	generate same_year_as_birth = .
	replace same_year_as_birth = 1 if year(obsdate) == year(dob)
	replace same_year_as_birth = 0 if missing(same_year_as_birth)
	label variable same_year_as_birth "Whether observation occurred during same year as year of birth (0/1)"

	drop dob regstartdate regenddate lcd date_of_death
	
	* Filter out codes that don't mean anything to us
	//e.g. 1572871000006117 means "Awaiting clinical code migration to EMIS Web"
	
	frlink m:1 medcodeid, frame(filter_out)
	keep if missing(filter_out)
	drop filter_out
	display "Number of observations is now " _N
	
	display "Compressing observations"
	compress
	display "Final number of observations is " _N
end
