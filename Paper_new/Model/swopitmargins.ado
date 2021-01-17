capture program drop swopitmargins
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