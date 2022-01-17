version 14
//cd "/Users/jhuismans/Desktop/Paper Swopit/Paper_new/Model"
cd "/home/andreis/StataFiles/Paper" 
mata: mata clear
run DefModel.ado
run helpfunctest.ado
run estimates.ado

mata:
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       MANUAL INPUT      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/*                           generate artificial covariates                                 */

// SPECIFY THE DGP //
n = 250	//0000
dgp = "SWOPITC" //ZIOP, SWOPIT, SWOPITC
overlap = "none" //"none", "partial", "complete" IMPORTANT: no caps
boot = "ON" //ON, OFF note: boot for now only supported with getME and getprobs == TRUE (this is a small change just to not save me/pr in boot_matrix)
stratified = "ON" //ON, OFF, stratified bootstrap
covar = "TRUE" //ALL for all covariates, TRUE for calibration covariates
getprobs = "TRUE" //FALSE to calculate without probs, TRUE for with
getME = "TRUE" //FALSE without me, True for with

// SPECIFY THE SIMULATION CHARACTERISTICS //
n_converged = 3 //change to the amount of converged needed
sim_iter	= 100 * n_converged  //change to maximum number of attempts
n_start_guesses = 5 // change to the number of starting guesses needed. If nothing specified starting guesses = 5
param_limit=100 //invoke limit on parameter values. If set to 0 no limit is invoked.
n_start_guesses_boot = 1 //starting guesses needed for bootstrap. If nothing specified starting guesses = 5
s_change = 0.2 //If starting values are specified, next one willbe in [b0 - s*abs(b0),  b + s*abs(b0)], If nothing specified s_change = 0.5
n_boot = 500 //number of bootstraps
max_boot = 100 * n_boot //change to maximum number of attempts 

