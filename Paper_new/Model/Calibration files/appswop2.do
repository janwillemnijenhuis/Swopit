// SPECIFY TO THE LOCATION OF YOUR FILES // 
cd "C:\Users\janwi\OneDrive\Documents\PaperSwopit\Paper_new\Swopit\Paper_new\Model" 
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

// RUN SWOPIT ESTIMATION //
swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) boot(2) maxiter(30)
//swopit y house gdp bias spread, reg(house gdp) outone(spread bias) outtwo(spread bias) 

// RUN SWOPIT CORRELATED ESTIMATION //
//swopitc y x1 x2 x3 x4 x5, reg(x1 x2 x3 x4 x5) outone(x1 x2 x3 x4 x5) outtwo(x1 x2 x3 x4 x5)

// POSTESTIMATION COMMANDS //
// swopitmargins
// swopitprobabilities
// swopitclassification
// swopitpredict, tabstat