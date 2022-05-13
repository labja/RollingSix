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
# 1    1    1   0
# 2    2    1   0
# 3    3    1   0
# 4    4    1   0
# 5    5    1   0
# 6    6    1   0
# 7    7    2   0
# 8    8    2   1
# 9    9    2   0
# 10  10    2   0
# 11  11    2   0
# 12  12    2   1
# 
# $res_time
# pat t_start_recruit t_recruited t_start_treat t_end_treat
# 1    1               0          14            14          44
# 2    2              14          16            16          46
# 3    3              16          17            17          47
# 4    4              17          25            25          55
# 5    5              25          29            29          59
# 6    6              29          39            39          69
# 7    7              39          40            69          99
# 8    8              40          50            69          74
# 9    9              50          58            69          99
# 10  10              58          70            70         100
# 11  11              70          71            71         101
# 12  12              71          76            76          92
# 
# $mtd_est
# [1] 1
```
* **res_dlt** Data frame with dose level and DLT result for each patient. In this case the first six patients receive dose level 1 without any observed DLTs. Patients 7 to 12 receive dose level 2 with patient 8 and patient 12 experiencing a DLT
* **res_time** Data frame with important time points in days since trial start for each patient. The first six patients can start treatment as soon as they are recruited at dose level 1. Patients 7, 8 and 9 are recruited between days 40 and 58 but need to wait until day 69 before receiving dose level 2. The reason is because that's the earliest day on which all DLT results for dose level 1 are known.
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
# [1] 19
# 
# $total_wait
# [1] 59
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
