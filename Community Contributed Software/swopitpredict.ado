capture program drop swopitpredict
program swopitpredict, rclass
	version 14
	syntax name [if] [in] [, regimes output(string asis)]
	marksample touse
	mata: SWOPITpredict(SWOPITMODEL, "`1'", "`regimes'"=="regimes", "`output'")
end


