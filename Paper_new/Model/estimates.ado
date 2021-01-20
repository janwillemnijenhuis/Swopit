version 14
mata
class ZIOPModel scalar estimateziop(y,x,z){

	//Optional parameters
	maxiter = 30
	ptol = 1e-6
	vtol = 1e-7
	nrtol = 1e-5
	lambda = 1e-50 
	infcat = 2
	
	starttime = clock(c("current_time"),"hms")
	n	= rows(x)
	kx	= cols(x)
	kz	= cols(z)
	allcat = uniqrows(y)
	ncat = rows(allcat)
	infcat_index = selectindex(allcat :== infcat)
	parlen = (kx+kz + ncat) // seems redundant

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}
	q0 = (y :== infcat) // regime matrix 

	//"Finding regime starting values"
	paramsz = coeffOP(z, (q0, 1 :- q0), 2, maxiter, ptol,vtol,nrtol)
	
	//"Finding outcome starting values"	
	paramsx = coeffOP(x, q, ncat, maxiter, ptol, vtol, nrtol) //For all obs

	startparam = paramsz\paramsx

	_ziop_params(startparam, kx, kz, ncat, b1=., a1=., g=., mu=.)
	//coded_param = g\mu\b1\a1
	coded_param = g\codeIncreasingSequence(mu)\b1\codeIncreasingSequence(a1)

	//replace by zeros if one of the variables is empty
	if (max(coded_param :==.)  > 0){
		coded_param = J(rows(coded_param), cols(coded_param), 0)

	}

	initial_coded_param = coded_param
	
	// different optim methods
	for (i = 1; i <= 8; i++){	
		if (i == 1) {
			initial_coded_param = coded_param
			opt_method = "nr"
			//"First attempt with nr"
		}
		if (i == 2) {
			initial_coded_param = coded_param
			opt_method = "bhhh"
			"bhhh"
		}
		if (i == 3) {
			initial_coded_param = coded_param
			opt_method = "dfp"
			"dfp"
		}
		if (i == 4) {
			initial_coded_param = coded_param
			opt_method = "bfgs"
			"bfgs"
		}
		if (i == 5) {
			initial_coded_param = coded_param * 0
			opt_method = "nr"
			"nr and start values 0"
		}
		if (i == 6) {
			initial_coded_param = coded_param * 0
			opt_method = "bhhh"
			"bhhh and start values 0"
		}
		if (i == 7) {
			initial_coded_param = coded_param * 0
			opt_method = "dfp"
			"dfp and start values 0"
		}
		if (i == 8) {
			initial_coded_param = coded_param * 0
			opt_method = "bfgs"
			"bfgs and start values 0"
		}


		singularHmethod= "hybrid"
		
		S = optimize_init()

		optimize_init_tracelevel(S , "none")
		optimize_init_verbose(S, 0)

		optimize_init_argument(S, 1, x) // outcome matrix
		optimize_init_argument(S, 2, z) // regime matrix
		optimize_init_argument(S, 3, q) // y dummies
		optimize_init_argument(S, 4, ncat)
		optimize_init_argument(S, 5, infcat_index)
		optimize_init_argument(S, 6, 1) // coded
		optimize_init_evaluator(S, &_ziop_optim())
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
		iterations 	= optimize_result_iterations(S)
		params 		= optimize_result_params(S)'
		if(convg==1){
			//"convergence"
			break
		}else{
			"no convergence, trying again with different method:"
		}
	}
	_ziop_params(params, kx, kz, ncat, b1=., a1=., g=., mu=.)
	params = g\decodeIncreasingSequence(mu)\b1\decodeIncreasingSequence(a1)
	
	S2 = optimize_init()

	optimize_init_tracelevel(S2 , "none")
	optimize_init_verbose(S2, 0)
	
	optimize_init_argument(S2, 1, x)
	optimize_init_argument(S2, 2, z)
	optimize_init_argument(S2, 3, q)
	optimize_init_argument(S2, 4, ncat)
	optimize_init_argument(S2, 5, infcat_index)
	optimize_init_argument(S2, 6, 0)
	optimize_init_evaluator(S2, &_ziop_optim())
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
	if (convg == 0) {
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
	prob_obs = MLziop(params, x, z, q, ncat, infcat_index, 1)

	//This will all be used to get all the information

	class ZIOPModel scalar model 
	model.model_class = "ZIOP"

	model.n	= n
	model.k	= kx + kz
	model.ncat	= ncat
	model.infcat = infcat_index
	model.allcat = allcat
	model.classes = q
	model.retCode = retCode
	model.error_code = errorcode
	model.etime = clock(c("current_time"),"hms") - starttime
	model.converged = convg
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
	
	return(model)
}

