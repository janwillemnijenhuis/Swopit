*! version 1.0.0 01apr2022
*! contains the Stata interface of the swopitpredict command
*! the command provides the predicted probabilities of the observed choices (by default) *! or latent classes for each observation

program swopitpredict, rclass
	version 14
	syntax [if] [in] [, name(string asis) regimes output(string asis), tabstat]
	marksample touse
	mata: SWOPITpredict(SWOPITMODEL, "`name'", "`regimes'"=="regimes", "`output'", "`tabstat'" == "tabstat")
end