// SET PARAMETERS FOR SIMULATION //
starttime = clock(c("current_time"),"hms")
start_iter = `1'
start_iter = start_iter * 1000
ready = 0
con = 0
boot_ready = 0
min_y_pct = 0.2 //to make sure enough variables per cat
min_boot_y_pct = 0.2 //to make sure enough variables per cat
infcat = 1 //change if needed
not_converged = 0

// SPECIFY STRUCTURAL PARAMETERS IN THE LOOP (so they are reset each iteration)//


//it limit depends on n_converged, 1 in 10 needs to converge
for(it = start_iter; it <= sim_iter + start_iter; it++){
	maxiter=50 // if nothing specified set to 30
	ptol=1e-6 // if nothing specified set to 1e-6
	vtol=1e-7 // if nothing specified set to 1e-7
	nrtol=1e-5 // if nothing specified set to 1e-5
	lambda=1e-50 // if nothing specified set to 1e-50
	startvalues=. // if nothing specified left empty
	maxiter_boot = 15

	rseed(42+it)
	
	generatedata(dgp , overlap , covar, n , x=. ,y=.,z=., param_true=., pr_true = ., regeq = ., outeqtot = ., outeq1=.,outeq2=., me_true=.,xpop =.)
	
	y_hist = sum(y:==0), sum(y:==1), sum(y:==2)
	
	if (min(y_hist/rows(y))<min_y_pct) {
		"bad data generated, continue another y"
		continue
	}
	estimate_and_get_params_v2(dgp,covar, p=., s=., me=., mese = ., pr = ., prse = ., conv = ., etime = ., eiter = ., y=y, x=x, z=z, infcat=infcat, getprobs, regeq, outeq1, outeq2,outeqtot,getME, xpop, n_start_guesses,s_change,param_limit,startvalues,maxiter,ptol,vtol,nrtol,lambda)
	
	//Should do something with need_meprse=1, see function is needed for extra results
	//We can maybe leave this out if we dont need those results.
	
	if (conv != 1) {
		"did not converge, resample once more"
		not_converged = not_converged + 1
		continue
	}
	if (boot == "ON"){
		boot_success = 0
		y_original = y //needed for resetting 
		x_original = x
		z_original = z
		for (booti = 1; booti <= max_boot; booti++) {
			//rseed(42 + it + booti * 10000000 + 123456789);
			if (stratified == "OFF"){
				y = y_original
				x = x_original
				z = z_original
				
				boot_indices = runiformint(n, 1, 1, n);
				//boot_indices = floor(1 :+ runiform(n, 1) :* n);
				y_iter = y[boot_indices,]
				x_iter = x[boot_indices,]
				z_iter = z[boot_indices,]
				//z_iter not checked yet, later when using boot
				y_iter_hist = sum(y_iter:==0), sum(y_iter:==1), sum(y_iter:==2)
			
				if (min(y_iter_hist/rows(y_iter)) < min_boot_y_pct) {
					"bad bootstrap data generated, resample once more"
					continue
				}
			}
			else{
				//boot_indices = runiformint(n, 1, 1, n);
				ncat = 3
				y = y_original
				x = x_original
				z = z_original

				allcat = uniqrows(y)
				q = J(n, ncat, 0)
				for(i=1; i<=ncat; i++) {
					q[.,i] = (y :== allcat[i])
				}
				y_sub1 = select(y,q[.,1])
				x_sub1 = select(x,q[.,1])
				z_sub1 = select(z,q[.,1])
				y_sub2 = select(y,q[.,2])
				x_sub2 = select(x,q[.,2])
				z_sub2 = select(z,q[.,2])
				y_sub3 = select(y,q[.,3])
				x_sub3 = select(x,q[.,3])
				z_sub3 = select(z,q[.,3])
				
				boot_indices1 = runiformint(length(y_sub1), 1, 1, length(y_sub1))
				boot_indices2 = runiformint(length(y_sub2), 1, 1, length(y_sub2))
				boot_indices3 = runiformint(length(y_sub3), 1, 1, length(y_sub3))

				y_sub1_iter = y_sub1[boot_indices1,]
				x_sub1_iter = x_sub1[boot_indices1,]
				z_sub1_iter = z_sub1[boot_indices1,]
				y_sub2_iter = y_sub2[boot_indices2,]
				x_sub2_iter = x_sub2[boot_indices2,]
				z_sub2_iter = z_sub2[boot_indices2,]
				y_sub3_iter = y_sub3[boot_indices3,]
				x_sub3_iter = x_sub3[boot_indices3,]
				z_sub3_iter = z_sub3[boot_indices3,]
				
				y_iter = y_sub1_iter\y_sub2_iter\y_sub3_iter
				x_iter = x_sub1_iter\x_sub2_iter\x_sub3_iter
				z_iter = z_sub1_iter\z_sub2_iter\z_sub3_iter

				y_iter_hist = sum(y_iter:==0), sum(y_iter:==1), sum(y_iter:==2)
			
				if (min(y_iter_hist/rows(y_iter)) < min_boot_y_pct) {
					"bad bootstrap data generated, resample once more"
					continue
				}
			
			}
			estimate_and_get_params_v2(dgp, covar, boot_p=., boot_s=., boot_me=., boot_mese = ., boot_pr = ., boot_prse = ., boot_conv = ., boot_etime = ., boot_eiter = ., y=y_iter, x=x_iter, z=z_iter, infcat=infcat, getprobs, regeq, outeq1, outeq2,outeqtot, getME, xpop, n_start_guesses_boot,s_change,param_limit,p,maxiter_boot,ptol,vtol,nrtol,lambda)
				if (boot_conv != 1) {	
					"boot did not converge, resample once more"
					continue
				}
				boot_row = ready, it, booti, boot_p, boot_me, boot_pr
				if (boot_success == 0) {
					boot_matrix_temp = boot_row
				} else {
					boot_matrix_temp = boot_matrix_temp \ boot_row 
				}
				
				boot_success ++;
				if (boot_success >= n_boot) {
					if (boot_ready == 0) {
						boot_matrix = boot_matrix_temp
					} else {
						boot_matrix = boot_matrix \ boot_matrix_temp 
					}
					boot_ready ++;
					break;
				}
		}
		if (boot_success < n_boot){
			"Number of bootstraps not reached within k*n_boots iterations"
			"Skipping bootstraps and trying with new data"
			not_converged = not_converged + 1
			continue
		
		}
	
		"Bootstrap completed. Another successful row added!"
		if (ready == 0) {
			allpa = p
			allse = s
			allme = me
			allms = mese
			allpr = pr
			allps = prse
			allco = conv
			allet = etime
			allyh = y_hist
			allei = eiter
			allit = it
		} else {
			allpa = allpa \ p
			allse = allse \ s
			allme = allme \ me
			allms = allms \ mese
			allpr = allpr \ pr
			allps = allps \ prse
			allco = allco \ conv
			allet = allet \ etime
			allyh = allyh \ y_hist
			allei = allei \ eiter
			allit = allit \ it
		}
		ready = rows(allit)
		con = sum(allco)
		if (con >= n_converged){
			break 
		}
		if(ready >= sim_iter){
			"ready is more than sim_iter; breaking"
			break
		}
	}
	else {
		if (ready == 0) {
			allpa = p
			allse = s
			allme = me
			allms = mese
			allpr = pr
			allps = prse
			allco = conv
			allet = etime
			allyh = y_hist
			allei = eiter
			allit = it
		} else {
			allpa = allpa \ p
			allse = allse \ s
			allme = allme \ me
			allms = allms \ mese
			allpr = allpr \ pr
			allps = allps \ prse
			allco = allco \ conv
			allet = allet \ etime
			allyh = allyh \ y_hist
			allei = allei \ eiter
			allit = allit \ it
		}
		ready = rows(allit)
		con = sum(allco)
		if (con >= n_converged){
			break 
		}
		if(ready >= sim_iter){
			"ready is more than sim_iter; breaking"
			break
		}		
	}
}
sim = allpa, allse, allme, allms, allpr, allps, allco, allet, allyh, allei, allit

//saving the matrices
if (boot == "ON"){
	if (stratified == "OFF"){
		fname = "results/mc_`1'boot_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
		fh = fopen(fname, "w")
		fputmatrix(fh, boot_matrix)
		fclose(fh)
	
		fname = "results/mc_`1'boot_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
		fh = fopen(fname, "w")
		fputmatrix(fh, sim)
		fclose(fh)
	} else{
		fname = "results/mc_`1'bootstrat_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
		fh = fopen(fname, "w")
		fputmatrix(fh, boot_matrix)
		fclose(fh)
	
		fname = "results/mc_`1'bootstrat_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
		fh = fopen(fname, "w")
		fputmatrix(fh, sim)
		fclose(fh)
	}
} else {
	fname = "results/mc_`1'" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
	fh = fopen(fname, "w")
	fputmatrix(fh, sim)
	fclose(fh)
}


