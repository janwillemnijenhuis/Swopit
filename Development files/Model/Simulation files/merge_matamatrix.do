version 14
clear all
cd "/Users/jhuismans/Desktop/Paper"
run helpfunctest.ado
cd "/Users/jhuismans/Desktop/Paper/results/Bootstrap/True/results none 500"

mata:

dgp = "SWOPITC" // "swopit" 
boot = "ON"
stratified = "ON"
obs = n =  500 // number of observations per iteration
overlap = "none" // "partial" "complete"
sim_iter = 1000 // number of attempts
num_batch = 1000 // number of batches 
covar = "TRUE"
getprobs = "TRUE" //FALSE to calculate without probs, TRUE for with
getME = "TRUE" //FALSE without me, True for with

n_converged = 1 //change to the amount of converged per batch
sim_iter	= 10 * n_converged  //change to maximum number of attempts
n_start_guesses = 10 // change to the number of starting guesses needed. If nothing specified starting guesses = 5
n_start_guesses_boot = 10 //starting guesses needed for bootstrap. If nothing specified starting guesses = 5
s_change = 0.5 //If starting values are specified, next one willbe in [b0 - s*abs(b0),  b + s*abs(b0)], If nothing specified s_change = 0.5

n_boot = 300 //number of bootstraps
max_boot = 10 * n_boot //change to maximum number of attempts 

starttime = clock(c("current_time"),"hms")
start_iter = 1
start_iter = start_iter * 1000
ready = 0
con = 0
boot_ready = 0
min_y_pct = 0.06 //to make sure enough variables per cat
min_boot_y_pct = 0.06 //to make sure enough variables per cat
infcat = 1 //change if needed
not_converged = 0

num_rows = n_converged*num_batch


generatedata(dgp , overlap , covar, n , x=. ,y=.,z=., param_true=., pr_true = ., regeq = ., outeqtot = ., outeq1=.,outeq2=., me_true=.,xpop =.)



for (i=1;i<=num_batch;i++){
	
	start_iter = i * 1000
	
	if (boot == "ON"){
		if (stratified == "OFF"){
			fname_boot = "mc_" + strofreal(i) + "boot_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
			
		
			fname_sim = "mc_" + strofreal(i) + "boot_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
			
		} else{
			fname_boot = "mc_" + strofreal(i) + "bootstrat_matrix" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
			
		
			fname_sim = "mc_" + strofreal(i) + "bootstrat_sim" + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
			
		}
	} else {
		fname_sim = "mc_"+strofreal(i) + strlower(dgp) + "_" + strofreal(n) + "_" + strlower(overlap) + "_" +strofreal(start_iter)+"to"+strofreal(sim_iter)+".matamatrix"
		
	}
	
	if (boot=="ON"){
	    fh = fopen(fname_sim, "r")
		temp_mat = fgetmatrix(fh)
		fclose(fh)
		fh = fopen(fname_boot, "r")
		temp_boot = fgetmatrix(fh)
		fclose(fh)
		if (i == 1){
			tot_mat = temp_mat
			boot_mat = temp_boot
		}
		
		else{
			tot_mat = tot_mat\temp_mat
			boot_mat = boot_mat\temp_boot
		}
	}
	else{
	    fh = fopen(fname_sim, "r")
		temp_mat = fgetmatrix(fh)
		fclose(fh)
		if (i == 1){
			tot_mat = temp_mat
		}
		
		else{
			tot_mat = tot_mat\temp_mat
		}
	}
}

results = tot_mat
boot_matrix = boot_mat
//results = colsum(tot_mat)/rows(tot_mat)

