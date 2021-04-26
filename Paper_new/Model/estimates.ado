version 14
mata
class SWOPITModel scalar estimateswopit(y, x1, x2, z,|guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol){

	if (param_limit == 0){
	    set_limit=0
		// if starting values are provided but one doesnt want a limit
	} else {
	    set_limit=1
		// if one wants a limit and a limit is provided
	}
	
	starttime = clock(c("current_time"),"hms")
	n	= rows(x1) // = rows(x2)
	//kx	= cols(x)
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz	= cols(z)
	allcat = uniqrows(y)
	ncat = rows(allcat)
	
	parlen = (kx1 + ncat - 1 + kx2 + ncat - 1 + kz + 1) // seems redundant

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}

	startoriginal = startvalues

	if (cols(startoriginal) != parlen && startoriginal != . && cols(startoriginal) > 0) {
		"Vector of initial values must have length "+ strofreal(parlen)
		"Please make corrections and re-enter correct initial values or leave them empty"
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

			//"Finding regime starting values"
			paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

			// Outcome pars distributed for regime 1 and 2
			x1obs = select(x1,r1)
			x2obs = select(x2,r2)
			q1 = select(q,r1)
			q2 = select(q,r2)

			//"Finding outcome starting values"	
			x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
			x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
			startparam = paramsz\x1pars\x2pars
			startvalues = startparam
		} else{
			if (tot_converged == 1){
				break
			}
			if (j == 1){
				startparam = startvalues'
				_swopit_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)

				if (sort(a1,1) != a1){
					"Initial thresholds of regime 1 are not in order"
					"Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest"
					exit(1)
				}
				if (sort(a2,1) != a2){
					"Initial thresholds of regime 2 are not in order"
					"Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest"
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
			"Attempt number " + strofreal(j) + " with method: nr"
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				"Trying again with different method: bhhh"
			}
			if (i == 3) {
				initial_coded_param = coded_param
				opt_method = "dfp"
				"Trying again with different method: dfp"
			}
			if (i == 4) {
				initial_coded_param = coded_param
				opt_method = "bfgs"
				"Trying again with different method: bfgs"
			}


			singularHmethod= "hybrid"
		
			S = optimize_init()

			optimize_init_tracelevel(S , "none")
			optimize_init_verbose(S, 0)	

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
			errorcode 	= _optimize(S)
			convg		= optimize_result_converged(S)
			retCode		= optimize_result_errortext(S)
			params 		= optimize_result_params(S)'
			iterations 	= optimize_result_iterations(S)
			
			if (convg==1){
				if (set_limit==0){
				    	//"convergence"
				    	break
				
				} else if (set_limit==1){
				    param_lim = J(rows(params),cols(params),param_limit)
					limit = (abs(params)<=param_lim)
					if (limit == 1){
						//"convergence"
						break
					} else if (limit == 0){
						"convergence with absurd parameters"
					}
				}				
				
			}else{
				"no convergence"
			}
		}
		if (convg==1){
			if (set_limit==0){
				if (tot_converged==0){
					"convergence"
					best_lik = optimize_result_value(S)
					tot_converged = 1
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else if (optimize_result_value(S) > best_lik){
					best_lik = optimize_result_value(S)
					tot_converged = 1
					"convergence with likelihood improvement"
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else{
					"convergence without likelihood improvement"

				}
			} else if (set_limit==1){
				param_lim = J(rows(params),cols(params),param_limit)
				limit = (abs(params)<=param_lim)
				if (limit == 1){
					if (tot_converged==0){
						"convergence"
						best_lik = optimize_result_value(S)
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						tot_converged = 1
						"convergence with likelihood improvement"
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						"convergence without likelihood improvement"
					}
					
				} else if (limit == 0){
					"convergence with absurd parameters: disregarding estimation"
				}
			}
		}else{
			"no convergence, trying again with different starting values"
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

	optimize_init_tracelevel(S , "none")
	optimize_init_verbose(S, 0)

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
	model.probabilities = prob_obs
	model.ll_obs = log(rowsum(prob_obs :* q))

	if (tot_converged != 1){
		"The command performed " + strofreal(guesses) + " random initializations and the estimation algorithm failed to converge."
		"Perhaps, there are too few data for such a complex model."
		"Try again, increase the number of random initializations in guesses() or provide your starting values."
		"Error code is " + strofreal(errorcode) + ": " + retCode
		"Convergence status is " + strofreal(convg)
	
	}
	
	return(model)
}

class SWOPITModel scalar estimateswopitc(y, x1, x2, z,|guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol){

	if (param_limit == 0){
	    set_limit=0
		// if starting values are provided but one doesnt want a limit
	} else {
	    set_limit=1
		// if one wants a limit and a limit is provided
	}
	
	starttime = clock(c("current_time"),"hms")
	n	= rows(x1) // = rows(x2)
	//kx	= cols(x)
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz	= cols(z)
	allcat = uniqrows(y)
	ncat = rows(allcat)
	
	parlen = (kx1+ ncat -1 + kx2 + ncat - 1 + kz + 1 + 2)

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}

	startoriginal = startvalues

	if (cols(startoriginal) != parlen && startoriginal != . && cols(startoriginal) > 0) {
		"Vector of initial values must have length "+ strofreal(parlen)
		"Please make corrections and re-enter correct initial values or leave them empty"
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

				//"Finding regime starting values"
				paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

				// Outcome pars distributed for regime 1 and 2
				x1obs = select(x1,r1)
				x2obs = select(x2,r2)
				q1 = select(q,r1)
				q2 = select(q,r2)

				//"Finding outcome starting values"	
				x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
				x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
				initialswopitvalues = paramsz\x1pars\x2pars

				class SWOPITModel scalar initial_model 

				"EXOGENOUS switching to find starting values"
				initial_model = estimateswopit(y,x1,x2,z,guesses, s_change, param_limit, initialswopitvalues', maxiter, ptol, vtol, nrtol)
				"Starting ENDOGENOUS switching estimations"

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

				//"Finding regime starting values"
				paramsz = coeffOP(z, q0, 2, maxiter, ptol,vtol,nrtol)

				// Outcome pars distributed for regime 1 and 2
				x1obs = select(x1,r1)
				x2obs = select(x2,r2)
				q1 = select(q,r1)
				q2 = select(q,r2)

				//"Finding outcome starting values"	
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
			if (tot_converged == 1){
				break
			}
			if (j == 1){
				startparam = startvalues'

				_swopitc_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)

				if (sort(a1,1) != a1){
					"Initial thresholds of regime 1 are not in order"
					"Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest"
					exit(1)
				}
				if (sort(a2,1) != a2){
					"Initial thresholds of regime 2 are not in order"
					"Please make corrections and re-enter the thresholds in the correct ordering, from the smallest to the largest"
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
				"Attempt number " + strofreal(j) + " with method: nr"
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				"Trying again with different method: bhhh"
			}
			if (i == 3) {
				initial_coded_param = coded_param
				opt_method = "dfp"
				"Trying again with different method: dfp"
			}
			if (i == 4) {
				initial_coded_param = coded_param
				opt_method = "bfgs"
				"Trying again with different method: bfgs"
			}
	



			singularHmethod= "hybrid"
		
			S = optimize_init()

			optimize_init_tracelevel(S , "none")
			optimize_init_verbose(S, 0)	

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
				    //"convergence"
				    break
				} else if (set_limit==1){
				    param_lim = J(rows(params),cols(params),param_limit)
					limit = (abs(params)<=param_lim)
					if (limit == 1){
						//"convergence"
						break
					} else if (limit == 0){
						"convergence with absurd parameters"
					}
				}				
				
			}else{
				"no convergence"
			}
		}

		if (convg==1){
			if (set_limit==0){
				if (tot_converged==0){
					if (startoriginal == .){
						if (optimize_result_value(S) > swopit_likelihood){
							"convergence"
							best_lik = optimize_result_value(S)
							tot_converged = 1
							best_retCode		= optimize_result_errortext(S)
							best_params 		= optimize_result_params(S)'
							best_iterations 	= optimize_result_iterations(S)
						} else{
							"convergence but likelihood is worse than original Swopit: local maxima"
						}
					}else{
						"convergence"
						best_lik = optimize_result_value(S)
						tot_converged = 1
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					}

				} else if (optimize_result_value(S) > best_lik){
					best_lik = optimize_result_value(S)
					tot_converged = 1
					"convergence with likelihood improvement"
					best_retCode		= optimize_result_errortext(S)
					best_params 		= optimize_result_params(S)'
					best_iterations 	= optimize_result_iterations(S)
				} else{
					"convergence without likelihood improvement"
				}
			} else if (set_limit==1){
				param_lim = J(rows(params),cols(params),param_limit)
				limit = (abs(params)<=param_lim)
				if (limit == 1){
					if (tot_converged==0){
						if (startoriginal == .){
							if (optimize_result_value(S) > swopit_likelihood){
								"convergence"
								best_lik = optimize_result_value(S)
								tot_converged = 1
								best_retCode		= optimize_result_errortext(S)
								best_params 		= optimize_result_params(S)'
								best_iterations 	= optimize_result_iterations(S)
							} else{
								"convergence but likelihood is worse than original Swopit: local maxima"
							}
						}
						else{
							"convergence"
							best_lik = optimize_result_value(S)
							tot_converged = 1
							best_retCode		= optimize_result_errortext(S)
							best_params 		= optimize_result_params(S)'
							best_iterations 	= optimize_result_iterations(S)
						}
					} else if (optimize_result_value(S) > best_lik){
						best_lik = optimize_result_value(S)
						tot_converged = 1
						"convergence with likelihood improvement"
						best_retCode		= optimize_result_errortext(S)
						best_params 		= optimize_result_params(S)'
						best_iterations 	= optimize_result_iterations(S)
					} else{
						"convergence without likelihood improvement"
					}
					
				} else if (limit == 0){
					"convergence with absurd parameters: disregarding estimation"
				}
			}
		}else{
			"no convergence, trying again with different starting values"
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

	optimize_init_tracelevel(S , "none")
	optimize_init_verbose(S, 0)

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
	model.probabilities = prob_obs
	model.ll_obs = log(rowsum(prob_obs :* q))

	if (tot_converged != 1){
		"The command performed " + strofreal(guesses) + " random initializations and the estimation algorithm failed to converge."
		"Perhaps, there are too few data for such a complex model."
		"Try again, increase the number of random initializations in guesses() or provide your starting values."
		"Error code is " + strofreal(errorcode) + ": " + retCode
		"Convergence status is " + strofreal(convg)
	
	}
	
	return(model)
}

class SWOPITModel scalar swopitmain(string scalar xynames, string scalar znames, string scalar x1names, string scalar x2names, touse, initial, guesses, change, limit, maxiter, ptol, vtol, nrtol, endogenous, boot, bootguesses){

	col_names = xynames
	xytokens = tokens(col_names)

	yname = xytokens[1]
	xnames = invtokens(xytokens[,2::cols(xytokens)])
	
	znames = znames
	x1names = x1names
	x2names = x2names

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

	st_view(z  = ., ., znames, touse)
	st_view(y  = ., ., yname, touse)
	st_view(x  = ., ., xnames, touse)
	st_view(x1 = ., ., x1names, touse)
	st_view(x2 = ., ., x2names, touse)

	n = length(y)

	if (initial != "") {
		initial = strtoreal(tokens(initial))'
		if (sum(initial :== .) > 0) {
			"Incorrect initial values! Expected a numeric sequence delimited with whitespace."
			"Default initial values will be used."
			initial = .
		}
	} else {
		initial = .
	}
	
	guesses = strtoreal(guesses)
	change = strtoreal(change)
	limit = strtoreal(limit)
	maxiter = strtoreal(maxiter)
	nrtol = strtoreal(nrtol)
	ptol = strtoreal(ptol)
	vtol = strtoreal(vtol)
	boot = strtoreal(boot)
	bootguesses = strtoreal(bootguesses)

	initial = initial'
	
	class SWOPITModel scalar model
	if (endogenous){
		model = estimateswopitc(y, x1, x2, z, guesses, change, limit, initial, maxiter, ptol, vtol, nrtol)
		model.eqnames = J(1, cols(tokens(znames)) + 1, "Regime equation"), J(1, cols(tokens(x1names)) + rows(model.allcat) -1, "Outcome equation 1"), J(1, cols(tokens(x2names)) + rows(model.allcat) -1, "Outcome equation 2"), J(1,2,"Correlations")
		model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), "rho1", "rho2"
		switching_type = "Endogenous"

	}else{
		model = estimateswopit(y, x1, x2, z, guesses, change, limit, initial, maxiter, ptol, vtol, nrtol)
		model.eqnames = J(1, cols(tokens(znames)) + 1, "Regime equation"), J(1, cols(tokens(x1names)) + rows(model.allcat)-1, "Outcome equation 1"), J(1, cols(tokens(x2names)) + rows(model.allcat)-1, "Outcome equation 2")
		model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1))
		switching_type = "Exogenous"
	}
	model.XZmedians = colmedian(x)
	model.XZnames = xnames
	model.outeq1 = outeq1
	model.outeq2 = outeq2
	model.regeq = regeq


	if (model.converged == 0){
		exit(1)
	}


	
	if (boot != 0){
		"Starting BOOTSTRAP estimations"
		ready = 0
		boot_initial = model.params'
		for (booti = 1; booti <= 10 * boot; booti++){
			boot_indices = runiformint(n, 1, 1, n);
			
			y_iter =  y[boot_indices,]
			x_iter =  x[boot_indices,]
			x1_iter = x1[boot_indices,]
			x2_iter = x2[boot_indices,]
			z_iter =  z[boot_indices,]

			class SWOPITModel scalar bootmodel
			if (endogenous){
				bootmodel = estimateswopitc(y_iter, x1_iter, x2_iter, z_iter, bootguesses, change, limit, boot_initial, maxiter, ptol, vtol, nrtol)

			}else{
				bootmodel = estimateswopit(y_iter, x1_iter, x2_iter, z_iter, bootguesses, change, limit, boot_initial, maxiter, ptol, vtol, nrtol)			
			}

			if (bootmodel.converged == 0){
				"Bad bootstrap data generated, resample once more"
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
		model.V = diag(bootstds)

		if (ready < boot){
			"Not enough samples with convergence within 10 * boot replications"
			"Only " + ready + " samples converged"
			"Perhaps increase the number of guesses to achieve more convergence"
			"Results will be shown based on all converged bootstrap estimations"
		}
	}

	if(model.converged == 1){
		"Printing converged estimation with highest likelihood:"
	}

	model_suptype = "Two-regime switching ordered probit regression"
	model_type = "Two-regime switching ordered probit regression"

	if (boot != 0){
		model_suptype = "Two-regime switching ordered probit regression with bootstrap"
		model_type = "Two-regime switching ordered probit regression with bootstrap"
	}

	printf("%s\n", model_suptype)
	printf("Regime switching:        %s  \n", switching_type)
	printf("Number of observations = %15.0f \n", model.n)
	printf("Log likelihood         = %15.4f \n", model.logLik)
	printf("McFadden pseudo R2     = %15.4f \n", model.R2)
	printf("LR chi2(%2.0f)            = %15.4f \n", model.df - model.df_null, 	model.chi2)
	printf("Prob > chi2            = %15.4f \n", model.chi2_pvalue)
	printf("AIC                    = %15.4f \n" , model.AIC)
	printf("BIC                    = %15.4f \n" , model.BIC)
	
	model.yname = yname
	model.x1names = x1names
	model.x2names = x2names
	model.znames = znames

	//pass everything to stata, maybe only these 2 needed?
	st_matrix("b", model.params')
	st_matrix("V", model.V)

	stripes = model.eqnames' , model.parnames'

	st_matrixcolstripe("b", stripes)
	st_matrixcolstripe("V", stripes)
	st_matrixrowstripe("V", stripes)
	st_local("depvar", model.yname)
	st_local("N", strofreal(model.n))
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
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit, ., maxiter, ptol, vtol, nrtol)
		} else{
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol)
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
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit, ., maxiter, ptol, vtol, nrtol)
		} else{
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit,startvalues, maxiter, ptol, vtol, nrtol)
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
	if (length(atTokens) >= 3) {
		xzbar = update_named_vector(xzbar, model.XZnames, atTokens)
	}
	loop = 1 // code of prediction type

	if (length(model.XZnames) <= 1){
		model.XZnames = tokens(model.XZnames)
	}
	
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
	
	output_mesetp(me, se, rowstripes, colstripes)
	
	// now the printing part! 
	"Evaluated at:"
	print_matrix(xzbar, ., model.XZnames)
	""
	if (zeroes) {
		"Marginal effects of all variables on the probabilities of different types of zeros"
	} 
	else if (regime) {
		"Marginal effects of all variables on the probabilities of different latent regimes"
	}
	else {
		"Marginal effects of all variables on the probabilities of different outcomes"
	}
	print_matrix(me, rowstripes, colstripes)
	""
	"Standard errors of marginal effects"
	print_matrix(se, rowstripes, colstripes)
}