class ZIOPModel scalar ziop2test(string scalar xynames, string scalar znames, string scalar xnames){
	col_names = xynames
	xytokens = tokens(col_names)
	yname = xytokens[1]
	xnames = xnames
	if (strlen(xnames)==0){
		xnames = invtokens(xytokens[,2::cols(xytokens)])
	}
	znames = znames
	if (strlen(znames)==0){
		znames=xnames
	}
	

	M = y = x = z = .
	st_view(M,.,(yname, xnames),0)
	st_subview(y, M, ., 1)
	//st_subview(x, M, ., (2\.))
	z = st_data(.,(znames),0)
	x = st_data(.,(xnames),0)

	class ZIOPModel scalar model 
	model = estimateziop(y,x,z)

	switching_type = "Exogenous"
	model_suptype = "Zero-inflated ordered probit regression"
	model_type = "Two-part zero-inflated ordered probit model"
	inflation_line = "Zero inflation:          two regimes"

	printf("%s\n", model_suptype)
	printf("Regime switching:        %s  \n", switching_type)
	printf("Number of observations = %9.0f \n", model.n)
	printf("Log likelihood         = %9.4f \n", model.logLik)
	printf("McFadden pseudo R2     = %9.4f \n", model.R2)
	printf("LR chi2(%2.0f)            = %9.4f \n", model.df - model.df_null, 	model.chi2)
	printf("Prob > chi2            = %9.4f \n", model.chi2_pvalue)
	printf("AIC                    = %9.4f \n" , model.AIC)
	printf("BIC                    = %9.4f \n" , model.BIC)
	
	model.yname = yname
	model.xnames = xnames
	model.znames = znames

	model.eqnames = J(1, cols(tokens(znames)) + 1, "Regime equation"), J(1, cols(tokens(xnames)) + rows(model.allcat)-1, "Outcome equation")
	model.parnames = tokens(znames), "/cut1", tokens(xnames), "/cut" :+ strofreal(1..(rows(model.allcat)-1))

	//pass everything to stata
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

class ZIOPModel scalar estimateswopit(y, x1, x2, z,|guesses,s_change,param_limit,startvalues){
	//Optional parameters
	maxiter = 30
	ptol = 1e-6
	vtol = 1e-7
	nrtol = 1e-5
	lambda = 1e-50 
	infcat  = 0 //

	if (args() == 4){
		guesses = 5
	}
	if (args() <= 5){
		s_change = 0.5
	}
	if (args() <= 6){
	    set_limit=0
		// invoke limit on parameter estimates for MC experiments
	} else if (param_limit == 0){
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
	
	infcat_index = selectindex(allcat :== infcat)
	parlen = (kx1 + kx2 + kz + ncat) // seems redundant

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}
	
