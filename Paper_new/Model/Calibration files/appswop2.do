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
swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) at(x1=10 cut1=10 x2=10 x3=10 cut1=10 cut2=10 x4=10 x5=10 cut1=10 cut2=10)
//swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) endo maxiter(10) at(x1=8 cut1=8 x2=8 x3=8 cut1=8 cut2=8 x4=8 x5=8 cut1=8 cut2=8 r1=10 r2=10)
// swopit y house gdp bias spread, reg(house gdp) outone(spread bias) outtwo(spread bias) maxiter(30)
//swopit health area weight female rural, reg(area weight female rural) outone(area weight female rural) outtwo(are weight female rural) endo

// POSTESTIMATION COMMANDS //
swopitmargins, at(x1=0 x2=2 x3=0 x4=1 x5=0)
//swopitprobabilities, at(x1=0)
// swopitclassification
// swopitpredict, tabstat