{smcl}
{* *! version 0.0.1  16feb2021}{...}
{title:Title}

{pstd}
{helpb swopit postestimation} {c -} Postestimation tools for {cmd:swopit}

{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {cmd:swopit}: 

{synoptset 22 notes}{...}
{p2coldent :Command}Description{p_end}
{synoptline}

{synopt :{helpb swopit postestimation##swopitpredict:swopitpredict}}      predicted probabilities of the observed choices (by default) or latent classes for each observation.{p_end}
{synopt :{helpb swopit postestimation##swopitprobabilities:swopitprobabilities}}     predicted probabilities for specified values of independent variables{p_end}
{synopt :{helpb swopit postestimation##swopitmargins:swopitmargins}}     marginal effects on probabilities for specified values of independent variables{p_end}
{synopt :{helpb swopit postestimation##swopitclassification:swopitclassification}} classification table and other goodness-of-fit measures{p_end}
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for swopitpredict}
{pstd}
{cmd:swopitpredict} {varname} [,{opt regimes} {opt choice(string)}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{cmd:regimes}} calculates the predicted probabilities of the latent classes (regimes) instead of the choice probabilities (by default).{p_end}

{synopt :{opt output(string)}}specifies the different types of predictions. The possible options for {it:string} are: {it:choice} for reporting the predicted outcome (the choice with the largest predicted probability); {it:mean} for reporting the expected value of the dependent variable computed as a summation of i*Pr(y=i) across all choices i; and 
{it:cum} for predicting the cumulative choice probabilities such as Pr(y<=0), Pr(y<=1), ... . 
If {it:string} is not specified, the usual choice probabilities such as Pr(y=0), Pr(y=1), ... are predicted and saved into new variables with the {it:varname} prefix.{p_end}
{synoptline}

{title:Description for swopitpredict}

{p 4 7}{cmd:swopitpredict} This command provides the predicted probabilities of the observed choices (by default) or latent classes for each observation. 
It creates the variables named varname_i where i is the label of the observed choice or latent class. varname can only consist of letters and underscores. If an invalid name is given an error message is displayed.{p_end}
{title:Examples for predict}

{pstd}Setup{p_end}
       . webuse rate_change
       . swopit rate_change spread pb houst gdp, reg(houst gdp) outone(spread gdp) outtwo(spread pb) endo

{pstd}Predicted probabilities of discrete choices{p_end}
       . predict pr_choice

{pstd}Predicted discrete choice (one with the largest probability){p_end}
       . predict pr_choice, output(choice)

{pstd}Expected value of dependent variable{p_end}
       . predict pr_choice, output(mean)

{pstd}Predicted cumulative probabilities of discrete choices{p_end}
       . predict pr_choice, output(cum)

{pstd}Predicted probabilities of the regimes{p_end}
       . predict pr_regime, regimes

{synoptline}

{marker swopitprobabilities}{...}
{title:Syntax for swopitprobabilities}

{pstd}
{cmd:swopitprobabilities} [, {opt at(string)} {opt regimes} ]

{synoptset 20 notes}{...}
{p2coldent :Option}Description{p_end}
{synoptline}

{synopt :{opt at(string)}} specifies the values of the independent variables at which to estimate the probabilities. 
By default, the probabilities are computed at the median values of the independent variables. 
The syntax of this command is varname = value for each variable, separated by a blank space. varname is the name of the variable listed in indepvars. If an independent variable from indepvars is excluded from this option, the probabilities are estimated at the median value of this variable.{p_end}

{synopt :{cmd:regimes}}calculates the predicted probabilities of the latent classes (regimes) instead of the choice probabilities (by default).{p_end}

{synoptline}
{p2colreset}{...}

{title:Description for swopitprobabilities}

{p 4 7}{cmd:swopitprobabilities} This command provides the predicted probabilities of the observed choices (by default) or latent classes with their standard errors for the specified values of the independent variables.{p_end}

{title:Examples for swopitprobabilities}

{pstd}Setup{p_end}
       . webuse rate_change
       . swopit rate_change spread pb houst gdp, reg(houst gdp) outone(spread gdp) outtwo(spread pb) 

{pstd}Predicted probabilities of discrete choices at the median values of independent variables{p_end}
       . swopitprobabilities 

{pstd}Predicted probabilities of discrete choices at the specified values of independent variables{p_end}
       . swopitprobabilities, at (pb=1, spread=0.426, houst=1.6, gdp=6.8)

{pstd}Predicted probabilities of two regimes at the median values of independent variables{p_end}
       . swopitprobabilities, regimes

{synoptline}

{marker swopitmargins}{...}
{title:Syntax for swopitmargins}

{pstd}
{cmd:swopitmargins} [, {opt at(string)} {opt regimes} ]

{synoptset 20 notes}{...}
{p2coldent :Option}Description{p_end}
{synoptline}

{synopt :{opt at(string)}}specifies the values of the independent variables at which to estimate the marginal effects. 
By default, the marginal effects are computed at the median values of the independent variables. The syntax of this command is varname = value for each variable, separated by a blank space. varname is the name of the variable listed in indepvars. If an independent variable from indepvars is excluded from this option, the marginal effects are estimated at the median value of this variable.{p_end}

{synopt :{cmd:regimes}}calculates the predicted marginal effects of the latent classes (regimes) instead of the choice marginal effects (by default).{p_end}

{synoptline}
{p2colreset}{...}

{title:Description for swopitmargins}

{p 4 7}{cmd:swopitmargins} This command provides the marginal (partial) effects on the predicted probabilities of the observed choices (by default) or latent classes with their standard errors for the specified values of the independent variables.{p_end}

{title:Examples for swopitmargins}

{pstd}Setup{p_end}
       . webuse rate_change
       . swopit rate_change spread pb houst gdp, reg(houst gdp) outone(spread gdp) outtwo(spread pb) 

{pstd}Marginal effects on choice probabilities at the median values of independent variables{p_end}
       . swopitmargins

{pstd}Marginal effects on choice probabilities at the specified values of independent variables{p_end}
       . swopitmargins, at (pb=1, spread=0.426, houst=1.6, gdp=6.8)

{pstd}Marginal effects on probabilities of three regimes at the median values of independent variables{p_end}
       . swopitmargins, regimes

{synoptline}

{marker swopitclassification}{...}
{title:Syntax for swopitclassification}

{pstd}
{cmd:swopitclassification}


{title:Description for swopitclassification}

{p 4 7}{cmd:swopitclassification} This command constructs a confusion matrix (classification table) for the dependent variable. 
The classification table shows the observed choices in the rows and the predicted ones (the choices with the highest predicted probability) in the columns. The diagonal elements give the numbers of correctly predicted choices. 
The command also reports the accuracy (the percentage of correct predictions), the Brier probability score (Brier 1950), the ranked probability score (Epstein 1969), the precisions, the recalls and the adjusted noise-to-signal ratios (Kaminsky and Reinhart 1999).{p_end}

{title:Examples for swopitclassification}

{pstd}Setup{p_end}
       . webuse rate_change
       . swopit rate_change spread pb houst gdp, reg(houst gdp) outone(spread gdp) outtwo(spread pb)

{pstd}Classification table and other measures of fit{p_end}
       . swopitclassification

{title:References for swopitclassification}

{p 4 7}Brier, G. W. 1950. Verification of forecasts expressed in terms of probability. {it:Monthly Weather Review} 78 (1): 1-3.{p_end}
{p 4 7}Epstein, E. S. 1969. A scoring system for probability forecasts of ranked categories. {it:Journal of Applied Meteorology} 8: 985-987.{p_end}
{p 4 7}Kaminsky, G. L., and C. M. Reinhart. 1999. The twin crises: the causes of banking and balance-of-payments problems. {it:American Economic Review} 89 (3): 473-500.{p_end}

{synoptline}