// sim = allpa, allse, allme, allms, allpr, allps, allco, allet, allyh, allei, allit
if (dgp == "SWOPITC"){
	if (overlap == "none"){
		if (covar == "ALL"){
			allpa = results[,1..22]
			allse = results[,23..44]
			allme = results[,45..59]
			allms = results[,60..74]
			allpr = results[,75..79]
			allps = results[,80..84]
			allco = results[,85..85]
			allet = results[,86..86]
			allyh = results[,87..89]
			allei = results[,90..90]
			allit = results[,91..91]		
		}
		else if(covar == "TRUE"){
			allpa = results[,1..12]
			allse = results[,13..24]
			allme = results[,25..39]
			allms = results[,40..54]
			allpr = results[,55..59]
			allps = results[,60..64]
			allco = results[,65..65]
			allet = results[,66..66]
			allyh = results[,67..69]
			allei = results[,70..70]
			allit = results[,71..71]	
		
		}
	}
	else if (overlap == "partial"){
		if (covar == "ALL"){
			allpa = results[,1..22]
			allse = results[,23..44]
			allme = results[,45..59]
			allms = results[,60..74]
			allpr = results[,75..79]
			allps = results[,80..84]
			allco = results[,85..85]
			allet = results[,86..86]
			allyh = results[,87..89]
			allei = results[,90..90]
			allit = results[,91..91]			
		}
		else if (covar == "TRUE"){
			allpa = results[,1..13]
			allse = results[,14..26]
			allme = results[,27..41]
			allms = results[,42..56]
			allpr = results[,57..61]
			allps = results[,62..66]
			allco = results[,67..67]
			allet = results[,68..68]
			allyh = results[,69..71]
			allei = results[,72..72]
			allit = results[,73..73]
		}
	}
	else if (overlap == "complete"){
		if (covar == "ALL"){
			allpa = results[,1..22]
			allse = results[,23..44]
			allme = results[,45..59]
			allms = results[,60..74]
			allpr = results[,75..79]
			allps = results[,80..84]
			allco = results[,85..85]
			allet = results[,86..86]
			allyh = results[,87..89]
			allei = results[,90..90]
			allit = results[,91..91]
		}
		else if (covar == "TRUE"){
			allpa = results[,1..12]
			allse = results[,13..24]
			allme = results[,25..39]
			allms = results[,40..54]
			allpr = results[,55..59]
			allps = results[,60..64]
			allco = results[,65..65]
			allet = results[,66..66]
			allyh = results[,67..69]
			allei = results[,70..70]
			allit = results[,71..71]
		}
	}
}


if (dgp == "SWOPIT"){
	if (overlap == "none"){
		if (covar == "ALL"){
			allpa = results[,1..20]
			allse = results[,21..40]
			allme = results[,41..55]
			allms = results[,56..70]
			allpr = results[,71..75]
			allps = results[,76..80]
			allco = results[,81..81]
			allet = results[,82..82]
			allyh = results[,83..85]
			allei = results[,86..86]
			allit = results[,87..87]		
		}
		else if(covar == "TRUE"){
			allpa = results[,1..10]
			allse = results[,11..20]
			allme = results[,21..35]
			allms = results[,36..50]
			allpr = results[,51..55]
			allps = results[,56..60]
			allco = results[,61..61]
			allet = results[,62..62]
			allyh = results[,63..65]
			allei = results[,66..66]
			allit = results[,67..67]	
		
		}
	}
	else if (overlap == "partial"){
		if (covar == "ALL"){
			allpa = results[,1..20]
			allse = results[,21..40]
			allme = results[,41..55]
			allms = results[,56..70]
			allpr = results[,71..75]
			allps = results[,76..80]
			allco = results[,81..81]
			allet = results[,82..82]
			allyh = results[,83..85]
			allei = results[,86..86]
			allit = results[,87..87]			
		}
		else if (covar == "TRUE"){
			allpa = results[,1..11]
			allse = results[,12..22]
			allme = results[,23..37]
			allms = results[,38..52]
			allpr = results[,53..57]
			allps = results[,58..62]
			allco = results[,63..63]
			allet = results[,64..64]
			allyh = results[,65..67]
			allei = results[,68..68]
			allit = results[,69..69]
		}
	}
	else if (overlap == "complete"){
		if (covar == "ALL"){
			allpa = results[,1..20]
			allse = results[,21..40]
			allme = results[,41..55]
			allms = results[,56..70]
			allpr = results[,71..75]
			allps = results[,76..80]
			allco = results[,81..81]
			allet = results[,82..82]
			allyh = results[,83..85]
			allei = results[,86..86]
			allit = results[,87..87]
		}
		else if (covar == "TRUE"){
			allpa = results[,1..10]
			allse = results[,11..20]
			allme = results[,21..35]
			allms = results[,36..50]
			allpr = results[,51..55]
			allps = results[,56..60]
			allco = results[,61..61]
			allet = results[,62..62]
			allyh = results[,63..65]
			allei = results[,66..66]
			allit = results[,67..67]
		}
	}
}

