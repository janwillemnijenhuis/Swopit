{smcl}
{* *! version 0.0.1  04feb2021}{...}
{title:Title}

{pstd}{helpb swopit##swopit:swopit} {c -} Two-regime switching ordered probit regression{p_end}
{pstd}{helpb swopit##swopitc:swopitc} {c -} Correlated two-regime switching ordered probit regression{p_end}


{title:Syntax}

{pstd}{cmd:swopit} {depvar} {it:indepvars} {ifin} {bind:[{cmd:,} {it:options}]}{p_end}

{pstd}{cmd:swopitc} {depvar} {it:indepvars} {ifin} {bind:[{cmd:,} {it:options}]}{p_end}


{synoptset 24 notes}{...}
{p2coldent :{it:indepvars}}list of the independent variables in the regime equation{p_end}



{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Model}
{synopt :{opth reg:indepvars(varlist)}} independent variables in the regime equation;if nothing specified, it is identical to {it:indepvars}.{p_end}

{synopt :{opth outone:indepvars(varlist)}} independent variables in the outcome equation of the 1st regime; if nothing specified, it is identical to {it:indepvars}.{p_end}

{synopt :{opth outtwo:indepvars(varlist)}} independent variables in the outcome equation of the 2nd regime; if nothing specified, it is identical to {it:indepvars}.{p_end}

{synopt :{opt guesses:(scalar)}} define the number of guesses of starting values; if nothing specified it is set to 7.{p_end}

{synopt :{opt change:(scalar)}} interval for starting values. If starting values are given by user, this will create slightly adjusted starting values to ensure global optimization according to the formula: {it:startingvalues = startingvalues + change * UNIF(-abs(startingvalues), abs(startingvalues))}; if nothing specified it is set to 0.5.{p_end}

{synopt :{opt lim:it(scalar)}} limit on parameter values; if nothing specified it is set to 0 and no limit is set.{p_end}

{synopt :{opt maxiter:(scalar)}} maximum number of optimization iterations before quitting; if nothing specified it is set to 30.{p_end}

{synopt :{opt ptol:(scalar)}} relative difference in coefficients; if nothing specified it is set to 1e-6.{p_end}

{synopt :{opt vtol:(scalar)}} relative difference in objective function; if nothing specified it is set to 1e-7.{p_end}

{synopt :{opt nrtol:(scalar)}} scaled hessian; if nothing specified it is set to 1e-5.{p_end}

{synopt :{opt lambda:(scalar)}} coefficient for ridge estimation (yet to be implemented); if nothing specified it is set to 50.{p_end}

{syntab :Maximization}
{synopt :{opt initial(string)}} whitespace-delimited list of the starting values of the parameters in the following order: gamma, mu, beta+, alpha+, beta-, alpha-, rho-, rho+ for the {cmd:nop} and {cmd:ziop3} regressions, and gamma, mu, beta, alpha, rho for the {cmd:ziop2} regression.{p_end}
{synoptline}

{pstd}See {help swopitpostestimation:swopit postestimation} for features available after estimation.{p_end}

{title:}


{marker nop}{...}
{p 4 7}{cmd:swopit} estimates a two-regime switching ordered probit regression (Sirchenko 2020) of an ordinal dependent variable {depvar} on independent variables {it:indepvar}. If nothing else specified, all independent variables are used in the regime and outcome equations. Different sets of variables can be specified by using the following optional commands: {opt reg:indepvars(varlist)} in the regime equation, {opt outone:indepvars(varlist)} in the outcome equation conditional on the first regime, and {opt outtwoindepvars(varlist)} in the outcome equation conditional on the second regime.{p_end}

{p 4 7}{cmd:swopitc} estimates a two-regime switching ordered probit regression with endogenous switching (Sirchenko 2020) of an ordinal dependent variable {depvar} on independent variables {it:indepvar}. If nothing else specified, all independent variables are used in the regime and outcome equations. Different sets of variables can be specified by using the following optional commands: {opt reg:indepvars(varlist)} in the regime equation, {opt outone:indepvars(varlist)} in the outcome equation conditional on the first regime, and {opt outtwoindepvars(varlist)} in the outcome equation conditional on the second regime.{p_end}

{p 4 7}The actual values taken on by the dependent variable are irrelevant, except that larger values are assumed to correspond to "higher" outcomes. Hence, only the ordered categories matter, not what their actual value is.{p_end}

{title:Examples}

{pstd}Setup{p_end}
       . webuse rate_change

{pstd}Fit two-regime switching ordered probit model with exogenous switching{p_end}
       . swopit rate_change spread pb houst gdp, reg(spread gdp) outone(spread pb) outtwo(houst gdp)

{pstd}Fit two-regime switching ordered probit model with endogenous switching{p_end}
       . swopitc rate_change spread pb houst gdp, reg(spread gdp) outone(spread pb) outtwo(houst gdp)

{title:Stored results}

{pstd}
{cmd:swopit} and {cmd:swopitc} store the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_cat)}}number of categories{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}McFadden pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(vuong)}}Vuong test statistic{p_end}
{synopt:{cmd:e(vuong_aic)}}Vuong test statistic with AIC correction{p_end}
{synopt:{cmd:e(vuong_bic)}}Vuong test statistic with BIC correction{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:nop}, {cmd:ziop2} and {cmd:ziop3}, respectively{p_end}
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

{p 4 7}Sirchenko, A. 2020. A model for ordinal responses with heterogeneous status quo outcomes. {it:Studies in Nonlinear Dynamics & Econometrics} 24 (1).{p_end}