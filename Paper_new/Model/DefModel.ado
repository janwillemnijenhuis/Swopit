version 14
mata
class SWOPITModel {
	string scalar model_class
	string scalar opt_method
	string scalar model_suptype
	string scalar model_bootstrap
	string scalar switching_type
	
	
	// utility parameters
	real vector beta
	real vector a
	real vector gamma
	real vector mu
	real scalar n
	real scalar k
	real scalar df
	real scalar df_null
	real vector outeq1
	real vector outeq2
	real vector regeq
	
	// categories of target variables
	real scalar ncat
	real scalar infcat
	real vector allcat
	real scalar ncatp
	real scalar ncatn
	real matrix classes
	
	// parameters for positive-negative
	real scalar kp
	real scalar kn
	real vector gammap
	real vector mup
	real vector gamman
	real vector mun
	real scalar rop
	real scalar ron
	
	// estimation options
	real scalar robust
	
	// main estimation results
	real vector params
	real matrix V
	real matrix V_rob
	real vector se
	real vector t
	real vector se_rob
	real vector t_rob
	real vector pval
	real matrix boot_params
	
	// probabilities
	real matrix probabilities
	real matrix ll_obs
	// probability of r == 1
	real scalar p1_sorted
	real scalar p1_range
	real scalar p1_xbar
	
	// optimization outcome
	string scalar retCode 
	real scalar etime
	real scalar error_code
	real scalar converged
	real scalar iterations
	
	// likelihood
	real scalar logLik
	real scalar logLik0
	real scalar R2 // mcFadden R2 = 1 - lnL(model)/lnL(simple model)
	real scalar chi2
	real scalar chi2_pvalue
	
	// infocriteria
	real scalar AIC		
	real scalar BIC		
	real scalar CAIC	
	real scalar AICc	
	real scalar HQIC
	real scalar brier_score
	real scalar ranked_probability_score
	real scalar accuracy
	
	// marginal effects
	real vector me
	real vector mese
	real vector met
	real vector mepval
	
	// description of data
	string scalar yname
	string scalar xnames
	string scalar x1names
	string scalar x2names
	string scalar znames
	string scalar zpnames
	string scalar znnames
	
	string vector XZnames	// Stata names of independent variables
	real matrix corresp	// coincidence of independent variables in X, Zp and Zn matrices
	/*
	Example of corresp:
	
	*/
	real vector XZmeans		// means of independent variables
	real vector XZmedians
	string vector eqnames
	string vector parnames
}
end