not_converged = 0
for (batch = 1; batch <= num_batch; batch++){
	last_iter = batch * n_converged
	last_con = allit[last_iter]
	not_con = last_con - batch*1000 - (n_converged-1)
	not_converged = not_converged + not_con

}

if (boot == "ON"){
	parlen = cols(param_true)
	bootvars = J(num_rows, parlen+5+15, 999) //parlen + number of probs + number of me's
	for(i=0; i< num_rows; i++) {
		slice = boot_matrix[1+i*n_boot..(i+1)*n_boot,4..cols(boot_matrix)] //Getting the first 7 rows and boot_p, boot_me, boot_pr
		slice_var = colsum((slice :- colsum(slice):/n_boot):^2) :/ (n_boot-1)
		bootvars[i+1,] = slice_var
	}
	bootstds = bootvars:^0.5
	bootspa = bootstds[,(1          )..(parlen     )]
	bootsme = bootstds[,(parlen+1   )..(parlen+15  )]
	bootspr = bootstds[,(parlen+16  )..(parlen+20  )]
}

cv = invnormal(.975)

meanparams = mean(allpa)
rmse = (mean((allpa:-param_true):^2)):^0.5

meanse = mean(allse)
medianse = colmedian(allse)
realse = mean((allpa:-meanparams):^2):^0.5

cil = allpa - cv:*allse
ciu = allpa + cv:*allse

coverage = (param_true :> cil) :* (param_true :< ciu)
meancoverage = mean(coverage)

cil = mean(cil)
ciu = mean(ciu)

if (dgp == "SWOPITC"){
	vars = cols(allpa)
	corr_pa = allpa[,(vars-1)::vars]
	corr_se = allse[,(vars-1)::vars]
	corr99 = corr_pa :> 0.99
	corr0 = corr_se :== 0 
	both = corr99 :* corr0
	left_out = colsum(both)
	
	corr_count = left_out[1], left_out[2]
	
	trimse1 = select(corr_se[,1],1:-both[,1])
	trimse2 = select(corr_se[,2],1:-both[,2])
	
	trimcorr1 = select(corr_pa[,1],1:-both[,1])
	trimcorr2 = select(corr_pa[,2],1:-both[,2])
	
	meantrim = mean(trimcorr1),mean(trimcorr2)
	
	rmsetrim1 = mean((trimcorr1:-param_true[vars-1]):^2):^0.5, mean((trimcorr2:-param_true[vars]):^2):^0.5
	
	meansetrim = mean(trimse1),mean(trimse2)
	
	mediansetrim = colmedian(trimse1),colmedian(trimse2)
	realsetrim = mean((trimcorr1:-meantrim[1]):^2):^0.5,mean((trimcorr2:-meantrim[2]):^2):^0.5

	ciltrim1 = trimcorr1 - cv:*trimse1
	ciltrim2 = trimcorr2 - cv:*trimse2
	
	ciutrim1 = trimcorr1 + cv:*trimse1
	ciutrim2 = trimcorr2 + cv:*trimse2

	coveragetrim1 = (param_true[vars-1] :> ciltrim1) :* (param_true[vars-1] :< ciutrim1)
	coveragetrim2 = (param_true[vars] :> ciltrim2) :* (param_true[vars] :< ciutrim2)
	
	meancoveragetrim = mean(coveragetrim1), mean(coveragetrim2)

	ciltrim = mean(ciltrim1), mean(ciltrim2)
	ciutrim = mean(ciutrim1), mean(ciutrim2)	
	
	namesrho = ("rho1","rho2")

}

