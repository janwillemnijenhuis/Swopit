capture program drop swopitpredict
program swopitpredict, rclass
	version 14
	syntax [if] [in] [, name(string asis) regimes output(string asis), tabstat]
	marksample touse
	mata: SWOPITpredict(SWOPITMODEL, "`name'", "`regimes'"=="regimes", "`output'", "`tabstat'" == "tabstat")
end


