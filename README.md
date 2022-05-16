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
tox_rates <- seq(0.1,0.4,0.1)
futime <- 30
accrual <- 50
nsim <- 10
seed <- 2
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
# $res_dlt
# pat dose dlt
#   1    1   0
#   2    1   0
#   3    1   0
#   4    1   0
#   5    1   0
#   6    1   0
#   7    2   0
#   8    2   1
#   9    2   0
#  10    2   0
#  11    2   0
#  12    2   1
# 
# $res_time
# pat t_start_recruit t_recruited t_start_treat t_end_treat
# 1          0          14            14          44
# 2         14          16            16          46
# 3         16          17            17          47
# 4         17          25            25          55
# 5         25          29            29          59
# 6         29          39            39          69
# 7         39          40            59          99
# 8         40          50            59          74
# 9         50          58            59          99
# 10        58          70            70         100
# 11        70          71            71         101
# 12        71          76            76          92
# 
# $mtd_est
# [1] 1
```
* **res_dlt** Data frame with dose level and DLT result for each patient. In this case the first six patients receive dose level 1 without any observed DLTs. Patients 7 to 12 receive dose level 2 with patient 8 and patient 12 experiencing a DLT
* **res_time** Data frame with important time points in days since trial start for each patient. The first six patients can start treatment as soon as they are recruited at dose level 1. Patients 7, 8 and 9 are recruited between days 40 and 58 but need to wait until day 59 before receiving dose level 2. The reason is that on day 59 five out of five patients at dose level 1 have been fully observed without any DLTs and regardless of the DLT result for patient 6 the dose will be escalated.
* **mtd_est** The estimated MTD at the end of the trial which is dose level 1 in this case 

### Summarizing a single trial
``` r
summary_trial(single_trial)
# $mtd_est
# [1] 1
# 
# $n_pat
# [1] 12
# 
# $n_dlt
# [1] 2
# 
# $n_wait
# [1] 3
# 
# $median_wait
# [1] 9
# 
# $total_wait
# [1] 29
# 
# $trial_duration
# [1] 101
```

* **mtd_est** The estimated MTD at the end of the trial which is dose level 1 in this case 
* **n_pat** The total number of patients which is 12 in this case
* **n_dlt** The total number of DLTs which is 3 in this case
* **n_wait** The total number of patients who have to wait after beeing recruited which is 3 in this case
* **median_wait** The median number of days patients have to wait (Waiting times of 0 days aren't included)
* **total_wait** The number of days all patients combined have to wait
* **trial_duration** The number of days it takes until the trial is completed

### Simulating multiple trials
``` r
multiple_trials <- sim_trials(tox_rates=tox_rates,design=design,futime=futime,accrual=accrual,nsim=nsim,seed=seed)
multiple_trials$res
# mtd_est n_pat n_dlt n_wait median_wait total_wait trial_duration
#     1    12     2      3         9.0         29            101
#     1    10     3      3        20.0         56            112
#     1    12     2      3        11.0         35            121
#     3    22     3      8         8.5         75            167
#     1    12     3      1        14.0         14            137
#     0     6     2      0          NA          0             83
#     3    24     5      4        15.0         57            226
#     2    18     2      7        16.0        107            169
#     2    18     3      3        21.0         56            181
#     3    22     6     14        16.5        253            165
```
The output is a data frame where each simulated trial is represented by a row. The first row corresponds to the example above for a single trial. Over the 10 simulated trials each of the dose level 1, 2 and 3 are estimated to be the MTD and in trial 6 all of the dose levels are deemd too toxic. Additionally, trial 6 is also the only trial in which no patient had to wait before receiving treatment.

### Summarizing multiple trials
TBD

