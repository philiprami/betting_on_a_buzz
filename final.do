version 17

** A few packages that may need to be installed
* ssc install ftools
* ssc install reghdfe
* ssc install distinct

* set cd to your data folder

use final.dta, clear

rename elopredict elopredictw
gen elopredictl = 1-elopredictw

rename elo_pi elopredict2w
gen elopredict2l = 1-elopredict2w

rename welo_pi welopredictw
gen welopredictl = 1-welopredictw

rename wrank rankw
rename lrank rankl
rename winner playerw
rename loser playerl
drop player
gen booksum_avg = 1/avgw + 1/avgl
gen booksum_max = 1/maxw + 1/maxl
gen booksum_b365 = 1/b365w + 1/b365l
egen tid = group(year tournament)
keep avgw avgl player* rank* year day month wiki* tid booksum* maxw maxl b365w b365l utc_offset round elo* welo*

gen probw = 1/avgw
gen errorw = 1-probw

gen probl = 1/avgl
gen errorl = 0-probl

gen rankxw = 1/rankw
gen rankxl = 1/rankl

replace rankxw= 0 if rankxw==.
replace rankxl= 0 if rankxl==.

gen rankdiffw = rankw - rankl
gen rankdiffl = rankl - rankw

gen rankdiffxw = -1*(rankxw - rankxl)
gen rankdiffxl = -1*(rankxl - rankxw)

gen wiki_diff_w = wiki_w - wiki_l
gen wiki_diff_l = wiki_l - wiki_w

gen wiki_diff_yesterday_w = wiki_yesterday_w - wiki_yesterday_l
gen wiki_diff_yesterday_l = wiki_yesterday_l - wiki_yesterday_w

gen wiki_dev_y_w = ln(wiki_yesterday_w / wiki_med365_w)
gen wiki_dev_y_l = ln(wiki_yesterday_l / wiki_med365_l)
gen wiki_dev_y_diff_w = wiki_dev_y_w - wiki_dev_y_l
gen wiki_dev_y_diff_l = wiki_dev_y_l - wiki_dev_y_w

gen wiki_dev_t_w = ln(wiki_w / wiki_med365_w)
gen wiki_dev_t_l = ln(wiki_l / wiki_med365_l)
gen wiki_dev_t_diff_w = wiki_dev_t_w - wiki_dev_t_l
gen wiki_dev_t_diff_l = wiki_dev_t_l - wiki_dev_t_w

rename *l *0
rename *w *1

* dummy for both players ranked at most 100
gen rank_100_match = (rank0<=100 & rank1<=100)
* dummy for both players ranked at most 50
gen rank_50_match = (rank0<=50 & rank1<=50)

gen mid = _n
reshape long avg max b365 elopredict elopredict2 welopredict prob error player rank rankdiff wiki wiki_yesterday_ wiki_twodays wiki_mean7 wiki_med7 wiki_mean30 wiki_med30 wiki_med365_ wiki_mean365 wiki_diff wiki_diff_yesterday_ rankx rankdiffx  wiki_dev_y_ wiki_dev_y_diff_  wiki_dev_t_ wiki_dev_t_diff_,  i(mid) j(outcome)

*** Generate analytic weights for WLS
capture drop weight
gen weight = 1/(prob*(1-prob))

gen rankxsq = rankx*rankx
gen rankdiffx_sq = rankdiffx*rankdiffx

replace rankdiff = rankdiff/100 // rescale

drop if year<2015

keep if wiki_dev_y_diff_ !=.
keep if prob!=.
keep if rankdiffx!=.

************************
**** TABLE 1 & Table 2 - 6 Columns

** FLB
reghdfe error prob i.year if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 1
*reghdfe error prob i.year [aweight=weight] if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 1 (alt with weights)
reghdfe error prob i.year, vce(cluster mid tid) noabsorb // TABLE 2, Column 1


*****************************
*** Some useful sample stats
distinct player if e(sample)
distinct tid  if e(sample)
distinct mid  if e(sample)


*****************************

** ADD Basic Rankdiff
reghdfe error prob rankdiff i.year if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 2
test prob rankdiff
*reghdfe error prob rankdiff i.year [aweight=weight] if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 2 (alt with weights)
reghdfe error prob rankdiff i.year, vce(cluster mid tid) noabsorb // TABLE 2, Column 2
test prob rankdiff

