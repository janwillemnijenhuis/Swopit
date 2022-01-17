capture program drop swopitprobabilities
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

