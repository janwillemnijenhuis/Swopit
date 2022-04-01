*! version 1.0.0 01apr2022
*! contains the Stata interface of the swopitprobabilities command
*! the command provides the predicted probabilities of the observed choices (by default) *! or latent classes and their standard errors 
*! for the specified values of the independent variables

program swopitprobabilities, rclass
	version 14
	syntax [, at(string asis) zeros regimes]
	mata: SWOPITprobabilities(SWOPITMODEL, "`at'", "`zeros'" == "zeros", "`regimes'"=="regimes")
	return matrix at at
	return matrix pr pr
	return matrix se se
	return matrix t t
	return matrix pval pval
end

