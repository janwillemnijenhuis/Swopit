version 14
mata
class SWOPITModel scalar estimateswopit(y, x1, x2, z,|guesses,s_change, param_limit, atVarlist, startvalues, maxiter, ptol, vtol, nrtol, nolog){
    
	starttime = clock(c("current_time"),"hms")
	n	= rows(x1) // = rows(x2)
	//kx	= cols(x)
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz	= cols(z)
	allcat = uniqrows(y)
	ncat = rows(allcat)
	
	if (param_limit == 0){
	    set_limit=0
		// if starting values are provided but one doesnt want a limit
	} else {
	    set_limit=1
		// if one wants a limit and a limit is provided
	}
	
	// set limit for params individually
	parlen = (kx1 + ncat - 1 + kx2 + ncat - 1 + kz + 1) // seems redundant, now it doesn't haha ty
	atTokens = tokens(atVarlist, " ") // create the tokens for the varlist

	// First check if only one value is specified
	if (length(atTokens) == 1) {
	    if (nolog != 0){
		stata(`"noisily display as text "The limit is set the same for all parameters""')
	    }

	    param_lim = J(1, parlen, 0)
		j = 1
		low = 0 // indicator if one of the parameter limits is set very low
	    for (i = 1; i <= parlen; i++) {
			val = strtoreal(atTokens[1])
			if (val < 1) {
				low = 1
			}
			param_lim[j] = val
			j++
		}
		if (low == 1) {
			stata(`"noisily display as err "The limit on all of the parameters is set very low.""')
			stata(`"noisily display as err "If it does not converge, please try running with different limits.""')
		} 
		set_limit = 1
	}
	// check if all parameters have a value
	else if (parlen == length(atTokens)) {
	    param_lim = J(1, parlen, 0)
		j = 1
		low = 0 // indicator if one of the parameter limits is set very low
	    for (i = 1; i <= length(atTokens); i++) {
			val = strtoreal(atTokens[i])
			if (val < 1) {
				low = 1
			}
			param_lim[j] = val
			j++
		}
		if (low == 1) {
			stata(`"noisily display as err "The limit on one or more of the parameters is set very low.""')
			stata(`"noisily display as err "If it does not converge, please try running with different limits.""')
		} 
		set_limit = 1
		
	} else if (length(atTokens) == 0) {
	    // do nothing
	} else {
		stata(`"noisily display as err "Incorrect number of parameters specified in lim().""')
 		stata(`"noisily display as err "' + strofreal(parlen) + `" " expected, received " "' + strofreal(length(atTokens)) )
		stata(`"noisily display as err "Limit on parameters will not be invoked.""')
 		stata(`"noisily display as err "Please rerun the command and specify the parameters correctly.""')
	}

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}

	startoriginal = startvalues

	if (cols(startoriginal) != parlen && startoriginal != . && cols(startoriginal) > 0) {
		stata(`"noisiliy display as err "Vector of initial values must have length ""' + strofreal(parlen))
		stata(`"noisiliy display as err "Please make corrections and re-enter correct initial values or leave them empty""')
		exit(1)
	}
	

	tot_converged = 0
	
	for (j = 1; j <= guesses; j++){

		//Proceed depending on initial values given	
		if(startoriginal == .){

			//random starting regimes
			r = runiform(n,1)
			r = (r:>=0.5)
			r1 = r
			r2 = 1 :- r
			q0 = (r, 1:-r) // regime matrix 

			if (nolog != 0) {
				stata(`"noisily display as text "Finding regime starting values""')
			}
			
			paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

			// Outcome pars distributed for regime 1 and 2
			x1obs = select(x1,r1)
			x2obs = select(x2,r2)
			q1 = select(q,r1)
			q2 = select(q,r2)

			if (nolog != 0) {
				stata(`"noisily display as text "Finding outcome starting values""')
			}
			
			x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
			x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
			startparam = paramsz\x1pars\x2pars
			startvalues = startparam
		} else{
			//In order to stop after first converged when initial is specified
			//if (tot_converged == 1){
			//	break
			//}
			if (j == 1){
				startparam = startvalues'
				_swopit_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)

				if (sort(a1,1) != a1){
					stata(`"noisiliy display as err "Initial thresholds of regime 1 are not in order.""')
					stata(`"noisiliy display as err "Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest.""')
					exit(1)
				}
				if (sort(a2,1) != a2){
					stata(`"noisiliy display as err "Initial thresholds of regime 2 are not in order.""')
					stata(`"noisiliy display as err "Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest.""')
					exit(1)
				}

			}
			else{
				startparam = startvalues'
				for (k = 1; k <= cols(startvalues); k++){
					startparam[k] = startparam[k] + s_change*runiform(1,1, -abs(startparam[k]), abs(startparam[k]))
				}
				
			}
		}

		_swopit_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)

		a1 = sort(a1,1)
		a2 = sort(a2,1)

		coded_param = g\codeIncreasingSequence(mu)\b1\codeIncreasingSequence(a1)\b2\codeIncreasingSequence(a2) //with a1,a2,b1,b2	

		//replace by zeros if one of the variables is empty
		if (max(coded_param :==.)  > 0){
			coded_param = J(rows(coded_param), cols(coded_param), 0)

		}
	
	
		initial_coded_param = coded_param
		
		// different optim methods
		for (i = 1; i <= 4; i++){	
			if (i == 1) {
			initial_coded_param = coded_param
			opt_method = "nr"
			
			if (nolog != 0) {
				stata(`"noisily display as text "Attempt #""' + strofreal(j) + `" " with method: nr" "')
			}
	
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: bhhh""')
				}
			}
			if (i == 3) {
				initial_coded_param = coded_param
				opt_method = "dfp"
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: dfp""')
				}
				
			}
			if (i == 4) {
				initial_coded_param = coded_param
				opt_method = "bfgs"
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: bfgs""')
				}
				
			}


			singularHmethod= "hybrid"
	
			
			S = optimize_init()


			optimize_init_verbose(S, 0)
			optimize_init_tracelevel(S , "none")

			optimize_init_argument(S, 1, x1) // outcome matrix 1
			optimize_init_argument(S, 2, x2) // outcome matrix 2
			optimize_init_argument(S, 3, z) // regime matrix
			optimize_init_argument(S, 4, q) // y dummies
			optimize_init_argument(S, 5, ncat)

			optimize_init_argument(S, 6, 1) // coded
			optimize_init_evaluator(S, &_swoptwo_optim())
			optimize_init_evaluatortype(S, "gf0") //gf1: making own derivative
			optimize_init_conv_maxiter(S, maxiter)
			optimize_init_params(S, initial_coded_param')
			optimize_init_conv_ptol(S, ptol)
			optimize_init_conv_vtol(S, vtol)
			optimize_init_conv_nrtol(S, nrtol)
			optimize_init_singularHmethod(S, singularHmethod)
			optimize_init_conv_warning(S, "off") 
			optimize_init_technique(S, opt_method)
			optimize_init_constraints(S,)

	
			errorcode = _optimize(S)
			

			convg		= optimize_result_converged(S)
			retCode		= optimize_result_errortext(S)
			params 		= optimize_result_params(S)'
			iterations 	= optimize_result_iterations(S)
			if (convg==1){
				if (set_limit==0){
				    	//"convergence"
				    	break
				
				} else if (set_limit==1 && length(param_lim) > 0){
				    limit = (abs(params)<=param_lim')
					if (limit == 1){
						//"convergence"
						break
					} else if (limit == 0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters""')
						}
					}
				} else {
				    param_lim = J(rows(params),cols(params),param_limit)
					limit = (abs(params)<=param_lim)
					if (limit == 1){
						//"convergence"
						break
					} else if (limit == 0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters""')
						}
					}
				}				
				
			}else{
				printMsg("no convergence", nolog)
			}
		}
		if (convg==1){
			if (set_limit==0){
				if (tot_converged==0){
					if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
						}
					best_lik = optimize_result_value(S)
					best_opt = opt_method
					tot_converged = 1
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else if (optimize_result_value(S) > best_lik){
					best_lik = optimize_result_value(S)
					best_opt = opt_method
					tot_converged = 1
					if (nolog != 0) {
						stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
					}
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else{
					if (nolog != 0) {
						stata(`"noisily display as text "convergence without likelihood improvement""')
					}
				}
			} else if (set_limit==1 && length(param_lim) > 0){
				limit = (abs(params)<=param_lim')
				if (limit == 1){
					if (tot_converged==0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						if (nolog != 0) {
							stata(`"noisily display as text "convergence without likelihood improvement""')
						}
					}
					
				} else if (limit == 0){
					if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters: disregarding estimation""')
						}
				}
			} else if (set_limit==1){
				param_lim = J(rows(params),cols(params),param_limit)
				limit = (abs(params)<=param_lim)
				if (limit == 1){
					if (tot_converged==0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						if (nolog != 0) {
							stata(`"noisily display as text "convergence without likelihood improvement""')
						}
					}
					
				} else if (limit == 0){
					if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters: disregarding estimation""')
						}
				}
			}
		}else{
			if (nolog != 0) {
				stata(`"noisily display as text "no convergence, trying again with different starting values""')
			}
		}
	
	}

	if (tot_converged == 1){
		retCode		= best_retCode
		params 		= best_params
		iterations 	= best_iterations
	}

	_swopit_params(params, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)
	params = g\decodeIncreasingSequence(mu)\b1\decodeIncreasingSequence(a1)\b2\decodeIncreasingSequence(a2)
	
	S2 = optimize_init()

	optimize_init_verbose(S, 0)
	optimize_init_tracelevel(S , "none")
	

	optimize_init_argument(S2, 1, x1)
	optimize_init_argument(S2, 2, x2)
	optimize_init_argument(S2, 3, z)
	optimize_init_argument(S2, 4, q)
	optimize_init_argument(S2, 5, ncat)
	optimize_init_argument(S2, 6, 0)
	//optimize_init_argument(S2, 7, 0) // flag that params are coded to avoid inequality constraints
	optimize_init_evaluator(S2, &_swoptwo_optim())
	optimize_init_evaluatortype(S2, "gf0")
	optimize_init_conv_maxiter(S2, maxiter)
	//if (cols(who) > 0 && who != .) {
	//	optimize_init_cluster(S2, who) 
	//}
	
	optimize_init_conv_ptol(S2, ptol)
	optimize_init_conv_vtol(S2, vtol)
	optimize_init_conv_nrtol(S2, nrtol)
	optimize_init_singularHmethod(S2, "hybrid")
	optimize_init_conv_warning(S2, "off") // show that convergence not achieved
	optimize_init_technique(S2, "nr") 
	
	optimize_init_params(S2, params')
	errorcode2 = _optimize_evaluate(S2)
	if (tot_converged == 0) {
		// not successful, robust covatiance matrix cannot be calculated
		maxLik	= optimize_result_value(S2)
		grad 	= optimize_result_gradient(S2)
		covMat	= optimize_result_V(S2)
		covMat_rob = covMat
	} else {
		//"TEST: MAXLIK IS"
		maxLik	= optimize_result_value(S2)
		//maxLik
		//"TEST: GRAD IS"
		grad 	= optimize_result_gradient(S2)
		//grad
		//"TEST: COVMAT IS"
		covMat	= optimize_result_V(S2)
		//covMat
		//"TEST: ROB IS"
		covMat_rob = optimize_result_V_robust(S2)
		//covMat_rob
	}
	
	if (best_opt == "nr") {
		maxMethod = "Newton Raphson"
	} else if (best_opt == "bhhh") {
		maxMethod = "BHHH"
	} else if (best_opt == "dfp") {
		maxMethod = "DFP"
	} else {
		maxMethod = "BFGS"
	}
	
	//calculate probabilities per observation
	prob_obs = mlswoptwo(params, x1 , x2, z, q, ncat, 1)

	//This will all be used to get all the information

	class SWOPITModel scalar model 
	model.model_class = "SWOPIT"
	model.n	= n
	model.k	= kx1 + kx2 + kz
	model.ncat	= ncat
	model.allcat = allcat
	model.classes = q
	model.retCode = retCode
	model.error_code = errorcode
	model.etime = clock(c("current_time"),"hms") - starttime
	model.converged = tot_converged
	model.iterations = iterations
	model.guesses = guesses

	model.params = params
	model.se		= sqrt(diagonal(covMat))
	model.t			= abs(params :/ model.se)
	model.se_rob	= sqrt(diagonal(covMat_rob))
	model.t_rob		= abs(params :/ model.se_rob)
	
	model.AIC	= -2 * maxLik + 2 * rows(params) 
	model.BIC	= -2 * maxLik + ln(n) * rows(params)
	model.CAIC	= -2 * maxLik + (1 + ln(n)) * rows(params)
	model.AICc	= model.AIC + 2 * rows(params) * (rows(params) + 1) / (n - rows(params) - 1)
	model.HQIC	= -2 * maxLik + 2*rows(params)*ln(ln(n))
	model.logLik0 	= sum(log(q :* mean(q)))
	model.R2 	= 1 - maxLik /  model.logLik0
	
	model.df = rows(params)
	model.df_null = cols(q) - 1
	model.chi2 = 2 * (maxLik - model.logLik0)
	model.chi2_pvalue = 1 - chi2(model.df - model.df_null, model.chi2)
	
	model.brier_score = matrix_mse(prob_obs - q)
	model.ranked_probability_score = matrix_mse(running_rowsum(prob_obs) - running_rowsum(q))
	
	values = runningsum(J(1, cols(q), 1))
	prediction = rowsum((prob_obs:==rowmax(prob_obs)) :* values)
	actual = rowsum((q:==rowmax(q)) :* values)
	model.accuracy = mean(prediction :== actual)
	
	model.V	= covMat
	model.V_rob	= covMat_rob
	model.logLik	= maxLik
	model.opt_method = maxMethod
	model.probabilities = prob_obs
	model.ll_obs = log(rowsum(prob_obs :* q))
	
	return(model)
}

class SWOPITModel scalar estimateswopitc(y, x1, x2, z,|guesses,s_change,param_limit, atVarlist, startvalues, maxiter, ptol, vtol, nrtol, nolog){

	starttime = clock(c("current_time"),"hms")
	n	= rows(x1) // = rows(x2)
	//kx	= cols(x)
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz	= cols(z)
	allcat = uniqrows(y)
	ncat = rows(allcat)
	
	if (param_limit == 0){
	    set_limit=0
		// if starting values are provided but one doesnt want a limit
	} else {
	    set_limit=1
		// if one wants a limit and a limit is provided
	}
	
	atVarlist_swopit = ""
	// set limit for params individually
	parlen = (kx1+ ncat -1 + kx2 + ncat - 1 + kz + 1 + 2) // seems redundant, now it doesn't haha ty
	atTokens = tokens(atVarlist, " ") // create the tokens for the varlist
	atV_swopit_length = parlen - 2

	// check if all parameters have a value
	// First check if only one value is specified
	if (length(atTokens) == 1) {
	    if (nolog != 0){
		stata(`"noisily display as text "The limit is set the same for all parameters""')
	    }
	    param_lim = J(1, parlen, 0) // init vector for param limit
		atVarlist_swopit = J(1, atV_swopit_length, "hi") // init vector for normal swopit varlist
		j = 1
		low = 0 // indicator if one of the parameter limits is set very low
	    for (i = 1; i <= length(atTokens); i++) {
		    if (j < parlen - 1) {
				    atVarlist_swopit[i] = atTokens[1]
			}
			val = strtoreal(atTokens[1])
			if (val < 1) {
				low = 1
			}
			param_lim[j] = val
			j++
		}
		if (low == 1) {
			stata(`"noisily display as err "The limit on all of the parameters is set very low.""')
			stata(`"noisily display as err "If it does not converge, please try running with different limits.""')
		}
		set_limit = 1
		atVarlist_swopit = invtokens(atVarlist_swopit)

	} else if (parlen == length(atTokens)) {
	    param_lim = J(1, parlen, 0) // init vector for param limit
		atVarlist_swopit = J(1, atV_swopit_length, "hi") // init vector for normal swopit varlist
		j = 1
		low = 0 // indicator if one of the parameter limits is set very low
	    for (i = 1; i <= length(atTokens); i++) {
		    if (j < parlen - 1) {
				length(atVarlist_swopit)
				atVarlist_swopit[i] = atTokens[i]
			}
			val = strtoreal(atTokens[i])
			if (val < 1) {
				low = 1
			}
			param_lim[j] = val
			j++
		}
		if (low == 1) {
			stata(`"noisily display as err "The limit on one or more of the parameters is set very low.""')
			stata(`"noisily display as err "If it does not converge, please try running with different limits.""')
		}
		set_limit = 1
		atVarlist_swopit = invtokens(atVarlist_swopit)
		
	} else if (length(atTokens) == 0) {
	    // do nothing
	} else {
	    stata(`"noisily display as err "Incorrect number of parameters specified in lim().""')
 		stata(`"noisily display as err "' + strofreal(parlen) + `" " expected, received " "' + strofreal(length(atTokens)) )
		stata(`"noisily display as err "Limit on parameters will not be invoked.""')
 		stata(`"noisily display as err "Please rerun the command and specify the parameters correctly.""')
	}

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}

	startoriginal = startvalues

	if (cols(startoriginal) != parlen && startoriginal != . && cols(startoriginal) > 0) {
		stata(`"noisiliy display as err "Vector of initial values must have length ""' + strofreal(parlen))
		stata(`"noisiliy display as err "Please make corrections and re-enter correct initial values or leave them empty""')
		exit(1)
	}
	

	tot_converged = 0

	for (j = 1; j <= guesses; j++){

		if (startoriginal == .){
			if (j == 1){
				//random starting regimes
				r = runiform(n,1)
				r = (r:>=0.5)
				r1 = r
				r2 = 1 :- r
				q0 = (r, 1:-r) // regime matrix 

				if (nolog != 0) {
					stata(`"noisily display as text "Finding regime starting values""')
				}
				
				paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

				// Outcome pars distributed for regime 1 and 2
				x1obs = select(x1,r1)
				x2obs = select(x2,r2)
				q1 = select(q,r1)
				q2 = select(q,r2)

				if (nolog != 0) {
					stata(`"noisily display as text "Finding outcome starting values""')
				}
				x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
				x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
				initialswopitvalues = paramsz\x1pars\x2pars

				class SWOPITModel scalar initial_model 
				
				if (nolog != 0) {
					stata(`"noisily display as text "EXOGENOUS switching to find starting values""')
				}
				
				initial_model = estimateswopit(y,x1,x2,z,guesses, s_change, param_limit, atVarlist_swopit, initialswopitvalues', maxiter, ptol, vtol, nrtol, nolog)
				
				if (nolog != 0) {
					stata(`"noisily display as text "Starting ENDOGENOUS switching estimations""')
				}
				
				startparams = initial_model.params
				swopit_likelihood = initial_model.logLik
			
				X = -9::9
				Y = -9::9
				corrvalues = X#J(rows(Y), 1, 1), J(rows(X), 1, 1)#Y
				corrvalues = corrvalues'/10

				bestrho = 0\0
				initialtest = startparams\bestrho
				best_likelihood = mlswoptwoc(initialtest,x1,x2,z,1,ncat)
				
				for (l = 1; l <= cols(corrvalues); l++){
					paramstemp = startparams\corrvalues[,l]
					liketemp = mlswoptwoc(paramstemp,x1,x2,z,1,ncat)
					if (liketemp > best_likelihood){
						best_likelihood = liketemp
						bestrho = corrvalues[,l]
					}
				}
				startparam = startparams\bestrho
				startvalues = startparam
			}
			else{
				//random starting regimes
				r = runiform(n,1)
				r = (r:>=0.5)
				r1 = r
				r2 = 1 :- r
				q0 = (r, 1:-r) // regime matrix 

				if (nolog != 0) {
					stata(`"noisily display as text "Finding regime starting values""')
				}
				
				paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

				// Outcome pars distributed for regime 1 and 2
				x1obs = select(x1,r1)
				x2obs = select(x2,r2)
				q1 = select(q,r1)
				q2 = select(q,r2)

				if (nolog != 0) {
					stata(`"noisily display as text "Finding outcome starting values""')
				}

				x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
				x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting

				bestrho = 0\0
			
				startparams = paramsz\x1pars\x2pars
				initialtest = startparams\bestrho

				best_likelihood = mlswoptwoc(initialtest,x1,x2,z,1,ncat)
				
				for (l = 1; l <= cols(corrvalues); l++){
					paramstemp = startparams\corrvalues[,l]
					liketemp = mlswoptwoc(paramstemp,x1,x2,z,1,ncat)
					if (liketemp > best_likelihood){
						best_likelihood = liketemp
						bestrho = corrvalues[,l]
					}
				}
				startparam = startparams\bestrho
				startvalues = startparam
			}

		} else{
			//In order to stop after first converged when initial is specified
			//if (tot_converged == 1){
			//	break
			//}
			if (j == 1){
				startparam = startvalues'

				_swopitc_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)

				if (sort(a1,1) != a1){
					stata(`"noisiliy display as err "Initial thresholds of regime 1 are not in order.""')
					stata(`"noisiliy display as err "Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest.""')
					exit(1)
				}
				if (sort(a2,1) != a2){
					stata(`"noisiliy display as err "Initial thresholds of regime 2 are not in order.""')
					stata(`"noisiliy display as err "Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest.""')
					exit(1)
				}
			}
			else{
				startparam = startvalues'
				for (k = 1; k <= cols(startvalues)-2; k++){
					startparam[k] = startparam[k] + s_change*runiform(1,1, -abs(startparam[k]), abs(startparam[k]))
				}
	
				X = -9::9
				Y = -9::9
				corrvalues = X#J(rows(Y), 1, 1), J(rows(X), 1, 1)#Y
				corrvalues = corrvalues'/10

				startparams = startparam[1::(cols(startvalues)-2)]
				bestrho = 0\0
				initialtest = startparams\bestrho
				best_likelihood = mlswoptwoc(initialtest,x1,x2,z,1,ncat)
		
				for (l = 1; l <= cols(corrvalues); l++){
					paramstemp = startparams\corrvalues[,l]
					liketemp = mlswoptwoc(paramstemp,x1,x2,z,1,ncat)
					if (liketemp > best_likelihood){
						best_likelihood = liketemp
						bestrho = corrvalues[,l]
					}
				}
				startparam = startparams\bestrho
			}
		}

		_swopitc_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)
		a1 = sort(a1,1)
		a2 = sort(a2,1)

		coded_param = g\codeIncreasingSequence(mu)\b1\codeIncreasingSequence(a1)\b2\codeIncreasingSequence(a2)\logit((rho1+1)/2)\logit((rho2+1)/2) //with a1,a2,b1,b2	

		//replace by zeros if one of the variables is empty
		if (max(coded_param :==.)  > 0){
			coded_param = J(rows(coded_param), cols(coded_param), 0)

		}
	
		initial_coded_param = coded_param
		// different optim methods
		for (i = 1; i <= 4; i++){	
			if (i == 1) {
				initial_coded_param = coded_param
				opt_method = "nr"
				if (nolog != 0) {
					stata(`"noisily display as text "Attempt #""' + strofreal(j) + `" " with method: nr" "')
				}
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: bhhh""')
				}
			}
			if (i == 3) {
				initial_coded_param = coded_param
				opt_method = "dfp"
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: dfp""')
				}
			}
			if (i == 4) {
				initial_coded_param = coded_param
				opt_method = "bfgs"
				if (nolog != 0) {
					stata(`"noisily display as text "Trying again with different method: bfgs""')
				}
			}
	



			singularHmethod= "hybrid"
		
			S = optimize_init()

			optimize_init_verbose(S, 0)
			optimize_init_tracelevel(S , "none")

			optimize_init_argument(S, 1, x1) // outcome matrix 1
			optimize_init_argument(S, 2, x2) // outcome matrix 2
			optimize_init_argument(S, 3, z) // regime matrix
			optimize_init_argument(S, 4, q) // y dummies
			optimize_init_argument(S, 5, ncat)

			optimize_init_argument(S, 6, 1) // coded
			optimize_init_evaluator(S, &_swoptwoc_optim())
			optimize_init_evaluatortype(S, "gf0") //gf1: making own derivative
			optimize_init_conv_maxiter(S, maxiter)
			optimize_init_params(S, initial_coded_param')
			optimize_init_conv_ptol(S, ptol)
			optimize_init_conv_vtol(S, vtol)
			optimize_init_conv_nrtol(S, nrtol)
			optimize_init_singularHmethod(S, singularHmethod)
			optimize_init_conv_warning(S, "off") 
			optimize_init_technique(S, opt_method)
			errorcode 	= _optimize(S)
			convg		= optimize_result_converged(S)
			retCode		= optimize_result_errortext(S)
			params 		= optimize_result_params(S)'
			iterations 	= optimize_result_iterations(S)
			
			if (convg==1){
			    if (set_limit==0){
					if (nolog != 0) {
						stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
					}
				    break
				} else if (set_limit==1 && length(param_lim) > 0){
				    limit = (abs(params)<=param_lim')
					if (limit == 1){
						//"convergence"
						break
					} else if (limit == 0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters""')
						}
					}
				} else {
				    param_lim = J(rows(params),cols(params),param_limit)
					limit = (abs(params)<=param_lim)
					if (limit == 1){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" iterations)"')
						}
						break
					} else if (limit == 0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with absurd parameters""')
						}
					}
				}				
			}
			else {
				if (nolog != 0) {
					stata(`"noisily display as text "no convergence""')
				}
			}
		}

		if (convg==1){
			if (set_limit==0){
				if (tot_converged==0){
					if (startoriginal == .){
						if (optimize_result_value(S) > swopit_likelihood){
							if (nolog != 0) {
								stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
							}
							best_lik = optimize_result_value(S)
							best_opt = opt_method
							tot_converged = 1
							best_retCode		= optimize_result_errortext(S)
							best_params 		= optimize_result_params(S)'
							best_iterations 	= optimize_result_iterations(S)
						} else{
							if (nolog != 0) {
								stata(`"noisily display as text "convergence but likelihood is worse than original Swopit: local maxima""')
							}
						}
					}else{
						if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					}

				} else if (optimize_result_value(S) > best_lik){
					best_lik = optimize_result_value(S)
					best_opt = opt_method
					tot_converged = 1
					if (nolog != 0) {
						stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
					}
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else{
					if (nolog != 0) {
						stata(`"noisily display as text "convergence without likelihood improvement""')
					}
				}
			} else if (set_limit==1 && length(param_lim) > 0){
				limit = (abs(params)<=param_lim')
				if (limit == 1){
					if (tot_converged==0){
						if (nolog != 0) {
							stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						if (nolog != 0) {
							stata(`"noisily display as text "convergence without likelihood improvement""')
						}
					}
					
				} else if (limit == 0){
					if (nolog != 0) {
						stata(`"noisily display as text "convergence with absurd parameters: disregarding estimation""')
					}
				}
			} else {
				param_lim = J(rows(params),cols(params),param_limit)
				limit = (abs(params)<=param_lim)
				if (limit == 1){
					if (tot_converged==0){
						if (startoriginal == .){
							if (optimize_result_value(S) > swopit_likelihood){
								if (nolog != 0) {
									stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
								}
								best_lik = optimize_result_value(S)
								best_opt = opt_method
								tot_converged = 1
								best_retCode		= optimize_result_errortext(S)
								best_params 		= optimize_result_params(S)'
								best_iterations 	= optimize_result_iterations(S)
							} else{
								if (nolog != 0) {
									stata(`"noisily display as text "convergence but likelihood is worse than original Swopit: local maxima""')
								}
							}
						}
						else{
							if (nolog != 0) {
								stata(`"noisily display as text "convergence (""' + strofreal(iterations) + `" " iterations)" "')
							}
							best_lik = optimize_result_value(S)
							best_opt = opt_method
							tot_converged = 1
							best_retCode		= optimize_result_errortext(S)
							best_params 		= optimize_result_params(S)'
							best_iterations 	= optimize_result_iterations(S)
						}
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						best_opt = opt_method
						tot_converged = 1
						if (nolog != 0) {
							stata(`"noisily display as text "convergence with likelihood improvement (""' + strofreal(iterations) + `" " iterations)" "')
						}
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						if (nolog != 0) {
							stata(`"noisily display as text "convergence without likelihood improvement""')
						}
					}
					
				} else if (limit == 0){
					if (nolog != 0) {
						stata(`"noisily display as text "convergence with absurd parameters: disregarding estimation""')
					}
				}
			}
		}else{
			if (nolog != 0 && j!=guesses) {
				stata(`"noisily display as text "no convergence, trying again with different starting values""')
			}
		}
	
	}

	if (tot_converged == 1){
		retCode		= best_retCode
		params 		= best_params
		iterations 	= best_iterations
	}
	
	_swopitc_params(params, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)
	params = g\decodeIncreasingSequence(mu)\b1\decodeIncreasingSequence(a1)\b2\decodeIncreasingSequence(a2)\invlogit(rho1)*2-1\invlogit(rho2)*2-1
	
	S2 = optimize_init()

	optimize_init_verbose(S, 0)
	optimize_init_tracelevel(S , "none")
	

	optimize_init_argument(S2, 1, x1)
	optimize_init_argument(S2, 2, x2)
	optimize_init_argument(S2, 3, z)
	optimize_init_argument(S2, 4, q)
	optimize_init_argument(S2, 5, ncat)
	optimize_init_argument(S2, 6, 0)
	//optimize_init_argument(S2, 7, 0) // flag that params are coded to avoid inequality constraints
	optimize_init_evaluator(S2, &_swoptwoc_optim())
	optimize_init_evaluatortype(S2, "gf0")
	optimize_init_conv_maxiter(S2, maxiter)
	//if (cols(who) > 0 && who != .) {
	//	optimize_init_cluster(S2, who) 
	//}
	
	optimize_init_conv_ptol(S2, ptol)
	optimize_init_conv_vtol(S2, vtol)
	optimize_init_conv_nrtol(S2, nrtol)
	optimize_init_singularHmethod(S2, "hybrid")
	optimize_init_conv_warning(S2, "off") // show that convergence not achieved
	optimize_init_technique(S2, "nr") 
	
	optimize_init_params(S2, params')
	errorcode2 = _optimize_evaluate(S2)
	if (tot_converged == 0) {
		// not successful, robust covariance matrix cannot be calculated
		maxLik	= optimize_result_value(S2)
		grad 	= optimize_result_gradient(S2)
		covMat	= optimize_result_V(S2)
		covMat_rob = covMat
	} else {
		//"TEST: MAXLIK IS"
		maxLik	= optimize_result_value(S2)
		//maxLik
		//"TEST: GRAD IS"
		grad 	= optimize_result_gradient(S2)
		//grad
		//"TEST: COVMAT IS"
		covMat	= optimize_result_V(S2)
		//covMat
		//"TEST: ROB IS"
		covMat_rob = optimize_result_V_robust(S2)
		//covMat_rob
	}
	
	if (best_opt == "nr") {
		maxMethod = "Newton Raphson"
	} else if (best_opt == "bhhh") {
		maxMethod = "BHHH"
	} else if (best_opt == "dfp") {
		maxMethod = "DFP"
	} else {
		maxMethod = "BFGS"
	}
	
	//calculate probabilities per observation
	prob_obs =  mlswoptwoc(params, x1 , x2, z, q, ncat, 1)
	//This will all be used to get all the information

	class SWOPITModel scalar model 
	model.model_class = "SWOPITC"
	model.n	= n
	model.k	= kx1 + kx2 + kz
	model.ncat	= ncat
	model.allcat = allcat
	model.classes = q
	model.retCode = retCode
	model.error_code = errorcode
	model.etime = clock(c("current_time"),"hms") - starttime
	model.converged = tot_converged
	model.iterations = iterations
	model.guesses = guesses

	model.params = params
	model.se		= sqrt(diagonal(covMat))
	model.t			= abs(params :/ model.se)
	model.se_rob	= sqrt(diagonal(covMat_rob))
	model.t_rob		= abs(params :/ model.se_rob)
	
	model.AIC	= -2 * maxLik + 2 * rows(params) 
	model.BIC	= -2 * maxLik + ln(n) * rows(params)
	model.CAIC	= -2 * maxLik + (1 + ln(n)) * rows(params)
	model.AICc	= model.AIC + 2 * rows(params) * (rows(params) + 1) / (n - rows(params) - 1)
	model.HQIC	= -2 * maxLik + 2*rows(params)*ln(ln(n))
	model.logLik0 	= sum(log(q :* mean(q)))
	model.R2 	= 1 - maxLik /  model.logLik0
	
	model.df = rows(params)
	model.df_null = cols(q) - 1
	model.chi2 = 2 * (maxLik - model.logLik0)
	model.chi2_pvalue = 1 - chi2(model.df - model.df_null, model.chi2)
	
	model.brier_score = matrix_mse(prob_obs - q)
	model.ranked_probability_score = matrix_mse(running_rowsum(prob_obs) - running_rowsum(q))
	
	values = runningsum(J(1, cols(q), 1))
	prediction = rowsum((prob_obs:==rowmax(prob_obs)) :* values)
	actual = rowsum((q:==rowmax(q)) :* values)
	model.accuracy = mean(prediction :== actual)
	
	model.V	= covMat
	model.V_rob	= covMat_rob
	model.logLik	= maxLik
	model.opt_method = maxMethod
	model.probabilities = prob_obs
	model.ll_obs = log(rowsum(prob_obs :* q))
	
	return(model)
}

class SWOPITModel scalar swopitmain(string scalar xynames, string scalar znames, string scalar x1names, string scalar x2names, touse, initial, guesses, change, string atVarlist, maxiter, ptol, vtol, nrtol, endogenous, boot, bootguesses, bootiter, nolog){

	col_names = xynames
	xytokens = tokens(col_names)

	yname = xytokens[1]
	xnames = invtokens(xytokens[,2::cols(xytokens)])
	
	xsplit = ustrsplit(xnames, " ")
	znames = znames
	zsplit = ustrsplit(znames, " ")
	x1names = x1names
	x1split = ustrsplit(x1names, " ")
	x2names = x2names
	x2split = ustrsplit(x2names, " ")
	
	outeq1 = outeq2 = regeq = J(1,cols(tokens(xnames)),0)
	for (i=1;i<=length(tokens(xnames));i++){
		if (anyof(tokens(x1names),tokens(xnames)[i])==1){
			outeq1[i]=1
		}
		if (anyof(tokens(x2names),tokens(xnames)[i])==1){
			outeq2[i]=1
		}
		if (anyof(tokens(znames),tokens(xnames)[i])==1){
			regeq[i]=1
		}
	}
	
	if (strlen(znames)==0){
		znames=xnames
	}
	if (strlen(x1names)==0){
		x1names=xnames
	}
	if (strlen(x2names)==0){
		x2names=xnames
	}
	
	// the snippet below alters the order of the variables if they're inputted in a different order in the regime and outcome equations
	tempz = J(1, cols(zsplit), "hi")
	tempx1 = J(1, cols(x1split), "hi")
	tempx2 = J(1, cols(x2split), "hi")
	k = l = m = 1
	for (i = 1; i <= length(xsplit); i++) {
	    for (j = 1; j <= length(zsplit); j++) {
		    if (xsplit[i] == zsplit[j]) {
			    tempz[k] = xsplit[i]
				k++
			}
		}
		
		for (j = 1; j <= length(x1split); j++) {
		    if (xsplit[i] == x1split[j]) {
			    tempx1[l] = xsplit[i]
				l++
			}
		}
		
		for (j = 1; j <= length(x2split); j++) {
		    if (xsplit[i] == x2split[j]) {
			    tempx2[m] = xsplit[i]
				m++
			}
		}
	}
	
	znames = invtokens(tempz, " ")
	x1names = invtokens(tempx1, " ")
	x2names = invtokens(tempx2, " ")

	st_view(z  = ., ., znames, touse)
	st_view(y  = ., ., yname, touse)
	st_view(x  = ., ., xnames, touse)
	st_view(x1 = ., ., x1names, touse)
	st_view(x2 = ., ., x2names, touse)

	n = length(y)

	if (initial != "") {
		initial = strtoreal(tokens(initial))'
		if (sum(initial :== .) > 0) {
			stata(`"noisiliy display as err "Incorrect initial values! Expected a numeric sequence delimited with whitespace.""')
			stata(`"noisiliy display as err "Default initial values will be used.""')
			initial = .
		}
	} else {
		initial = .
	}
	
	if (nolog) {
		nolog = 1
	} else {
		nolog = 0
	}
	guesses = strtoreal(guesses)
	change = strtoreal(change)
	maxiter = strtoreal(maxiter)
	nrtol = strtoreal(nrtol)
	ptol = strtoreal(ptol)
	vtol = strtoreal(vtol)
	boot = strtoreal(boot)
	bootguesses = strtoreal(bootguesses)
	bootiter = strtoreal(bootiter)
	//limit = strtoreal(limit)
	limit = 0

	nametest1 ="Outcome model (Class 1)"
	nametest2 ="Outcome model (Class 2)"
	
	initial = initial'
	
	class SWOPITModel scalar model
	if (endogenous){
		model = estimateswopitc(y, x1, x2, z, guesses, change, limit, atVarlist, initial, maxiter, ptol, vtol, nrtol, nolog)
		model.eqnames = J(1, cols(tokens(znames)) + 1, "Class membership model"), J(1, cols(tokens(x1names)) + rows(model.allcat) -1, nametest1 ), J(1, cols(tokens(x2names)) + rows(model.allcat) -1, nametest2), J(1,2,"Correlations")
		model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), "rho1", "rho2"
		switching_type = "Endogenous"

	}else{
		model = estimateswopit(y, x1, x2, z, guesses, change, limit, atVarlist, initial, maxiter, ptol, vtol, nrtol, nolog)
		model.eqnames = J(1, cols(tokens(znames)) + 1, "Class membership model"), J(1, cols(tokens(x1names)) + rows(model.allcat)-1, nametest1), J(1, cols(tokens(x2names)) + rows(model.allcat)-1, nametest2)
		model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1))
		switching_type = "Exogenous"
	}
	model.XZmedians = colmedian(x)
	model.XZnames = xnames
	model.outeq1 = outeq1
	model.outeq2 = outeq2
	model.regeq = regeq


	if (model.converged == 0){
		return(model)
		//exit(1)
	}


	model.model_bootstrap = "OIM"

	model.boot_params = model.params'

	if (boot != 0){
		model.model_bootstrap = "Bootstrap"
		if (nolog != 0) {
			stata(`"noisily display as text "Starting BOOTSTRAP estimations""')
		}
		ready = 0
		boot_initial = model.params'
		for (booti = 1; booti <= 10 * boot; booti++){
		    
			if (nolog != 0) {
				stata(`"noisily display as text "Bootstrap #""' + strofreal(booti))
			}
			
			boot_indices = runiformint(n, 1, 1, n);
			
			y_iter =  y[boot_indices,]
			x_iter =  x[boot_indices,]
			x1_iter = x1[boot_indices,]
			x2_iter = x2[boot_indices,]
			z_iter =  z[boot_indices,]

			class SWOPITModel scalar bootmodel
			if (endogenous){
				bootmodel = estimateswopitc(y_iter, x1_iter, x2_iter, z_iter, bootguesses, change, limit, atVarlist, boot_initial, bootiter, ptol, vtol, nrtol, nolog)

			}else{
				bootmodel = estimateswopit(y_iter, x1_iter, x2_iter, z_iter, bootguesses, change, limit, atVarlist , boot_initial, bootiter, ptol, vtol, nrtol, nolog)			
			}

			if (bootmodel.converged == 0){
				if (nolog != 0) {
					stata(`"noisily display as text "Resample once more""')
				}
				continue
			}
			
			if (ready == 0){
				allpa = bootmodel.params'
			} else{
				allpa = allpa \ bootmodel.params'
			}
			
			ready = ready + 1
			if (ready == boot){
				break
			}
		}
		bootstds = colsum((allpa:- colsum(allpa):/boot):^2)/(boot-1)
		model.boot_params = allpa
		model.V = diag(bootstds)

		if (ready < boot){
			stata(`"noisiliy display as err "Not enough samples with convergence within 10 * boot replications.""')
			stata(`"noisiliy display as err "Default initial values will be used.""')
			stata(`"noisiliy display as err "Only ""' + strofreal(ready) + `" " samples converged." "')
			stata(`"noisiliy display as err "Results will be shown based on all converged bootstrap estimations.""')		
		}
	}

	if(model.converged == 1){
		stata(`"noisily display as text "Printing converged estimation with highest likelihood:""')
	}

	model_suptype = "A mixture of ordered probit models with two latent classes"
	model_type = "A mixture of ordered probit models with two latent classes"

	//if (boot != 0){
	//	model_suptype = "Two-regime switching ordered probit regression with bootstrap"
	//	model_type = "Two-regime switching ordered probit regression with bootstrap"
	//}

	model.model_suptype = model_suptype
	model.switching_type = switching_type
	
	model.yname = yname
	model.x1names = x1names
	model.x2names = x2names
	model.znames = znames

	//pass everything to stata, maybe only these 2 needed?
	st_matrix("b", model.params')
	st_matrix("boot", model.boot_params)
	st_matrix("V", model.V)

	stripes = model.eqnames' , model.parnames'

	st_matrixcolstripe("b", stripes)
	st_matrixcolstripe("V", stripes)
	st_matrixrowstripe("V", stripes)
	st_local("depvar", model.yname)
	st_local("N", strofreal(model.n))
	st_local("switching", switching_type)
	st_local("opt", model.opt_method)
	st_numscalar("ll", model.logLik)
	st_numscalar("k", rows(model.params))
	st_matrix("ll_obs", model.ll_obs)
	st_numscalar("r2_p", model.R2)
	st_numscalar("k_cat", model.ncat)
	st_numscalar("df_m", model.df)
	st_numscalar("ll_0", model.logLik0)
	st_numscalar("chi2", model.chi2)
	st_numscalar("p", model.chi2_pvalue)
	st_numscalar("aic", model.AIC)
	st_numscalar("bic", model.BIC)

	return(model)

}

function printoutput(class SWOPITModel scalar model){

	displayas("txt")
	printf("\n%s\n\n", model.model_suptype)
	printf("Latent class switching = ")
	displayas("res")
	printf("%20s  \n", model.switching_type)
	displayas("txt")
 	printf("SE method              = ")
 	displayas("res")
 	printf("%20s\n", model.model_bootstrap)
	displayas("txt")
	printf("Optimization method    = ")
	displayas("res")
	printf("%20s\n", model.opt_method)
	displayas("txt")
	printf("Number of observations = ")
	displayas("res")
	printf("%20.0f \n", model.n)
	displayas("txt")
	printf("Log likelihood         = ")
	displayas("res")
	printf("%20.4f \n", model.logLik)
	displayas("txt")
	printf("McFadden pseudo R2     = ")
	displayas("res")
	printf("%20.4f \n", model.R2)
	displayas("txt")
	printf("LR chi2(")
	displayas("res")
	printf("%2.0f", model.df - model.df_null)
	displayas("txt")
	printf(")            = ")
	displayas("res")
	printf("%20.4f \n", model.chi2)
	displayas("txt")
	printf("Prob > chi2            = ")
	displayas("res")
	printf("%20.4f \n", model.chi2_pvalue)
	displayas("txt")
	printf("AIC                    = ")
	displayas("res")
	printf("%20.4f \n" , model.AIC)
	displayas("txt")
	printf("BIC                    = ")
	displayas("res")
	printf("%20.4f \n" , model.BIC)
}

function printerror(class SWOPITModel scalar model){

	tot_converged = model.converged
	errorcode = model.error_code
	convg = tot_converged
	guesses = model.guesses
	retCode  = model.retCode

	if (tot_converged != 1){
		displayas("err")
		printf("The command performed " + strofreal(guesses) + " random initializations and the estimation algorithm failed to converge.\n")
		printf("Perhaps, there are too few data for such a complex model.\nIf you set a limit on the parameters, you might want to loosen it.\n")
		printf("Try again, increase the number of random initializations in guesses(), increase the number of iterations in maxiter() or provide your starting values.\n")
		printf("Error code is " + strofreal(errorcode) + ": " + retCode + "\n")
		printf("Convergence status is " + strofreal(convg) + "\n")
		exit(1)
	}
	
		
}



function estimate_and_get_params_v2(dgp,covar, p, s, me, mese, pr, prse, conv, etime, eiter, y, x, z, infcat, getprobs, regeq, outeq1,outeq2,outeqtot,getME,xpop,|guesses,s_change,param_limit,startvalues,maxiter,ptol,vtol,nrtol,lambda) {
	
	if (maxiter==.){
		maxiter = 30
	} if (ptol==.){
		ptol = 1e-6
	} if (vtol==.){
		vtol = 1e-7
	} if (nrtol==.){
		nrtol = 1e-5
	} if (lambda==.){
		lambda = 1e-50 
	}
	
	class SWOPITModel scalar mod
	if (dgp == "SWOPIT") {
		if (covar == "TRUE"){
			xb1 = select(x, outeq1)
			xb2 = select(x, outeq2)
		}
		else{
			z = x
			xb1 = x
			xb2 = x
		}
		if (startvalues==.){
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit, ., maxiter, ptol, vtol, nrtol, nolog)
		} else{
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol, nolog)
		}
		kx1 = cols(xb1)
		kx2 = cols(xb2)
		kz = cols(z)
		ncat = rows(uniqrows(y))
		_swopit_params(mod.params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)
		if (g[1] <= 0){
			g = -g
			mu = -mu
			mod.params = g\mu\b2\a2\b1\a1
			_swopit_params(mod.se, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)
			mod.se = g\mu\b2\a2\b1\a1	
		}
	}
	else if (dgp == "SWOPITC") {
		if (covar == "TRUE"){
			xb1 = select(x, outeq1)
			xb2 = select(x, outeq2)
		}
		else{
			z = x
			xb1 = x
			xb2 = x
		}
		if (args() == 25){
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit, ., maxiter, ptol, vtol, nrtol, nolog)
		} else{
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol, nolog)
		}
		kx1 = cols(xb1)
		kx2 = cols(xb2)
		kz = cols(z)
		ncat = rows(uniqrows(y))
		_swopitc_params(mod.params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.,rho1=. , rho2=. )
		if (g[1] <= 0){
			g = -g
			mu = -mu
			rho1 = -rho1
			rho2 = -rho2
			mod.params = g\mu\b2\a2\b1\a1\rho2\rho1
			_swopitc_params(mod.se, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)
			mod.se = g\mu\b2\a2\b1\a1\rho2\rho1	
		}
	} else {
		"Don't know how to estimate model specified as " + dgp
	}
	probs = mod.probabilities
	p = mod.params'
	s = mod.se'
	mod.corresp = (1,1,0 \ 0,1,1 \ 1,0,1)
	
	if (mod.robust == 1) {
		V = mod.V_rob
	} else {
		V = mod.V
	}
	conv = mod.converged
	etime = mod.etime
	eiter = mod.iterations
	xzbar = xpop
	if (getprobs == "TRUE"){
		if (dgp == "SWOPIT"){
			pr_se = generalPredictWithSE(dgp, p, xzbar,ncat,outeq1,outeq2,regeq, V,1)
			pr_reg_se = generalPredictWithSE(dgp, p, xzbar,ncat,outeq1,outeq2,regeq, V,3)
			pr_se = pr_se,pr_reg_se	
		}
		if (dgp == "SWOPITC"){
			pr_se = generalPredictWithSE(dgp, p, xzbar,ncat,outeq1,outeq2,regeq, V,1)
			pr_reg_se = generalPredictWithSE(dgp, p, xzbar,ncat,outeq1,outeq2,regeq, V,3)
			pr_se = pr_se,pr_reg_se	
		}
	}
	else{
		pr_se = J(2,5,.)
	}
	
	
	if (getME == "TRUE"){
		if (dgp == "SWOPIT"){
			me_se = generalMEwithSE(dgp, p, xzbar, ncat, outeq1, outeq2, regeq, V,1)
		}
		if (dgp == "SWOPITC"){
			me_se = generalMEwithSE(dgp, p, xzbar, ncat, outeq1, outeq2, regeq, V,1)
		}
	}
	else{
		me_se = J(10,5,.)
	}

	/*
	if (conv == 1 && need_meprse == 1) {
		/* todo: decide whether we need the argument  (0,0,1) which has been the third */
		//me_se = generalMEwithSE((2,0,0), mod, 1)
		me_se = J(6,5,.)
		pr_se = generalPredictWithSE((2,0,0),mod, 1)
	} else {
		me_se = J(6,5,.)
		pr_se = J(2,5,.)
	}
	*/
	
	//pr_se = J(2,5,.)
	me = rowshape(me_se[(1,2,3,4,5),], 1)
	mese = rowshape(me_se[(6,7,8,9,10),], 1)
	pr = pr_se[1,]
	prse = pr_se[2,]
	
	
}

function SWOPITmargins(class SWOPITModel scalar model, string atVarlist, zeroes, regime) {
	xzbar = model.XZmedians
	atTokens = tokens(atVarlist, " =")
	if (length(model.XZnames) <= 1){
		model.XZnames = tokens(model.XZnames)
	}
	
	nvars = length(model.XZnames)
	
	if (length(atTokens) == 3 * nvars) {
		xz_from = update_named_vector(xzbar, model.XZnames, atTokens)
	} else if (length(atTokens) == 0) {
	    // do nothing
	} else {
	    displayas("err")
		printf("Incorrect number of variables specified in at().\n")
		printf("%f expected, received %f\n", nvars, length(atTokens) / 3)
		printf("Please rerun the swopitmargins command and fix your input.\n")
		printf("The marginal effects evaluated at their median value:\n")
	}
	
	loop = 1 // code of prediction type

	
	
	output_matrix("at", xzbar, " ", model.XZnames')

	rowstripes = model.XZnames'
	colstripes = "Pr(y=" :+ strofreal(model.allcat) :+ ")"
	

	if (zeroes) {
		loop = 2
		"not yet supported"
	} else if (regime) {
		loop = 2
		colstripes = ("Pr(s=0)" \ "Pr(s=1)")
	}

	if (model.robust == 1) {
		V = model.V_rob
	} else {
		V = model.V
	}
	
	mese = generalMEwithSE(model.model_class, model.params', xzbar,model.ncat, model.outeq1, model.outeq2, model.regeq, V, loop)
	kxz = cols(xzbar)
	me = mese[1::kxz,]
	se = mese[(1::kxz) :+ kxz,]

	if (model.model_bootstrap == "Bootstrap"){
 		boot_params = model.boot_params

 		total_boot = rows(boot_params)
 		for (i = 1; i <= total_boot; i++){
 			boot_params_iter = boot_params[i,]
 			generalME(boot_params_iter, model.model_class, xzbar, model.ncat, model.outeq1, model.outeq2, model.regeq, loop, seboot=.)

 			if(i == 1){
 				se_all = seboot

 			}else{
 				se_all = se_all \ seboot

 			}
 		}

 	
 		se = colsum((se_all:- colsum(se_all):/total_boot):^2)/(total_boot-1) 
 		se = rowshape(se, length(xzbar))
		se = se:^0.5

 	}
	
	output_mesetp(me, se, rowstripes, colstripes)
	
	// now the printing part! 
	displayas("txt")
	printf("\nEvaluated at:\n")
	print_matrix(xzbar, ., model.XZnames)
	if (zeroes) {
		displayas("txt")
		printf("\nMarginal effects of all variables on the probabilities of different types of zeros\n")
	} 
	else if (regime) {
		displayas("txt")
		printf("\nMarginal effects of all variables on the probabilities of different latent regimes\n")
	}
	else {
		displayas("txt")
		printf("\nMarginal effects of all variables on the probabilities of different outcomes\n")
	}
	print_matrix(me, rowstripes, colstripes)

	if(model.model_bootstrap == "Bootstrap"){
		displayas("txt")
		printf("\nBootstrap standard errors of marginal effects\n")
	}
	else{
		displayas("txt")
		printf("\nDelta-method standard errors of marginal effects\n")
	}

	print_matrix(se, rowstripes, colstripes)
}

function SWOPITprobabilities(class SWOPITModel scalar model, string atVarlist, zeroes, regime) {
	xz_from = model.XZmedians
	atTokens = tokens(atVarlist, " =")
	
	if (length(model.XZnames) <= 1){
		model.XZnames = tokens(model.XZnames)
	}
	
	nvars = length(model.XZnames)
	
	if (length(atTokens) == 3 * nvars) {
		xz_from = update_named_vector(xz_from, model.XZnames, atTokens)
	} else if (length(atTokens) == 0) {
	    // do nothing
	} else {
	    displayas("err")
		printf("Incorrect number of variables specified in at().\n")
		printf("%f expected, received %f\n", nvars, length(atTokens) / 3)
		printf("Please rerun the swopitprobabilities command and fix your input.\n")
		printf("The probabilities evaluated at their median value:\n")
	}
	
	loop = 1 // code of prediction type
	if (zeroes) {
		loop = 2
	} else if (regime) {
		loop = 3
	}
	
	

	output_matrix("at", xz_from, " ", model.XZnames')


	colstripes = "Pr(y=" :+ strofreal(model.allcat) :+ ")"
	

	if (zeroes) {
		loop = 2
		"not yet supported"
	} else if (regime) {
		loop = 3
		colstripes = ("Pr(s=0)" \ "Pr(s=1)")
	}
	
	if (model.robust == 1) {
		V = model.V_rob
	} else {
		V = model.V
	}
	
	rowstripes = " " // rowstripes made invisible
	mese = generalPredictWithSE(model.model_class,model.params', xz_from, model.ncat, model.outeq1,model.outeq2,model.regeq,V, loop)
	me = mese[1,]
	se = mese[2,]

	if(model.model_bootstrap == "Bootstrap"){
 		
 		boot_params = model.boot_params

 		xb1 = select(xz_from,model.outeq1)
 		xb2 = select(xz_from,model.outeq2)
 		z = select(xz_from,model.regeq)
 		dgp = model.model_class
 		ncat = model.ncat

 		total_boot = rows(boot_params)
 		for (i = 1; i <= total_boot; i++){
 			boot_params_iter = boot_params[i,]
 			generalPredictWrapper(boot_params_iter, xb1, xb2, z,dgp,ncat, loop, probsboot =.)

 			if(i == 1){
 				prediction_all = probsboot

 			}else{
 				prediction_all = prediction_all \ probsboot

 			}
 		}
 	
 		se = colsum((prediction_all:- colsum(prediction_all):/total_boot):^2)/(total_boot-1) 
		se = se:^0.5

 	}


	output_mesetp(me, se, rowstripes, colstripes)
	
	// now the printing part! 
	displayas("txt")
	printf("\nEvaluated at:\n")
	print_matrix(xz_from, ., model.XZnames)
	if (zeroes) {
		displayas("txt")
		printf("\nPredicted probabilities of different types of zeros\n")
	} 
	else if (regime) {
		displayas("txt")
		printf("\nPredicted probabilities of different latent regimes\n")
	}
	else {
		displayas("txt")
		printf("\nPredicted probabilities of different outcomes\n")
	}
	print_matrix(me, ., colstripes)

	if(model.model_bootstrap == "Bootstrap"){
		displayas("txt")
		printf("\nBootstrap standard errors of probabilities\n")
	}
	else{
		displayas("txt")
		printf("\nDelta-method standard errors of probabilities\n")
	}

	print_matrix(se, ., colstripes)
}

function SWOPITclassification(class SWOPITModel scalar model){
    
	allcat = model.allcat
	classes = model.classes
	ncat = model.ncat
	prob_obs = model.probabilities
	temp_cat = 0::(ncat-1)
	predictions = (prob_obs:==rowmax(prob_obs))
	prediction = rowsum(predictions:*temp_cat')
	classes = rowsum(classes:*temp_cat')
	conf_mat = J(ncat,ncat,0)
	for (i=1;i<=rows(classes);i++){
		j = prediction[i]+1
		k = classes[i]+1
		conf_mat[j,k]=conf_mat[j,k]+1
	}
	colstripes = "y=" :+ strofreal(model.allcat) 
	rowstripes = "y=" :+ strofreal(model.allcat) 
	rowtitle = "True"
	coltitle = "Predicted"

	tot = sum(conf_mat)
	all_pos = colsum(conf_mat)'
	all_neg = tot :- all_pos
	pre_pos = rowsum(conf_mat)
	pre_neg = tot :- pre_pos
	
	true_pos = diagonal(conf_mat)
	fals_pos = pre_pos - true_pos
	fals_neg = all_pos - true_pos
	true_neg = pre_neg - fals_neg
	
	noise = fals_pos :/ all_neg
	recall = true_pos :/ all_pos
	precision = true_pos :/ pre_pos
	n2s = noise :/ recall
	
	result = precision, recall, n2s
	colname = "Precision" \  "Recall" \  "Adj. noise-to-signal"
	rowname = "y=" :+ strofreal(model.allcat) 
	print_matrix(result, rowname, colname,., ., ., 4, ., .)
	displayas("txt")
	printf("\n")
	printf("Accuracy                 = %9.4f \n", model.accuracy)
	printf("Brier score              = %9.4f \n", model.brier_score)
	printf("Ranked probability score = %9.4f \n", model.ranked_probability_score)
	printf("\nConfusion Matrix\n")
	print_matrix(conf_mat, rowstripes, colstripes,., ., ., 0, rowtitle, coltitle)
}

function SWOPITpredict(class SWOPITModel scalar model, string scalar newVarName, real scalar regime, scalar output, tabstat){
    var_ind = 0
	if (strlen(newVarName) == 0 && !regime) {
	    var_ind = 1
		newVarName = "swopit_pr"
	} else if (strlen(newVarName) == 0 && regime) {
	    var_ind = 1
	    newVarName = "swopit_r"
	}
// this used to be the code, left here if we need to still change it
// 	else {
// 		sp = strpos(newVarName, ",")
// 		if (sp != 0){
// 			newVarName = substr(newVarName, 1, sp - 1)
// 		}
// 	}
	loop = 1 // code of prediction type
	if (regime) {
		loop = 3
	}
	label_indices = strofreal(1..model.ncat)
	labels = strofreal(model.allcat')
	values = model.allcat'

	st_view(x1  = ., ., model.x1names)
	st_view(x2  = ., ., model.x2names)
	st_view(z  = ., ., model.znames)
	
	if (model.model_class == "SWOPIT") {
		p 	= mlswoptwo(model.params, x1 , x2, z, q=., model.ncat, loop)
	} else if (model.model_class == "SWOPITC") {
		p 	= mlswoptwoc(model.params, x1 , x2, z, q=., model.ncat, loop)
	}
	if (loop == 2) {
		"Not applicable for this type of estimation."
	}
	if (loop == 3) {
		label_indices = ("0", "1")
		labels = ("first", "second") :+ " regime"
		values = (0, 1)
	}
	
	
	label_indices = newVarName + "_" :+ label_indices
	if (output == "mode" | output == "choice") {
		if (_st_varindex(newVarName) :== .) {
			tmp = st_addvar("double", newVarName)
		}
		st_view(v = ., ., newVarName)
		prediction = rowsum((p:==rowmax(p)) :* values)
		v[,] = prediction
		st_vlmodify(newVarName, values', labels')
	} else if (output == "mean") {
		if (_st_varindex(newVarName) :== .) {
			tmp = st_addvar("double", newVarName)
		}
		st_view(v = ., ., newVarName)
		prediction = rowsum(p :* values)
		v[,] = prediction
		st_vlmodify(newVarName, values', labels')
	} else if (output == "cum"){
		tmp = st_addvar("double", label_indices[selectindex(_st_varindex(label_indices) :== .)])
		st_view(v = ., ., label_indices)
		for (i = 1; i <= length(labels); ++i) {
			st_varlabel(label_indices[i], labels[i])
		}
		v[,1] = p[,1]
		for (i = 2; i <= cols(p); ++i) {
			v[,i] = v[,i-1] + p[,i]
		}
	} else {
		tmp = st_addvar("double", label_indices[selectindex(_st_varindex(label_indices) :== .)])
		st_view(v = ., ., label_indices)
		for (i = 1; i <= length(labels); ++i) {
			st_varlabel(label_indices[i], labels[i])
		}
		v[,] = p
	}
	
	if (tabstat) {
	    if (var_ind == 0) {
			stata("tabstat " + newVarName + "*, stats(co me sd v ma mi) columns(statistics) format(%9.4g)")
		} else if (var_ind == 1) {
		    stata("tabstat swopit_*, stats(co me sd v ma mi) columns(statistics) format(%9.4g)")
		}
	}


}

end




















