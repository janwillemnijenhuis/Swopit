capture program drop swopit
program swopit, eclass
	version 14
	syntax varlist(min=2) [if] [in] [, REGindepvars(varlist) OUTONEindepvars(varlist) OUTTWOindepvars(varlist) INITIAL(string asis) GUESSES(real 7) CHANGE(real 0.5) LIMit(real 0)]

	marksample touse
	//display "`varlist'"
	//display "`outindepvars'"
	//display "`touse'"

	mata: mata clear

	run helpfunctest.ado
	run DefModel.ado
	run estimates.ado

	mata: SWOPITMODEL = swopit2test("`varlist'","`regindepvars'","`outoneindepvars'","`outtwoindepvars'", "`touse'", "`initial'", "`guesses'", "`change'", "`limit'")
	ereturn post b V, esample(`touse')  depname(`depvar') obs(`N')
	ereturn local predict "zioppredict"
	ereturn local cmd "ziop2"
	ereturn scalar ll = ll
	ereturn scalar k = k
	ereturn matrix ll_obs ll_obs
	ereturn scalar r2_p = r2_p
	ereturn scalar k_cat = k_cat
	ereturn scalar df_m = df_m
	ereturn scalar ll_0 = ll_0
	ereturn scalar chi2 = chi2
	ereturn scalar p = p
	ereturn scalar aic = aic
	ereturn scalar bic = bic
	ereturn display	

end
	
	
	



