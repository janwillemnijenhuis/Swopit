cd "/Users/jhuismans/Desktop/Paper"

mata

run DefModel.ado
run helpfunctest.ado
run estimates.ado
dgp = "SWOPITC" // SWOPITMODEL.model_class
outeq1 = (0,1,1,0,0)
outeq2 = (0,0,1,1,0)
regeq = (1,0,1,0,0)
maxiter = 30
mu = 0.2
gamma = (2, 0, 1, 0, 0)
beta1    = (0, 2, 1, 0, 0)
beta2    = (0, 1, -2, 1, -2)

a1     = (-5.23, 2.46);			
a2     = (-6.17, 0.97);			

gamma = select(gamma, regeq)
beta1 = select(beta1, outeq1)
beta2 = select(beta2, outeq2)

ro1 = 0.3
ro2 = 0.5

params = gamma , mu , beta1 , a1 , beta2 , a2 , ro1, ro2
params = params'

ncat = 3
loop = 1

best_values = (0,0,0,0,0)
best_prob = 0
end_probs = (0,0,0)
start_iter = 0
for(it = start_iter; it <= 20000000; it++){
	xpop = rnormal(1,5,0,1):*10
	xb1 = select(xpop,outeq1)
	xb2 = select(xpop,outeq2)
	z = select(xpop,regeq)
	generalPredictWrapper(params', xb1, xb2, z,dgp,ncat, loop, probs =.)
	generalPredictWrapper(params', xb1, xb2, z,dgp,ncat, 3, probsreg =.)
	if (probs[1]*probs[2]*probs[3]*probsreg[1]*probsreg[2] > best_prob){
		best_prob = probs[1]*probs[2]*probs[3]*probsreg[1]*probsreg[2]
		best_values = xpop
		end_probs = probs, probsreg
		
	}	
}


end
