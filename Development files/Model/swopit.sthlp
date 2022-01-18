{smcl}
{* *! version 0.1.0  10jan2022}{...}
{title:Title}

{pstd}{helpb swopit##swopit:swopit} {c -} Two-regime switching ordered probit regression{p_end}


{title:Syntax}

{marker nop}{...}
{p 4 7} The following command fits a mixture of OP models with either exogenous or endogenous assignment to two latent classes (regimes) (Huismans, Nijenhuis and Sirchenko 2022).{p_end}

{pstd}{cmd:swopit} {depvar} {it:indepvars} {ifin} {bind:[{cmd:,} {it:options}]}{p_end}

{p 4 7} The dependent variable {it:depvar} may take on two or more discrete ordered values. The independent variables listed in {it:indepvar} will be, by default, included in each model. 
The alternative (and possibly not the same) lists of independent variables to be included in the class assignment model and each outcome model can be specified in {it:options}. {p_end}
{p 4 7}To avoid the locally optimal solutions the swopit command performs several estimation attempts with different initialization by randomly assigning observations to each class (regime). Besides, at each attempt, the four optimization techniques are applied one after another until convergence is achieved or all four of them are used. After each random initialization, the command obtains the starting values for the slope and threshold parameters using the independent estimations of binary probit class-assignment model and OP output models. Further, in the case of endogenous class assignment, the command obtains the starting values for rho1 and rho2 by maximizing the likelihood functions over a grid search from -0.95 to 0.95 in increments of 0.05 holding the other parameters fixed at their estimates in the exogenous switching case.
The following options are available.
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

{synopt :{opt guesses:(scalar)}} specifies the number of estimation attempts to be performed by the command optimize() with different initializations by randomly assigning observations to each class, and obtaining starting values for the slope and threshold parameters using the independent estimations of binary probit regime-switching model and two OP outcome models. Further, in the case of endogenous switching, the swopit command obtains the starting values for 1 and 2 by maximizing the likelihood functions over a grid search from -0.95 to 0.95 in increments of 0.05 holding the other parameters fixed at their estimates in the exogenous switching case. At each attempt, the following optimization techniques are applied one after another until convergence is achieved or all four of them are used: NR, BHHH, DFP, and BFGS. The estimation output with the highest likelihood is reported. The default is guesses(5). {p_end}

{synopt :{opt lim:it(numlist)}} specifies a space-delimited list of the limits for the maximum absolute
value of each parameter in the following order: gamma, mu, beta1, alpha1, beta2, alpha2, rho1 and rho2.
If only one value is specified, this limit applies to all parameters. By default, no
constraints on the parameters values are applied.
{p_end}

{synopt :{opt log}} shows the progress of the numerical optimization of the log likelihood: current
estimation attempt, optimization method, and convergence status. By default, the
log output is suppressed.{p_end}

{synopt :{opt max:iter(scalar)}} specifies the maximum number of iterations before the optimization algorithm quits and reports that the estimation of the model does not converge. 
The default is maxiter(500).{p_end}

{synopt :{opt ptol:(scalar)}} specifies the tolerance for parameters. 
The default is ptol(1e-6).{p_end}

{synopt :{opt vtol:(scalar)}} specifies the tolerance for log likelihood. 
The default is vtol(1e-7).{p_end}

{synopt :{opt nrtol:(scalar)}} specifies the tolerance for scaled gradient. 
The default is nrtol(1e-5).{p_end}

{synopt :{opt initial:(numlist)}} specifies a space-delimited list string of the starting values of the parameters in the following order: gamma, mu, beta1, alpha1, beta2, alpha2, rho1 and rho2. 
The elements of alpha1 and alpha2 should be provided in the ascending order.{p_end}

{synopt :{opt change:(scalar)}} specifies the interval for randomly selecting new starting values (SV)
for the next estimation attempt if the user has specified the starting values in
initial(). The estimation is stopped if all attempts specified in guesses()
are performed. The SV for all coefficients with the exception of the correlation
coefficients are adjusted for each estimation attempt according to the formula:
SV = SV + change * U(-|SV|, |SV|), where U() represents a uniformly distributed
random variable. In the case of endogenous switching, the SV for the correlation
coefficients rho1 and rho2 are determined by maximizing the likelihood function over a
grid search from -0.95 to 0.95 in increments of 0.05 holding the other parameters
fixed. The option is ignored if the initial() option is not used. However, it is
always applied in the bootstrap estimations if bootstrap() option is used. The
default is change(0.5).{p_end}

{synopt :{opt boot:strap(scalar)}} specifies the number of bootstrap replications to be performed to estimate the standard errors. 
The default is bootstrap(0), and no bootstrapping is performed.
{p_end}

{synopt :{opt bootguesses(scalar)}}  specifies the number of attempts with different starting values of parameters to be performed with each bootstrap sample. At the first attempt, the starting values are the values of the parameters estimated with the original sample. At each new attempt, the starting values are selected as described in change(). At each attempt, the following optimization techniques are applied one after another until convergence is achieved or all four of them are used: NR, BHHH, DFP, and BFGS. The estimation output with the highest likelihood is reported. The default is bootguesses(3).
{p_end}

{synopt :{opt bootiter(scalar)}}  specifies the maximum number of iterations in the bootstrap estimation before the optimisation algorithm quits.
The default is bootiter(100).
{p_end}

{synoptline}

{pstd}See {help swopitpostestimation:swopit postestimation} for features available after estimation.{p_end}

{title:Examples}

{pstd}Fit a mixture of two ordered probit models with exogenous switching{p_end}
       . swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread)

{pstd}Fit a mixture of two ordered probit models with endogenous switching{p_end}
       . swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) endo guesses(25)

{pstd}Fit a mixture of two ordered probit models with exogenous switching and bootstrap st. errors{p_end}
       . swopit y house gdp bias spread, reg(house gdp) outone(bias spread) outtwo(bias spread) boot(900) bootguesses(2) bootiter(100) change(0.25)

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
{synopt:{cmd:e(opt)}}optimization method{p_end}
{synopt:{cmd:e(properties)}}{bf:b V}{p_end}
{synopt:{cmd:e(vce)}}standard error method{p_end}
{synopt:{cmd:e(switching)}}type of regime switching{p_end}
{synopt:{cmd:e(vcetype)}}title to label standard errors{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(ll_obs)}}vector of observation-wise log-likelihood{p_end}
{synopt:{cmd:e(boot)}}coefficient vectors in the bootstrap samples{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{title:References}

{p 4 7}Huismans, J., Nijenhuis, J.W., Sirchenko, A. 2022. A mixture of ordered probit models with endogenous switching between two latent classes. {it:Manuscript}.{p_end}