if (boot == "ON"){
	realse_boot = mean(bootspa)
	boot_se_median = colmedian(bootspa)
	cil_boot = allpa - cv:*bootspa
	ciu_boot = allpa + cv:*bootspa
	boot_meancoverage = mean((param_true :> cil_boot) :* (param_true :< ciu_boot))
	
	if (dgp == "SWOPITC"){
		corr_bootspa = bootspa[,(vars-1)::vars]
		
		trimse1_boot = select(corr_bootspa[,1],1:-both[,1])
		trimse2_boot = select(corr_bootspa[,2],1:-both[,2])
		
		meansetrim_boot = mean(trimse1_boot),mean(trimse2_boot)
		mediansetrim_boot = colmedian(trimse1_boot),colmedian(trimse2_boot)

		ciltrim1_boot = trimcorr1 - cv:*trimse1_boot
		ciltrim2_boot = trimcorr2 - cv:*trimse2_boot
	
		ciutrim1_boot = trimcorr1 + cv:*trimse1_boot
		ciutrim2_boot = trimcorr2 + cv:*trimse2_boot

		coveragetrim1_boot = (param_true[vars-1] :> ciltrim1_boot) :* (param_true[vars-1] :< ciutrim1_boot)
		coveragetrim2_boot = (param_true[vars] :> ciltrim2_boot) :* (param_true[vars] :< ciutrim2_boot)
	
		meancoveragetrim_boot = mean(coveragetrim1_boot), mean(coveragetrim2_boot)
	}
	
}

if (getprobs == "TRUE"){
	pr_true = rowshape(pr_true,1)
	p_meanparams = mean(allpr)
	p_rmse = (mean((allpr:-pr_true):^2)):^0.5

	p_meanse = mean(allps)
	p_medianse = colmedian(allps)
	p_realse = mean((allpr:-p_meanparams):^2):^0.5

	p_cil = allpr - cv:*allps
	p_ciu = allpr + cv:*allps

	p_coverage = (pr_true :> p_cil) :* (pr_true :< p_ciu)
	p_meancoverage = mean(p_coverage)

	p_cil = mean(p_cil)
	p_ciu = mean(p_ciu)
	
	if (boot == "ON"){
		p_realse_boot = mean(bootspr)
		p_boot_se_median = colmedian(bootspr)
		p_cil_boot = allpr - cv:*bootspr
		p_ciu_boot = allpr + cv:*bootspr
		p_boot_meancoverage = mean((pr_true :> p_cil_boot) :* (pr_true :< p_ciu_boot))
	}

	outcome = ("Choice 1", "Choice 2", "Choice 3", "Reg 1", "Reg 2")
}

if (getME == "TRUE"){
	"test1"
	me_true = rowshape(me_true,1)
	m_meanparams = mean(allme)
	m_rmse = (mean((allme:-me_true):^2)):^0.5

	m_meanse = mean(allms)
	m_medianse = colmedian(allms)
	m_realse = mean((allme:-m_meanparams):^2):^0.5

	m_cil = allme - cv:*allms
	m_ciu = allme + cv:*allms

	m_coverage = (me_true :> m_cil) :* (me_true :< m_ciu)
	m_meancoverage = mean(m_coverage)

	m_cil = mean(m_cil)
	m_ciu = mean(m_ciu)
	
	if (boot == "ON"){
		m_realse_boot = mean(bootsme)
		m_boot_se_median = colmedian(bootsme)
		m_cil_boot = allme - cv:*bootsme
		m_ciu_boot = allme + cv:*bootsme
		m_boot_meancoverage = mean((me_true :> m_cil_boot) :* (me_true :< m_ciu_boot))
	}
	
	menames = ("X1 on 1", "X1 on 2", "X1 on 3", "X2 on 1", "X2 on 2", "X2 on 3", "X3 on 1", "X3 on 2", "X3 on 3", "X4 on 1", "X4 on 2", "X4 on 3", "X5 on 1", "X5 on 2", "X5 on 3")
}



