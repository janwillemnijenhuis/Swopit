#### COPYRIGHT STATEMENT: We give our consent to anyone to use this code for non-commercial and non-profit purposes only. For commercial purposes contact one of the authors. 
#### © 2021 Andrei Sirchenko, Jochem Huismans and Jan Willem Nijenhuis. All rights reserved.
------------------------------------------------------------------------------
# Swopit
Ordinal responses can be generated, in a time-series context, by different latent regimes or, in a cross-sectional context, by different unobserved classes of population. We introduce a new command **swopit** that fits a mixture of ordered probit models with either exogenous or endogenous switching between two latent classes (or regimes). Switching is endogenous if the unobservables in the class-assignment model are correlated with the unobservables in the outcome models. We provide a battery of postestimation commands, assess by Monte Carlo experiments the finite-sample performance of the maximum likelihood estimator of the parameters, probabilities and their standard errors (both the asymptotic and bootstrap ones), and apply the new command to model the policy interest rates.

## Installation instructions:
1. Download (or clone) package and store on your device (Code -> Download ZIP or Clone);
2. Set path of package in Stata Command Window using: cd "C:/yourpath";
3. Run using artificial or real dataset (both are provided).

## To use on calibrated data:
We have added a calibration file with precalibrated parameters. To run this:
1. Run calibration.do from do-file editor;
2. Run applicaton.do from do-file editor, with the desired options (some examples provided);
3. Use post-estimation commands as you wish, in the do-file or Command Window.

## To use on real dataset:
The two different datasets used in the paper are available. To run this:
1. Run policy_rate.dta from command window;
2. Run Emperical_example.do from do-file editor.

## Folder structure
The folder structure is shown in the figure below. We first give an explanation of the files.<br />
`Community Contributed Software` contains the files as sent to Stata Journal.<br />
`Estimation of two-regime switching ordered probit model - revision.pdf` the latest version of the paper, as submitted to Stata Journal <br />
`Paper_new/Model` contains all development code.<br />
&emsp;&emsp;`DefModel.ado` contains all model definitions.<br />
&emsp;&emsp;`Empirical_example.do` the do-file with the empirical example from the paper <br />
&emsp;&emsp;`estimates.ado` contains the main estimation routines and postestimation commands.<br />
&emsp;&emsp;`helpfunctest.ado` contains the auxiliary functions used in optimization.<br />
&emsp;&emsp;`policy_rate.dta` data on policy rate changes (used in the paper). <br />
&emsp;&emsp;`sim_results.xlsx` simulation results. <br />
&emsp;&emsp;`sim_results_bootstrap.xlsx` simulation results for bootstrap. <br />
&emsp;&emsp;`swopit.ado` the Stata interface of the swopit command.<br />
&emsp;&emsp;`swopitprobabilities.ado` the Stata interface of the swopitprobabilities command.<br />
&emsp;&emsp;`swopitmargins.ado` the Stata interface of the swopitmargins command.<br />
&emsp;&emsp;`swopitclassification.ado` the Stata interface of the swopitclassification command.<br />
&emsp;&emsp;`swopitpredict.ado` the Stata interface of the swopitpredict command.<br />
&emsp;&emsp;`swopit.sthlp` swopit help file.<br />
&emsp;&emsp;`swopitpostestimation.sthlp` swopitpostestimation help file.<br />
&emsp;`Calibration files` contains files used in debugging and for determining simulation parameters. <br />
&emsp;&emsp;`application.do` do-file with different examples of the command.<br />
&emsp;&emsp;`calibration.do` do-file which performs the calibration of parameters used in simulation.<br />
&emsp;`Simulation files` contains the simulation files. <br />
&emsp;&emsp;`create_sets.py` creates the bash scripts used on the Lisa cluster for simulations. <br />
&emsp;&emsp;`merge_matamatrix.do` combines the resulting matrices to obtain simulation results. <br />
&emsp;&emsp;`runsim.do` runs simulations. <br />   
`README.md` this file. <br \>
`readme.txt` the description of the paper, authors and copyright. <br />

```bash
Swopit
│   Estimation of two-regime switching ordered probit model - revision.pdf
│   README.md
│   readme.txt
│
├───Community Contributed Software
│       DefModel.ado
│       Empirical_example.do
│       estimates.ado
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
    └───Model
        │   DefModel.ado
        │   Empirical_example.do
        │   estimates.ado
        │   helpfunctest.ado
        │   policy_rate.dta
        │   sim_results.xlsx
        │   sim_results_bootstrap.xlsx
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
        │       calibration.do
        │
        └───Simulation files
                create_sets.py
                merge_matamatrix.do
                runsim.do
```