** SIGNIF BUT TINY

** ADD Alternative Rankdiff
reghdfe error prob rankdiffx i.year if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 3
test prob rankdiffx
*reghdfe error prob rankdiffx i.year [aweight=weight] if year<2019, vce(cluster mid tid) noabsorb // TABLE 1, Column 3 (alt with weights)
reghdfe error prob rankdiffx i.year, vce(cluster mid tid) noabsorb // TABLE 2, Column 3
test prob rankdiffx
**  --- shown effect is for an unranked player agains number 1 in the world!!!


***********************************************

*** Kdensity plots -- for paper

count if wiki_dev_y_diff!=. & rankdiffx!=. & prob!=.

gen log_wiki_yesterday_ = ln(wiki_yesterday_)

gen log_wiki_med365_ = ln(wiki_med365_)

twoway (kdensity log_wiki_yesterday_ if outcome==0, kernel(gauss) bw(0.2) lp(solid) lcolor(black) lwidth(medium)) ///
 (kdensity log_wiki_yesterday_ if outcome==1, kernel(gauss) bw(0.2) lp(dash) lcolor(black) lwidth(medium)) , ///
 title("") xtitle("Log wikipedia profile page views", size(medlarge)) ytitle("Density", size(medlarge)) legend(label(1 "Loser") label(2 "Winner")) ///
 ylabel(0(0.1)0.4, format(%9.1fc) nogrid angle(0)) ymlabel(,nolabels) xsc(r(0 15)) xlabel(0(3)15, format(%9.0fc)) ///
 graphregion(fcolor(white)) plotregion(margin(0)) name(fig1, replace)
 graph export "fig1.png" , as(png) name(fig1) replace width(2800) height(2000)

 twoway (kdensity log_wiki_med365_ if outcome==0, kernel(gauss) bw(0.2) lp(solid) lcolor(black) lwidth(medium))  ///
    (kdensity log_wiki_med365_ if outcome==1, kernel(gauss) bw(0.2) lp(dash) lcolor(black) lwidth(medium)) , ///
 title("") xtitle("Log wikipedia median profile page views", size(medlarge)) ytitle("Density", size(medlarge)) legend(label(1 "Loser") label(2 "Winner")) ///
 ylabel(0(0.1)0.4, format(%9.1fc) nogrid angle(0)) ymlabel(,nolabels) xsc(r(0 15)) xlabel(0(3)15, format(%9.0fc)) ///
 graphregion(fcolor(white)) plotregion(margin(0)) name(fig2, replace)
 graph export "fig2.png" , as(png) name(fig2) replace width(2800) height(2000)


twoway (kdensity wiki_dev_y_diff if outcome==1, kernel(gauss) bw(0.2) lp(solid) lcolor(black) lwidth(medium)), ///
title("") xtitle("Log difference in wikipedia profile page views", size(medlarge)) ytitle("Density", size(medlarge))  ///
 ylabel(0(0.1)0.4, format(%9.1fc) nogrid angle(0)) ymlabel(,nolabels) xsc(r(-9 9)) xlabel(-9(3)9, format(%9.0fc)) ///
 graphregion(fcolor(white)) plotregion(margin(0)) name(fig3, replace)
 graph export "fig3.png" , as(png) name(fig3) replace width(2800) height(2000)

 summarize wiki_dev_y_diff if outcome==1, detail
 ttest wiki_dev_y_diff==0 if outcome==1
 summarize wiki_dev_y_diff, detail
 sktest wiki_dev_y_diff


***********************************************


** Add Wiki Diff Yesterday (Log diff from median over last 365 days on day of match, diff between players)
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if year<2019, vce(cluster tid mid) noabsorb resid // TABLE 1, Column 4
test prob rankdiffx wiki_dev_y_diff
*reghdfe error prob rankdiffx wiki_dev_y_diff i.year [aweight=weight] if year<2019, vce(cluster tid mid) noabsorb // TABLE 1, Column 4 (alt with weights)
reghdfe error prob rankdiffx wiki_dev_y_diff i.year, vce(cluster tid mid) noabsorb resid // TABLE 2, Column 4
test prob rankdiffx wiki_dev_y_diff


