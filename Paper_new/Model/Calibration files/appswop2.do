// SPECIFY TO THE LOCATION OF YOUR FILES // 
cd "C:\Users\janwi\OneDrive\Documents\PaperSwopit\Paper_new_2\Swopit\Paper_new\Model" 
mata: mata clear

// RUN FILES NEEDED FOR ESTIMATION // 
run DefModel.ado	
run helpfunctest.ado
run estimates.ado
run swopit.ado
run swopitpredict.ado
// AVAILABLE DATASETS //
//use rate_change.dta
//use policy_rate.dta
//use rates2.dta
//use EUKnowledge.dta
set seed 3
set more off
// RUN SWOPIT ESTIMATION //
//swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) guesses(2) boot(3) bootguesses(2) bootiter(100) change(0.25) log
swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) log
//swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) endo maxiter(3) lim(10)
//swopit y house gdp bias spread, reg(house gdp) outone(spread bias) outtwo(spread bias) log endo
// swopit health area weight female rural, reg(area weight female rural) outone(area weight female rural) outtwo(are weight female rural) endo

// POSTESTIMATION COMMANDS //
//swopitmargins, at(x1=0 x2=2 x3=0 x4=1 x5=0)
//swopitprobabilities, at(x1=0)
// swopitclassification
swopitpredict, regimes tabstat