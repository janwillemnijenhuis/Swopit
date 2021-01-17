mata: mata clear
run helpfunctest.ado

mata
xpop = (-11.3026,0.4221,-12.7261,-3.6010,-8.7785)

void test_optim(todo, params, v, g, H){
	v = getprob(params)
}

function getprob(xpop){
gamma	= (1.2, 1.8, 2.3, 2.5, -2.8); 
beta1   = (3.0, 3.4, 4.2, 4.8, -5.8);
beta2   = (1.1, 1.6, 1.9, 2.2, -2.6); 
a1     		= (-19.43, -8.31);				
a2     		= (3.83, 8.23);	
mu = 0.2
regeq		= (1,1,1,1,1); 
outeq1		= (1,1,1,1,1);
outeq2		= (1,1,1,1,1);

gamma 	= gamma :* regeq			// select coefficients in the model
beta1 	= beta1 :* outeq1
beta2 	= beta2 :* outeq2

gamma = select(gamma, regeq)

beta1 = select(beta1, outeq1)
beta2 = select(beta2, outeq2)
xpop1 = select(xpop, outeq1)
xpop2 = select(xpop, outeq2)
zpop  = select(xpop, regeq)

param_true = gamma , mu , beta1 , a1 , beta2 , a2

mu_est = zpop*gamma'
mu_est = abs(mu - mu_est)
mu_est
if (mu_est<=0.05){
	mu_est=0
}

pr = mlswoptwo(param_true', xpop1, xpop2, zpop, q=. , 3 , 1)
totalprob = pr[1]*pr[2]*pr[3]-mu_est
return(totalprob)
}

S = optimize_init(	)

optimize_init_verbose(S, 0)
optimize_init_tracelevel(S , "none")
optimize_init_evaluator(S, &test_optim())
optimize_init_evaluatortype(S, "gf0") // unresolved errors=(
optimize_init_params(S, xpop)
	//return(optimize_init_params(S)) //error checking
code = _optimize(S)
answer = optimize_result_params(S)'



end
