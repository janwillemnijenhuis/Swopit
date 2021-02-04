{smcl}
{* *! version 0.0.1  04february2021}{...}
{title:Title}

{pstd}{helpb ziop##swopit:swopit} {c -} Two-regime switching ordered probit regression{p_end}
{pstd}{helpb ziop##swopitc:swopitc} {c -} Correlated two-regime switching ordered probit regression{p_end}


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

{synopt :{opth outone:indepvars(varlist)}} independent variables in the outcome equation of the 1st regression equation; if nothing specified, it is identical to {it:indepvars}.{p_end}

{synopt :{opth outtwo:indepvars(varlist)}} independent variables in the outcome equation of the 2nd regression equation; if nothing specified, it is identical to {it:indepvars}.{p_end}

{synopt :{opt initial:(string asis)}} idk wat dit is.{p_end}

{synopt :{opt guesses:(scalar)}} define the number of guesses of starting values; if nothing specified it is set to 7.{p_end}

{synopt :{opt change:(scalar)}} idk wat dit is; if nothing specified it is set to 0.5.{p_end}

{synopt :{opt lim:it(scalar)}} limit on parameter values; if nothing specified it is set to 0 and no limit is set.{p_end}

{synopt :{opt maxiter:(scalar)}} maximum number of optimization iterations before quitting; if nothing specified it is set to 30.{p_end}

{synopt :{opt ptol:(scalar)}} probability tolerance;if nothing specified it is set to 1e-6.{p_end}

{synopt :{opt vtol:(scalar)}} variance tolerance;if nothing specified it is set to 1e-7.{p_end}

{synopt :{opt nrtol:(scalar)}} newton-rhapson tolerance;if nothing specified it is set to 1e-5.{p_end}

{synopt :{opt lambda:(scalar)}} lambda?;if nothing specified it is set to 50.{p_end}

{syntab :SE/Robust}
{synopt :{opt robust}} use robust sandwich estimator of variance; the default estimator is based on the observed information matrix.{p_end}
{synopt :{opth cluster(varname)}} clustering variable for the clustered robust sandwich estimator of variance{p_end}

{syntab :Reporting}
{synopt :{opt vuong}} perform the Vuong test (Vuong 1989) against the conventional ordered probit (OP) model (not available for {cmd:ziop2}).{p_end}
 
{syntab :Maximization}
{synopt :{opt initial(string)}} whitespace-delimited list of the starting values of the parameters in the following order: gamma, mu, beta+, alpha+, beta-, alpha-, rho-, rho+ for the {cmd:nop} and {cmd:ziop3} regressions, and gamma, mu, beta, alpha, rho for the {cmd:ziop2} regression.{p_end}
{synopt :{opt nolog}} suppress the iteration log and intermediate results.{p_end}
{synoptline}

{pstd}See {help ziop_postestimation:ziop postestimation} for features available after estimation.{p_end}

{title:}


{marker nop}{...}
{p 4 7}{cmd:nop} estimates a three-part nested ordered probit regresion (Sirchenko 2020) of an ordinal dependent variable {depvar} on three sets of independent variables: {it:indepvars} in the regime equation, {opt posindepvars(varlist)} in the outcome equation conditional on the regime s=1, and {opt negindepvars(varlist)} in the outcome equation conditional on the regime s=-1.{p_end}

{marker ziop2}{...}
{p 4 7}{cmd:ziop2} estimates a two-part zero-inflated ordered probit regression (Harris and Zhao 2007; Brooks, Harris and Spencer 2012; Bagozzi and Mukherjee 2012) of an ordinal dependent variable {depvar} on two sets of independent variables: {it:indepvars} in the regime equation and {opt outindepvars(varlist)} in the outcome equation.{p_end}

{marker ziop3}{...}
{p 4 7}{cmd:ziop3} estimates a three-part zero-inflated ordered probit regression (Sirchenko 2020) of an ordinal dependent variable {depvar} on three sets of independent variables: {it:indepvars} in the regime equation, {opt posindepvars(varlist)} in the outcome equation conditional on the regime s=1, and {opt negindepvars(varlist)} in the outcome equation conditional on the regime s=-1.{p_end}

{p 4 7}The actual values taken on by the dependent variable are irrelevant, except that larger values are assumed to correspond to "higher" outcomes.{p_end}

{title:Examples}

{pstd}Setup{p_end}
       . webuse rate_change

{pstd}Fit three-part nested ordered probit model with exogenous switching{p_end}
       . nop rate_change spread pb houst gdp, neg(spread gdp) pos(spread pb) inf(0)

{pstd}Fit three-part nested ordered probit model with endogenous switching and report Vuong test of NOP versus ordered probit{p_end}
       . nop rate_change spread pb houst gdp, neg(spread gdp) pos(spread pb) inf(0) endo vuong

{pstd}Fit two-part zero-inflated ordered probit model with exogenous switching{p_end}
       . ziop2 rate_change spread pb houst gdp, out(spread pb houst gdp) inf(0)

{pstd}Fit three-part zero-inflated ordered probit model with exogenous switching{p_end}
       . ziop3 rate_change spread pb houst gdp, neg(spread gdp) pos(spread pb) inf(0)

{pstd}Fit three-part zero-inflated ordered probit model with endogenous switching and report Vuong test of ZIOP-3 versus ordered probit{p_end}
       . ziop3 rate_change spread pb houst gdp, neg(spread gdp) pos(spread pb) inf(0) endo vuong

{title:Stored results}

{pstd}
{cmd:nop}, {cmd:ziop2} and {cmd:ziop3} store the following in {cmd:e()}:

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

{p 4 7}Bagozzi, B. E., and B. Mukherjee. 2012. A mixture model for middle category inflation in ordered survey responses. {it:Political Analysis} 20: 369-386.{p_end}
{p 4 7}Brooks, R., M. N. Harris, and C. Spencer. 2012. Inflated ordered outcomes. {it:Economics Letters} 117: 683-686.{p_end}
{p 4 7}Harris, M. N., and X. Zhao. 2007. A zero-inflated ordered probit model, with an application to modelling tobacco consumption. {it:Journal of Econometrics} 141: 1073-1099.{p_end}
{p 4 7}Sirchenko, A. 2020. A model for ordinal responses with heterogeneous status quo outcomes. {it:Studies in Nonlinear Dynamics & Econometrics} 24 (1).{p_end}
{p 4 7}Vuong, Q. H. 1989. Likelihood ratio tests for model selection and non-nested hypotheses. {it:Econometrica} 57: 307-333.{p_end}