#### COPYRIGHT STATEMENT: We give our consent to anyone to use this code for non-commercial and non-profit purposes only. For commercial purposes contact one of the authors. 
#### © 2021 Andrei Sirchenko, Jochem Huismans and Jan Willem Nijenhuis. All rights reserved.
------------------------------------------------------------------------------
# Swopit
Ordinal responses can be generated, in a cross-sectional context, by different latent classes of the population or, in a time-series context, by different latent states (regimes) of the underlying process. We introduce a new command swopit that fits a mixture of ordered probit (OP) models for ordinal outcomes with either exogenous or endogenous assignment to two latent classes (or regimes). The decision-making process, which determines an outcome in each class (regime), is represented by a separate OP model. The class-assignment (regime-switching) mechanism is represented by a binary probit model. Endogenous regime switching implies that the unobservables in the class-assignment model are correlated with the unobservables in the outcome models. The three latent equations from the class-assignment model and two outcome models, each with its own set of observables (control variables) and unobservables (disturbance terms), are estimated simultaneously by full information maximum likelihood, providing the probabilities of both the discrete choices and the latent classes for each observation. In this way, observed explanatory variables can have different marginal effects on the choice probabilities in different classes. We provide a battery of postestimation commands, assess by Monte Carlo experiments the finite-sample performance of the maximum likelihood estimator of the parameters, choice and regime probabilities and their standard errors (both the asymptotic and bootstrap ones), and apply the new command to model the policy interest rates and health status responses.

## Installation instructions:
1. Download (or clone) package and store on your device;
2. Set path of package in Stata using: cd "C:/yourpath";
3. Run using artificial or real dataset.

## To use on calibrated data:
We have added a calibration file with precalibrated parameters. To run this:
1. Run test_calibrswop.do from do-file editor;
2. Run appswop2.do from do-file editor;
3. (Un)comment post-estimation commands as you wish.

### To use on real dataset:
The two different datasets used in the paper are available. To run this:
1. Run fmm_health.dta/policy_rate.dta from command window;
2. In Stata run "swopit" in command window according to help file;
3. Perform postestimation commands according to help file.
