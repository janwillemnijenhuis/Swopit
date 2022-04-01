*! version 1.0.0 01apr2022
*! contains the Stata interface of the swopitmargins command
*! the command provides the marginal (partial) effects on the predicted probabilities 
*! of the observed choices (by default) or latent classes and their standard errors 
*! for the specified values of the independent variables

program swopitmargins, rclass
	version 14
	syntax [, at(string asis) zeros regimes]
	mata: SWOPITmargins(SWOPITMODEL, "`at'", "`zeros'" == "zeros", "`regimes'"=="regimes")
	return matrix at at
	return matrix me me
	return matrix se se
	return matrix t t
	return matrix pval pval
end