stoptime = clock(c("current_time"),"hms")
runtime = stoptime - starttime
runtime 
allseconds = runtime/1000 //to seconds
seconds = mod(allseconds,60) //leftover seconds
if (allseconds >= 60){
	allminutes = (allseconds-seconds)/60 
	minutes = mod(allminutes,60)
}
else{
	minutes = 0
	allminutes = (allseconds-seconds)/60 
}
if (allseconds >= 3600){
	allhours = allseconds - seconds - minutes * 60 //leftover hours
	hours = allhours / 60 / 60
}
else{
	hours = 0
}

// sim = allpa, allse, allme, allms, allpr, allps, allco, allet, allyh, allei, allit

// if (boot == "ON"){
// 	parlen = cols(param_true)
// 	bootvars = J(rows(sim), parlen+5+15, 999) //parlen + number of probs + number of me's
// 	for(i=0; i< rows(sim); i++) {
// 		slice = boot_matrix[1+i*n_boot..(i+1)*n_boot,4..cols(boot_matrix)] //Getting the first 7 rows and boot_p, boot_me, boot_pr
// 		slice_var = colsum((slice :- colsum(slice):/n_boot):^2) :/ (n_boot-1)
// 		bootvars[i+1,] = slice_var
// 	}
// 	bootstds = bootvars:^0.5
// 	bootspa = bootstds[,(1          )..(parlen     )]
// 	bootsme = bootstds[,(parlen+1   )..(parlen+15  )]
// 	bootspr = bootstds[,(parlen+16  )..(parlen+20  )]
// }
//
// cv = invnormal(.975)
//
// meanparams = mean(allpa)
//
// rmse = (mean((allpa:-param_true):^2)):^0.5
//
// meanse = mean(allse)
// medianse = colmedian(allse)
// realse = mean((allpa:-meanparams):^2):^0.5
//
// cil = allpa - cv:*allse
// ciu = allpa + cv:*allse
//
// coverage = (param_true :> cil) :* (param_true :< ciu)
// meancoverage = mean(coverage)
//
// cil = mean(cil)
// ciu = mean(ciu)
//
// if (boot == "ON"){
// 	realse_boot = mean(bootspa)
// 	boot_se_median = colmedian(bootspa)
// 	cil_boot = allpa - cv:*bootspa
// 	ciu_boot = allpa + cv:*bootspa
// 	boot_meancoverage = mean((param_true :> cil_boot) :* (param_true :< ciu_boot))
//	
// }
//
// if (getprobs == "TRUE"){
// 	pr_true = rowshape(pr_true,1)
// 	p_meanparams = mean(allpr)
// 	p_rmse = (mean((allpr:-pr_true):^2)):^0.5
//
// 	p_meanse = mean(allps)
// 	p_medianse = colmedian(allps)
// 	p_realse = mean((allps:-p_meanse):^2):^0.5
//
// 	p_cil = allpr - cv:*allps
// 	p_ciu = allpr + cv:*allps
//
// 	p_coverage = (pr_true :> p_cil) :* (pr_true :< p_ciu)
// 	p_meancoverage = mean(p_coverage)
//
// 	p_cil = mean(p_cil)
// 	p_ciu = mean(p_ciu)
//	
// 	if (boot == "ON"){
// 		p_realse_boot = mean(bootspr)
// 		p_boot_se_median = colmedian(bootspr)
// 		p_cil_boot = allpr - cv:*bootspr
// 		p_ciu_boot = allpr + cv:*bootspr
// 		p_boot_meancoverage = mean((pr_true :> p_cil_boot) :* (pr_true :< p_ciu_boot))
// 	}
//
// 	outcome = ("Choice 1", "Choice 2", "Choice 3", "Reg 1", "Reg 2")
// }
//
// if (getME == "TRUE"){
// 	me_true = rowshape(me_true,1)
// 	m_meanparams = mean(allme)
// 	m_rmse = (mean((allme:-me_true):^2)):^0.5
//
// 	m_meanse = mean(allms)
// 	m_medianse = colmedian(allms)
// 	m_realse = mean((allms:-m_meanse):^2):^0.5
//
// 	m_cil = allme - cv:*allms
// 	m_ciu = allme + cv:*allms
//
// 	m_coverage = (me_true :> m_cil) :* (me_true :< m_ciu)
// 	m_meancoverage = mean(m_coverage)
//
// 	m_cil = mean(m_cil)
// 	m_ciu = mean(m_ciu)
//	
// 	if (boot == "ON"){
// 		m_realse_boot = mean(bootsme)
// 		m_boot_se_median = colmedian(bootsme)
// 		m_cil_boot = allme - cv:*bootsme
// 		m_ciu_boot = allme + cv:*bootsme
// 		m_boot_meancoverage = mean((me_true :> m_cil_boot) :* (me_true :< m_ciu_boot))
// 	}
//	
// 	menames = ("X1 on 1", "X1 on 2", "X1 on 3", "X2 on 1", "X2 on 2", "X2 on 3", "X3 on 1", "X3 on 2", "X3 on 3", "X4 on 1", "X4 on 2", "X4 on 3", "X5 on 1", "X5 on 2", "X5 on 3")
// }
//
//
//
// if (dgp == "SWOPIT"){
// 	b_names = ("b1","b2","b3","b4","b5")
// 	g_names = ("g1","g2","g3","g4","g5")
// 	mu_names = "reg_cutoff"
// 	a1_names = ("out1_cutoff1","out1_cutoff2")
// 	a2_names = ("out2_cutoff1","out2_cutoff2")
// 	names = g_names,mu_names,b_names,a1_names,b_names,a2_names
// 	if (covar == "TRUE"){
// 		b1_names = select(b_names,outeq1)
// 		b2_names = select(b_names,outeq2)
// 		g_names = select(g_names,regeq)
// 		names = g_names,mu_names,b1_names,a1_names,b2_names,a2_names
// 	}
// } else if (dgp == "SWOPITC"){
// 	b_names = ("b1","b2","b3","b4","b5")
// 	g_names = ("g1","g2","g3","g4","g5")
// 	mu_names = "reg_cutoff"
// 	a1_names = ("out1_cutoff1","out1_cutoff2")
// 	a2_names = ("out2_cutoff1","out2_cutoff2")
// 	rho_names = ("rho1", "rho2")
// 	names = g_names,mu_names,b_names,a1_names,b_names,a2_names, rho_names
// 	if (covar == "TRUE"){
// 		b1_names = select(b_names,outeq1)
// 		b2_names = select(b_names,outeq2)
// 		g_names = select(g_names,regeq)
// 		names = g_names,mu_names,b1_names,a1_names,b2_names,a2_names, rho_names
// 	}
// }
// else{
// 	b_names = ("b1","b2","b3","b4","b5")
// 	g_names = ("g1","g2","g3","g4","g5")
// 	mu_names = "reg_cutoff"
// 	a1_names = ("out1_cutoff1","out1_cutoff2")
// 	if (covar == "TRUE"){
// 		b_names = select(b_names,outeqtot)
// 		g_names = select(g_names,regeq)
// 	}
// 	names = g_names,mu_names,b_names,a1_names	
// }
//
//
// //saving the matrices
// if (boot == "ON"){
// 	if (stratified == "OFF"){
// 		fname = "results/mc_boot_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
// 		fh = fopen(fname, "w")
// 		fputmatrix(fh, boot_matrix)
// 		fclose(fh)
//	
// 		fname = "results/mc_boot_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
// 		fh = fopen(fname, "w")
// 		fputmatrix(fh, sim)
// 		fclose(fh)
// 	} else{
// 		fname = "results/mc_bootstrat_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
// 		fh = fopen(fname, "w")
// 		fputmatrix(fh, boot_matrix)
// 		fclose(fh)
//	
// 		fname = "results/mc_bootstrat_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
// 		fh = fopen(fname, "w")
// 		fputmatrix(fh, sim)
// 		fclose(fh)
// 	}
// } else {
// 	fname = "results/mc_" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
// 	fh = fopen(fname, "w")
// 	fputmatrix(fh, sim)
// 	fclose(fh)
// }
//
//
// stoptime = clock(c("current_time"),"hms")
// runtime = stoptime - starttime
// runtime 
// allseconds = runtime/1000 //to seconds
// seconds = mod(allseconds,60) //leftover seconds
// if (allseconds >= 60){
// 	allminutes = (allseconds-seconds)/60 
// 	minutes = mod(allminutes,60)
// }
// else{
// 	minutes = 0
// 	allminutes = (allseconds-seconds)/60 
// }
// if (allseconds >= 3600){
// 	allhours = allseconds - seconds - minutes * 60 //leftover hours
// 	hours = allhours / 60 / 60
// }
// else{
// 	hours = 0
// }


