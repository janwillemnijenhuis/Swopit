{smcl}
{* *! version 0.0.1  16feb2021}{...}
{title:Title}

{pstd}
{helpb swopit postestimation} {c -} Postestimation tools for {cmd:swopit}

{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {cmd:swopit}: 

{synoptset 20 notes}{...}
{p2coldent :Command}Description{p_end}
{synoptline}

{synopt :{helpb swopit postestimation##swopitpredict:swopitpredict}}predicted probabilities and other predictions for all values of independent variables{p_end}
{synopt :{helpb swopit postestimation##swopitprobabilities:swopitprobabilities}}predicted probabilities for specified values of independent variables{p_end}
{synopt :{helpb swopit postestimation##swopitmargins:swopitmargins}}marginal effects on probabilities for specified values of independent variables{p_end}
{synopt :{helpb swopit postestimation##swopitclassification:swopitclassification}}classification table and other goodness-of-fit measures{p_end}
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for swopitpredict}
{pstd}
{cmd:swopitpredict} {newvar} {bind:[{cmd:,} {it:options}]}{p_end}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{cmd:regimes}}indicates that the probabilities of the regimes must be predicted instead of the choice probabilities.{p_end}

{synopt :{opt output(string)}}specifies the different types of predictions. The possible options for {it:string} are: {it:choice} for reporting the predicted outcome (the choice with the largest predicted probability); {it:mean} for reporting the expected value of the dependent variable computed as a summation of i*Pr(y=i) across all choices i; and 
{it:cum} for predicting the cumulative choice probabilities such as Pr(y<=0), Pr(y<=1), ... . 
If {it:string} is not specified, the usual choice probabilities such as Pr(y=0), Pr(y=1), ... are predicted and saved into new variables with the {it:newvar} prefix.{p_end}
{synoptline}


{title:Description for swopitpredict}

{p 4 7}{cmd:swopitpredict} creates new variables containing predictions such as the predicted probabilities of the discrete choices, the regimes, the types of zeros conditional on the regime, the expected values of the dependent variable, the predicted choice (one with the largest predicted probability) at all observed values of the independent variables in the sample.

{title:Examples for predict}

{pstd}Setup{p_end}
       . webuse rate_change
       . swopit rate_change spread pb houst gdp, endo

{pstd}Predicted probabilities of discrete choices{p_end}
       . predict pr_choice

{pstd}Predicted discrete choice (one with the largest probability){p_end}
       . predict pr_choice, output(choice)

{pstd}Expected value of dependent variable{p_end}
       . predict pr_choice, output(mean)

{pstd}Predicted cumulative probabilities of discrete choices{p_end}
       . predict pr_choice, output(cum)

{pstd}Predicted probabilities of three regimes{p_end}
       . predict pr_regime, regimes

{synoptline}

{marker swopitprobabilities}{...}
{title:Syntax for swopitprobabilities}

{pstd}
{cmd:swopitprobabilities} [, {opt at(string)} {opt regimes} ]

{synoptset 20 notes}{...}
{p2coldent :Option}Description{p_end}
{synoptline}
{synopt :{opt at(string)}}specifies for which values of the independent variables to estimate the predicted probabilities. If at() is used ({it:string} is a list of varname=value expressions, separated by commas), the predicted probabilities are estimated at these values and displayed without saving to the dataset. If some independent variable names are not specified, their median values are taken instead. If at() is not used, by default the predicted probabilities are estimated at the median values of the independent variables.{p_end}
{synopt :{cmd:regimes}}indicates that the probabilities of the regimes must be predicted instead of the choice probabilities.{p_end}
{synoptline}
{p2colreset}{...}

{title:Description for swopitprobabilities}

{p 4 7}{cmd:swopitprobabilities} shows the predicted probabilities estimated at the specified values of independent variables along with the standard errors.{p_end}

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
{synopt :{opt at(string)}}specifies for which values of the independent variables to estimate the marginal effects on the predicted probabilities. If at() is used ({it:string} is a list of varname=value expressions, separated by commas), the marginal effects are estimated for these values and displayed without saving to the dataset. If some independent variable names are not specified, their median values are taken instead. If at() is not used, by default the marginal effects are estimated for the median values of the independent variables.{p_end}
{synopt :{cmd:regimes}}indicates that the marginal effects on the probabilities of the regimes must be predicted instead of the effects on the choice probabilities.{p_end}
{synoptline}
{p2colreset}{...}

{title:Description for swopitmargins}

{p 4 7}{cmd:swopitmargins} shows the marginal effects of each independent variable on the predicted probabilities estimated at the specified values of the independent variables along with the standard errors.{p_end}

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

{p 4 7}{cmd:swopitclassification} shows: the classification table (or confusion matrix); the percentage of correct predictions; the two strictly proper scores {c -} the probability, or Brier, score (Brier 1950) and the ranked probability score (Epstein 1969); the precisions, the hit rates (or recalls) and the adjusted noise-to-signal ratios (Kaminsky and Reinhart 1999).{p_end}
{p 10 7}The classification table reports the predicted choices (ones with the highest predicted probability) in columns, the actual choices in rows, and the number of (mis)classifications in each cell.{p_end}
{p 10 7}The Brier probability score is computed as a summation of (1/T)[Pr(y=j)-I(j,t)]^2 over all t from 1 to T and all j, where indicator I(j,t)=1 if y(t)=j and I(j,t)=0 otherwise. The ranked probability score is computed as a summation of (1/T)[Q(j,t)-D(j,t)]^2 over all t and j, where Q(j,t) is a summation of Pr(y=i) over all i less or equal to j, and D(j,t) is a summation of I(i,t) over all i less or equal to j. The better the prediction, the smaller both score values. Both scores have a minimum value of zero when all the actual outcomes are predicted with a unit probability.{p_end}
{p 10 7}The precision, the hit rate (or recall) and the adjusted noise-to-signal ratios are defined as follows. Let TP denote the true positive event that the outcome was predicted and occurred; let FP denote the false positive event that the outcome was predicted but did not occur; let FN denote the false positive event that the outcome was not predicted but occurred; and let TN denote the true negative event that the outcome was not predicted and did not occur. The desirable outcomes fall into categories TP and TN, while the noisy ones fall into categories FP and FN. A perfect prediction has no entries in FP and FN, while a noisy prediction has many entries in FP and FN, but few in TP and TN. The precision is defined for each choice as TP/(TP+FP), the recall {c -} as TP/(TP+FN), and the adjusted noise-to-signal ratio {c -} as [FP/(FP+TN)]/[TP/(TP+FN)].{p_end}

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