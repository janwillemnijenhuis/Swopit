*! version 1.0.0 01apr2022
*! contains the Stata interface of the swopit command
*! the command fits a mixture of OP models with either exogenous 
*! or endogenous switching between two latent classes (regimes)

program swopit, eclass
	version 14
	syntax varlist(min=2) [if] [in] [, REGindepvars(varlist) OUTONEindepvars(varlist) OUTTWOindepvars(varlist) INITIAL(string asis) GUESSES(real 5) CHANGE(real 0.5) LIMit(string asis) MAXiter(real 500) PTOL(real 1e-6) VTOL(real 1e-7) NRTOL(real 1e-5) ENDOgenous BOOTstrap(real 0) BOOTGUESSES(real 3) BOOTITER(real 100) LOG]

	marksample touse

	mata: mata clear

	run helpfunctest.ado
	run defmodel.ado
	run swopitestimates.ado
		
	capture mata: SWOPITMODEL = swopitmain("`varlist'","`regindepvars'","`outoneindepvars'","`outtwoindepvars'", "`touse'", "`initial'", "`guesses'", "`change'", "`limit'", "`maxiter'", "`ptol'", "`vtol'", "`nrtol'", "`endogenous'" == "endogenous", "`bootstrap'", "`bootguesses'", "`bootiter'", "`log'" == "log")


	mata: printerror(SWOPITMODEL)
	mata: printoutput(SWOPITMODEL)

	ereturn post b V, esample(`touse')  depname(`depvar') obs(`N')
	ereturn local predict "swopitpredict"
	ereturn local cmd "swopit"
	ereturn local switching  = "`switching'"
	ereturn local opt  = "`opt'"
	ereturn local vce "Observed Information Matrix (OIM)"
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

	if "`bootstrap'" != "0" {
		ereturn local vce "Bootstrap"
		ereturn local vcetype Bootstrap
		ereturn matrix boot boot
	}

	ereturn display	

end
	
	
	