reghdfe error prob rankdiffx wiki_dev_y_diff if year<2019, absorb(tid) vce(cluster mid tid) // TABLE 1, Column 5 --- torunament-year FEs instead of just year
test prob rankdiffx wiki_dev_y_diff
*reghdfe error prob rankdiffx wiki_dev_y_diff [aweight=weight] if year<2019, absorb(tid) vce(cluster mid tid) // TABLE 1, Column 5 --- torunament-year FEs instead of just year (alt with weights)
reghdfe error prob rankdiffx wiki_dev_y_diff, absorb(tid) vce(cluster mid tid) // TABLE 2, Column 5 --- torunament-year FEs instead of just year
test prob rankdiffx wiki_dev_y_diff


**** 1st Round Matches only
gen r1 = (round == "1st Round")
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if r1==1 & year<2019, vce(cluster tid mid) noabsorb // TABLE 3, Column 5
test prob rankdiffx wiki_dev_y_diff

**** both players ranked at most 100 in first round
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if r1==1 & rank_100_match==1 & year<2019, vce(cluster tid mid) noabsorb // TABLE 3, Column 6
test prob rankdiffx wiki_dev_y_diff


******************************
**** Table 3, columns 1-4
**** Insert rolling torunament window results by timezone. Regression model from TABLE 1, Column 4

* Column 1
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if year<2019, vce(cluster mid tid) noabsorb
test prob rankdiffx wiki_dev_y_diff
* Column 2
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if utc_offset < 11 & year<2019, vce(cluster mid tid) noabsorb // drop Australia, Syndey to Aukland
test prob rankdiffx wiki_dev_y_diff
* Column 3
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if utc_offset < 9 & year<2019, vce(cluster mid tid) noabsorb // Then Japan and Korea
test prob rankdiffx wiki_dev_y_diff
* Column 4
reghdfe error prob rankdiffx wiki_dev_y_diff i.year if utc_offset < 7 & year<2019, vce(cluster mid tid) noabsorb // China and Hong Kong
test prob rankdiffx wiki_dev_y_diff

******************************
*** Can results in Table 1, column 4 be used to make money?
*** Use model predictions and Kelly Criterion

