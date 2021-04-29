// make the current directory working directory (change the address to that on your own computer!)
cd "C:/Users/janwi/OneDrive/Documents/PaperSwopit/Swopit/Paper_new/Model" 

// policy rate application as in paper
use policy_rate.dta, clear

set more off
oprobit y house gdp bias spread, nolog
estat ic

set more off
capture swopit y house gdp bias spread, reg(house gdp) outone(spread bias) outtwo(spread bias)

swopitprobabilities, at(house=1.65 gdp=4.1 bias=0 spread=0.55)

swopitpredict choice, output(choice)
tab choice

swopitpredict pregim, regimes
tabstat pregim*, stat(mean)

swopitmargins, at(house=1.65 gdp=4.1 bias=0 spread=0.55)

swopitclassification

// health data application as in paper 
use fmm_health.dta, clear
oprobit health area weight female rural, nolog

estimates stat

swopit health weight female rural, reg(area weight female rural) outone(area weight female rural) outtwo(area weight female rural)

swopit health weight female rural, reg(area weight female rural) outone(area weight female rural) outtwo(area weight female rural) endo

// view help
view swopit.sthlp
view swopitpostestimation.sthlp

