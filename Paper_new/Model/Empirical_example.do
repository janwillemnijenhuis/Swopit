// make the current directory working directory (change the address to that on your own computer!)
cd "C:\Swopit_application" 

// policy rate empirical example as in paper

use policy_rate.dta, clear
summarize

set seed 3
set more off
oprobit y house gdp bias spread, nolog
estat ic

set seed 3
set more off
swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) log

swopitprobabilities, at(house=1.5 gdp=8.9 bias=1 spread=-0.0633333)

quietly oprobit y house gdp bias spread
predict pr*, p
display pr1[2], pr2[2], pr3[2]

swopitpredict, output(choice)
display swopit_pr[2]

swopitpredict, regimes tabstat

display swopit_r_0[2], swopit_r_1[2]

swopitmargins, at(house=1.56 gdp=5.9 bias=1 spread=-0.41)

quietly oprobit y house gdp bias spread
margins, dydx(house gdp bias spread) at(house=(1.56) gdp=(5.9) bias=(1) spread=(-0.41))

swopitclassification

set seed 3
set more off
swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) boot(900) bootguesses(2) bootiter(100) change(0.25)

swopitprobabilities, at(house=1.5 gdp=8.9 bias=1 spread=-0.0633333)

set seed 3
set more off
swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) endo guesses(25)

// view help
view swopit.sthlp
view swopitpostestimation.sthlp

