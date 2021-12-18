{smcl}
{* *! version 0.0.1  04feb2021}{...}
{title:Title}

{pstd}{helpb swopit##swopit:swopit} {c -} Two-regime switching ordered probit regression{p_end}


{title:Syntax}

{marker nop}{...}
{p 4 7} The following command fits a mixture of OP models with either exogenous or endogenous assignment to two latent classes (regimes) (Huismans, Nijenhuis and Sirchenko 2021).{p_end}

{pstd}{cmd:swopit} {depvar} {it:indepvars} {ifin} {bind:[{cmd:,} {it:options}]}{p_end}

{p 4 7} The dependent variable {it:depvar} may take on two or more discrete ordered values. The independent variables listed in {it:indepvar} will be, by default, included in each model. 
The alternative (and possibly not the same) lists of independent variables to be included in the class assignment model and each outcome model can be specified in {it:options}. The following options are available.
{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Model}
{synopt :{opt reg:indepvars(varlist)}} specifies the list of independent variables included in the class assignment model. 
By default, it is equal to all independent variables listed in {it:indepvars}.{p_end}

{synopt :{opt outone:indepvars(varlist)}} specifies the list of independent variables included in the first outcome model. 
By default, it is equal to all independent variables listed in {it:indepvars}.{p_end}

{synopt :{opt outtwo:indepvars(varlist)}} specifies the list of independent variables included in the second outcome model. 
By default, it is equal to all independent variables listed in {it:indepvars}.{p_end}

{synopt :{opt endo:genous(string)}} specifies that the endogenous class assignment (regime switching) is to be used instead of the default exogenous switching.{p_end}

{synopt :{opt guesses:(scalar)}} specifies the number of estimation attempts with different random starting values. 
The default is guesses(5). 
At each attempt, the following algorithms are used (NR, BHHH, DFP and BFGS) one after another until convergence is achieved or all four algorithms are employed. 
The estimation output with the highest likelihood is reported. 
If starting values are specified in initial() then the estimation attempts are stopped after the first converged one (if any). {p_end}

{synopt :{opt lim:it(scalar)}} specifies the limit for the maximum absolute value of each parameter in the ML estimation. 
The default is limit(0), and no constraints are applied.
{p_end}

{synopt :{opt maxiter:(scalar)}} specifies the maximum number of iterations before the optimization algorithm quits and reports that the estimation of the model does not converge. 
The default is maxiter(500).{p_end}

{synopt :{opt ptol:(scalar)}} specifies the tolerance for parameters. 
The default is ptol(1e-6).{p_end}

{synopt :{opt vtol:(scalar)}} specifies the tolerance for log likelihood. 
The default is vtol(1e-7).{p_end}

{synopt :{opt nrtol:(scalar)}} specifies the tolerance for scaled gradient. 
The default is nrtol(1e-5).{p_end}

{synopt :{opt initial:(string asis)}} specifies a space-delimited list string of the starting values of the parameters in the following order: gamma, mu, beta1, alpha1, beta2, alpha2, rho1 and rho2. 
The elements of alpha1 and alpha2 should be provided in the ascending order.{p_end}

{synopt :{opt change:(scalar)}} specifies the interval for randomly selecting new starting values (SV) for the next estimation attempt if the user has specified the starting values in initial(). 
The estimation attempts are stopped after the first converged one or until all attempts specified in guesses() are performed. 
The SV for all coefficients with the exception of the correlation coefficients are adjusted for each estimation attempt according to the formula: {it:SV = SV + change * U(-abs(SV), abs(SV))}, 
where U() represents a uniformly distributed random variable. 
In the case of endogenous switching, the SV for the correlation coefficients 1 and 2 are determined by maximizing the likelihood function over a grid search from -0.95 to 0.95 in increments of 0.05 holding the other parameters fixed. 
The default is change(0.5). 
The option is ignored if the initial() option is not used. 
However, it is always applied for the bootstrap.{p_end}

{synopt :{opt boot:strap(scalar)}} specifies the number of bootstrap replications to be performed to estimate the standard errors. 
Bootstrapping uses the initial values of estimated parameters as the starting ones. 
The default is bootstrap(0), and no bootstrapping is performed.
{p_end}

{synopt :{opt bootguesses(scalar)}}  specifies the maximum number of attempts with different random starting values in the bootstrap estimations. 
At each new attempt, the starting values are selected as described in change() and the following algorithms are used (NR, BHHH, DFP and BFGS) one after another until convergence is achieved or all four of them are employed. 
The estimation attempts are stopped after the first converged one or until all attempts specified in bootguesses() are performed. 
The default is bootguesses(3).
{p_end}

{synopt :{opt bootiter(scalar)}}  specifies the maximum number of iterations in the bootstrap estimation before the optimisation algorithm quits.
The default is bootiter(50).
{p_end}

{synoptline}

{pstd}See {help swopitpostestimation:swopit postestimation} for features available after estimation.{p_end}

{title:Examples}

{pstd}Setup{p_end}
       . webuse rate_change

{pstd}Fit two-regime switching ordered probit model with exogenous switching{p_end}
       . swopit rate_change spread pb houst gdp, reg(spread gdp) outone(spread pb) outtwo(houst gdp)

{pstd}Fit two-regime switching ordered probit model with endogenous switching{p_end}
       . swopit rate_change spread pb houst gdp, reg(spread gdp) outone(spread pb) outtwo(houst gdp) endo

{title:Stored results}

{pstd}
{cmd:swopit} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_cat)}}number of categories{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}McFadden pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(aic)}}Akaike Information Criterion{p_end}
{synopt:{cmd:e(bic)}}Bayesian Information Criterion{p_end}
{synopt:{cmd:e(chi2)}}Chi-square test Statistic{p_end}
{synopt:{cmd:e(p)}}p-value of Chi-square test{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:swopit}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(ll_obs)}}vector of observation-wise log-likelihood{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{title:References}

{p 4 7}Huismans, J., J. W. Nijenhuis, and A. Sirchenko. 2021. A mixture of ordered probit models with endogenous assignment to two latent classes. {it:Manuscript.} 24 (1).{p_end}
