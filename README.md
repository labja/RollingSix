# RollingSix

## Installation

You can install this package from GitHub with
``` r
# install.packages("devtools")
devtools::install_github("labja/RollingSix")
```

## Example

### Setting parameters 
``` r
library(RollingSix)
design <- "RollingSix"
tox_rates <- seq(0.1,0.5,0.1)
futime <- 50
accrual <- 50
nsim <- 10
seed <- 1
```
* **design** The dose-finding design which is employed. So far no option other than "RollingSix" for Rolling Six has been implemented
* **tox_rates** Vector of true toxicity rates for each dose level in ascending order
* **futime** Follow-up time in days
* **accrual** Expected number of patients to be recruited in a year
* **nsim** Number of simulated trials when simulating multiple trials

### Simulating a single trial
``` r
set.seed(seed)
single_trial <- sim_trial(tox_rates=tox_rates,design=design,futime=futime,accrual=accrual)
single_trial
# Result of simulated trial
# single_trial <- sim_trial(tox_rates=tox_rates,design=design,futime=futime,accrual=accrual)
# single_trial
# $res_dlt
# pat dose dlt
#    1    1   0
#    2    1   0
#    3    1   0
#    4    1   0
#    5    1   0
#    6    1   0
#    7    2   0
#    8    2   1
#    9    2   1
#    10   2   1
#    11   2   0
#    12   2   0
# 
# $res_time
# pat t_start_recruit t_recruited t_start_treat t_end_treat
#    1               0           1             1          51
#    2               1           2             2          52
#    3               2           9             9          59
#    4               9          17            17          67
#    5              17          18            18          68
#    6              18          22            22          72
#    7              22          28            73         123
#    8              28          30            30          75
#    9              30          34            34          35
#   10              34          36            36          79
#   11              36          41            41          91
#   12              41          70            70         120
# 
# $mtd_est
# [1] 1
```
In this simulated trial the first six patients are treated at dose level 1 with no DLTs observed. The next six patients are treated at dose level 2 and three DLTs are observed. Therefore, the estimated MTD is dose level 1. Patients 7 to 12 have to wait for day 72 to start treatment even though they were recruited earlier because 