/*** First generate in-sample ROI (%) - if interested in this...

* RESULTS on in-sample ROIs NOT SHOWN in PAPER

capture drop model_prob
capture drop fractional* f_star* return* investment* roi*
quietly: reg outcome prob rankdiffx wiki_dev_y_diff, vce(cluster mid)
predict model_prob if e(sample), xb
gen fractional = avg-1
gen f_star = model_prob - (1-model_prob)/fractional if e(sample)
replace f_star = . if f_star <=0
gen return = f_star*fractional if outcome==1
replace return = -f_star if outcome==0
egen investment_insample = sum(f_star)
egen return_insample = sum(return)
gen roi_insample = return_insample/investment_insample
count if f_star!=.
count if model_prob!=.
sum booksum_avg if model_prob!=.
sum roi_insample
* Bet on less than 3% of matches
* ROI: -5.1% ---, only slightly better than overround at 5.6% on average in_sample

*** what about using "best" odds?

gen fractional2 = max-1
gen f_star2 = model_prob - (1-model_prob)/fractional2 if e(sample)
replace f_star2 = . if f_star2 <=0
gen return2 = f_star2*fractional2 if outcome==1
replace return2 = -f_star2 if outcome==0
egen investment_insample2 = sum(f_star2)
egen return_insample2 = sum(return2)
gen roi_insample2 = return_insample2/investment_insample2
count if f_star2!=.
count if model_prob!=.
sum booksum_max if model_prob!=.
sum roi_insample2

*** what about using Bet365 odds?

gen fractional4 = b365-1
gen f_star4 = model_prob - (1-model_prob)/fractional4 if e(sample)
replace f_star4 = . if f_star4 <=0
gen return4 = f_star4*fractional4 if outcome==1
replace return4 = -f_star4 if outcome==0
egen investment_insample4 = sum(f_star4)
egen return_insample4 = sum(return4)
gen roi_insample4 = return_insample4/investment_insample4
count if f_star4!=.
count if model_prob!=. & b365!=.
sum booksum_b365 if model_prob!=. & b365!=.
sum roi_insample4

************************************************************************************************************
quietly: reghdfe outcome prob wiki_dev_y_diff, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob if e(sample), xb
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3 if e(sample)
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3

************
*** What about Elopredict/Welopredict?
gen fractionalelo = b365-1
gen f_starelo = elopredict - (1-elopredict)/fractionalelo
replace f_starelo = . if f_starelo <=0
gen returnelo = f_starelo*fractionalelo if outcome==1
replace returnelo = -f_starelo if outcome==0
egen investment_insampleelo = sum(f_starelo)
egen return_insampleelo = sum(returnelo)
gen roi_insampleelo = return_insampleelo/investment_insampleelo
count if f_starelo!=.
count if elopredict!=. & b365!=.
sum booksum_b365 if elopredict!=. & b365!=.
sum roi_insampleelo if elopredict!=. & b365!=.

gen fractionalelo2 = b365-1
gen f_starelo2 = elopredict2 - (1-elopredict2)/fractionalelo2
replace f_starelo2 = . if f_starelo2 <=0
gen returnelo2 = f_starelo2*fractionalelo2 if outcome==1
replace returnelo2 = -f_starelo2 if outcome==0
egen investment_insampleelo2 = sum(f_starelo2)
egen return_insampleelo2 = sum(returnelo2)
gen roi_insampleelo2 = return_insampleelo2/investment_insampleelo2
count if f_starelo2!=.
count if elopredict2!=. & b365!=.
sum booksum_b365 if elopredict2!=. & b365!=.
sum roi_insampleelo2 if elopredict2!=. & b365!=.

gen fractionalwelo = b365-1
gen f_starwelo = welopredict - (1-welopredict)/fractionalwelo
replace f_starwelo = . if f_starwelo <=0
gen returnwelo = f_starwelo*fractionalwelo if outcome==1
replace returnwelo = -f_starwelo if outcome==0
egen investment_insamplewelo = sum(f_starwelo)
egen return_insamplewelo = sum(returnwelo)
gen roi_insamplewelo = return_insamplewelo/investment_insamplewelo
count if f_starwelo!=.
count if welopredict!=. & b365!=.
sum booksum_b365 if welopredict!=. & b365!=.
sum roi_insamplewelo if welopredict!=. & b365!=.

*/
**************************************************************************************************
**************************************************************************************************

**** OUT-OF-SAMPLE - TABLE 4 Results
**** Estiamte up to 2019, use 2019 and start of 2020 as out-of-sample

* Column 1
capture drop model_prob
capture drop fractional* f_star* return* investment* roi*
quietly: reg outcome prob rankdiffx wiki_dev_y_diff if year<2019, vce(cluster mid)
predict model_prob, xb
replace model_prob=. if e(sample)
gen fractional = avg-1
gen f_star = model_prob - (1-model_prob)/fractional
replace f_star = . if f_star <=0
gen return = f_star*fractional if outcome==1
replace return = -f_star if outcome==0
egen investment_insample = sum(f_star)
egen return_insample = sum(return)
gen roi_insample = return_insample/investment_insample
count if f_star!=.
count if model_prob!=.
sum booksum_avg if model_prob!=. & avg!=.
sum roi_insample
* ROI: -6.4% ---, only slightly better than overround at 5.3% on average in_sample

*** what about using "best" odds?
* column 2
gen fractional2 = max-1
gen f_star2 = model_prob - (1-model_prob)/fractional2
replace f_star2 = . if f_star2 <=0
gen return2 = f_star2*fractional2 if outcome==1
replace return2 = -f_star2 if outcome==0
egen investment_insample2 = sum(f_star2)
egen return_insample2 = sum(return2)
gen roi_insample2 = return_insample2/investment_insample2
count if f_star2!=.
count if model_prob!=.
sum booksum_max if model_prob!=.
sum roi_insample2

*** 3.0% ... that's not so impresive

*** what about using Bet365 odds
* column 3
gen fractional4 = b365-1
gen f_star4 = model_prob - (1-model_prob)/fractional4
replace f_star4 = . if f_star4 <=0
gen return4 = f_star4*fractional4 if outcome==1
replace return4 = -f_star4 if outcome==0
egen investment_insample4 = sum(f_star4)
egen return_insample4 = sum(return4)
gen roi_insample4 = return_insample4/investment_insample4
count if f_star4!=.
count if model_prob!=. & b365!=.
sum booksum_b365 if model_prob!=. & b365!=.
sum roi_insample4