function SWOPITprobabilities(class SWOPITModel scalar model, string atVarlist, zeroes, regime) {
	xz_from = model.XZmedians
	atTokens = tokens(atVarlist, " =")
	
	if (length(atTokens) >= 3) {
		xz_from = update_named_vector(xz_from, model.XZnames, atTokens)
	}
	
	loop = 1 // code of prediction type
	if (zeroes) {
		loop = 2
	} else if (regime) {
		loop = 3
	}
	
	if (length(model.XZnames) <= 1){
		model.XZnames = tokens(model.XZnames)
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
	output_mesetp(me, se, rowstripes, colstripes)
	
	// now the printing part! 
	"Evaluated at:"
	print_matrix(xz_from, ., model.XZnames)
	""
	if (zeroes) {
		"Predicted probabilities of different types of zeros"
	} 
	else if (regime) {
		"Predicted probabilities of different latent regimes"
	}
	else {
		"Predicted probabilities of different outcomes"
	}
	print_matrix(me, ., colstripes)
	""
	"Standard errors of the probabilities"
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
	printf("\n")
	printf("Accuracy                 = %9.4f \n", model.accuracy)
	printf("Brier score              = %9.4f \n", model.brier_score)
	printf("Ranked probability score = %9.4f \n", model.ranked_probability_score)
	printf("\n")
	"Confusion matrix"
	print_matrix(conf_mat, rowstripes, colstripes,., ., ., 0, rowtitle, coltitle)
}

function SWOPITpredict(class SWOPITModel scalar model, string scalar newVarName, real scalar regime, scalar output){
	sp = strpos(newVarName, ",")
	if (sp != 0){
		newVarName = substr(newVarName, 1, sp - 1)
	}
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

}

end




