if (dgp == "SWOPIT"){
	b_names = ("b1","b2","b3","b4","b5")
	g_names = ("g1","g2","g3","g4","g5")
	mu_names = "reg_cutoff"
	a1_names = ("out1_cutoff1","out1_cutoff2")
	a2_names = ("out2_cutoff1","out2_cutoff2")
	names = g_names,mu_names,b_names,a1_names,b_names,a2_names
	if (covar == "TRUE"){
		b1_names = select(b_names,outeq1)
		b2_names = select(b_names,outeq2)
		g_names = select(g_names,regeq)
		names = g_names,mu_names,b1_names,a1_names,b2_names,a2_names
	}
} else if (dgp == "SWOPITC"){
	b_names = ("b1","b2","b3","b4","b5")
	g_names = ("g1","g2","g3","g4","g5")
	mu_names = "reg_cutoff"
	a1_names = ("out1_cutoff1","out1_cutoff2")
	a2_names = ("out2_cutoff1","out2_cutoff2")
	rho_names = ("rho1", "rho2")
	names = g_names,mu_names,b_names,a1_names,b_names,a2_names, rho_names
	if (covar == "TRUE"){
		b1_names = select(b_names,outeq1)
		b2_names = select(b_names,outeq2)
		g_names = select(g_names,regeq)
		names = g_names,mu_names,b1_names,a1_names,b2_names,a2_names, rho_names
	}
}
else{
	b_names = ("b1","b2","b3","b4","b5")
	g_names = ("g1","g2","g3","g4","g5")
	mu_names = "reg_cutoff"
	a1_names = ("out1_cutoff1","out1_cutoff2")
	if (covar == "TRUE"){
		b_names = select(b_names,outeqtot)
		g_names = select(g_names,regeq)
	}
	names = g_names,mu_names,b_names,a1_names	
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
end

cd "/Users/jhuismans/Desktop/Paper/results/Bootstrap/True"

mata


// Write to excel //
excel = xl()
excel.load_book("sim_results")
excel.set_mode("open")
if (boot == "OFF"){
	sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + strofreal(n)
	sheetname	
}
else{
	if (stratified == "OFF"){
		sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + "BOOT" + "_" + strofreal(n)
		sheetname
	} else{
		sheetname = strupper(dgp) + "_" + strupper(overlap) + "_" + strupper(covar) + "_" + "STRAT" + "_" + strofreal(n)
		sheetname
	}
}
if(max(excel.get_sheets():==sheetname)==0){
	excel.add_sheet(sheetname)
}
excel.set_sheet(sheetname)
excel.clear_sheet(sheetname)

erow = 1
excel.put_string(erow, 1, "ESTIMATION RESULTS for " + sheetname)
erow = erow + 1
excel.put_string(erow, 9, "Hours")
excel.put_string(erow, 10, "Mins")
excel.put_string(erow, 11, "Secs")
erow = erow + 1
excel.put_string(erow, 1, "Converged: ")
excel.put_number(erow, 2, sum(allco))
excel.put_string(erow, 3, "Not Converged: ")
excel.put_number(erow, 4, not_converged)
excel.put_string(erow, 5, "Startiter:")
excel.put_number(erow, 6, start_iter)
excel.put_string(erow, 8, "Runtime:")
excel.put_number(erow, 9,  hours)
excel.put_number(erow, 10, minutes)
excel.put_number(erow, 11, seconds)

if (boot == "OFF"){
	erow=erow+1
	excel.put_string(erow, 1, "PARAMETERS " + sheetname)
	erow = erow + 1
	excel.put_string(erow, 1, ("NAMES","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
	erow=erow+1
	excel.put_string(erow,1,names')
	excel.put_number(erow, 2, (param_true', meanparams', cil', ciu', meanse', realse', (realse' :/ meanse'), (realse':/medianse'), rmse', meancoverage') )
	erow = erow + cols(param_true)
	
	if (dgp == "SWOPITC"){
		excel.put_string(erow,1,"Trimmed")
		excel.put_string(erow,12,"Dropped")
		erow = erow + 1
		excel.put_string(erow,1, namesrho')
		excel.put_number(erow, 2, (param_true[vars-1::vars]', meantrim', ciltrim', ciutrim', meansetrim', realsetrim', (realsetrim' :/ meansetrim'), (realsetrim':/mediansetrim'), rmsetrim1', meancoveragetrim',corr_count') )
		erow = erow+2
	}
	
	erow = erow + 2
	
	if (getprobs == "TRUE"){
		excel.put_string(erow, 1, "PROBABILITIES " + sheetname)
		erow = erow + 1
		excel.put_string(erow, 1, ("Choice/Reg","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
		erow=erow+1
		excel.put_string(erow,1,outcome')
		excel.put_number(erow, 2, (pr_true', p_meanparams', p_cil', p_ciu', p_meanse', p_realse', (p_realse' :/ p_meanse'), (p_realse':/p_medianse'), p_rmse', p_meancoverage') )
		erow = erow + cols(pr_true) + 2
	}
	if (getME == "TRUE"){
		excel.put_string(erow, 1, "MARGINAL EFFECT " + sheetname)
		erow = erow + 1
		excel.put_string(erow, 1, ("NAMES", "TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage"))
		erow=erow+1
		excel.put_string(erow,1,menames')
		excel.put_number(erow, 2, (me_true', m_meanparams', m_cil', m_ciu', m_meanse', m_realse', (m_realse' :/ m_meanse'), (m_realse':/m_medianse'), m_rmse', m_meancoverage') )
		erow = erow + cols(pr_true) + 2
	}
}else{ //Here specified foor bootstraps
	erow=erow+1
	excel.put_string(erow, 1, "PARAMETERS " + sheetname)
	erow = erow + 1
	excel.put_string(erow, 1, ("NAMES","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
	erow=erow+1
	excel.put_string(erow,1,names')
	excel.put_number(erow, 2, (param_true', meanparams', cil', ciu', meanse', realse', (realse' :/ meanse'), (realse':/medianse'), rmse', meancoverage', boot_meancoverage', realse_boot', (realse' :/ realse_boot'), (realse' :/ boot_se_median')) )
	
	erow = erow + cols(param_true)
	if (dgp == "SWOPITC"){
		excel.put_string(erow,1,"Trimmed")
		excel.put_string(erow,16,"Dropped")
		erow = erow + 1
		excel.put_string(erow,1, namesrho')
		excel.put_number(erow, 2, (param_true[vars-1::vars]', meantrim', ciltrim', ciutrim', meansetrim', realsetrim', (realsetrim' :/ meansetrim'), (realsetrim':/mediansetrim'), rmsetrim1', meancoveragetrim',meancoveragetrim_boot', meansetrim_boot',(realsetrim' :/ meansetrim_boot'),(realsetrim' :/ mediansetrim_boot'), corr_count') )
		erow = erow + 2
	}
	
	erow = erow + 2
	
	if (getprobs == "TRUE"){
		excel.put_string(erow, 1, "PROBABILITIES " + sheetname)
		erow = erow + 1
		excel.put_string(erow, 1, ("Choice/Reg","TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
		erow=erow+1
		excel.put_string(erow,1,outcome')
		excel.put_number(erow, 2, (pr_true', p_meanparams', p_cil', p_ciu', p_meanse', p_realse', (p_realse' :/ p_meanse'), (p_realse':/p_medianse'), p_rmse', p_meancoverage', p_boot_meancoverage', p_realse_boot', (p_realse' :/ p_realse_boot'), (p_realse' :/ p_boot_se_median')) )
		erow = erow + cols(pr_true) + 2
	}
	if (getME == "TRUE"){
		excel.put_string(erow, 1, "MARGINAL EFFECT " + sheetname)
		erow = erow + 1
		excel.put_string(erow, 1, ("NAMES", "TRUE", "mean","mean ci_low", "mean ci_high", "mean se", "real se", "real2mean se", "real2median se", "rmse", "coverage", "boot_cov", "boot_se", "real2boot_se", "real2boot_median_se"))
		erow=erow+1
		excel.put_string(erow,1,menames')
		excel.put_number(erow, 2, (me_true', m_meanparams', m_cil', m_ciu', m_meanse', m_realse', (m_realse' :/ m_meanse'), (m_realse':/m_medianse'), m_rmse', m_meancoverage', m_boot_meancoverage', m_realse_boot', (m_realse' :/ m_realse_boot'), (m_realse' :/ m_boot_se_median')) )
		erow = erow + cols(pr_true) + 2
	}

}

excel.close_book()
end