/*
// Write to excel //
 */
// excel = xl()
// excel.load_book("sim_results")
// excel.set_mode("open")
// if (boot == "OFF"){
// 	sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + strofreal(n)
// 	sheetname	
// }
// else{
// 	if (stratified == "OFF"){
// 		sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + "BOOT" + "_" + strofreal(n)
// 		sheetname
// 	} else{
// 		sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + "STRAT" + "_" + strofreal(n)
// 		sheetname
// 	}
// }
// if(max(excel.get_sheets():==sheetname)==0){
// 	excel.add_sheet(sheetname)
// }
// excel.set_sheet(sheetname)
// excel.clear_sheet(sheetname)
//
// erow = 1
// excel.put_string(erow, 1, "ESTIMATION RESULTS for " + sheetname)
// erow = erow + 1
// excel.put_string(erow, 9, "Hours")
// excel.put_string(erow, 10, "Mins")
// excel.put_string(erow, 11, "Secs")
// erow = erow + 1
// excel.put_string(erow, 1, "Converged: ")
// excel.put_number(erow, 2, sum(allco))
// excel.put_string(erow, 3, "Not Converged: ")
// excel.put_number(erow, 4, not_converged)
// excel.put_string(erow, 5, "Startiter:")
// excel.put_number(erow, 6, start_iter)
// excel.put_string(erow, 8, "Runtime:")
// excel.put_number(erow, 9,  hours)
// excel.put_number(erow, 10, minutes)
// excel.put_number(erow, 11, seconds)
//
// if (boot == "OFF"){
// 	erow=erow+1
// 	excel.put_string(erow, 1, "PARAMETERS " + sheetname)
// 	erow = erow + 1
// 	excel.put_string(erow, 1, ("NAMES","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
// 	erow=erow+1
// 	excel.put_string(erow,1,names')
// 	excel.put_number(erow, 2, (param_true', meanparams', cil', ciu', meanse', realse', (realse' :/ meanse'), (realse':/medianse'), rmse', meancoverage') )
// 	erow = erow + cols(param_true) + 2
// 	if (getprobs == "TRUE"){
// 		excel.put_string(erow, 1, "PROBABILITIES " + sheetname)
// 		erow = erow + 1
// 		excel.put_string(erow, 1, ("Choice/Reg","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
// 		erow=erow+1
// 		excel.put_string(erow,1,outcome')
// 		excel.put_number(erow, 2, (pr_true', p_meanparams', p_cil', p_ciu', p_meanse', p_realse', (p_realse' :/ p_meanse'), (p_realse':/p_medianse'), p_rmse', p_meancoverage') )
// 		erow = erow + cols(pr_true) + 2
// 	}
// 	if (getME == "TRUE"){
// 		excel.put_string(erow, 1, "MARGINAL EFFECT " + sheetname)
// 		erow = erow + 1
// 		excel.put_string(erow, 1, ("NAMES", "TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
// 		erow=erow+1
// 		excel.put_string(erow,1,menames')
// 		excel.put_number(erow, 2, (me_true', m_meanparams', m_cil', m_ciu', m_meanse', m_realse', (m_realse' :/ m_meanse'), (m_realse':/m_medianse'), m_rmse', m_meancoverage') )
// 		erow = erow + cols(pr_true) + 2
// 	}
// }else{ //Here specified foor bootstraps
// 	erow=erow+1
// 	excel.put_string(erow, 1, "PARAMETERS " + sheetname)
// 	erow = erow + 1
// 	excel.put_string(erow, 1, ("NAMES","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
// 	erow=erow+1
// 	excel.put_string(erow,1,names')
// 	excel.put_number(erow, 2, (param_true', meanparams', cil', ciu', meanse', realse', (realse' :/ meanse'), (realse':/medianse'), rmse', meancoverage', boot_meancoverage', realse_boot', (realse' :/ realse_boot'), (realse' :/ boot_se_median')) )
// 	erow = erow + cols(param_true) + 2
// 	if (getprobs == "TRUE"){
// 		excel.put_string(erow, 1, "PROBABILITIES " + sheetname)
// 		erow = erow + 1
// 		excel.put_string(erow, 1, ("Choice/Reg","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
// 		erow=erow+1
// 		excel.put_string(erow,1,outcome')
// 		excel.put_number(erow, 2, (pr_true', p_meanparams', p_cil', p_ciu', p_meanse', p_realse', (p_realse' :/ p_meanse'), (p_realse':/p_medianse'), p_rmse', p_meancoverage', p_boot_meancoverage', p_realse_boot', (p_realse' :/ p_realse_boot'), (p_realse' :/ p_boot_se_median')) )
// 		erow = erow + cols(pr_true) + 2
// 	}
// 	if (getME == "TRUE"){
// 		excel.put_string(erow, 1, "MARGINAL EFFECT " + sheetname)
// 		erow = erow + 1
// 		excel.put_string(erow, 1, ("NAMES", "TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
// 		erow=erow+1
// 		excel.put_string(erow,1,menames')
// 		excel.put_number(erow, 2, (me_true', m_meanparams', m_cil', m_ciu', m_meanse', m_realse', (m_realse' :/ m_meanse'), (m_realse':/m_medianse'), m_rmse', m_meancoverage', m_boot_meancoverage', m_realse_boot', (m_realse' :/ m_realse_boot'), (m_realse' :/ m_boot_se_median')) )
// 		erow = erow + cols(pr_true) + 2
// 	}
//
// }
//
// excel.close_book()


end						
