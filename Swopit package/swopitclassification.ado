*! version 1.0.0 01apr2022
*! contains the Stata interface of the swopitclassification command
*! the command constructs a confusion matrix (classifcation table) for the dependent variable

program swopitclassification, rclass
	version 14
	syntax
	mata: SWOPITclassification(SWOPITMODEL)
end
	