	for (j = 1; j <= guesses; j++){
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
		y1 = select(y,r1)
		y2 = select(y,r2)
	
		if(args() <= 7){
			//"Finding outcome starting values"	
			//paramsx = coeffOP(x, q, ncat, maxiter, ptol, vtol, nrtol) //For all obs
			x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
			x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
			//x1pars = paramsx // equal outcome in first determination of outcome pars
			//x2pars = paramsx // comments these 2 lines for random starting
			startparam = paramsz\x1pars\x2pars
		} else{
			if (j == 1){
				startparam = startvalues'
			}
			else{
				startparam = startvalues'
				for (k = 1; k <= cols(startvalues); k++){
					startparam[k] = startparam[k] + s_change*runiform(1,1, -abs(startparam[k]), abs(startparam[k]))
				}
				
			}
		}

		_swopit_params(startparam, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)
		//coded_param = g\mu\b1\a1\b2\a2
		coded_param = g\codeIncreasingSequence(mu)\b1\codeIncreasingSequence(a1)\b2\codeIncreasingSequence(a2) //with a1,a2,b1,b2	

		//replace by zeros if one of the variables is empty
		if (max(coded_param :==.)  > 0){
			coded_param = J(rows(coded_param), cols(coded_param), 0)

		}
	
	
		initial_coded_param = coded_param
		
		// different optim methods
		for (i = 1; i <= 2; i++){	
			if (i == 1) {
			initial_coded_param = coded_param
			opt_method = "nr"
			//"First attempt with nr"
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				"bhhh"
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
						"convergence with absurd parameters, trying again with different method:"
					}
				}				
				
			}else{
				"no convergence, trying again with different method:"
			}
		}
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
					"convergence with absurd parameters, trying again with different method:"
				}
			}
		}else{
			"no convergence, trying again with different starting values"
		}
	
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
	if (convg == 0) {
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

	class ZIOPModel scalar model 
	model.model_class = "SWOPIT"
	model.n	= n
	model.k	= kx1 + kx2 + kz
	model.ncat	= ncat
	model.infcat = infcat_index
	model.allcat = allcat
	model.classes = q
	model.retCode = retCode
	model.error_code = errorcode
	model.etime = clock(c("current_time"),"hms") - starttime
	model.converged = convg
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
	
	return(model)
}

class ZIOPModel scalar estimateswopitc(y, x1, x2, z,|guesses,s_change,param_limit,startvalues){
	//Optional parameters
	maxiter = 30
	ptol = 1e-6
	vtol = 1e-7
	nrtol = 1e-5
	lambda = 1e-50 
	infcat  = 0 //

	if (args() == 4){
		guesses = 5
	}
	if (args() <= 5){
		s_change = 0.5
	}
	if (args() <= 6){
	    set_limit=0
		// invoke limit on parameter estimates for MC experiments
	} else if (param_limit == 0){
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
	
	infcat_index = selectindex(allcat :== infcat)
	parlen = (kx1 + kx2 + kz + ncat) // seems redundant

	// compute categories
	q = J(n, ncat, 0)
	for(i=1; i<=ncat; i++) {
			q[.,i] = (y :== allcat[i])
	}
	
	for (j = 1; j <= guesses; j++){
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
		y1 = select(y,r1)
		y2 = select(y,r2)
	
		if (args() <= 7){
			if (j == 1){
				//"Finding outcome starting values"	
				//paramsx = coeffOP(x, q, ncat, maxiter, ptol, vtol, nrtol) //For all obs
				x1pars = coeffOP(x1obs, q1, ncat, maxiter, ptol, vtol, nrtol) //Random starting
				x2pars = coeffOP(x2obs, q2, ncat, maxiter, ptol, vtol, nrtol) //Random starting
	
				//x1pars = paramsx // equal outcome in first determination of outcome pars
				//x2pars = paramsx // comments these 2 lines for random starting


				//Maybe not needed??
				class ZIOPModel scalar initial_model 
				initial_model = estimateswopit(y,x1,x2,z,guesses)
				startparams = initial_model.params
			
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
				startparam = startvalues
				for (k = 1; k <= rows(startvalues)-2; k++){
					startparam[k] = startparam[k] + s_change*runiform(1,1, -abs(startparam[k]), abs(startparam[k]))
				}
				
				initialtest = startparam
				startparams = startparam[1::(rows(startvalues)-2)]
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

		} else{
			if (j == 1){
				startparam = startvalues'
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
		//coded_param = g\mu\b1\a1\b2\a2

		coded_param = g\codeIncreasingSequence(mu)\b1\codeIncreasingSequence(a1)\b2\codeIncreasingSequence(a2)\logit((rho1+1)/2)\logit((rho2+1)/2) //with a1,a2,b1,b2	

		//replace by zeros if one of the variables is empty
		if (max(coded_param :==.)  > 0){
			coded_param = J(rows(coded_param), cols(coded_param), 0)

		}
	
		initial_coded_param = coded_param
		// different optim methods
		for (i = 1; i <= 2; i++){	
			if (i == 1) {
				initial_coded_param = coded_param
				opt_method = "nr"
				//"First attempt with nr"
			}
			if (i == 2) {
				initial_coded_param = coded_param
				opt_method = "bhhh"
				"bhhh"
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
						"convergence with absurd parameters, trying again with different method:"
					}
				}				
				
			}else{
				"no convergence, trying again with different method:"
			}
		}
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
					"convergence with absurd parameters, trying again with different method:"
				}
			}
		}else{
			"no convergence, trying again with different starting values"
		}
	
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
	if (convg == 0) {
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
	prob_obs = mlswoptwoc(params, x1 , x2, z, q, ncat, 1)

	//This will all be used to get all the information

	class ZIOPModel scalar model 
	model.model_class = "SWOPITC"
	model.n	= n
	model.k	= kx1 + kx2 + kz
	model.ncat	= ncat
	model.infcat = infcat_index
	model.allcat = allcat
	model.classes = q
	model.retCode = retCode
	model.error_code = errorcode
	model.etime = clock(c("current_time"),"hms") - starttime
	model.converged = convg
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
	
	return(model)
}

class ZIOPModel scalar swopit2test(string scalar xynames, string scalar znames, string scalar x1names, string scalar x2names){
	//testx1 = (1,0,1,0,1)
	//testx2 = (0,1,0,1,0)
	col_names = xynames
	xytokens = tokens(col_names)

