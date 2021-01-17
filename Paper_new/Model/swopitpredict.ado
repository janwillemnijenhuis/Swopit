capture program drop swopitpredict
program swopitpredict
	version 14
	syntax name [if] [in] [, zeros regimes]
	mata: SWOPITpredict(SWOPITMODEL, "`zeros'" == "zeros", "`regimes'"=="regimes")
end