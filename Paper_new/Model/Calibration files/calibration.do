mata:

dgp = "SWOPITC" // SWOPITMODEL.model_class
outeq1 = (0,1,1,0,0)
outeq2 = (0,1,1,0,0)
regeq = (1,0,0,0,0)
maxiter = 30
mu = 0.2
gamma = (2, 0, 0, 0, 0)
beta1    = (0, 2, 1, 0, 0)
beta2    = (0, 1, -2, 1, -2)

a1     = (-3.83, 3.76);					//no overlap
a2     = (-3.97, 3.97);					//no overlap

gamma = select(gamma, regeq)
beta1 = select(beta1, outeq1)
beta2 = select(beta2, outeq2)

ro1 = 0.3
ro2 = 0.5

params = gamma , mu , beta1 , a1 , beta2 , a2 , ro1, ro2
params = params'

ncat = 3
loop = 1

void getmaxprobs13(todo, xpop, dgp, params, ncat, outeq1, outeq2, regeq, loop, v, g, H){
	xb1 = select(xpop,outeq1)
	xb2 = select(xpop,outeq2)
	z = select(xpop,regeq)
	generalPredictWrapper(params', xb1, xb2, z,dgp,ncat, loop, probs =.)
	generalPredictWrapper(params', xb1, xb2, z,dgp,ncat, 3, probsreg =.)
	v = log(probs[1])+log(probs[2])+log(probs[3])+log(probsreg[1]) +log(probsreg[2])  
}

best_values = (0,0,0,0,0)
best_probs = 0
start_probs = (0,0,0)
start_iter = 0
for(it = start_iter; it <= 100000; it++){

	xpop = rnormal(1,5,0,1):*10
	S = optimize_init()

	optimize_init_tracelevel(S , "none")
	optimize_init_verbose(S, 0)	

	optimize_init_argument(S, 1, dgp) 
	optimize_init_argument(S, 2, params) 
	optimize_init_argument(S, 3, ncat) 
	optimize_init_argument(S, 4, outeq1) 
	optimize_init_argument(S, 5, outeq2)
	optimize_init_argument(S, 6, regeq)
	optimize_init_argument(S, 7, loop)
	optimize_init_conv_maxiter(S, maxiter)
	optimize_init_singularHmethod(S, "hybrid")

	optimize_init_evaluator(S, &getmaxprobs13())
	optimize_init_evaluatortype(S, "gf0") //gf1: making own derivative
	optimize_init_params(S, xpop)
	optimize_init_conv_warning(S, "off") 
	optimize_init_technique(S, "nr")
	errorcode 	= _optimize(S)
	xzbar = optimize_result_params(S)

	xb1 = select(xzbar,outeq1)
	xb2 = select(xzbar,outeq2)
	z = select(xzbar,regeq)
	generalPredictWrapper(params', xb1, xb2, z,dgp,ncat, loop, probs =.)
	if (probs[1]*probs[2]*probs[3] > best_probs){
		best_probs = probs[1]*probs[2]*probs[3]
		xpop = xzbar
		start_probs = probs
	}	
}


end
