********************************************************************************
*** iterate through csv files, compile into one dta file
********************************************************************************

* cd to data dir

import delimited 2011.csv, encoding(UTF-8)
gen year=2011
foreach j in lrank lpts{
replace `j' = "" if `j'=="N/A"
}
destring lrank lpts, replace
save 2011.dta, replace

forvalues i = 2013/2013{
clear
import delimited `i'.csv, encoding(UTF-8)
foreach j in wrank wpts lrank lpts{
replace `j' = "" if `j'=="N/A"
destring `j', replace
}
gen year=`i'
save `i'.dta, replace
}

forvalues i = 2014/2016{
clear
import delimited `i'.csv, encoding(UTF-8)
foreach j in lrank lpts{
replace `j' = "" if `j'=="N/A"
}
destring lrank lpts, replace
gen year=`i'
save `i'.dta, replace
}

forvalues i = 2017/2018{
clear
import delimited `i'.csv, encoding(UTF-8)
foreach j in wrank wpts lrank lpts{
replace `j' = "" if `j'=="N/A"
destring `j', replace
}
gen year=`i'
save `i'.dta, replace
}

forvalues i = 2019/2019{
clear
import delimited `i'.csv, encoding(UTF-8)
foreach j in wrank wpts lrank lpts psw maxl{
replace `j' = "" if `j'=="N/A" | `j' == "#N/A"
destring `j', replace
}
gen year=`i'
save `i'.dta, replace
}

forvalues i = 2020/2020{
clear
import delimited `i'.csv, encoding(UTF-8)
gen year=`i'
save `i'.dta, replace
}

use 2011.dta, clear
forvalues i = 2013/2020{
append using `i'.dta
}

* some clean up to create unique names (for twins and sisters) 
replace winner = "Williamsx S." if winner == "Williams S."
replace winner = "Radwanskax U." if winner == "Radwanska U."
replace winner = "Pliskovax K." if winner == "Pliskova Ka."
replace winner = "Pliskova K." if winner == "Pliskova Kr."
replace winner = "Rodionova A." if winner == "Rodionova Ar."
replace winner = "Rodionovax A." if winner == "Rodionova An."

replace loser = "Williamsx S." if loser == "Williams S."
replace loser = "Radwanskax U." if loser == "Radwanska U."
replace loser = "Pliskovax K." if loser == "Pliskova Ka."
replace loser = "Pliskova K." if loser == "Pliskova Kr."
replace loser = "Rodionova A." if loser == "Rodionova Ar."
replace loser = "Rodionovax A." if loser == "Rodionova An."

capture drop lastname_w
gen lastname_w = ""
format lastname_w %33s
replace lastname_w = substr(winner, 1 , strpos(winner,".")-3)
replace lastname_w = regexr(lastname_w,".+ ","")

capture drop lastname_l
gen lastname_l = ""
format lastname_l %33s
replace lastname_l = substr(loser, 1 , strpos(loser,".")-3)
replace lastname_l = regexr(lastname_l,".+ ","")

save odds.dta, replace
