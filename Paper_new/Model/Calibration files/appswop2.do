// SPECIFY TO THE LOCATION OF YOUR FILES // 
cd "/Users/jhuismans/Desktop/Paper Swopit/Swopit/Paper_new/Model" 
mata: mata clear
// RUN FILES NEEDED FOR ESTIMATION // 
run DefModel.ado
run helpfunctest.ado
run estimates.ado

// AVAILABLE DATASETS //
//use rate_change.dta
//use rates2.dta
//use EUKnowledge.dta

// RUN SWOPIT ESTIMATION //
swopit y x1 x2 x3 x4 x5, reg(x1) outone(x2 x3) outtwo(x4 x5) maxiter(20) boot(1) bootiter(3)

// RUN SWOPIT CORRELATED ESTIMATION //
//swopitc y x1 x2 x3 x4 x5, reg(x1 x2 x3 x4 x5) outone(x1 x2 x3 x4 x5) outtwo(x1 x2 x3 x4 x5)

// POSTESTIMATION COMMANDS //
//swopitmargins, at(x1=0 x2=0 x3=0 x4=0 x5=0)
//swopitprobabilities, at(x1=0 x2=0 x3=0 x4=0 x5=0)
//swopitclassification

// NOT YET SUPPORTED //
//swopitpredict