	yname = xytokens[1]
	xnames = invtokens(xytokens[,2::cols(xytokens)])
	//x1names = invtokens(select(xnames, testx1))
	//x2names = invtokens(select(xnames, testx2))
	
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
	

	M = y = x1 = x2 = z = .
	st_view(M,.,(yname, xnames),0)
	st_subview(y, M, ., 1)
	st_subview(x, M, ., (2\.))
	z = st_data(.,(znames),0)
	x1 = st_data(.,(x1names),0)
	x2 = st_data(.,(x2names),0)
	
	class ZIOPModel scalar model
	model = estimateswopit(y, x1, x2, z)
	model.XZmedians = colmedian(x)
	model.XZnames = xnames
	model.outeq1 = outeq1
	model.outeq2 = outeq2
	model.regeq = regeq


	switching_type = "Exogenous"
	model_suptype = "Two regime switching regression"
	model_type = "Two Regime Switching Regression"

	printf("%s\n", model_suptype)
	printf("Regime switching:        %s  \n", switching_type)
	printf("Number of observations = %9.0f \n", model.n)
	printf("Log likelihood         = %9.4f \n", model.logLik)
	printf("McFadden pseudo R2     = %9.4f \n", model.R2)
	printf("LR chi2(%2.0f)            = %9.4f \n", model.df - model.df_null, 	model.chi2)
	printf("Prob > chi2            = %9.4f \n", model.chi2_pvalue)
	printf("AIC                    = %9.4f \n" , model.AIC)
	printf("BIC                    = %9.4f \n" , model.BIC)
	
	model.yname = yname
	model.x1names = x1names
	model.x2names = x2names
	model.znames = znames

	model.eqnames = J(1, cols(tokens(znames)) + 1, "Regime equation"), J(1, cols(tokens(x1names)) + rows(model.allcat)-1, "Outcome equation 1"), J(1, cols(tokens(x2names)) + rows(model.allcat)-1, "Outcome equation 2")
	model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1))

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

class ZIOPModel scalar swopit2ctest(string scalar xynames, string scalar znames, string scalar x1names, string scalar x2names){
	//testx1 = (1,0,1,0,1)
	//testx2 = (0,1,0,1,0)
	col_names = xynames
	xytokens = tokens(col_names)

