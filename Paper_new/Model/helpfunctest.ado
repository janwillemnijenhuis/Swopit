version 14

mata:
function punishSort(x) {
	// the function returns vector x, if it is sorted in ascending order
	// otherwise, it returns modified x in increasing order with very small distances between swapped points
	// the goal is to avoid negative probability

	delta = 10^-5
	mu = x;
	n = length(mu);
	i = 1;
	while(i<n){
		if(mu[i+1] <= mu[i]) {
			mu[i+1] = mu[i] + delta
		}
		i=i+1;
	}
	return(mu);
}


function MLop(params, x, q, ncat, | loop) {
	k 		= cols(x) //number of explenatory variables x
	n		= rows(x) //number of data points
	gama 		= params[1::k] //Coefficients of x variables
	mu 		= params[(k+1)::length(params)] //Treshhold parameters
	mu		= punishSort(mu) //Gives ascending thresholds also punishes if not ascending
	xg 		= x * gama // outcome/estimate of equation rt*
	prob = normal(mu'[J(n,1,1),] :- xg) , J(n,1,1) //get total cdf, extra row of 1 for last category  
	prob[ , 2::ncat] = prob[ , 2::ncat] - prob[ , 1::(ncat-1)] //get probability per category
	if(loop==1){
		return(prob) //later needed to show probs in appendix
	}else{
		col_logl	= rowsum(log(prob) :* q) //q as indicator function 
		logl 	= colsum(col_logl) //returns log-likelihood
		return(logl)
	}
}

void _op_optim(todo, params, x, q, ncat, v,g,H) {
	v		= MLop(params', x, q, ncat, 0) // maximize v
}

function coeffOP(x, ycateg, ncat, maxiter, ptol, vtol, nrtol) {
	ntry = 1
	cumprob 	= runningsum(mean(ycateg)); //get total percentage per category
	start_mu1	= invnormal(cumprob[1::ncat-1])'; // assume intercept as in a model with no slope
	start_b1	= invsym(x'*x)*x'*(ycateg * invnormal(0.5 :* cumprob + 0.5 :* (0, cumprob[1::ncat-1]))'); // try to predict median for each category 
	startbmu = (start_b1 \ start_mu1)';
	
	S = optimize_init(	)

	optimize_init_verbose(S, 0)
	optimize_init_tracelevel(S , "none")
	optimize_init_argument(S, 1, x)
	optimize_init_argument(S, 2, ycateg)
	optimize_init_argument(S, 3, ncat)
	optimize_init_evaluator(S, &_op_optim())
	optimize_init_evaluatortype(S, "gf0") // unresolved errors=(
	optimize_init_params(S, startbmu)
	//return(optimize_init_params(S)) //error checking
	optimize_init_conv_maxiter(S, maxiter)
	optimize_init_conv_ptol(S, ptol)
	optimize_init_conv_vtol(S, vtol)
	optimize_init_conv_nrtol(S, nrtol)
	
	optimize_init_conv_warning(S, "off")
	
	//optimize_init_singularHmethod(S, "hybrid")
	code = _optimize(S)
	
	while (code != 0) {
		"OP: smth happened"
		optimize_result_errortext(S)
		if(ntry == 1) {
			start_b1 = start_b1 * 0
			startbmu 	= start_b1 \ start_mu1
			optimize_init_params(S, (startbmu'))
		} else if(ntry==2) {
			optimize_init_evaluatortype(S, "gf0")
		} else if(ntry==3) {
			optimize_init_technique("bfgs")
		} else {
			"ZIOP ordered probit estimation: no way to converge"
			break;
		}
		ntry = ntry+1
		code = _optimize(S)'
	}
	
	answer = optimize_result_params(S)'
	
	return(answer)
}

void _swopit_params(params, kx1, kx2, kz, ncat, b1, b2, a1, a2, g, mu) {	
	g 	= params[1::kz]
	mu	= params[kz+1]
	b1	= params[(kz+2)::(kx1+kz+1)]
	a1	= params[(kx1+kz+2)::(kx1+kz+1 + ncat - 1)]
	b2	= params[(kx1+kz+2 + ncat - 1)::(kx1+kx2+kz+1 + ncat - 1)]
	a2	= params[(kx1+kx2+kz+2 + ncat - 1)::length(params)]
	//mu	= punishSort(mu)
	//a1	= punishSort(a1)
	//a2	= punishSort(a2)
}

void _swopitc_params(params, kx1, kx2, kz, ncat, b1, b2, a1, a2, g, mu, rho1, rho2) {
	g 	= params[1::kz]
	mu	= params[kz+1]
	b1	= params[(kz+2)::(kx1+kz+1)]
	a1	= params[(kx1+kz+2)::(kx1+kz+1 + ncat - 1)]
	b2	= params[(kx1+kz+2 + ncat - 1)::(kx1+kx2+kz+1 + ncat - 1)]
	a2	= params[(kx1+kx2+kz+2 + ncat - 1)::(length(params)-2)]
	rho1 = params[length(params)-1]
	rho2 = params[length(params)]
	//mu	= punishSort(mu)
	//a1	= punishSort(a1)
	//a2	= punishSort(a2)
}

void _ziop_params(params, kx, kz, ncat, b1, a1, g, mu) {	
	g 	= params[1::kz]
	mu	= params[kz+1]
	b1	= params[(kz+2)::(kx+kz+1)]
	a1	= params[(kx+kz+2)::length(params)]
	//mu	= punishSort(mu)
	//a1	= punishSort(a1)
}
void _swoptwo_optim(todo, params, x1 , x2, z, q, ncat, coded, v, g, H) {
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz 	= cols(z)
	n	= rows(x1) // = rows(x2)
	_swopit_params(params', kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)
	if (coded == 1) {
		a1  = decodeIncreasingSequence(a1);
		a2  = decodeIncreasingSequence(a2);
		mu  = decodeIncreasingSequence(mu);
	}
	decoded_params = g \ mu \ b1 \ a1 \ b2 \ a2 
	
	v = mlswoptwo(decoded_params, x1, x2, z, q, ncat, 0)
	
}

void _swoptwoc_optim(todo, params, x1,x2, z, q, ncat, coded, v, g, H) {
	kx1 	= cols(x1)
	kx2	= cols(x2)
	kz 	= cols(z)
	n	= rows(x1) // = rows(x2)
	_swopitc_params(params', kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)
	if (coded == 1) {
		a1  = decodeIncreasingSequence(a1);
		a2  = decodeIncreasingSequence(a2);
		mu = decodeIncreasingSequence(mu);
		rho1 = invlogit(rho1)*2-1;
		rho2 = invlogit(rho2)*2-1;
	}
	decoded_params = g \ mu \ b1 \ a1 \ b2 \ a2 \ rho1 \ rho2
	
	
	v = mlswoptwoc(decoded_params, x1,x2, z, q, ncat, 0)
	
	//wellicht moeten we zelf een gradient functie maken zoals hieronder (zie cnop)
}

void _ziop_optim(todo, params, x, z, q, ncat, infcat, coded, v, g, H){
	kx	= cols(x)
	kz	= cols(z)
	_ziop_params(params', kx, kz, ncat, b1=., a1=., g=., mu=.)
	if (coded == 1) {
		a1  = decodeIncreasingSequence(a1);
		mu = decodeIncreasingSequence(mu);
	}
	decoded_params = g \ mu \ b1 \ a1
	v = MLziop(decoded_params, x, z, q, ncat, infcat, 0)
	
	/*
	if(todo==1){
		// alas! gradient is not available so far
		grad = nop_deriv(decoded_params, x, zp, zn, q, ncat, infcat, 1)
		g = grad;
	}
	*/
}
function codeIncreasingSequence(decoded_sequence) {
	/* incomplete: check if increasing! */
	coded_sequence = decoded_sequence
	n = length(coded_sequence)
	for (i = 2; i <= n; i++) {
		coded_sequence[i] = log(decoded_sequence[i] - decoded_sequence[i-1])
	}
	return(coded_sequence)
}
function decodeIncreasingSequence(coded_sequence) {
	decoded_sequence = coded_sequence
	n = length(coded_sequence)
	for (i = 2; i <= n; i++) {
		next = coded_sequence[i]
		/* for numerical stability we have to bound exponentials */
		next = min((700, max((-700, next))))
		decoded_sequence[i] = decoded_sequence[i-1] + exp(next)
	}
	return(decoded_sequence)
}
function mlswoptwo(params, x1, x2, z, q, ncat, | loop) {
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz 	= cols(z)
	n	= rows(x1)
	
	_swopit_params(params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)

	// probs
	zg	= z * g

	p1	= normal((mu :- zg)) //vector with prob of being in outcome eq 1, b1
	p2	= 1 :- p1 //vector with prob of being in outcome eq2, b2

	probreq = p1,p2
	
	//Indicator function for regime1 and 2 respectively
	reg1 = (p1:>=0.5)
	reg2 = 1 :- reg1

	//x1	= select(x,reg1) //can be used to select only observations of regime 1
	//x2	= select(x,reg2) // ... regime 2
	
	xb1	= x1 * b1
	xb2 	= x2 * b2

	//n1 	= rows(xb1)
	//n2	= rows(xb2)
	
	//Making cdf
	pb1 = normal(a1'[J(n,1,1),] :- xb1) , J(n,1,1)
	pb1[ ,2::cols(pb1)] = pb1[,2::cols(pb1)] - pb1[,1::(cols(pb1)-1)]
	pb1 = pb1 //:* reg1 //Should we get rid of observations not in regime 1?
	

	//probabilities per category
	pb2 = normal(a2'[J(n,1,1),] :- xb2) , J(n,1,1)
	pb2[ ,2::cols(pb2)] = pb2[,2::cols(pb2)] - pb2[,1::(cols(pb2)-1)]
	pb2 = pb2 //:* reg2 //Should we get rid of observations not in regime 2?

	probeq1 = pb1 :* p1 //probabilities of outcome through reg 1
	probeq2 = pb2 :* p2 //probabilities of outcome through reg 2 
	
	prob = probeq1 + probeq2   //add probs reg1 and reg2 for total prob
	if(loop==1){
		return(prob)
	}else if(loop == 3){
		return(probreq)
	
	}
	else{
		col_logl	= rowsum(log(prob) :* q) //q is indicator function
		logl 	= colsum(col_logl)
		return(logl) 
		//return(col_logl)
	}
}

function mlswoptwoc(params, x1, x2, z, q, ncat, | loop) {
	kx1 	= cols(x1)
	kx2 	= cols(x2)
	kz 	= cols(z)
	n	= rows(x1)
	
	_swopitc_params(params, kx1,kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1=., rho2=.)
	// probs
	zg	= z * g

	p1	= normal((mu :- zg)) //vector with prob of being in outcome eq 1, b1
	p2	= 1 :- p1 //vector with prob of being in outcome eq2, b2

	probreq = p1,p2
	
	//Indicator function for regime1 and 2 respectively
	reg1 = (p1:>=0.5) 
	reg2 = 1 :- reg1

	//x1	= select(x,reg1)
	//x2	= select(x,reg2)
	
	xb1	= x1 * b1
	xb2 	= x2 * b2

	//n1 	= rows(xb1)
	//n2	= rows(xb2)
	
	//Making cdf
	pb1 = binormal((mu:-zg), a1'[J(n,1,1),] :- xb1, rho1) , p1
	pb1[ ,2::cols(pb1)] = pb1[,2::cols(pb1)] - pb1[,1::(cols(pb1)-1)]
	pb1 = pb1 //:* reg1

	//probabilities per category
	pb2 = binormal(-(mu:-zg), a2'[J(n,1,1),] :- xb2, -rho2) , p2
	pb2[ ,2::cols(pb2)] = pb2[,2::cols(pb2)] - pb2[,1::(cols(pb2)-1)]
	pb2 = pb2 //:* reg2

	probeq1 = pb1 //:* p1 //probabilities of outcome through reg 1
	probeq2 = pb2 //:* p2 //probabilities of outcome through reg 2 
	
	prob = probeq1 + probeq2   //add probs reg1 and reg2 for total prob
	
	if(loop==1){
		return(prob)
	}else if(loop == 3){
		return(probreq)
	}
	else{
		col_logl	= rowsum(log(prob) :* q) //q is indicator function
		logl 	= colsum(col_logl)
		return(logl) // return(col_logl)
	}
}

function MLziop(params, x, z, q, ncat, infcat, | loop) {
	kx 	= cols(x)
	kz 	= cols(z)
	n	= rows(x)
	
	_ziop_params(params, kx, kz, ncat, b1 = ., a1 = ., g = ., mu = .)
	xb	= x * b1
	zg	= z * g
	p0	= normal(mu :- zg)
	p1	= 1 :- p0
	
	prob = normal(a1'[J(n,1,1),] :- xb) , J(n,1,1)
	prob[ , 2::ncat] = prob[ , 2::ncat] - prob[ , 1::(ncat-1)]
	prob	= prob :* p1
	prob[ , infcat]	= prob[ , infcat] :+ p0
	// INCOMPLETE: check sum of probabilities
	
	if(loop == 1) {
		return(prob)
	}else if(loop == 5){
		probreq = p0,p1
		return(probreq)
	}
	else{
		col_logl 	= rowsum(log(prob) :* q)
		return(col_logl)
	}
}

function colmedian(input_matrix) {
	m = cols(input_matrix)
	n = rows(input_matrix)
	result = J(1, m, .)
	for (i = 1; i <= m; i++) {
		sorted = sort(input_matrix[ , i], 1)
		result[1, i] = (sorted[(n + 1) / 2] + sorted[(n+1) / 2 + 0.5])/2
	}
	return(result)
}

function generalMEwithSE(dgp, params, xzbar, ncat, outeq1, outeq2, regeq, V,loop){
	generalME(params, dgp, xzbar, ncat, outeq1, outeq2, regeq,loop, me=.)
	
	me = rowshape(me, length(xzbar))
	nc = cols(me)
	nr = rows(me)
	np = rows(params)
	D = deriv_init()
	deriv_init_evaluator(D, &generalME())
	deriv_init_evaluatortype(D, "t")
	
	deriv_init_params(D, params)
	deriv_init_argument(D, 1, dgp)
	deriv_init_argument(D, 2, xzbar)
	deriv_init_argument(D, 3, ncat)
	deriv_init_argument(D, 4, outeq1)
	deriv_init_argument(D, 5, outeq2)
	deriv_init_argument(D, 6, regeq)
	deriv_init_argument(D, 7, loop)
	
	errorcode = _deriv(D, 1)
	if (errorcode != 0) {
		" Error in numerical ME differentiation " + strofreal(errorcode)
		params
		// INCOMPLETE: do something if differentiation fails; research whether it can be corrected
	}
	/*grad = rowshape(deriv_result_Jacobian(D), np)*/
	grad = deriv_result_Jacobian(D)'
	
	se = J(nr,nc,.)
	
	for(i=1; i<=nr;++i) {
		for(j=1; j<=nc;++j){
			gradrow= grad[,(i-1)*nc + j]'
			se[i,j] = gradrow * V * gradrow'
		}
	}
	se = sqrt(se)
	me = me
	mese = se
	
	
	return (me \ se)
	
}

void generalME(params, dgp, xzbar, ncat, outeq1, outeq2, regeq,loop, returnME){
	if (dgp == "SWOPIT"){
		ME = swopit_me_raw(params', xzbar, ncat, outeq1, outeq2, regeq,loop)
		returnME = rowshape(ME,1)
	}
	if (dgp == "SWOPITC"){
		ME = swopitc_me_raw(params', xzbar, ncat, outeq1, outeq2, regeq,loop)
		returnME = rowshape(ME,1)
	}
}

function swopit_me_raw(params, xzbar, ncat, outeq1, outeq2, regeq,loop){

	xbar1 = select(xzbar, outeq1)
	xbar2 = select(xzbar, outeq2)
	kx1 	= cols(xbar1)
	kx2		= cols(xbar2)

	zbar 	= select(xzbar, regeq)
	kz 		= cols(zbar)
		
	_swopit_params(params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=.)

	//g 	= select(g,regeq')
	//b1 	= select(b1,outeq1')
	//b2 	= select(b2,outeq2')

	xb1	= xbar1 * b1
	xb2 	= xbar2 * b2
	zg	= zbar * g


	// tot hier is het denk ik wel goed, aan de probs ben ik nog niet toegekomen
	p_g1	= normal(mu :- zg) // idk wrm dit 1-normal() is 
	p_g2	= 1 - p_g1 //onderaan nodig

	p_b1 = normal(a1':- xb1) , 1
	p_b1[ ,2::cols(p_b1)] = p_b1[,2::cols(p_b1)] - p_b1[,1::(cols(p_b1)-1)]

	p_b2 = normal(a2' :- xb2) , 1
	p_b2[ ,2::cols(p_b2)] = p_b2[,2::cols(p_b2)] - p_b2[,1::(cols(p_b2)-1)]

	dp_g	= -normalden(mu :- zg) :* (-g)

	dp_b1	= normalden(a1' :- xb1)
	// dit is je probit marginal effects
	dp_b1	= ((dp_b1, 0) - (0, dp_b1))[J(kx1,1,1), ] :* (-b1)

	dp_b2	= normalden(a2' :- xb2)
	dp_b2	= ((dp_b2, 0) - (0, dp_b2))[J(kx2,1,1), ] :* (-b2)


	// now calculate ME themselves
	//regime
	dp_g1	= normalden(mu - zg) :* (-g)
	dp_g2   = -normalden(mu - zg) :* (-g)


	if (loop == 2){
		f=1
		mer = (dp_g1, dp_g2)
		mert = J(cols(xzbar),2,0)
		for (i=1;i<=cols(xzbar);i++){
			if (regeq[i]==1){
				
				mert[i,] = mer[f,]
				f++
			}
			else{
				mert[i,] = J(1,2,0)
			}
		}
		mer = mert
		
	}


	//outeq 1
	dp_b1	= normalden(a1' :- xb1)
	dp_b1	= ((dp_b1, 0) - (0, dp_b1))[J(kx1,1,1), ] :* (-b1)

	//outeq2
	dp_b2	= normalden(a2' :- xb2)
	dp_b2	= ((dp_b2, 0) - (0, dp_b2))[J(kx2,1,1), ] :* (-b2)

	mez1 = p_b1[J(kz,1,1),] :* dp_g1
	mez2 = p_b2[J(kz,1,1),] :* dp_g2
	mez = mez1 + mez2
	mex	= mex1t = mex2t = mezt = J(cols(xzbar),ncat,0)

	h = 1
	for (i=1;i<=cols(xzbar);i++){
		if (regeq[i]==1){
			
			mezt[i,] = mez[h,] 
			h++
			
		}
		else{
			mezt[i,] = J(1,ncat,0)
		}
	}

	mez = mezt
	mex1	= p_g1 :* dp_b1
	mex2	= p_g2 :* dp_b2

	k = 1
	j = 1
	for (i=1;i<=cols(xzbar);i++){
		if (outeq1[i]==1){
			mex1t[i,] = mex1[j,] 
			j++
		}
		else{
			mex1t[i,] = J(1,ncat,0)
		}
		if(outeq2[i]==1){
			mex2t[i,] = mex2[k,] 
			k++
		}
		else{
			mex2t[i,] = J(1,ncat,0)
		}
	}
	mex = mex1t+mex2t

	if (loop==2){
		//"Total marginal effects on Pr(s=i)"
		return(mer)
	}
	
	//"Total marginal effects on Pr(y=j)"
	mes = mex+mez
	return(mes)
}

function swopitc_me_raw(params, xzbar, ncat, outeq1, outeq2, regeq,loop){

	xbar1 = select(xzbar, outeq1)
	xbar2 = select(xzbar, outeq2)
	kx1 	= cols(xbar1)
	kx2	= cols(xbar2)

	zbar 	= select(xzbar, regeq)
	kz 	= cols(zbar)
		
	_swopitc_params(params, kx1, kx2, kz, ncat, b1=., b2=., a1=., a2=., g=., mu=., rho1 = ., rho2 = .)

	//g 	= select(g,regeq')
	//b1 	= select(b1,outeq1')
	//b2 	= select(b2,outeq2')

	xb1	= xbar1 * b1
	xb2     = xbar2 * b2
	zg	= zbar * g

	dpr1 = normalden(mu - zg)
	dpr2 = -normalden(mu - zg)

	p1dz = ( dpr1 :* normal(((a1' :- xb1) :- ((mu :-zg) * rho1)) :/ sqrt(1 - rho1^2)) , dpr1)[J(kz,1,1),] :* -g
	p1dz[,2::(ncat)] = p1dz[ ,2::(ncat)] :- p1dz[ , 1::(ncat-1)]

	p1dx = (normalden(a1' :- xb1) :* normal(((mu:-zg) :- rho1 * (a1' :- xb1)) :/ sqrt(1 - rho1^2)), 0)[J(kx1,1,1),] :* -b1
	p1dx[,2::(ncat)] = p1dx[ ,2::(ncat)] :- p1dx[ , 1::(ncat-1)]
	
	p2dz = ( dpr2 :* normal(((a2' :- xb2) :- ((mu :-zg) * rho2)) :/ sqrt(1 - rho2^2)) , dpr2 )[J(kz,1,1),] :* -g
	p2dz[,2::(ncat)] = p2dz[ ,2::(ncat)] :- p2dz[ , 1::(ncat-1)]

	p2dx = (normalden(a2' :- xb2) :* normal(((mu:-zg) :- rho2 * (a2' :- xb2)) :/ sqrt(1 - rho2^2)), 0)[J(kx2,1,1),] :* -b2
	p2dx[,2::(ncat)] = p2dx[ ,2::(ncat)] :- p2dx[ , 1::(ncat-1)]

	if (loop == 2){
		f=1
		botha = a1\a2
		mer = (dpr1, dpr2) :* -1
		mert = J(cols(xzbar),2,0)
		for (i=1;i<=cols(xzbar);i++){
			if (regeq[i]==1){
				mert[i,] = mer[f,]
				f++
			}
			else{
				mert[i,] = J(1,2,0)
			}
		}
		mer = mert
		return(mer)
		
	}

	mez1 = p1dz
	mez2 = p2dz
	mez = mez1 + mez2
	mex	= mex1t = mex2t = mezt = J(cols(xzbar),ncat,0)

	h = 1
	for (i=1;i<=cols(xzbar);i++){
		if (regeq[i]==1){
			
			mezt[i,] = mez[h,] 
			h++
			
		}
		else{
			mezt[i,] = J(1,ncat,0)
		}
	}

	mez = mezt
	mex1	= p1dx
	mex2	= p2dx

	k = 1
	j = 1
	for (i=1;i<=cols(xzbar);i++){
		if (outeq1[i]==1){
			mex1t[i,] = mex1[j,] 
			j++
		}
		else{
			mex1t[i,] = J(1,ncat,0)
		}
		if(outeq2[i]==1){
			mex2t[i,] = mex2[k,] 
			k++
		}
		else{
			mex2t[i,] = J(1,ncat,0)
		}
	}
	mex = mex1t+mex2t
	
	//"Total marginal effects on Pr(y=j)"
	mes = mex+mez
	return(mes)
}

function generalPredictWithSE(dgp, params, xzbar, ncat, outeq1, outeq2, regeq, V,loop){
	xb1 = select(xzbar,outeq1)
	xb2 = select(xzbar,outeq2)
	z = select(xzbar,regeq)

	generalPredictWrapper(params, xb1, xb2, z,dgp,ncat, loop, probs =.)
	
	nc = cols(probs)
	nr = rows(probs)
	D = deriv_init()
	deriv_init_evaluator(D, &generalPredictWrapper())
	deriv_init_evaluatortype(D, "t")
	
	deriv_init_params(D, params)
	deriv_init_argument(D, 1, xb1)
	deriv_init_argument(D, 2, xb2)
	deriv_init_argument(D, 3, z)
	deriv_init_argument(D, 4, dgp)
	deriv_init_argument(D, 5, ncat)
	deriv_init_argument(D, 6, loop)
	

	errorcode = _deriv(D, 1)

	if (errorcode != 0) {
		" Error in numerical PREDICT (SE) differentiation " + strofreal(errorcode)
		// INCOMPLETE: do something if differentiation fails; research whether it can be corrected
	}
	/*grad = rowshape(deriv_result_Jacobian(D), np)*/
	grad = deriv_result_Jacobian(D)'
	
	se = J(nr,nc,.)
	
	/*
	if (mod.robust == 1) {
		V = mod.V_rob
	} else {
		V = model.V
	}
	*/
	
	for(i=1; i<=nr;++i) {
		for(j=1; j<=nc;++j){
			gradrow= grad[,(i-1)*nc + j]'
			se[i,j] = gradrow * V * gradrow'
		}
	}
	se = sqrt(se)
	
	return (probs \ se)

}

void generalPredictWrapper(params, xb1, xb2, z, dgp, ncat,loop, prediction){
	if (dgp == "SWOPIT"){
			prediction = rowshape(mlswoptwo(params', xb1, xb2, z, q=. , ncat , loop) ,1)
	}
	if (dgp == "SWOPITC"){
			prediction = rowshape(mlswoptwoc(params', xb1, xb2, z, q=. , ncat , loop),1)
	}
	//returnpred = rowshape(prediction,1)
	
}

function generatedata(dgp,overlap, covar, n, x, y,z, param_true, pr_true, regeq, outeqtot, outeq1, outeq2, me_true,xpop){
//generating explanatory variables
	x1 = rnormal(n,1,0,1):*4	
	x2 = rnormal(n,1,0,1):*4	 
	x3 = rnormal(n,1,0,1):*4	
	x4 = rnormal(n,1,0,1):*4
	x5 = rnormal(n,1,0,1):*4
	
	//More if statements needed for SWOPITC, calibration
	if (dgp == "SWOPIT"){
		if (overlap == "none"){
			xpop = (.1107881184, -3.976418159,  12.13442585,  -.2792527126,  2.065452509)
		}
		else if (overlap == "partial"){
			xpop = ( -2.204557618,-.8031044209,4.585550939 , 2.681426937, -1.402007089)
		}
		else {
			xpop = (.0926441758,.810674341,2.540061733, -1.32448933, 2.36486985)
		}
	} else {
		if (overlap == "none"){
			xpop = (.0873596412,   -1.302229666, -1.451681655, 3.497783925,  -.2737838849)
		}
		else if (overlap == "partial"){
			xpop = (-.7880186633, -3.422588615,1.627394035, 4.625070074, -23.37244365)
		}
		else {
			xpop = (.1388318471, -.7772909207, -2.37580418, -6.238999327,  -19.36128341)
		}

	}

	//generating error terms
	epsreg 	= rnormal(n,1,0,1);
	epseq1 	= rnormal(n,1,0,1);
	epseq2 	= rnormal(n,1,0,1); 
	
	//coefficients
	gamma = (2, 0, 1, 0, 0)
	beta1 = (0, 2, 1, 0, 0)
	beta2 = (0, 1, -2, 1, -2)


	//More If statements needed for dgp SWOPITC
	if (dgp == "SWOPIT"){
		mu      = (0.20);
		if (overlap == "none"){
			//no overlap
			regeq 		= (1,0,0,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,0,0,1,1);
			outeqtot 	= (0,1,1,1,1);
			a1     = (-3.83, 3.76);		
			a2     = (-3.97, 3.97);								
		} else if (overlap == "partial"){
			//partial overlap
			regeq 		= (1,0,1,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,0,1,1,0);
			outeqtot 	= (0,1,1,1,0);
			a1     = (-5.23, 2.46);			
			a2     = (-6.17, 0.97);																					
		} else {
			//complete overlap, also if not correct specified
			regeq 		= (1,0,0,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,1,1,0,0); 	
			outeqtot 	= (0,1,1,0,0);
			a1     = (-3.83, 3.81);			
			a2     = (-3.83, 3.93);													
		}

		// building model

		gamma 	= gamma :* regeq			// select coefficients in the model
		beta1 	= beta1 :* outeq1
		beta2 	= beta2 :* outeq2

		x 	= (x1, x2, x3, x4, x5);
		//xpop = colmedian(x)
		
		
		gamma_true = gamma 
		beta1_true = beta1 
		beta2_true = beta2 

	
		z = select(x, regeq)
		gamma = select(gamma, regeq)
		xb1 = select(x, outeq1)
		xb2 = select(x, outeq2)
		beta1 = select(beta1, outeq1)
		beta2 = select(beta2, outeq2)
		xpop1 = select(xpop, outeq1)
		xpop2 = select(xpop, outeq2)
		zpop  = select(xpop, regeq)
	
		
		ncat = cols(a1) + 1
		param_true = gamma , mu , beta1 , a1 , beta2 , a2
		pr_true = mlswoptwo(param_true', xpop1, xpop2, zpop, q=. , ncat , 1)
		pr_reg_true = mlswoptwo(param_true', xpop1, xpop2, zpop, q=. , ncat , 3)
		pr_true = pr_true,pr_reg_true
		me_true = swopit_me_raw(param_true', xpop,ncat , outeq1, outeq2, regeq, 1)
		

	
		rs 		= z * gamma' + epsreg;				// regime equation
		r 		= J(n, 2, 0);
		
		r[.,1]  = rs :< mu; 					//regime 1 decision
		r[.,2]  = rs :>= mu;					//regime 2 decision
					
		rvec	= rowsum(r*(-1,1)');				// -1 indicates reg1, 1 reg2

		ys1     = xb1 * beta1' + epseq1;				// second layer of y
		ys2     = xb2 * beta2' + epseq2;

		y1                	= J(n, cols(a1)+1,0);
		y1[., 1]           	= ys1 :< a1[1]; 		    //dummy if outc 1
		y1[., 2]		= (ys1 :>= a1[1]) :* (ys1:< a1[2]); //dummy if outc 2	
		y1[., cols(a1)+1]	= ys1 :>= a1[2];		    //dummy if outc 3


		y2                	= J(n, cols(a2)+1,0);
		y2[., 1]           	= ys2 :< a2[1]; 		    //dummy if outc 1
		y2[., 2]		= (ys2 :>= a2[1]) :* (ys2:< a2[2]); //dummy if outc 2	
		y2[., cols(a2)+1]	= ys2 :>= a2[2];		    //dummy if outc 3


		y1      = y1*range(0,2,1); // specify outcomes
		y2      = y2*range(0,2,1); // specify outcomes

		yr      = (y1,y2);
		y       = rowsum(r :* yr);	// observed y, depends on regime

		ycat	= uniqrows(y);		// column 0 1 2
		
		if (covar == "ALL"){
			outeq1 = outeq2 = regeq = (1,1,1,1,1)
			param_true = gamma_true , mu , beta1_true , a1 , beta2_true , a2
					
		}

	}
	
	//Still calibration needed for SWOPITC
	if (dgp == "SWOPITC"){
		mu      = (0.20);
		rho1 	= (0.3);
		rho2 	= (0.5);

		epseq1 = epseq1 * sqrt(1 - rho1^2) + epsreg * rho1
		epseq2 = epseq2 * sqrt(1 - rho2^2) + epsreg * rho2
		
		if (overlap == "none"){
			//no overlap
			regeq 		= (1,0,0,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,0,0,1,1);
			outeqtot 	= (0,1,1,1,1);
			a1     = (-3.83, 3.76);		
			a2     = (-3.97, 3.97);													
		} else if (overlap == "partial"){
			//partial overlap
			regeq 		= (1,0,1,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,0,1,1,0);
			outeqtot 	= (0,1,1,1,0);
			a1     = (-5.23, 2.46);			
			a2     = (-6.17, 0.97);			

		} else {
			//complete overlap, also if not correct specified
			regeq 		= (1,0,0,0,0); 
			outeq1 		= (0,1,1,0,0);
			outeq2 		= (0,1,1,0,0); 	
			outeqtot 	= (0,1,1,0,0);
			a1     = (-3.83, 3.81);			
			a2     = (-3.83, 3.93);								
		}

		// building model

		gamma 	= gamma :* regeq			// select coefficients in the model
		beta1 	= beta1 :* outeq1
		beta2 	= beta2 :* outeq2

		x 	= (x1, x2, x3, x4, x5);
		//xpop = colmedian(x)
		
		gamma_true = gamma 
		beta1_true = beta1 
		beta2_true = beta2 


		z = select(x, regeq)
		gamma = select(gamma, regeq)
		xb1 = select(x, outeq1)
		xb2 = select(x, outeq2)
		beta1 = select(beta1, outeq1)
		beta2 = select(beta2, outeq2)
		xpop1 = select(xpop, outeq1)
		xpop2 = select(xpop, outeq2)
		zpop  = select(xpop, regeq)


		
		ncat = cols(a1) + 1
		
		param_true = gamma , mu , beta1 , a1 , beta2 , a2 , rho1 , rho2
		pr_true = mlswoptwoc(param_true', xpop1, xpop2, zpop, q=. , ncat , 1)
		pr_reg_true = mlswoptwoc(param_true', xpop1, xpop2, zpop, q=. , ncat , 3)
		pr_true = pr_true,pr_reg_true
		me_true = swopitc_me_raw(param_true', xpop,ncat , outeq1, outeq2, regeq, 1)

		
		rs 		= z * gamma' + epsreg;				// regime equation
		r 		= J(n, 2, 0);
		
		r[.,1]  = rs :< mu; 					//regime 1 decision
		r[.,2]  = rs :>= mu;					//regime 2 decision
					
		rvec	= rowsum(r*(-1,1)');				// -1 indicates reg1, 1 reg2

		ys1     = xb1 * beta1' + epseq1;				// second layer of y
		ys2     = xb2 * beta2' + epseq2;

		y1                	= J(n, cols(a1)+1,0);
		y1[., 1]           	= ys1 :< a1[1]; 		    //dummy if outc 1
		y1[., 2]		= (ys1 :>= a1[1]) :* (ys1:< a1[2]); //dummy if outc 2	
		y1[., cols(a1)+1]	= ys1 :>= a1[2];		    //dummy if outc 3


		y2                	= J(n, cols(a2)+1,0);
		y2[., 1]           	= ys2 :< a2[1]; 		    //dummy if outc 1
		y2[., 2]		= (ys2 :>= a2[1]) :* (ys2:< a2[2]); //dummy if outc 2	
		y2[., cols(a2)+1]	= ys2 :>= a2[2];		    //dummy if outc 3


		y1      = y1*range(0,2,1); // specify outcomes
		y2      = y2*range(0,2,1); // specify outcomes

		yr      = (y1,y2);
		y       = rowsum(r :* yr);	// observed y, depends on regime

		ycat	= uniqrows(y);		// column 0 1 2

		if (covar == "ALL"){
			outeq1 = outeq2 = regeq = (1,1,1,1,1)
			param_true = gamma_true , mu , beta1_true , a1 , beta2_true , a2 , rho1 , rho2					
		}
	}

	if (dgp == "ZIOP"){
		mu      = (-2.5);	
		if (overlap == "none"){
			//no overlap
			regeq		= (1,0,0,1,0); 
			outeq1		= (0,1,1,0,1);
			outeqtot	= (0,1,1,0,1)
			a1     = (-7.13, 6.56);										
		} else if (overlap == "partial"){
			//partial overlap
			regeq		= (1,0,1,1,0); 
			outeq1		= (0,1,1,0,1);
			outeqtot	= (0,1,1,0,1)
			a1     = (-3.85, 9.72);								
		} else {
			//complete overlap, also if not correct specified
			regeq		= (1,1,1,1,1); 
			outeq1		= (1,1,1,1,1);	
			outeqtot	= (1,1,1,1,1)
			a1     = (5.03, 16.21);							
		}

		// building model

		gamma 	= gamma :* regeq			// select coefficients in the model
		beta1 	= beta1 :* outeq1
		
		x 	= (x1, x2, x3, x4, x5); 
		//xpop = colmedian(x)
		
		if (covar == "TRUE"){
			z = select(x, regeq)
			gamma = select(gamma, regeq)
			x = select(x, outeqtot)
			beta1 = select(beta1, outeqtot)
			zpop = select(xpop,regeq)
			xpop = select(xpop,outeqtot)
		}
		else if (covar == "ALL"){
			z = x
		}
		
		ncat = cols(a1) + 1
		
		param_true = gamma , mu , beta1 , a1
		pr_true = MLziop(param_true', xpop, zpop, q=. , ncat , 1, 1)

		rs 		= z * gamma' + epsreg;				// regime equation
		r 		= J(n, 2, 0);

		r[.,1]  = rs :< mu; 					//regime 1 decision
		r[.,2]  = rs :>= mu;					//regime 2 decision
					
		//rvec	= rowsum(r*(-1,1)');				// -1 indicates reg1, 1 reg2

		ys2     = x * beta1' + epseq1;				// second layer of y

		y2                	= J(n, cols(a1)+1,0);
		y2[., 1]           	= ys2 :< a1[1]; 		    //dummy if outc 1
		y2[., 2]		= (ys2 :>= a1[1]) :* (ys2:< a1[2]); //dummy if outc 2	
		y2[., cols(a1)+1]	= ys2 :>= a1[2];		    //dummy if outc 3

		y2      = y2*range(0,2,1); // specify outcomes
		y1                	= J(n, 1,0);

		yr      = (y1,y2);
		y       = rowsum(r :* yr);	// observed y, depends on regime

		//ycat	= uniqrows(y);		// column 1 2 3
	}
}

function update_named_vector(values, names, tokens) {
	atVarnames = tokens[range(1, cols(tokens)-2, 3)]
	atValues = subinstr(tokens[range(3, cols(tokens), 3)], ",", "") 
	atTable = sort( (atVarnames' , atValues'), 1)
	if (length(names) == length(atVarnames)){
		names = names
	}
	else{
		names = tokens(names)
	}

	for(i = 1; i <= rows(atTable); i++) {
		index = selectindex(names :== atTable[i,1])
		if (cols(index)) {
			newValue = strtoreal(atTable[i,2])
			if (newValue == .) {
				"'" + atTable[i,1] + " = " + atTable[i,2] + " could not be parsed"
			}
			values[index] = newValue
		} else {
			atTable[i,1] + " was not applied in the last ZIOP/NOP model"
		}
	}
	return(values)
} 

function output_matrix(matrix_name, matrix_value, rowstripes, colstripes){
	rowstripes_new = escape_stripes(rowstripes)
	colstripes_new = escape_stripes(colstripes)
	st_matrix(matrix_name, matrix_value)
	st_matrixrowstripe(matrix_name, (J(rows(rowstripes_new), 1, ""), rowstripes_new))
	st_matrixcolstripe(matrix_name, (J(rows(colstripes_new), 1, ""), colstripes_new))
}

function escape_stripes(stripes) {
	// workaround: stata does not allow colstripes containing dots
	colstripes = subinstr(stripes, "=.", "=0.")
	colstripes = subinstr(colstripes, "=-.", "=-0.")
	colstripes = subinstr(colstripes, ".", ",")
	return(colstripes)
}

function output_mesetp(me, se, rowstripes, colstripes) {
	t = me :/ se
	pval = (1:-normal(abs(t))) :* 2
	output_matrix("me",     me, rowstripes, colstripes)
	output_matrix("se",     se, rowstripes, colstripes)
	output_matrix("t",       t, rowstripes, colstripes)
	output_matrix("pval", pval, rowstripes, colstripes)
}

void print_matrix(contents, rownames, colnames, | uline, lline, mline, digits, rowtitle, coltitle) {
	// because Stata cannot display matrices with dots in colnames, we need our own printing function!
	n = rows(contents)
	m = cols(contents)
	if (rownames == . | rows(rownames) == 0) {
		rowname_width = 0
		rowname_flag = 0
	} else {
		rowname_width = max(strlen(rownames) \ 10)
		rowname_flag = 1
	}
	if (uline == . | rows(uline) == 0) {
		uline = 0
	} 
	if (lline == . | rows(lline) == 0) {
		lline = 0
	}
	if (mline == . | rows(mline) == 0) {
		mline = (n > 1)
	}
	if (digits == . | rows(digits) == 0) {
		digits = 4
	}
	_colnames = colnames
	if (cols(_colnames) > 1){
		_colnames = _colnames'
	}
	
	if (rowtitle == . | rows(rowtitle) == 0) {
		rowtitle_rows = 0
	} else {
		// todo: ensure that rowname_flag is true
		rowtitle_rows = rows(rowtitle)
		rowname_width = max((strlen(rowtitle) \ rowname_width))
	}
	if (coltitle == . | rows(coltitle) == 0) {
		coltitle_rows = 0
	} else {
		// todo: ensure that rowname_flag is true
		coltitle_rows = rows(coltitle)
	}
	
	colwidths = rowmax((strlen(_colnames) :+ 3 , J(rows(_colnames), 1, 6)))
	// todo: support word wrap for long colnames and maybe row and col titles
	// todo: make colwidths depend on the contents
	// todo: support lines before totals
	numberf = strofreal(digits) + "f"
	if (rowname_flag) {
		hline = "{hline " + strofreal(rowname_width+1)+ "}{c +}{hline " + strofreal(sum(colwidths :+ 1) + 2)+ "}\n"
	} else {
		hline = "{hline " + strofreal(rowname_width+1+1+sum(colwidths :+ 1) + 2) + "}\n"
	}
	// print header
	if (uline) {
		printf(hline)
	}
	
	if (rowtitle_rows > 1) {
		for(i=1; i <= rowtitle_rows; i++) {
			// todo: take into accoutn possible difference in vlines
			printf("%" + strofreal(rowname_width) + "s {c |}", rowtitle[i])
			// todo: make coltitle centered
			if (coltitle_rows > 0) {
				coltitle_current =  i + coltitle_rows - rowtitle_rows + 1
				if ((coltitle_current > 0) & (coltitle_current <= coltitle_rows)) {
					printf(coltitle[coltitle_current])
				}
			}
			if (i < rowtitle_rows) {
				printf("\n")
			}
		}
	} else if (rowtitle_rows==1){
	    printf("%" + strofreal(rowname_width) + "s {c |} ", rowtitle)	    
	} else if (rowname_flag) {
		printf("%" + strofreal(rowname_width) + "s {c |} ", "")
	}
	for(j=1; j<=m; j++){
		printf("%" + strofreal(colwidths[j]) + "s ", colnames[j])
	}
	printf("\n")
	if (mline) {
		printf(hline)
	}
	// print the rest of the table
	if (coltitle_rows==1){
	    printf("%"+strofreal(rowname_width)+ "s {c |}\n",coltitle)
	} else if (coltitle_rows>1){
	    "A higher (>1) number of words for column title is not yet supported"
	}
	for(i=1; i<=n; i++) {
		if (rowname_flag) {
			printf("%" + strofreal(rowname_width)+ "s {c |} ", rownames[i])
		}
		for(j=1; j<=m; j++){
			printf("%" + strofreal(colwidths[j]) + "." + numberf + " ", contents[i, j])
		}
		printf("\n")
	}
	if (lline) {
		printf(hline)
	}
}

function matrix_mse(residual) {
	result = mean(rowsum(residual :* residual))
	return(result)
}
function running_rowsum(input_matrix) {
	result = input_matrix
	for(i=2; i<=cols(input_matrix); i++) {
		result[,i] = result[,i-1] + result[,i]
	}
	return(result)
}

end