** 17.3% - healthy

************************************************************************************************************
*** what about without the rank distance effect in the model? Is it just buzz effect that gets 17%?
* Column 4
quietly: reghdfe outcome prob wiki_dev_y_diff if year<2019, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob, xb
replace model_prob=. if e(sample)
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3


*** What about using Elopredict and Bet 365 odds instead
* Column 5
preserve
drop if year<2019
gen fractionalelo = b365-1
gen f_starelo = elopredict - (1-elopredict)/fractionalelo
replace f_starelo = . if f_starelo <=0
gen returnelo = f_starelo*fractionalelo if outcome==1
replace returnelo = -f_starelo if outcome==0
egen investment_insampleelo = sum(f_starelo)
egen return_insampleelo = sum(returnelo)
gen roi_insampleelo = return_insampleelo/investment_insampleelo
count if f_starelo!=.
count if elopredict!=. & b365!=.
sum booksum_b365 if elopredict!=. & b365!=.
sum roi_insampleelo if elopredict!=. & b365!=.
restore

*** Using Welo-predicted?
* Column 6 
preserve
drop if year<2019
gen fractionalwelo = b365-1
gen f_starwelo = welopredict - (1-welopredict)/fractionalwelo
replace f_starwelo = . if f_starwelo <=0
gen returnwelo = f_starwelo*fractionalwelo if outcome==1
replace returnwelo = -f_starwelo if outcome==0
egen investment_insamplewelo = sum(f_starwelo)
egen return_insamplewelo = sum(returnwelo)
gen roi_insamplewelo = return_insamplewelo/investment_insamplewelo
count if f_starwelo!=.
count if welopredict!=. & b365!=.
sum booksum_b365 if welopredict!=. & b365!=.
sum roi_insamplewelo if welopredict!=. & b365!=.
restore


*******************
*** Betting returns using subsets of matches by p competitiveness
*** TABLE 5

*** P>0.8,p<0.2
* Column 1
capture drop fractional* f_star* return* investment* roi*
quietly: reghdfe outcome prob wiki_dev_y_diff if (prob>0.8 | prob<0.2) & year<2019, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob, xb
replace model_prob=. if e(sample)
replace model_prob=. if (prob<=0.8 & prob>=0.2)
replace model_prob=. if year<2019
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3

*** P>0.6,p<0.4
* Column 2
capture drop fractional* f_star* return* investment* roi*
quietly: reghdfe outcome prob wiki_dev_y_diff if (prob>0.6 | prob<0.4) & year<2019, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob, xb
replace model_prob=. if e(sample)
replace model_prob=. if (prob<=0.6 & prob>=0.4)
replace model_prob=. if year<2019
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3

*** P<=0.8,p>=0.2
* Column 3
capture drop fractional* f_star* return* investment* roi*
quietly: reghdfe outcome prob wiki_dev_y_diff if (prob<=0.8 & prob>=0.2) & year<2019, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob, xb
replace model_prob=. if e(sample)
replace model_prob=. if (prob>0.8 | prob<0.2)
replace model_prob=. if year<2019
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3


*** P<=0.6,p>=0.4
* Column 4
capture drop fractional* f_star* return* investment* roi*
quietly: reghdfe outcome prob wiki_dev_y_diff if (prob<=0.6 & prob>=0.4) & year<2019, noabsorb vce(cluster mid)
capture drop model_prob
predict model_prob, xb
replace model_prob=. if e(sample)
replace model_prob=. if (prob>0.6 | prob<0.4)
replace model_prob=. if year<2019
gen fractional3 = b365-1
gen f_star3 = model_prob - (1-model_prob)/fractional3
replace f_star3 = . if f_star3 <=0
gen return3 = f_star3*fractional3 if outcome==1
replace return3 = -f_star3 if outcome==0
egen investment_insample3 = sum(f_star3)
egen return_insample3 = sum(return3)
gen roi_insample3 = return_insample3/investment_insample3
count if f_star3!=.
count if model_prob!=.
sum booksum_b365 if model_prob!=.
sum roi_insample3