	yname = xytokens[1]
	xnames = invtokens(xytokens[,2::cols(xytokens)])
	//x1names = invtokens(select(xnames, testx1))
	//x2names = invtokens(select(xnames, testx2))
	
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
	

	M = y = x1 = x2 = z = .
	st_view(M,.,(yname, xnames),0)
	st_subview(y, M, ., 1)
	st_subview(x, M, ., (2\.))
	z = st_data(.,(znames),0)
	x1 = st_data(.,(x1names),0)
	x2 = st_data(.,(x2names),0)
	
	class ZIOPModel scalar model
	model = estimateswopitc(y, x1, x2, z)
	model.XZmedians = colmedian(x)
	model.XZnames = xnames
	model.outeq1 = outeq1
	model.outeq2 = outeq2
	model.regeq = regeq



	switching_type = "Endogenous"
	model_suptype = "Two regime switching regression"
	model_type = "Two Regime Switching Regression"

	printf("%s\n", model_suptype)
	printf("Regime switching:        %s  \n", switching_type)
	printf("Number of observations = %9.0f \n", model.n)
	printf("Log likelihood         = %9.4f \n", model.logLik)
	printf("McFadden pseudo R2     = %9.4f \n", model.R2)
	printf("LR chi2(%2.0f)            = %9.4f \n", model.df - model.df_null, 	model.chi2)
	printf("Prob > chi2            = %9.4f \n", model.chi2_pvalue)
	printf("AIC                    = %9.4f \n" , model.AIC)
	printf("BIC                    = %9.4f \n" , model.BIC)
	
	model.yname = yname
	model.x1names = x1names
	model.x2names = x2names
	model.znames = znames

	model.eqnames = J(1, cols(tokens(znames)) + 1, "Regime equation"), J(1, cols(tokens(x1names)) + rows(model.allcat) -1, "Outcome equation 1"), J(1, cols(tokens(x2names)) + rows(model.allcat) -1, "Outcome equation 2"), J(1,2,"Correlations")
	model.parnames = tokens(znames), "/cut1", tokens(x1names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), tokens(x2names), "/cut" :+ strofreal(1..(rows(model.allcat)-1)), "rho1", "rho2"

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


function estimate_and_get_params_v2(dgp,covar, p, s, me, mese, pr, prse, conv, etime, eiter, y, x, z, infcat, getprobs, regeq, outeq1,outeq2,outeqtot,getME,xpop,|guesses,s_change,param_limit,startvalues) {
	
	class ZIOPModel scalar mod
	if (dgp == "ZIOP") {
		mod = estimateziop(y, x, z)
	} 
	else if (dgp == "SWOPIT") {
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
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit)
		} else{
			mod = estimateswopit(y, xb1, xb2, z, guesses,s_change,param_limit,startvalues)
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
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit)
		} else{
			mod = estimateswopitc(y, xb1, xb2, z,guesses,s_change,param_limit,startvalues)
		}
		kx1 = cols(xb1)
		kx2 = cols(xb2)
		kz = cols(z)
		ncat = rows(uniqrows(y))
		_swopitc_params(mod.params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.,rho1=. , rho2=. )
		if (g[1] <= 0){
			g = -g
			mu = -mu
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
		if (dgp == "ZIOP"){
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

function SWOPITmargins(class ZIOPModel scalar model, string atVarlist, zeroes, regime) {
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

function SWOPITprobabilities(class ZIOPModel scalar model, string atVarlist, zeroes, regime) {
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

function SWOPITclassification(class ZIOPModel scalar model){
    
	allcat = model.allcat
	classes = model.classes
	ncat = model.ncat
	prob_obs = model.probabilities
	predictions = (prob_obs:==rowmax(prob_obs))
	prediction = rowsum(predictions:*allcat')
	classes = rowsum(classes:*allcat')
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
	"Confusion matrix"
	print_matrix(conf_mat, rowstripes, colstripes,., ., ., 0, rowtitle, coltitle)
}

end
