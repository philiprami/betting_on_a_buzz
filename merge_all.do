********************************************************************************
*** merge wikipedia data into the odds.dta file for winners and losers
********************************************************************************

* cd to data folder

* process wiki dataset
import delimited wikipedia.csv, encoding(UTF-8) clear
gen date1 = mdy(month,day,year)
drop date
rename date1 date
egen pid = group(odds_player)

* check for duplicates
duplicates list pid date
sort pid date wiki

* make wiki stats
xtset pid date
tsfill
replace wiki=0 if wiki==.
capture drop month year day
gen year=year(date)
gen month=month(date)
gen day=day(date)

* Med/Mean/Min over past 7,30,365 days
ssc install rangestat
rangestat (median) wiki_med30=wiki , int(date -30 -1) by(pid)
rangestat (median) wiki_med365=wiki , int(date -365 -1) by(pid)
rangestat (median) wiki_med7=wiki , int(date -7 -1) by(pid)
rangestat (mean) wiki_mean30=wiki , int(date -30 -1) by(pid)
rangestat (mean) wiki_mean365=wiki , int(date -365 -1) by(pid)
rangestat (mean) wiki_mean7=wiki , int(date -7 -1) by(pid)
rangestat (min) wiki_min30=wiki , int(date -30 -1) by(pid)
rangestat (min) wiki_min365=wiki , int(date -365 -1) by(pid)
rangestat (min) wiki_min7=wiki , int(date -7 -1) by(pid)
egen wiki_mean_player = mean(wiki), by(pid)
egen wiki_med_player = median(wiki), by(pid)
gen wiki_yesterday = L.wiki
gen wiki_twodays = L2.wiki

* merge in wiki with odds
gen winner = odds_player
gen loser = odds_player
save wiki_data.dta, replace

* load master file
use odds.dta, clear
gen date1 = date(date, "DMY")
drop date
rename date1 date
gen month=month(date)
gen day=day(date)

* merge winner
merge m:1 month year day winner using wiki_data.dta
drop if _merge==2
drop _merge
foreach i in wiki*{
	rename `i' `i'_w
}

* merge loser
merge m:1 month year day loser using wiki_data.dta
drop if _merge==2
drop _merge
foreach i in wiki*{
	rename `i' `i'_l
}
foreach i in wiki*{
	rename `i'_w_l `i'_w
}
save final.dta, replace

********************************************************************************
*** prep timezones
********************************************************************************

use timezones.dta, clear
recast float month year day
save timezones.dta, replace

********************************************************************************
*** prep elo
********************************************************************************

use elo.dta, clear
drop if month == "NA"
destring year, generate(year1)
destring month, generate(month1)
destring day, generate(day1)
drop year month day
rename year1 year
rename month1 month
rename day1 day
recast float month year day
save elo.dta, replace

********************************************************************************
*** prep welo
********************************************************************************

use welo.dta, clear
drop if month == "NA"
destring year, generate(year1)
destring month, generate(month1)
destring day, generate(day1)
drop year month day
rename year1 year
rename month1 month
rename day1 day
recast float month year day
save welo.dta, replace

********************************************************************************
*** merge in timezones, elo and welo
********************************************************************************

use final.dta, clear
merge m:1 month year day location using timezones.dta, keepusing(timezone utc_offset)
capture drop _merge
drop if month==.

merge m:1 month year day winner loser using elo.dta , force keepusing(elopredict)
drop if _merge==2
capture drop _merge

merge m:1 month year day winner loser using welo.dta , keepusing(elo_pi* welo_pi)
drop if _merge==2
capture drop _merge

save final.dta, replace
