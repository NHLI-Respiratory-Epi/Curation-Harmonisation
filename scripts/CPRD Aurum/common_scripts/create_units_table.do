/*BREATHE Dataset curation project
Do file creation date 14/10/2022
Do file author Sara Hatam
Do file purpose to get units from numunitid to aid conversions for units -  height and weight and FEV1
*/

frame change default
import delimited "Z:\Database guidelines and info\CPRD\CPRD_Latest_Lookups_Linkages_Denominators\Aurum_Lookups_Feb_2022\NumUnit.txt", clear
preserve

// stones
generate stone = 1 if regexm(description, "^[Ss][tT]$|[Ss]tone|^[sS][tT]\.")

// pounds
generate pound = 1 if regexm(description, "^lb$|lb\.|lbs|[pP]ounds")

// kilos
generate kg = 1 if regexm(description, "^([kK]ilo(s)?|[Kk][gG]([sS])?|[Kk]ilogram(s)?)$")

// cm
generate cm = 1 if regexm(description, "^(cm(\.|'?s|,)?)|([Cc]entimet(re|er)s?)$")

// metre
generate metre = 1 if regexm(description, "^[mM]s?$|^[mM]et(re|er)s?$")

// feet
generate feet = 1 if regexm(description, "feet|^[fF][tT]$")

// inches
generate inch = 1 if regexm(description, "inch|^[Ii][nN]$")

drop if missing(stone) & missing(pound) & missing(kg) & missing(cm) & missing(metre) & missing(feet) & missing(inch)
drop if stone == 1 & pound == 1
replace inch = 0 if feet == 1

generate unit = ""
replace unit = "st" if stone == 1
replace unit = "lb" if pound == 1
replace unit = "kg" if kg == 1
replace unit = "cm" if cm == 1
replace unit = "m" if m == 1
replace unit = "ft" if feet == 1
replace unit = "in" if inch == 1

keep numunitid description unit
save_to_file "${codelists}\other\cprd_height_weight_units.dta" 1

restore
generate unit = ""

// litres
replace unit = "L/s" if regexm(description, "^/?([lL]|[Ll]iter|[Ll]itre|[Ll]tr)[Ss]?/?[Ss]?(1?.*[Ss]ec(ond)?)?$")

// ml 
replace unit = "ml/s" if regexm(description, "^/?[mM]([lL]|[Ll]iter|[Ll]itre|[Ll]tr)[Ss]?/?[Ss]?(1?.*[Ss]ec(ond)?)?$")

// %
replace unit = "% predicted" if regexm(description, "(^(% )?[Pp]er ?[Cc]ent(age)?( [Uu]nit| [Pp]redicted)?$)|(^%( [Oo]f)?( [Nn]ormal| [Pp]redicted)?$)")

drop if missing(unit)
save_to_file "${codelists}\other\cprd_fev1_units.dta" 1
