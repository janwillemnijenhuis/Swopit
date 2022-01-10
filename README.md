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

## To use on real dataset:
The two different datasets used in the paper are available. To run this:
1. Run fmm_health.dta/policy_rate.dta from command window;
2. In Stata run "swopit" in command window according to help file;
3. Perform postestimation commands according to help file.

## Folder structure
The folder structure is shown in the figure below the explanation of the folder structure.<br />
`Community Contributed Software` contains the files as sent to Stata Journal.<br />
`Paper_new/Model` contains all development code.<br />
&emsp;`DefModel.ado` contains all model definitions.<br />
&emsp;`estimates.ado` contains the main estimation routines and postestimation commands.<br />
&emsp;`helpfunctest.ado` contains the auxiliary functions used in optimization.<br />
&emsp;`swopit.ado` the Stata interface of the swopit command.<br />
&emsp;`swopitprobabilities.ado` the Stata interface of the swopitprobabilities command.<br />
&emsp;`swopitmargins.ado` the Stata interface of the swopitmargins command.<br />
&emsp;`swopitclassification.ado` the Stata interface of the swopitclassification command.<br />
&emsp;`swopitpredict.ado` the Stata interface of the swopitpredict command.<br />
&emsp;`swopit.sthlp` swopit help file.<br />
&emsp;`swopitpostestimation.sthlp` swopitpostestimation help file.<br />
`Calibration files` contains files used in debugging and for determining simulation parameters. <br />
&emsp;`application.do` do-file with different examples of the command.<br />
&emsp;`calibration.do` do-file which performs the calibration of parameters used in simulation.<br />
`Data files` contains data files on which the swopit command can be estimated. <br />
&emsp;`fmm_health.dta` data on ordinal responses of a health survey. <br />
&emsp;`policy_rate.dta` data on policy rate changes (used in the paper). <br />
`Simulation files` contains the simulation files. <br />
&emsp;`create_sets.py` creates the bash scripts used on the Lisa cluster for simulations. <br />
&emsp;`merge_matamatrix.do` combines the resulting matrices to obtain simulation results. <br />
&emsp;`runsim.do` runs simulations. <br />   

```bash
Swopit
│   .DS_Store
│   Community Contributed Software.zip
│   Estimation of two-regime switching ordered probit model.pdf
│   README.md
│   readme.txt
│
├───Community Contributed Software
│       application.do
│       DefModel.ado
│       estimates.ado
│       fmm_health.dta
│       helpfunctest.ado
│       policy_rate.dta
│       readme.txt
│       swopit.ado
│       swopit.sthlp
│       swopitclassification.ado
│       swopitmargins.ado
│       swopitpostestimation.sthlp
│       swopitpredict.ado
│       swopitprobabilities.ado
│
└───Paper_new
    │   .DS_Store
    │
    └───Model
        │   .DS_Store
        │   DefModel.ado
        │   estimates.ado
        │   fmm_health.dta
        │   helpfunctest.ado
        │   policy_rate.dta
        │   sim_results.xlsx
        │   swopit.ado
        │   swopit.sthlp
        │   swopitclassification.ado
        │   swopitmargins.ado
        │   swopitpostestimation.sthlp
        │   swopitpredict.ado
        │   swopitprobabilities.ado
        │
        ├───Calibration files
        │       application.do
        │       appswop2.do
        │       calibration.do
        │       calibration2.do
        │       test.do
        │       test_calibrswop.do
        │
        ├───Data Files
        │       .DS_Store
        │       fmm_health.dta
        │       policy_rate.dta
        │
        └───Simulation files
                create_sets.py
                merge_matamatrix.do
                runsim.do
```